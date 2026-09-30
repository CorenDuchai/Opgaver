# Specialisterne Academy - Opgaver

Dette repository indeholder opgaver og dokumentation fra mit forløb på Specialisterne Academy.

## Opgave 1 - Linux 101

Linux 101-opgaven dokumenterer opsætning og hærdning af en Ubuntu Server VM med fokus på sikker drift, adgangskontrol, netværk, logging og automatisering.

### Moduler

- [Modul 1 - VM, netværk og SSH](Opgave%201/Modul%201/README.md)
- [Modul 2 - Filsystem og adgangskontrol](Opgave%201/Modul%202/README.md)
- [Modul 3 - Brugere, grupper og sudo](Opgave%201/Modul%203/README.md)
- [Modul 4 - Firewall og netværkssikkerhed](Opgave%201/Modul%204/README.md)
- [Modul 5 - Monitorering og logging](Opgave%201/Modul%205/README.md)
- [Modul 6 - Shell og Bash-scripting](Opgave%201/Modul%206/README.md)

Opgaven omfatter blandt andet:

- Ubuntu Server i Hyper-V
- separat management-netværk
- SSH med nøglebaseret login og hardening
- Linux filrettigheder, grupper, setgid og ACL
- rollebaseret bruger- og sudo-adgang
- UFW med default deny
- monitorering af CPU, RAM og disk
- logrotation
- analyse af mislykkede SSH-loginforsøg
- cron
- Bash-scripting
- idempotent automatisering
- system-healthcheck

Hvert modul indeholder sin egen dokumentation og screenshots som bevis på den gennemførte konfiguration.

## Opgave 2 - Windows OS intro (AD-lab)

[Se dokumentation for Opgave 2](Opgave%202/README.md)

Opgave 2 samler Windows Server, Active Directory, Group Policy, PowerShell, Registry Editor og Event Viewer i et mindre domænemiljø.

Opgaven omfatter blandt andet:

- Windows Server Domain Controller og Windows-klient i Hyper-V
- domænet `spec.test`
- design af OU-, bruger- og gruppestruktur
- automatiseret oprettelse af AD-objekter med PowerShell
- workstation security baseline via Group Policy
- firewall, inactivity timeout og PowerShell logging
- verificering af GPO-applikation på klienten
- kontrolleret Registry-ændring med før/efter-dokumentation
- Security Event IDs 4624, 4625, 4720 og 4732
- sikkerhedsmæssig begrundelse for adgangsstyring, logging og central policy

## Opgave 3 - Netværks-lag

[Se dokumentation for Opgave 3](Opgave%203/README.md)

Opgave 3 bygger centrale dele af netværksstakken fra bunden og dokumenterer trafikken med packet captures og Wireshark.

Opgaven omfatter blandt andet:

- egen TCP-klient og -server med Python sockets
- TCP three-way handshake og connection teardown
- manuel konstruktion af en DNS-query som rå bytes
- parsing af DNS-response og name compression
- DNS recordtyperne A, CNAME, MX, NS og TXT
- lokal navneopløsning med `netlab.test`
- egen HTTP-server med parsing af request-linje og headers
- HTTP statuskoder og korrekt `Content-Length`
- selvsigneret certifikat og HTTPS/TLS
- analyse med `ss`, `dig`, `curl`, `openssl s_client`, `tcpdump` og Wireshark
- sammenligning af klartekst-HTTP og krypteret TLS Application Data

## Repository-struktur

```text
Opgave 1/   Linux 101
Opgave 2/   Windows OS intro / Active Directory lab
Opgave 3/   Netværks-lag / TCP, DNS, HTTP og TLS
```
