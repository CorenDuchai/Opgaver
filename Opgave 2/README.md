# Opgave 2 – Windows OS intro (AD-lab)

Denne opgave samler VM-/netværksopsætning, Active Directory, Group Policy, PowerShell, Registry Editor og Event Viewer i et mindre Windows-domænemiljø.

Målet har været at bygge et reproducerbart og dokumenterbart lab, hvor sikkerhedskonfiguration ikke kun bliver sat, men også verificeret.

## Miljø

- Hyper-V på Windows 11 host
- Domæne: `spec.test`
- Domain Controller: `DC01`
- Windows-klient: `CLIENT01`
- Intern Hyper-V switch til domænetrafik
- DC01 fungerer som Active Directory Domain Services- og DNS-server
- CLIENT01 er domain-joined og placeret i Workstations-OU'en

## Active Directory

AD-strukturen er oprettet med PowerShell-scriptet [create-ad-structure.ps1](./create-ad-structure.ps1).

Strukturen er bygget under en separat top-level OU:

```text
spec.test
└── OU=SpecLab
    ├── OU=Users
    │   ├── OU=Admins
    │   ├── OU=Developers
    │   └── OU=Guests
    ├── OU=Computers
    │   ├── OU=Servers
    │   └── OU=Workstations
    └── OU=Groups
```

Der er oprettet tre globale security groups:

- `GG-Admins`
- `GG-Developers`
- `GG-Guests`

Testbrugere:

- `admin1` → `GG-Admins`
- `dev1` → `GG-Developers`
- `guest1` → `GG-Guests`

Scriptet er lavet idempotent, så det kan køres igen uden at oprette dubletter.

Dokumentation:

- [OU script idempotent](./OU%20script%20idempotent.png)
- [Group memberships](./group-memberships.png)

## Group Policy

GPO'en **SpecLab - Workstation Security Baseline** er oprettet med [create-workstation-gpo.ps1](./create-workstation-gpo.ps1) og linket til:

```text
OU=Workstations,OU=Computers,OU=SpecLab,DC=spec,DC=test
```

GPO'en konfigurerer:

- Windows Firewall aktiveret på Domain, Private og Public profiler
- Machine inactivity timeout på 900 sekunder
- PowerShell Script Block Logging
- PowerShell Module Logging

CLIENT01 blev flyttet til Workstations-OU'en, hvorefter `gpupdate /force` og `gpresult /r` blev brugt til at verificere, at GPO'en faktisk blev anvendt.

Derudover bruges [verify-gpo.ps1](./verify-gpo.ps1) til at kontrollere de konkrete settings lokalt på klienten.

Dokumentation:

- [GPO script run](./GPO-script%20run.png)
- [GPO verification](./GPO-verification.png)

### Sikkerhedsmæssig begrundelse

GPO giver centraliseret håndhævelse af sikkerhedsindstillinger. Det gør konfigurationen ensartet og reproducerbar på klientmaskiner, men betyder samtidig, at en fejlkonfigureret GPO kan påvirke mange systemer på én gang. Derfor er denne GPO scoped specifikt til Workstations-OU'en og ikke til Domain Controllers.

PowerShell logging er aktiveret, fordi PowerShell både er et vigtigt administrationsværktøj og ofte bruges som "living off the land"-værktøj ved angreb. Logging forbedrer derfor muligheden for efterfølgende detektion og analyse.

## Registry Editor

På CLIENT01 blev følgende værdi ændret:

```text
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
HideFileExt
```

Ændringen var:

```text
1 → 0
```

Det betyder, at kendte filendelser vises i Explorer.

Sikkerhedsmæssigt gør synlige filendelser det nemmere for brugeren at opdage filer, der forsøger at skjule deres egentlige filtype, eksempelvis en fil med et navn som `invoice.pdf.exe`.

Dokumentation:

- [Registry før ændring](./prior-regedit.png)
- [Registry efter ændring](./after-regedit.png)

## Event Viewer og auditing

Security-loggen blev brugt til at identificere konkrete sikkerhedshændelser på CLIENT01 og DC01.

| Event ID | Betydning | Eksempel i lab |
| --- | --- | --- |
| 4624 | Successful logon | Successful logon på CLIENT01 |
| 4625 | Failed logon | Failed logon for `dev1` |
| 4720 | User account created | `dev2` oprettet i domænet af Administrator |
| 4732 | Member added to local security group | `dev1` tilføjet til Remote Desktop Users |

Dokumentation:

- [Event Viewer 4624](./eventviewer%204624.png)
- [Event Viewer 4625](./eventviewer%204625.png)
- [Event Viewer 4720](./eventviewer%204720.png)
- [Event Viewer 4732](./eventviewer%204732.png)

### Detektionsperspektiv

Event Viewer demonstrerer forskellen mellem forebyggelse og detektion. Firewall, adgangsstyring og GPO reducerer risikoen, mens audit logs giver mulighed for at se, hvad der faktisk er sket.

De valgte events viser blandt andet:

- succesfulde og fejlede loginforsøg
- oprettelse af nye konti
- ændringer i gruppemedlemskab

Det er hændelser, som er relevante ved både almindelig drift og sikkerhedsovervågning.

## PowerShell og reproducerbarhed

Følgende scripts indgår i opgaven:

- [create-ad-structure.ps1](./create-ad-structure.ps1) – opretter OU'er, grupper og brugere
- [create-workstation-gpo.ps1](./create-workstation-gpo.ps1) – opretter og linker workstation security baseline
- [verify-gpo.ps1](./verify-gpo.ps1) – verificerer de anvendte GPO-indstillinger på klienten

Ved at bruge scripts i stedet for kun GUI-konfiguration bliver opsætningen lettere at gentage, kontrollere og dokumentere.

## Resultat

Labbet indeholder nu:

- fungerende Active Directory-domæne
- strukturerede OU'er, grupper og brugere
- domain-joined Windows-klient
- centralt håndhævet workstation security GPO
- verificerede firewall- og PowerShell logging-settings
- dokumenteret registry-ændring
- dokumenterede Security Event IDs 4624, 4625, 4720 og 4732

Dermed er de centrale emner i Windows OS intro-opgaven dækket både teknisk og med sikkerhedsmæssig begrundelse.
