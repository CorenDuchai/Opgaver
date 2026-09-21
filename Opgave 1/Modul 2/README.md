# Linux 101 – Modul 2: Filsystem og adgangskontrol

## Formål

Formålet med modulet er at arbejde med Linux' filsystemhierarki og adgangskontrol, så filer og mapper kun er tilgængelige for de brugere og grupper, der har behov for adgang.

Modulet demonstrerer brug af FHS, standardrettigheder, grupper, `setgid` og ACL'er ud fra princippet om least privilege.

---

## 1. FHS – centrale mapper

| Mappe | Formål |
|---|---|
| `/etc` | Indeholder systemets og programmernes konfigurationsfiler. |
| `/var` | Indeholder data der ændrer sig løbende, fx logs, cache og spool-data. |
| `/var/log` | Indeholder system- og servicelogs. |
| `/home` | Indeholder almindelige brugeres hjemmemapper. |
| `/root` | Root-brugerens hjemmemappe. |
| `/tmp` | Bruges til midlertidige filer. |
| `/srv` | Bruges til data og områder, som stilles til rådighed af serveren eller dens services. |
| `/usr` | Indeholder programmer, biblioteker og anden installeret software. |

---

## 2. Delt projektmappe med grupperettigheder

Der blev oprettet en fælles projektmappe:

```text
/srv/sharedfolder
```

Gruppen `project` blev oprettet:

```bash
sudo groupadd project
```

Brugeren `axel` blev tilføjet til gruppen:

```bash
sudo usermod -aG project axel
```

Projektmappen blev oprettet og fik gruppen `project`:

```bash
sudo mkdir -p /srv/sharedfolder
sudo chown root:project /srv/sharedfolder
sudo chmod 2770 /srv/sharedfolder
```

Rettighederne blev kontrolleret med:

```bash
ls -ld /srv/sharedfolder
```

Resultat:

```text
drwxrws--- root project /srv/sharedfolder
```

### Forklaring af `2770`

```text
2    = setgid
7    = owner: rwx
7    = group: rwx
0    = others: ingen adgang
```

`setgid` på mappen gør, at nye filer og mapper automatisk arver gruppen `project`.

Det er velegnet til et fælles projektområde, fordi flere brugere kan arbejde i samme mappe uden at give adgang til alle brugere på systemet.

### Testbrugere

Der blev oprettet to testbrugere:

```bash
sudo adduser dev1
sudo adduser guest1
```

`dev1` blev tilføjet til projektgruppen:

```bash
sudo usermod -aG project dev1
```

Gruppemedlemskaberne blev kontrolleret:

```bash
groups dev1
groups guest1
```

Resultat:

```text
dev1 : dev1 users project
guest1 : guest1 users
```

### Test af adgang

`dev1`, som er medlem af `project`, kunne oprette en fil:

```bash
sudo -u dev1 touch /srv/sharedfolder/dev1-test.txt
```

`guest1`, som ikke er medlem af gruppen, blev afvist:

```bash
sudo -u guest1 touch /srv/sharedfolder/guest1-test.txt
```

Resultat:

```text
Permission denied
```

Filen fra `dev1` blev kontrolleret:

```bash
ls -l /srv/sharedfolder
```

Resultat:

```text
-rw-r--r-- 1 dev1 project ... dev1-test.txt
```

Filen har automatisk arvet gruppen `project`, hvilket viser at `setgid` fungerer.

**Dokumentation:** `gruppeadgang-og-setgid.png`

---

## 3. Identifikation og rettelse af for brede rettigheder

Der blev oprettet et kontrolleret testmiljø:

```text
/srv/permission-test
```

med filerne:

```text
app.conf
credentials.conf
```

### Før

Filerne blev bevidst konfigureret med for brede rettigheder:

```bash
sudo chmod 666 /srv/permission-test/app.conf
sudo chmod 644 /srv/permission-test/credentials.conf
ls -l /srv/permission-test
```

