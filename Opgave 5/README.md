# Opgave 5 – OWASP Juice Shop

**Specialisterne Academy · 30. oktober 2026 (seneste statuskontrol)**  
**Status:** I gang – **26/186 deludfordringer** ifølge Juice Shop-eksporten fra 30. oktober 2026: **14 hacking-challenges + 6 Find It + 6 Fix It**. Samme progressionskoder som i den seneste eksport 28. oktober. Tidligere optælling på 18 var ufuldstændig.

## Formål

Opgaven handler om at identificere og udnytte mindst tre konkrete sårbarheder i OWASP Juice Shop, dokumentere proof-of-concept (PoC), forklare årsager og anbefale afbødende tiltag. Resultaterne skal kunne bruges til en præsentation på 10–15 minutter.

Applikationen er med vilje usikker. Alle forsøg er udført i mit autoriserede, lokale undervisningsmiljø. Opgaveoplægget findes i [OWASP Juice-shop.pdf](./OWASP%20Juice-shop.pdf).

## Præsentationsguide (10–15 minutter)

README'en kan bruges direkte som præsentation **uden live-demo**. Foreslået rækkefølge:

1. **Introduktion (1 min):** Hvorfor OWASP Juice Shop, og hvordan VM/Docker/SSH-tunnel er sat op.
2. **Arbejdsmetode (1 min):** Browser, DevTools, OSINT og `curl`; se den konkrete HTTP-kommunikation.
3. **Fund 1 (3 min):** Usikre sikkerhedsspørgsmål, fx Jims Star Trek-spor → `Samuel` → password reset.
4. **Fund 2 (2 min):** Tom brugerregistrering; vis `curl`-requesten og `HTTP/1.1 201 Created`.
5. **Fund 3 (2 min):** Adresse-sletning → `HTTP 500`, SQLite/Sequelize-fejl og interne stier.
6. **Andre erfaringer (1–2 min):** Steganografi, coding-challenges, forskel på challenge-status og faktisk udnyttet sårbarhed.
7. **Konklusion (1 min):** Server-side inputvalidering, sikker password reset og fejlhåndtering; SOC-relevans.

**Præsentationsprincip:** Brug fundenes eksisterende kodeblokke som evidence. Spring den lange challenge-oversigt over, medmindre der bliver spurgt. En grøn challenge-markering beviser ikke nødvendigvis, at den tilsigtede angrebsmetode blev brugt.

## Labmiljø og opsætning

| Del | Opsætning |
| --- | --- |
| Virtualisering | Hyper-V, VM `linux101-securebase` |
| Operativsystem | Ubuntu Server 26.04.1 LTS |
| Bruger og SSH | `axel@10.10.10.10` |
| Container | Docker, `bkimminich/juice-shop`, navn `juice-shop` |
| Netværk | Juice Shop eksponeret på VM'ens loopback `127.0.0.1:3000` |
| Klient | Windows-browser med DevTools, lokalt `http://127.0.0.1:3000` |
| Adgang | SSH-local-port-forwarding fra Windows til VM'en |
| Andre værktøjer | `curl`, Firefox/Edge DevTools, OpenStego, Google-søgning/AI og TinEye |

Docker var installeret og kørende på VM'en. Containeropsætningen svarer til:

```bash
sudo docker pull bkimminich/juice-shop
sudo docker run -d --name juice-shop \
  -p 127.0.0.1:3000:3000 \
  bkimminich/juice-shop
```

Den brugte browserforbindelse blev oprettet fra **Windows PowerShell**:

```powershell
ssh -N -L 3000:127.0.0.1:3000 axel@10.10.10.10
```

Derefter blev `http://127.0.0.1:3000` åbnet lokalt. Denne fremgangsmåde kræver ikke, at den sårbare webapplikation åbnes mod det øvrige netværk. Kommandoen ovenfor er en **reproducerbar containeropsætning**, ikke en ordret log af den oprindelige `docker run`-kommando.

## Resultat og status

Eksporten `owasp_juice_shop-2026-10-30.json` er sammenholdt med de to tidligere JSON-eksporter. De tre progressionskoder er identiske med eksporten fra 28. oktober (anden eksport). Koderne er afkodet med de salte/Hashids-parametre, som Juice Shops egen kode bruger, og ID'erne er sammenholdt med den officielle challenge-liste.

