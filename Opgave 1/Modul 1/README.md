# Linux 101 – Modul 1: VM-opsætning og netværk

## Formål

Formålet med modulet er at etablere en Linux-server med en kontrolleret netværksopsætning og sikker fjernadgang via SSH.

Serveren er installeret som en virtuel maskine i Microsoft Hyper-V med Ubuntu Server uden grafisk brugerflade. SSH-adgangen er konfigureret til kun at tillade nøglebaseret autentifikation. Dette følger opgavens krav om en reproducerbar serveropsætning med begrænset angrebsflade.

---

## System

| Indstilling | Konfiguration |
|---|---|
| Hypervisor | Microsoft Hyper-V |
| Operativsystem | Ubuntu Server 26.04.1 LTS |
| Hostname | `linux101-securebase` |
| Administrativ bruger | `axel` |
| Root-login via SSH | Deaktiveret |
| SSH password-login | Deaktiveret |
| SSH key authentication | Aktiveret |

Ubuntu Server er installeret uden GUI, da serveren ikke har behov for en grafisk brugerflade. Dette reducerer antallet af installerede komponenter og dermed også den potentielle angrebsflade.

Hostname `linux101-securebase` er valgt, fordi det beskriver maskinens funktion og gør serveren lettere at identificere i et miljø med flere systemer.

---

## Netværkskonfiguration

Serveren har to virtuelle netværkskort.

### eth0 – internetforbindelse

`eth0` er tilsluttet Hyper-Vs `Default Switch` og modtager sin IPv4-konfiguration via DHCP.

Formålet med dette interface er at give serveren adgang til internettet til blandt andet opdateringer og installation af software.

```text
eth0
Hyper-V Default Switch
IPv4: DHCP
```

### eth1 – management-netværk

`eth1` er tilsluttet en separat intern Hyper-V-switch kaldet:

```text
Linux101-Internal
```

Netværket er konfigureret således:

```text
Windows host:  10.10.10.1/24
Ubuntu server: 10.10.10.10/24
```

Der er ikke konfigureret gateway eller DNS på dette interface, da det kun benyttes til lokal administration og SSH.

Den statiske adresse sikrer, at serverens management-adresse ikke ændrer sig og dermed altid kan bruges til administration.

Netplan-konfigurationen findes i:

```text
/etc/netplan/00-installer-config.yaml
```

Konfiguration:

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      match:
        macaddress: 00:15:5d:b9:68:01
      set-name: eth0

    eth1:
      dhcp4: false
      addresses:
        - 10.10.10.10/24
      match:
        macaddress: 00:15:5d:b9:68:03
      set-name: eth1
```

---

## Administrativ bruger

Serveren administreres med den almindelige bruger:

```text
axel
```

Direkte administration som root undgås. Administrative handlinger udføres i stedet med `sudo`.

Dette giver bedre sporbarhed og reducerer risikoen ved at arbejde permanent med ubegrænsede root-rettigheder.

---

## SSH

OpenSSH Server blev installeret sammen med Ubuntu Server.

SSH benyttes via det interne management-interface:

```powershell
ssh axel@10.10.10.10
```

### SSH-nøgle

Der er oprettet en ED25519-nøgle på Windows-klienten:

```powershell
ssh-keygen -t ed25519
```

Den offentlige nøgle er derefter kopieret til serverens:

```text
/home/axel/.ssh/authorized_keys
```

Nøglebaseret autentifikation reducerer risikoen for password-baserede brute-force-angreb og gør det muligt helt at deaktivere SSH-login med password.

---

## SSH-hardening

Følgende indstillinger anvendes:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
```

Ubuntu havde desuden følgende standardkonfiguration fra cloud-init:

```text
/etc/ssh/sshd_config.d/50-cloud-init.conf
```

Denne aktiverede password-login. Derfor blev der oprettet en særskilt hardening-fil:

```text
/etc/ssh/sshd_config.d/00-hardening.conf
```

med:

```text
PasswordAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

SSH-konfigurationen blev valideret med:

```bash
sudo sshd -t
```

og tjenesten derefter genstartet:

```bash
sudo systemctl restart ssh
```

Den effektive konfiguration blev kontrolleret med:

```bash
sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin|pubkeyauthentication'
```

Resultat:

```text
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
```

---

## Test af SSH-adgang

### Nøglebaseret login

Normal forbindelse fra Windows:

```powershell
ssh axel@10.10.10.10
```

Login gennemføres uden serverbrugerens password.

Dokumentation:

```text
login med key.png
```

### Password-login

Password-login blev testet eksplicit med:

```powershell
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no axel@10.10.10.10
```

Resultat:

```text
Permission denied (publickey).
```

Dette dokumenterer, at password-baseret SSH-login er deaktiveret.

Dokumentation:

```text
denied login med password.png
```

### Effektiv SSH-konfiguration

Den aktive SSH-konfiguration er dokumenteret i:

```text
Effektiv SSH-konfiguration efter hardening.png
```

---

## Sikkerhedsmæssige valg

| Valg | Begrundelse |
|---|---|
| Ubuntu Server uden GUI | Færre installerede komponenter reducerer angrebsfladen og ressourceforbruget. |
| Ikke-root administratorbruger | Daglig administration udføres uden permanent root-adgang og giver bedre sporbarhed. |
| `PermitRootLogin no` | Forhindrer direkte SSH-login til systemets mest privilegerede konto. |
| `PasswordAuthentication no` | Reducerer risikoen for brute-force og password-baserede angreb. |
| ED25519 SSH-nøgle | Giver stærk nøglebaseret autentifikation i stedet for password-login. |
| Separat management-interface | Adskiller management-trafik fra serverens almindelige internetforbindelse. |
| Statisk management-IP | Giver en kendt og stabil adresse til administration af serveren. |
| Ingen gateway på management-nettet | Det interne interface kan kun bruges på det lokale management-net og bliver ikke en alternativ internetroute. |

---

## Resultat

Modul 1 er afsluttet med:

- Ubuntu Server installeret uden GUI
- sigende hostname
- separat ikke-root administratorbruger
- statisk management-IP
- fungerende SSH-adgang
- nøglebaseret SSH-autentifikation
- direkte root-login deaktiveret
- password-login deaktiveret
- test og screenshots af SSH-konfigurationen
