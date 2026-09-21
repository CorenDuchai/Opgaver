#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------
# Linux 101 - reproducerbar serveropsætning
# ------------------------------------------------------------

PRIMARY_USER="${SUDO_USER:-axel}"

ADMIN_USER="admin1"
DEV_USER="dev1"
GUEST_USER="guest1"

PROJECT_GROUP="project"
ADMIN_GROUP="admins"
DEV_GROUP="developers"
GUEST_GROUP="guests"

MGMT_SUBNET="10.10.10.0/24"

MONITOR_SCRIPT="/usr/local/bin/system-monitor.sh"
MONITOR_LOG="/var/log/system-monitor.log"

# ------------------------------------------------------------
# Hjælpefunktioner
# ------------------------------------------------------------

require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Kør scriptet med sudo:"
        echo "sudo $0"
        exit 1
    fi
}

ensure_packages() {
    echo
    echo "=== Pakker ==="

    local packages=(acl ufw cron openssh-server procps)
    local missing=()

    for package in "${packages[@]}"; do
        if dpkg -s "$package" >/dev/null 2>&1; then
            echo "[OK] $package er installeret."
        else
            missing+=("$package")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        echo "[SET] Installerer manglende pakker: ${missing[*]}"
        apt-get update
        apt-get install -y "${missing[@]}"
    fi
}

ensure_group() {
    local group="$1"

    if getent group "$group" >/dev/null; then
        echo "[OK] Gruppe findes: $group"
    else
        groupadd "$group"
        echo "[SET] Gruppe oprettet: $group"
    fi
}

ensure_user() {
    local user="$1"

    if id "$user" >/dev/null 2>&1; then
        echo "[OK] Bruger findes: $user"
    else
        useradd -m -s /bin/bash "$user"
        echo "[SET] Bruger oprettet: $user"
    fi
}

ensure_membership() {
    local user="$1"
    local group="$2"

    if id -nG "$user" | tr ' ' '\n' | grep -qx "$group"; then
        echo "[OK] $user er allerede medlem af $group"
    else
        usermod -aG "$group" "$user"
        echo "[SET] Tilføjede $user til $group"
    fi
}

configure_users_and_groups() {
    echo
    echo "=== Brugere og grupper ==="

    ensure_group "$PROJECT_GROUP"
    ensure_group "$ADMIN_GROUP"
    ensure_group "$DEV_GROUP"
    ensure_group "$GUEST_GROUP"

    ensure_user "$ADMIN_USER"
    ensure_user "$DEV_USER"
    ensure_user "$GUEST_USER"

    ensure_membership "$PRIMARY_USER" "$PROJECT_GROUP"
    ensure_membership "$DEV_USER" "$PROJECT_GROUP"
    ensure_membership "$DEV_USER" "$DEV_GROUP"
    ensure_membership "$GUEST_USER" "$GUEST_GROUP"
    ensure_membership "$ADMIN_USER" "$ADMIN_GROUP"
}

configure_filesystem() {
    echo
    echo "=== Filsystem og adgangskontrol ==="

    mkdir -p /srv/sharedfolder
    chown root:"$PROJECT_GROUP" /srv/sharedfolder
    chmod 2770 /srv/sharedfolder

    echo "[OK] /srv/sharedfolder -> root:$PROJECT_GROUP 2770"

    mkdir -p /srv/role-project
    chown root:"$DEV_GROUP" /srv/role-project
    chmod 2770 /srv/role-project
    setfacl -m g:"$GUEST_GROUP":rx /srv/role-project

    echo "[OK] /srv/role-project konfigureret med guest read-only ACL"

    mkdir -p /srv/permission-test

    touch /srv/permission-test/app.conf
    touch /srv/permission-test/credentials.conf

    chown root:root /srv/permission-test/app.conf
    chown root:root /srv/permission-test/credentials.conf

    chmod 640 /srv/permission-test/app.conf
    chmod 600 /srv/permission-test/credentials.conf

    echo "[OK] Sikre filrettigheder sat på testfiler"
}