**Status: 26/186 løste deludfordringer**, fordelt på **14 hacking-challenges** og **12 coding-dele**: seks `Find It` og seks `Fix It`. Den tidligere README angav 18/186, fordi kun to af de seks coding-challenges var blevet medregnet. Et tidligere screenshot viste 17/186 på et tidligere tidspunkt.

| Sværhedsgrad | Løst | Total |
| --- | ---: | ---: |
| 1 stjerne | 8 | 27 |
| 2 stjerner | 2 | 29 |
| 3 stjerner | 9 | 51 |
| 4 stjerner | 4 | 40 |
| 5 stjerner | 3 | 25 |
| 6 stjerner | 0 | 14 |
| **I alt** | **26** | **186** |

### Bekræftede løste hacking-challenges (14)

| Challenge | Stjerner | Juice Shop-kategori | Metode og begrænsning |
| --- | ---: | --- | --- |
| Bjoern's Favorite Pet | 3 | Broken Authentication | OSINT om Zaya og password reset |
| Empty User Registration | 2 | Improper Input Validation | POST med tom e-mail og adgangskode → 201 |
| Error Handling | 1 | Security Misconfiguration | Sletning af adresse → 500 med stack trace |
| **Login Jim** | **3** | **Injection** | **Løst via almindeligt login efter OSINT-baseret password reset. Ingen SQL Injection blev udnyttet ved dette login.** |
| Privacy Policy | 1 | Miscellaneous | Løst ifølge eksport; præcis fremgangsmåde ikke noteret |
| Repetitive Registration | 1 | Improper Input Validation | Løst ifølge eksport; præcis fremgangsmåde ikke noteret |
| Reset Jim's Password | 3 | Broken Authentication | Star Trek-spor → Samuel |
| Reset Morty's Password | 5 | Broken Anti Automation | OSINT om Snowball og svaret `5N0wb41L`; ingen rate-limit-bypass afprøvet i password-reset-forløbet |
| Score Board | 1 | Miscellaneous | Åbnet via link fra appen |
| Security Policy | 2 | Miscellaneous | `/security.txt` åbnet og læst |
| Steganography | 4 | Security through Obscurity | OpenStego på `5.png`, identificerede Pickle Rick |
| Missing Encoding | 1 | Improper Input Validation | Kodede `#` i billede-URL som `%23` |
| Reset Uvogin's Password | 4 | Sensitive Data Exposure | OSINT om yndlingsfilm |
| Mass Dispel | 1 | Miscellaneous | Shift + klik på X |

### Bekræftede coding challenges (6 × Find It + Fix It)

| Coding challenge | Find It | Fix It | Hvad vi konkret har noteret |
| --- | :---: | :---: | --- |
| Bjoern's Favorite Pet | ✓ | ✓ | Sikrere password reset med tidsbegrænset engangslink |
| Login Jim | ✓ | ✓ | SQL-streng med direkte brugerinput identificeret; sikker rettelse valgt i kodeøvelsen |
| Reset Jim's Password | ✓ | ✓ | Gennemført ifølge eksport; ikke detaljeret dokumenteret |
| Reset Morty's Password | ✓ | ✓ | Usikker `X-Forwarded-For`-baseret rate-limit-nøgle; Fix 2 fjerner den brugerdefinerede `keyGenerator` |
| Score Board | ✓ | ✓ | Gennemført ifølge eksport; ikke detaljeret dokumenteret |
| Reset Uvogin's Password | ✓ | ✓ | Gennemført ifølge eksport; ikke detaljeret dokumenteret |

**Vigtigt:** `Find It` og `Fix It` er Juice Shops interaktive kodeøvelser. At vælge en korrekt rettelse her betyder **ikke**, at kildekoden i den kørende Docker-container er blevet ændret. Og en challenge kan blive løst ved en anden metode end den tilsigtede. Jims login blev for eksempel løst med en adgangskode efter reset, selv om den tilsigtede kategori er *Injection*; SQL Injection blev kun behandlet særskilt i kodeøvelsen.

De rå `continueCode`-værdier er ikke medtaget i det offentlige repository.
---

## Sikkerhedsfund 1 – Usikre sikkerhedsspørgsmål / Broken Authentication

**Kategori:** OWASP Top 10 2021 A07 – Identification and Authentication Failures  
**Vurderet risiko:** Høj, fordi password-reset-funktionen kan misbruges til kontoovertagelse.

### Fremgangsmåde og PoC

Jeg gennemgik offentlige produktanmeldelser i Juice Shop og koblede brugernes oplysninger til baggrundsviden eller OSINT-søgninger. Derefter blev svarene anvendt i `Forgot Password`-funktionen.

