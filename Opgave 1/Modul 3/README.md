# Linux 101 – Modul 3: Bruger- og gruppestyring

## Formål

Formålet med modulet er at opbygge en rollebaseret adgangsstruktur med forskellige rettigheder for administrator-, developer- og guest-brugere.

Opsætningen følger principperne om **least privilege** og **segregation of duties**, så brugere kun får de rettigheder, der er nødvendige for deres rolle.

---

## 1. Brugerroller

Der blev anvendt tre testbrugere:

| Bruger | Rolle | Gruppe |
|---|---|---|
| `admin1` | Administrator | `admins` |
| `dev1` | Developer | `developers` |
| `guest1` | Guest | `guests` |

Brugeren `axel` blev beholdt som den oprindelige systemadministrator og blev ikke brugt som test-admin, så den eksisterende administrative adgang ikke blev påvirket under sudo-testen.

### Oprettelse af admin-bruger og grupper

```bash
sudo adduser admin1

sudo groupadd admins
sudo groupadd developers
sudo groupadd guests
```

Brugerne blev tilføjet til deres respektive grupper:

```bash
sudo usermod -aG admins admin1
sudo usermod -aG developers dev1
sudo usermod -aG guests guest1
```

Rollerne blev kontrolleret med:

```bash
id admin1
id dev1
id guest1
```

Resultatet viste blandt andet:

```text
admin1 → admins
dev1   → developers
guest1 → guests
```

`dev1` er desuden stadig medlem af gruppen `project` fra Modul 2.

---

## 2. Adgang til fælles projektområde

Der blev oprettet et separat projektområde til rolle-testen:

```text
/srv/role-project
```

Mappen blev oprettet med gruppen `developers`:

```bash
sudo mkdir -p /srv/role-project
sudo chown root:developers /srv/role-project
sudo chmod 2770 /srv/role-project
```

Dette giver `developers` læse-, skrive- og execute-adgang til projektområdet.

### Read-only adgang til guest-rollen

Gruppen `guests` fik read/execute-adgang via ACL:

```bash
sudo setfacl -m g:guests:rx /srv/role-project
```

ACL'en blev kontrolleret med:

```bash
getfacl /srv/role-project
```

Relevant resultat:

```text
group::rwx
group:guests:r-x
other::---
```

Dermed kan developers arbejde med projektfilerne, mens guests kun kan læse og tilgå området.

---

## 3. Test af developer- og guest-rettigheder

Developer-brugeren blev testet med:

```bash
sudo -u dev1 touch /srv/role-project/dev-test.txt
```

Kommandoen lykkedes, hvilket viser at `dev1` har skriveadgang.

Guest-brugeren kunne læse indholdet:

```bash
sudo -u guest1 ls -l /srv/role-project
```

men kunne ikke oprette filer:

```bash
sudo -u guest1 touch /srv/role-project/guest-test.txt
```

Resultat:

```text
Permission denied
```

Det viser, at guest-rollen har read-only adgang.

---

## 4. Granulære sudo-rettigheder

Admin-brugeren skulle ikke have ubegrænset sudo-adgang.

Der blev derfor oprettet en separat sudoers-fil:

```text
/etc/sudoers.d/admin1
```

Filen blev redigeret med:

```bash
sudo visudo -f /etc/sudoers.d/admin1
```

Indhold:

```text
admin1 ALL=(root) /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
```

Dermed må `admin1` kun:

```text
systemctl status ssh
systemctl restart ssh
```

som root.

Sudoers-filen blev sat til korrekte rettigheder og valideret:

```bash
sudo chmod 440 /etc/sudoers.d/admin1
sudo visudo -cf /etc/sudoers.d/admin1
```

Resultat:

```text
/etc/sudoers.d/admin1: parsed OK
```

De tilladte kommandoer blev kontrolleret med:

```bash
sudo -l -U admin1
```

Resultat:

```text
User admin1 may run the following commands on linux101-securebase:
    (root) /usr/bin/systemctl status ssh, /usr/bin/systemctl restart ssh
```

---

## 5. Test af begrænset sudo

Der blev skiftet til `admin1`:

```bash
su - admin1
```

En tilladt kommando blev testet:

```bash
sudo /usr/bin/systemctl status ssh
```

Denne kommando lykkedes.

Derefter blev en ikke-tilladt kommando testet:

```bash
sudo /usr/bin/apt update
```

Denne blev afvist:

```text
sudo: I'm sorry admin1. I'm afraid I can't do that
```

Det dokumenterer, at `admin1` ikke har ubegrænset sudo-adgang.

---

## 6. Dokumentation af roller og grupper

Grupperne blev kontrolleret med:

```bash
getent group admins
getent group developers
getent group guests
```

Brugerrollerne blev kontrolleret med:

```bash
id admin1
id dev1
id guest1
```

Sudoers-reglen blev vist med:

```bash
sudo cat /etc/sudoers.d/admin1
sudo -l -U admin1
```

**Dokumentation:** `modul3-roller-og-granulaer-sudo.png`

---

## Rolleskema

| Bruger | Gruppe/rolle | Rettigheder | Begrundelse |
|---|---|---|---|
| `admin1` | `admins` | Må kun se status og genstarte SSH via sudo | Administrative rettigheder begrænses til konkrete nødvendige opgaver |
| `dev1` | `developers` | Read/write til `/srv/role-project` | Developer skal kunne arbejde med og ændre projektfiler |
| `guest1` | `guests` | Read-only til `/srv/role-project` | Guest må kunne læse projektdata, men ikke ændre dem |

---

## Sikkerhedsmæssige valg

### Least privilege

Ingen af testbrugerne får flere rettigheder end nødvendigt.

`admin1` får ikke generel sudo-adgang, men kun adgang til to specifikke SSH-relaterede kommandoer.

### Segregation of duties

Rollerne er adskilt:

- administrator håndterer en begrænset administrativ funktion
- developer kan ændre projektdata
- guest kan kun læse projektdata

Hvis én konto kompromitteres, giver den derfor ikke automatisk adgang til alle funktioner på serveren.

### Individuelle brugerkonti

Der anvendes individuelle konti frem for delte logins. Det gør det muligt at se, hvilken bruger der har udført en handling, og giver bedre sporbarhed.

---

## Resultat

Modul 3 er gennemført med:

- tre separate brugerroller
- separate grupper til admin, developer og guest
- developer med skriveadgang til fælles projektområde
- guest med read-only adgang
- granulær sudo-konfiguration via `/etc/sudoers.d/`
- test af både tilladt og afvist sudo-kommando
- dokumentation af grupper, `id`-output og sudoers-regler