Resultat:

```text
-rw-rw-rw- app.conf
-rw-r--r-- credentials.conf
```

Problemerne var:

- `app.conf` var world-writable (`666`), så alle brugere kunne ændre konfigurationen.
- `credentials.conf` var world-readable (`644`), så alle brugere kunne læse potentielt følsomme oplysninger.

### Efter

Rettighederne blev strammet:

```bash
sudo chmod 640 /srv/permission-test/app.conf
sudo chmod 600 /srv/permission-test/credentials.conf
ls -l /srv/permission-test
```

Resultat:

```text
-rw-r----- app.conf
-rw------- credentials.conf
```

`app.conf` kan nu kun ændres af ejeren, mens gruppen kun kan læse filen. Andre brugere har ingen adgang.

`credentials.conf` kan kun læses og ændres af ejeren.

**Dokumentation:** `forkerte-rettigheder-før-og-efter.png`

---

## 4. Midlertidig adgang med ACL

Formålet med testen var at give `guest1` midlertidig og begrænset adgang til projektmappen uden at tilføje brugeren til gruppen `project`.

Før ændringen blev det kontrolleret, at `guest1` ikke var medlem af projektgruppen:

```bash
groups guest1
```

Resultat:

```text
guest1 : guest1 users
```

Den eksisterende ACL blev kontrolleret:

```bash
getfacl /srv/sharedfolder
```

Der var ingen særskilt ACL for `guest1`.

### Tilføj ACL

`guest1` fik read/execute-adgang:

```bash
sudo setfacl -m u:guest1:rx /srv/sharedfolder
```

ACL'en blev kontrolleret:

```bash
getfacl /srv/sharedfolder
```

Relevant resultat:

```text
user:guest1:r-x
```

Det betyder, at `guest1` kan læse og tilgå mappen, men ikke skrive til den.

### Test af den afgrænsede adgang

`guest1` kunne nu se indholdet:

```bash
sudo -u guest1 ls -l /srv/sharedfolder
```

Men brugeren kunne ikke oprette en fil:

```bash
sudo -u guest1 touch /srv/sharedfolder/guest1-acl-test.txt
```

Resultat:

```text
Permission denied
```

Det viser, at ACL'en gav den ønskede begrænsede adgang uden at ændre gruppemedlemskabet.

### Fjern ACL igen

Den midlertidige ACL blev fjernet:

```bash
sudo setfacl -x u:guest1 /srv/sharedfolder
```

Efter fjernelsen blev adgangen testet igen:

```bash
sudo -u guest1 ls -l /srv/sharedfolder
```

Resultat:

```text
Permission denied
```

`guest1` var dermed tilbage til den oprindelige adgangstilstand.

**Dokumentation:** `ACL.png`

---

## Hvorfor ikke `chmod 777`?

`chmod 777` giver owner, group og alle øvrige brugere fuld læse-, skrive- og execute-adgang.

Det bryder med princippet om least privilege, fordi brugere uden et arbejdsrelateret behov også får mulighed for at læse, ændre eller slette data.

I projektmappen blev der i stedet brugt:

```bash
sudo chown root:project /srv/sharedfolder
sudo chmod 2770 /srv/sharedfolder
```

Dermed styres den normale adgang via gruppen `project`, mens ACL bruges til særlige, midlertidige undtagelser.

---

## Resultat

Modul 2 er gennemført med:

- kort redegørelse for centrale FHS-mapper
- delt projektmappe med gruppebaseret adgang
- `setgid` til automatisk gruppe-arv
- test af bruger med og uden gruppeadgang
- identifikation og rettelse af to for brede filrettigheder
- dokumentation af rettigheder før og efter ændring
- midlertidig, afgrænset adgang med ACL
- test af ACL-adgang
- fjernelse af ACL og kontrol af, at adgangen igen blev fjernet
- begrundelse for hvorfor `chmod 777` ikke anvendes