| Konto | Ledetråd / research | Svar anvendt |
| --- | --- | --- |
| `bjoern@owasp.org` | Offentligt omtalt kæledyr | `Zaya` |
| `jim@juice-sh.op` | Starfleet-uniform → James T. Kirk → bror George Samuel Kirk | `Samuel` |
| `uvogin@juice-sh.op` | Filmoplysninger fundet gennem OSINT | `Silence of the Lambs` |
| `morty@juice-sh.op` | Karakteren Morty Smiths hund Snuffles/Snowball | Obfuskeret `5N0wb41L` |

Juice Shop viste succesmeddelelser for de gennemførte nulstillinger, herunder:

```text
You successfully solved a challenge: Reset Jim's Password
You successfully solved a challenge: Reset Uvogin's Password
You successfully solved a challenge: Reset Morty's Password
```

Bjoerns konto blev også brugt til at logge ind efter nulstilling. Mortys udfordring er i Juice Shop desuden klassificeret som **Broken Anti Automation**; vi har ikke dokumenteret en separat test af rate-limit-bypass eller `X-Forwarded-For`-manipulation.

### Hvorfor er det en sårbarhed?

Svarene på sikkerhedsspørgsmål er ikke reelle hemmeligheder. De kan findes i brugerens egne kommentarer, offentlig information eller oplysninger om fiktive karakterer, som kontiene bygger på. En angriber kan dermed nulstille adgangskoden uden adgang til brugerens e-mailkonto.

**Underliggende årsag:** Password-reset-flowet accepterer videnbaserede sikkerhedsspørgsmål som tilstrækkelig identitetskontrol. Den præcise kodeimplementering er endnu ikke gennemgået linje for linje.

### Anbefalet afhjælpning

1. Fjern sikkerhedsspørgsmål som autentifikationsfaktor ved password reset.
2. Brug et kryptografisk tilfældigt engangstoken sendt til den registrerede e-mailadresse.
3. Giv tokenet kort levetid, og gør det ugyldigt efter brug.
4. Begræns antallet af reset-forsøg, og monitorér misbrug uden at afsløre, hvilke konti der findes.
5. Anvend MFA, hvor det er relevant.

I en relateret *coding challenge* blev en løsning med et kortlivet engangslink identificeret som det sikrere alternativ.

---

## Sikkerhedsfund 2 – Tom brugerregistrering via API

**Kategori:** Mangelfuld inputvalidering / registreringslogik; relevant for OWASP A04 – Insecure Design  
**Vurderet risiko:** Middel; den konkrete følgevirkning ud over oprettelse af en ugyldig konto er ikke undersøgt.

### Fremgangsmåde og PoC

Registrerings-API'et blev kaldt direkte fra Ubuntu VM'en:

```bash
curl -i -X POST http://127.0.0.1:3000/api/Users/ \
  -H "Content-Type: application/json" \
  -d '{"email":"","password":""}'
```

Observeret svar:

```http
HTTP/1.1 201 Created
Location: /api/Users/25
```

Svarbodyen rapporterede blandt andet `"status":"success"`, `"id":25` og `"email":""`. Requesten indeholdt hverken gyldig e-mail, adgangskode eller et `passwordRepeat`-felt.

Juice Shop registrerede også:

```text
You successfully solved a challenge: Empty User Registration
```

### Hvorfor er det en sårbarhed?

Klientens normale formularvalidering er ikke tilstrækkelig, hvis backend accepterer en ugyldig direkte HTTP-request. Den kan resultere i konti med tomme identitetsfelter og uventede applikationstilstande.

**Underliggende årsag:** Serveren validerer ikke effektivt de påkrævede registreringsfelter for den afprøvede request. En mulig årsag er, at valideringslogikken håndterer udeladte felter forkert, men dette er **ikke verificeret ved kildekodeanalyse**.

Der er **ikke** påvist login med tom adgangskode eller privilege escalation på baggrund af denne test.

### Anbefalet afhjælpning

1. Foretag server-side validering af samtlige obligatoriske felter, uanset frontend.
2. Afvis tomme/blanke e-mailadresser og adgangskoder med `400 Bad Request`.
3. Kontrollér e-mailformat og normalisér input.
4. Beskyt databaseintegriteten med passende constraints.
5. Tilføj regressionstest for tomme felter, udeladte felter og ugyldige datatyper.

---

## Sikkerhedsfund 3 – Information disclosure via fejlhåndtering