configure_sudo() {
    echo
    echo "=== Granulær sudo ==="

    cat > /etc/sudoers.d/admin1 <<'EOF'
admin1 ALL=(root) /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
EOF

    chmod 440 /etc/sudoers.d/admin1
    visudo -cf /etc/sudoers.d/admin1

    echo "[OK] Granulær sudo-regel installeret"
}

configure_ssh() {
    echo
    echo "=== SSH-hardening ==="

    local authorized_keys="/home/$PRIMARY_USER/.ssh/authorized_keys"

    if [[ -s "$authorized_keys" ]]; then
        mkdir -p /etc/ssh/sshd_config.d

        cat > /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

        sshd -t
        systemctl restart ssh

        echo "[OK] SSH hardening aktiv."
    else
        echo "[SKIP] Ingen authorized_keys fundet for $PRIMARY_USER."
        echo "[SKIP] PasswordAuthentication blev derfor ikke deaktiveret."
    fi
}

configure_firewall() {
    echo
    echo "=== Firewall ==="

    ufw default deny incoming
    ufw default allow outgoing

    ufw allow from "$MGMT_SUBNET" to any port 22 proto tcp
    ufw --force enable

    echo "[OK] UFW aktiv. SSH tilladt fra $MGMT_SUBNET"
}

configure_monitoring() {
    echo
    echo "=== Monitorering ==="

    cat > "$MONITOR_SCRIPT" <<'EOF'
#!/bin/bash

LOG="/var/log/system-monitor.log"

DISK_THRESHOLD=85
RAM_THRESHOLD=90

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

CPU=$(vmstat 1 2 | tail -1 | awk '{print 100 - $15}')
RAM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2 * 100}')
DISK=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "$TIMESTAMP CPU=${CPU}% RAM=${RAM}% DISK=${DISK}%" >> "$LOG"

if (( DISK > DISK_THRESHOLD )); then
    echo "$TIMESTAMP WARNING: Disk usage is ${DISK}% - threshold is ${DISK_THRESHOLD}%" >> "$LOG"
fi

if awk "BEGIN {exit !($RAM > $RAM_THRESHOLD)}"; then
    echo "$TIMESTAMP WARNING: RAM usage is ${RAM}% - threshold is ${RAM_THRESHOLD}%" >> "$LOG"
fi
EOF

    chmod 750 "$MONITOR_SCRIPT"

    touch "$MONITOR_LOG"
    chown root:adm "$MONITOR_LOG"
    chmod 640 "$MONITOR_LOG"

    echo "[OK] Monitoreringsscript installeret"
}

configure_logrotate() {
    echo
    echo "=== Logrotation ==="

    cat > /etc/logrotate.d/system-monitor <<'EOF'
/var/log/system-monitor.log {
    su root adm
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
}
EOF

    logrotate -d /etc/logrotate.d/system-monitor >/dev/null 2>&1

    echo "[OK] Logrotate-konfiguration valideret"
}

configure_cron() {
    echo
    echo "=== Cron ==="

    local cron_line="*/5 * * * * /usr/local/bin/system-monitor.sh"

    systemctl enable --now cron

    if crontab -l 2>/dev/null | grep -Fqx "$cron_line"; then
        echo "[OK] Monitoreringsjob findes allerede."
    else
        (
            crontab -l 2>/dev/null || true
            echo "$cron_line"
        ) | crontab -

        echo "[SET] Monitoreringsjob tilføjet til root crontab."
    fi
}

main() {
    require_root

    echo "========================================"
    echo " Linux 101 - Setup"
    echo "========================================"

    ensure_packages
    configure_users_and_groups
    configure_filesystem
    configure_sudo
    configure_ssh
    configure_firewall
    configure_monitoring
    configure_logrotate
    configure_cron

    echo
    echo "========================================"
    echo " Setup gennemført uden fejl"
    echo "========================================"
}

main
