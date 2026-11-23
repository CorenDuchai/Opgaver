
Denne guide tager jer igennem hvordan vi anbefaler I strukturerer jeres GitHub-repo til Linux-opgaven. Opgaven nævner ikke selv en fast repo-struktur — det er bevidst overladt til jer, men her er en anbefaling baseret på opgavens egen opbygning i seks moduler.

## Hvorfor strukturen betyder noget her

Scenariet i opgaven er, at serveren "senere skal kunne driftes og overvåges af andre" — alt skal derfor være **scriptet og dokumenteret, ikke kun klikket sammen manuelt**. Jeres GitHub-repo er i praksis instruksionerne/dokumentationen på det. Strukturen nedenfor er et forslag på hvordan man  at I reelt kan levere noget, en anden systemadministrator kan overtage.

## Anbefalet mappestruktur

```
securebase/
├── README.md
├── .gitignore
├── docs/
│   ├── 01-vm-netvaerk.md
│   ├── 02-filsystem.md
│   ├── 03-brugere-grupper.md
│   ├── 04-firewall.md
│   ├── 05-monitorering.md
│   └── 06-scripting.md
└── scripts/
    ├── setup.sh
    ├── healthcheck.sh
    └── ...
```

- **`docs/`** — én `.md`-fil pr. modul, med den løbende dokumentation og begrundelser, opgaven kræver.
- **`scripts/`** — alle jeres bash-scripts (også dem, I bruger undervejs i modul 1-5, ikke kun modul 6's automatisering).
- **Rod-README.md** fungerer som indgang og indholdsfortegnelse — se nedenfor.

## Root-README'en som indgangspunkt

README'en i roden skal ikke gentage alt indholdet fra `docs/`, men fungere som en kort oversigt, der linker videre. Det svarer til, hvordan man i praksis ville dokumentere en produktionsserver: ét overbliksdokument, der peger på de detaljerede dele.

```markdown
# MinFørsteLinuxServer — SPAC efterår 2026

Kort beskrivelse af projektet og scenariet.

## Struktur
- [Modul 1: VM-opsætning og netværk](docs/01-vm-netvaerk.md)
- [Modul 2: Filsystem og adgangskontrol](docs/02-filsystem.md)
- [Modul 3: Bruger- og gruppestyring](docs/03-brugere-grupper.md)
- [Modul 4: Firewall og netværkssikkerhed](docs/04-firewall.md)
- [Modul 5: Monitorering og logging](docs/05-monitorering.md)
- [Modul 6: Shell og bash-scripting](docs/06-scripting.md)

## Sådan køres scripts
...
```

Denne opdeling gør det også let for en vejleder hurtigt at navigere direkte til det modul, der skal tjekkes, uden at skulle scrolle igennem ét kæmpe dokument.

## Skabelon til hver modul-fil i `docs/`

For at holde dokumentationen af de seks delopgaver konsistent — og for at sikre, at I rent faktisk får begrundet jeres valg, som opgaven kræver, ikke kun beskrevet hvad I gjorde — kan hver `docs/0X-*.md`-fil med fordel følge samme skabelon:

```markdown
# Modul X: <titel>

## Formål
Én-tre sætninger: hvad skal dette modul opnå, og hvorfor er det en del af
en hærdet serveropsætning?

## Udførte opgaver
Kort, punktvis liste over hvad der konkret er gjort (ikke kun opgavens
formulering gentaget — hvad I faktisk konfigurerede).

## Sikkerhedsmæssig begrundelse
Her hører kernen i dokumentationen til: *hvorfor* er valget sikkert?
Hvilket princip understøtter det (least privilege, default deny,
segregation of duties, osv.)? Dette er ikke det samme som at beskrive,
hvordan man gjorde det — det er at kunne argumentere for, at det var
det rigtige at gøre.

## Dokumentation / bevis
Konkret output der viser, at konfigurationen er implementeret som
beskrevet — se afsnittet om kodeblokke og evidence nedenfor.

## Overvejelser og fravalg
Valgfrit, men stærkt anbefalet: nævn kort alternativer, I overvejede
og fravalgte, og hvorfor. Det viser, at valget var bevidst, ikke
tilfældigt.
```

**Metodisk hint:** Skriv "Sikkerhedsmæssig begrundelse"-afsnittet, mens I stadig har konteksten present — helst lige efter I har konfigureret det pågældende modul, ikke som en samlet øvelse til sidst. Det er markant sværere at rekonstruere en begrundelse bagefter, end det er at skrive den ned i nuet.

## Konkrete .md-formateringsvalg, det er værd at bruge bevidst

- **Kodeblokke med sprogangivelse.** Brug altid ```bash omkring kommandoer og terminaloutput, `` ```ini `` eller `` ```conf `` omkring konfigurationsuddrag (fx `sshd_config`, `sudoers`-regler), og `` ```text `` til rå logoutput. Det giver syntax-highlighting på GitHub og gør det klart, hvad der er kommando, og hvad der er output.
- **Tabeller til struktureret dokumentation.** Opgaven beder eksplicit om et par ting, der egner sig oplagt til Markdown-tabeller frem for løbende tekst:
  - Modul 3's rolleskema (bruger → gruppe → rettigheder → begrundelse).
  - Modul 4's portbegrundelsestabel (port, protokol, tjeneste, begrundelse).
  
  ```markdown
  | Bruger    | Gruppe     | Rettigheder                  | Begrundelse                          |
  |-----------|------------|-------------------------------|----------------------------------------|
  | admin     | sudo       | Afgrænset sudo via sudoers.d  | Skal kunne administrere uden fuld root |
  | developer | developer  | Læse/skrive i /srv/project    | Skal kunne arbejde i fælles projektmappe |
  | guest     | guest      | Kun læseadgang                | Ingen behov for at ændre data          |
  ```
  
  En tabel gør det langt lettere for en vejleder (eller jer selv) hurtigt at overskue og verificere strukturen, end hvis det samme stod som løbende afsnit.
- **Før/efter som parrede kodeblokke.** Modul 2 kræver dokumentation af "før" og "efter" på rettigheder — vis dem side om side som to kodeblokke med tydelige overskrifter (`**Før:**` / `**Efter:**`), ikke som ét langt, udifferentieret output.
- **Relative links, ikke absolutte stier.** Når `docs/`-filerne linker til `evidence/`-mapperne eller til hinanden, brug relative Markdown-links (`../evidence/04-firewall/ufw-status.txt`) — så virker links stadig, uanset hvor repoet klones hen.
- **Konsekvent overskriftsniveau.** Hold jer til samme hierarki i alle modul-filer (`#` til modultitel, `##` til de faste afsnit fra skabelonen ovenfor) — det gør navigationen forudsigelig, og GitHub kan generere en indholdsfortegnelse automatisk ud fra det.

## Et par git-specifikke opmærksomhedspunkter for denne opgave

- **Commit løbende, modul for modul** — Fremadrettet kan det være en god ide ikke bare at lave et ét stort commit når i er færdige med opgaven. Løbende pushes afspejler bedre den reelle arbejdsproces og gør det muligt at følge, hvordan jeres sikring af serveren er bygget op trin for trin (svarende til modulernes egen logiske rækkefølge: adgang → filsystem → brugere → netværk → overvågning → automatisering).

- **Scripts og dokumentation følges ad.** Når I opdaterer et script i modul 6, så det fx automatiserer et trin fra modul 2, bør den tilhørende `docs/02-filsystem.md` opdateres i samme eller en tæt efterfølgende commit — ellers risikerer dokumentationen at blive forældet i forhold til, hvad scriptet reelt gør.