**Kategori:** OWASP Top 10 2021 A05 – Security Misconfiguration / Information Disclosure  
**Vurderet risiko:** Lav til middel isoleret set; informationen kan bruges til at planlægge yderligere angreb.

### Fremgangsmåde og PoC

Under arbejde med adresser og recycling-funktionen blev en eksisterende adresse forsøgt slettet:

```http
DELETE /api/Addresss/7
```

Bemærk stinavnet `Addresss` med tre s'er; det er den observerede API-sti, ikke en slåfejl i dokumentationen.

Resultatet var `HTTP 500` og et detaljeret fejlobjekt, som blandt andet afslørede:

```text
SequelizeForeignKeyConstraintError
SQLITE_CONSTRAINT: FOREIGN KEY constraint failed
/juice-shop/node_modules/sequelize/lib/dialects/sqlite/query.js
/juice-shop/build/routes/address.js
```

Juice Shop viste:

```text
You successfully solved a challenge: Error Handling
```

### Hvorfor er det en sårbarhed?

Et almindeligt klientkald modtog interne detaljer om databasen, ORM-frameworket og serverens filstruktur. Fejlinformationen hører til i serverlogs, ikke i et offentligt API-response.

**Underliggende årsag:** En databaseconstraint-fejl blev ikke oversat til et kontrolleret, informationsfattigt HTTP-svar, før den blev returneret til klienten. Den præcise modelrelation, der forhindrede sletningen, er ikke fastslået.

### Anbefalet afhjælpning

1. Fang forventede databasefejl, eksempelvis foreign-key-constraints.
2. Returnér en passende klientfejl, fx `409 Conflict` og en neutral forklaring om, at adressen er i brug.
3. Log detaljerede fejl internt sammen med et korrelations-ID.
4. Undlad stack traces, absolutte filstier, SQL-detaljer og interne frameworkversioner i HTTP-responses.
5. Tilføj automatiske tests for fejlscenarier.

---

## Øvrige undersøgelser og læringspunkter

### Recycling: client-side kontrol vs. server-side validering

I `Request Recycling Box` blev en deaktiveret Submit-knap undersøgt med DevTools. En HTML-`disabled`-attribut blev fjernet i forbindelse med afprøvningen; `disabled="false"` er **stadig en aktiv boolean-attribut** i HTML og er derfor ikke det samme som at fjerne attributten.

En observeret request:

```http
POST /api/Recycles/
Content-Type: application/json

{"UserId":13,"quantity":255}
```

Serveren svarede `201 Created`. **Dette beviser ikke en server-side valideringsfejl**, fordi antallet 255 ligger inden for formularens forventede interval 10–1000. Forsøget illustrerer derimod, at kontrol af en knaps tilstand i browseren ikke er en sikkerhedsgrænse.

### Missing Encoding – Photo Wall

På `/#/photo-wall` var et kattebillede ødelagt, fordi filnavnets `#` blev behandlet som URL-fragment:

```text
.../ᓚᘏᗢ-#zatschi-#whoneedsfourlegs-1572600969477.jpg
```

Ved at erstatte `#` med `%23` kunne billedet indlæses, og challen­gen `Missing Encoding` blev registreret som løst.

Dette er dokumenteret som en fejl i URL-kodning og applikationens funktionalitet – **ikke** som en påvist kritisk sikkerhedssårbarhed.

### Security Policy

Filen blev fundet direkte på:

```text
http://127.0.0.1:3000/security.txt
```

Den indeholdt blandt andet `Contact`, `Encryption`, `Acknowledgements`, `Preferred-languages`, `Hiring`, `Csaf` og `Expires`. Det er en `security.txt`-fil, som hjælper sikkerhedsforskere med at finde kontakt- og rapporteringskanaler. Den standardiserede placering er `/.well-known/security.txt`.

### Steganography – skjulte data i billede

Denne udfordring var en praktisk forensics-øvelse og ikke i sig selv dokumentation for en exploiterbar adgangskontrolfejl.

Arbejdsgang:

1. Gennemgik billeder i shoppen. `BeeHaven.png` blev først forsøgt med OpenStego, men kunne ikke udtrækkes; det var det forkerte billede.
2. OpenStego krævede en installeret Java Runtime på Windows. Efter installation kunne programmet starte.
3. Hentede det korrekte billede fra About Us-karrusellen:  
   `http://127.0.0.1:3000/assets/public/images/carousel/5.png`.
4. Anvendte **OpenStego → Extract hidden data** uden password.
5. Det udtrukne pixel-art-billede viste en grøn figur i et mekanisk skelet.
6. TinEye gav **0 matches**. Billedgenkendelse med AI identificerede figuren som **Pickle Rick** fra *Rick and Morty*.
7. Navnet blev indsendt via `Contact Us`, hvilket løste `Steganography`-challengen.

**Læring:** Udtræk af skjult information og fortolkning af indholdet er to separate analysetrin. Man kan bruge billedanalyse, når motivet ikke er genkendeligt ud fra egen baggrundsviden.

### Andre challenges og observationer

- **Score Board:** Siden blev åbnet via et link fra Juice Shop efter gennemført coding challenge. Det viste, at appens egen navigation kan afsløre ellers skjulte routes.
- **Mass Dispel:** `Shift + klik` på et X lukker alle grønne challenge-notifikationer. Den handling udløste en særskilt *Good Practice*-challenge.
- **Repetitive Registration:** Registreret som løst, men den nøjagtige manipulation er endnu ikke beskrevet i noterne.
- **Juicy the Smart Assistant:** Chatbotten oplyste, at AI-endpointet ikke var konfigureret eller tilgængeligt i denne installation. Det er ikke dokumenteret som en sikkerhedssårbarhed.
- Offentlige brugernavne og e-mailadresser fra anmeldelser er nyttige OSINT-spor, men udgør **ikke automatisk** en sårbarhed.

## Prioriteret plan for afhjælpning

| Prioritet | Fund | Forslag | Verifikation |
| --- | --- | --- | --- |
| P1 | Usikre sikkerhedsspørgsmål | Erstat med kortlivet, engangs-password-reset-link og rate limiting | OSINT-svar alene kan ikke nulstille konto |
| P2 | Tom registrering | Server-side schema-validering og databaseconstraints | Tomme/udeladte felter giver 4xx, ikke 201 |
| P3 | Fejllækage | Central fejlhåndtering og sikre responses | Constraint-fejl giver fx 409 uden stack trace |
| P4 | Manglende URL-kodning | Korrekt encoding af sti-/filnavnskomponenter | Fotoindhold med `#` indlæses normalt |

Prioriteringen er en kvalitativ vurdering til undervisningsbrug, ikke en formel CVSS-beregning.

## Sikker udvikling og SOC-perspektiv

- **Secure by design:** En sikker reset-mekanisme skal bygges ind fra begyndelsen frem for at forsøge at gøre gættelige spørgsmål sværere.
- **Defence in depth:** Frontend-validering er nyttig for brugeroplevelsen, men må aldrig erstatte backend-validering.
- **Code review og tests:** Negative tests er vigtige: tomme værdier, manglende felter, sletning af refererede objekter og mislykkede reset-forsøg.
- **Logging:** Interne detaljer er nødvendige for udviklere og SOC-analytikere, men skal holdes ude af brugerrettede responses.
- **Detektion:** Mistænkelig password-reset-aktivitet, usædvanlige registreringsforsøg og gentagne `500`-fejl er relevante signaler for overvågning og korrelation.

## Dokumentation og videre arbejde

- [x] Lokal, isoleret Juice Shop i Docker.
- [x] Undersøgelse via browser, DevTools og direkte HTTP-requests.
- [x] Minimum tre særskilte sårbarhedsfund med observerede PoC-resultater.
- [x] Konkrete forslag til afhjælpning.
- [x] Flere OSINT- og forensics-øvelser gennemført.
- [ ] Gennemgå den faktiske kildekode og angiv konkrete filer/linjer for de tre hovedfund.
- [ ] Tilføj **redigerede** screenshots af PoC, HTTP-responses og badges.
- [x] Udfyld de 14 hacking-challenges og seks fuldførte coding challenges ud fra Juice Shop-eksporten.
- [x] Lav præsentationsguide til 10–15 minutter med de tre fund; selve fremlæggelsen er ikke afholdt.
- [ ] Valgfri patch eller regressionstest er **ikke** implementeret.

**Dokumentationshygiejne:** Før screenshots, HAR-filer eller netværkslogs lægges i et offentligt repository, skal de kontrolleres for `Authorization: Bearer`-tokens, cookies, session-ID'er og andre hemmeligheder. Ingen rå autentifikationsdata er medtaget her.

**Samlet resultat:** Opgavens krav om mindst tre fund er opfyldt i den praktiske labafprøvning. Der mangler fortsat kildekodeverifikation og en samlet præsentation, så opgaven er endnu ikke markeret som fuldt afsluttet.
