# Opgave 5 – OWASP Juice Shop

**Specialisterne Academy · 30. oktober 2026 (seneste statuskontrol)**  
**Status:** Nyeste JSON-eksport fra 30. oktober 2026 viser **35/186** (**17 hacking-challenges + 9 Find It + 9 Fix It**).

## Formål

Opgaven handler om at identificere og udnytte mindst tre konkrete sårbarheder i OWASP Juice Shop, dokumentere proof-of-concept (PoC), forklare årsager og anbefale afbødende tiltag. Resultaterne skal kunne bruges til en præsentation på 10–15 minutter.

Applikationen er med vilje usikker. Alle forsøg er udført i mit autoriserede, lokale undervisningsmiljø. Opgaveoplægget findes i [OWASP Juice-shop.pdf](./OWASP%20Juice-shop.pdf).

## Præsentationsguide (10–15 minutter)

README'en kan bruges direkte som præsentation **uden live-demo**. Foreslået rækkefølge:

1. **Introduktion (1 min):** Hvorfor OWASP Juice Shop, og hvordan VM/Docker/SSH-tunnel er sat op.
2. **Arbejdsmetode (1 min):** Startede med at gennemgå **alle produkter og anmeldelser**, noterede e-mailadresser og kommentarer, sammenholdt dem med OSINT og brugte derefter DevTools og `curl` til konkrete HTTP-tests.
3. **Fund 1 (3 min):** Usikre sikkerhedsspørgsmål, fx OSINT om Jims Star Trek-reference → `Samuel` → **Forgot Password**-reset; Mortys hund **Snuffles/Snowball** og leetspeak som andet eksempel.
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

Seneste backup **`owasp_juice_shop-2026-10-30(1).json`** er afkodet med Juice Shops egne Hashids-salte og ID-liste. Den viser **35/186 løste deludfordringer:** **17 hacking-challenges** samt **9 Find It + 9 Fix It**. Dette er ni deludfordringer flere end eksporten tidligere samme dag (26/186). Denne status er baseret på eksportens indhold, ikke på et nyt Score Board-screenshot.

| Sværhedsgrad | Løst | Total |
| --- | ---: | ---: |
| 1 stjerne | 8 | 27 |
| 2 stjerner | 2 | 29 |
| 3 stjerner | 15 | 51 |
| 4 stjerner | 7 | 40 |
| 5 stjerner | 3 | 25 |
| 6 stjerner | 0 | 14 |
| **I alt** | **35** | **186** |

### Bekræftede løste hacking-challenges (17)

| Challenge | Stjerner | Juice Shop-kategori | Metode og begrænsning |
| --- | ---: | --- | --- |
| Bjoern's Favorite Pet | 3 | Broken Authentication | OSINT om Zaya og password reset |
| Empty User Registration | 2 | Improper Input Validation | POST med tom e-mail og adgangskode → 201 |
| Error Handling | 1 | Security Misconfiguration | Sletning af adresse → 500 med stack trace |
| **Login Bender** | **3** | **Injection** | Registreret som løst efter arbejde med Benders password-reset og konto; ingen SQL Injection mod login dokumenteret |
| **Login Jim** | **3** | **Injection** | Opdaget efter Reset Jim's Password; normalt login med den nye adgangskode, ikke SQL Injection |
| Privacy Policy | 1 | Miscellaneous | Account → Privacy & Security → Privacy Policy |
| **Product Tampering** | **3** | **Broken Access Control** | Anonym `PUT /api/Products/9` ændrede den gemte produktbeskrivelse, HTTP 200; særskilt PoC nedenfor |
| Repetitive Registration | 1 | Improper Input Validation | Løst med samme `curl` som Empty User Registration; `passwordRepeat` udeladt |
| **Reset Bender's Password** | **4** | **Broken Authentication** | OSINT om Futurama-Benders arbejde med stålbjælker til Stop'n'Drop; anvendt ved Forgotten Password |
| Reset Jim's Password | 3 | Broken Authentication | Starfleet-kommentar → James T. Kirk → broderens mellemnavn `Samuel` |
| Reset Morty's Password | 5 | Broken Anti Automation | Mortys hund Snuffles/Snowball → leetspeak `5N0wb41L`; ingen rate-limit-bypass påvist |
| Score Board | 1 | Miscellaneous | Åbnede link vist under Bjoerns coding challenge, ikke selvstændig discovery |
| Security Policy | 2 | Miscellaneous | `/security.txt` |
| Steganography | 4 | Security through Obscurity | OpenStego på `5.png`; TinEye 0 matches; Google AI identificerede Pickle Rick |
| Missing Encoding | 1 | Improper Input Validation | `#` i Photo Wall-URL erstattet med `%23` |
| Reset Uvogin's Password | 4 | Sensitive Data Exposure | Google OSINT → *The Silence of the Lambs* |
| Mass Dispel | 1 | Miscellaneous | Shift + klik på X |

### Bekræftede coding challenges (9 × Find It + Fix It)

| Coding challenge | Find It | Fix It | Dokumenteret metode |
| --- | :---: | :---: | --- |
| Bjoern's Favorite Pet | ✓ | ✓ | Sikkert password reset med engangslink |
| **Login Bender** | ✓ | ✓ | Løst ifølge eksport; præcis kodeændring ikke dokumenteret |
| Login Jim | ✓ | ✓ | SQL Injection i strengkonkateneret loginquery fundet og rettelse valgt |
| **Product Tampering** | ✓ | ✓ | Løst ifølge eksport; manglende PUT-adgangskontrol analyseret nedenfor |
| **Reset Bender's Password** | ✓ | ✓ | Løst ifølge eksport; præcis kodeændring ikke dokumenteret |
| Reset Jim's Password | ✓ | ✓ | Løst ifølge eksport; detaljer ikke dokumenteret |
| Reset Morty's Password | ✓ | ✓ | Usikker `X-Forwarded-For`-`keyGenerator` fjernet med Fix 2 |
| Score Board | ✓ | ✓ | Løst ifølge eksport; detaljer ikke dokumenteret |
| Reset Uvogin's Password | ✓ | ✓ | Løst ifølge eksport; detaljer ikke dokumenteret |

**Vigtig afgrænsning:** Juice Shops kategorier angiver tilsigtede sårbarheder, men ikke nødvendigvis min faktiske løsningsmetode. Fx blev Login Jim løst ved almindeligt login efter password reset, ikke med SQL Injection. `Find It` og `Fix It` er interaktive kodeøvelser; de ændrer **ikke** koden i Docker-containeren.

De rå `continueCode`-værdier er udeladt af det offentlige repository.
---

## Sikkerhedsfund 1 – Usikre sikkerhedsspørgsmål / Broken Authentication

**Kategori:** OWASP Top 10 2021 A07 – Identification and Authentication Failures  
**Vurderet risiko:** Høj, fordi password-reset-funktionen kan misbruges til kontoovertagelse.

### Fremgangsmåde og PoC

Min undersøgelse begyndte **ikke** med et bestemt login eller en bestemt person. Jeg gik først **systematisk alle produkter og deres anmeldelser igennem** og noterede de e-mailadresser, som brugerne havde offentliggjort, samt hvad de faktisk skrev i deres reviews. Det gav et første overblik over brugerkonti og mulige OSINT-spor, herunder `bender@juice-sh.op`. Derefter sammenholdt jeg relevante kommentarer med åbne kilder. **Det var dog først efter opdagelsen af Score Board**, at jeg begyndte at vælge konkrete challenges ud fra deres opgavebeskrivelser.

**Kronologien omkring Jim:** Først gennemgik jeg produkterne og anmeldelserne, hvor Jims kommentar om en **Star Trek-/Starfleet-uniform** blev noteret. Under arbejdet med **Bjoern's Favorite Pet-coding challenge** viste Juice Shop mig et link til **Score Board**; jeg vidste ikke på forhånd, at siden fandtes. Jeg trykkede på linket og gennemgik derefter listen over challenges. **Reset Jim's Password** fangede min interesse, fordi beskrivelsen direkte henviste til **Forgot Password** og det oprindelige svar på sikkerhedsspørgsmålet. Jeg vendte tilbage til Star Trek-sporet: Jim var sandsynligvis en reference til **James Tiberius Kirk**. OSINT om hans familie førte til broderen **George Samuel Kirk**, og svaret `Samuel` virkede på Forgot Password-siden. **Først efter nulstillingen** opdagede jeg **Login Jim**, som blev markeret løst, da jeg loggede ind normalt med den nye adgangskode. Der blev **ikke** brugt SQL Injection til dette login.

Arbejdsmetoden var altså **gennemgang af applikationens offentlige data → notater over e-mailadresser og indhold → opdagelse af Score Board → valg af challenge ud fra beskrivelsen → OSINT og sammenkobling af oplysninger → test af password reset → almindeligt login**. En offentlig e-mailadresse eller anmeldelse er ikke i sig selv en sårbarhed; problemet opstår, når offentlige oplysninger kan bruges som adgangskontrol.

| Konto | Ledetråd / research | Svar anvendt |
| --- | --- | --- |
| `bjoern@owasp.org` | Offentligt omtalt kæledyr | `Zaya` |
| `jim@juice-sh.op` | OSINT fra Jims kommentar om Starfleet-uniform → James T. Kirk → bror George Samuel Kirk; svaret indtastet på Forgot Password-siden | `Samuel` |
| `uvogin@juice-sh.op` | Google-søgning/OSINT efter kontoens yndlingsfilm; brugt på Forgot Password-siden | `Silence of the Lambs` |
| `morty@juice-sh.op` | OSINT om Mortys hund **Snuffles**, som kalder sig **Snowball** i et afsnit; Snowball blev obfuskeret med 1337/leetspeak og indtastet på Forgot Password-siden | `5N0wb41L` |

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

**To challenges med én request:** Den samme request opfyldte også **Repetitive Registration**, fordi `passwordRepeat` var udeladt. Juice Shops challenge-kode markerer den som løst, når `req.body.passwordRepeat !== req.body.password`. Her var `passwordRepeat` `undefined`, mens `password` var den tomme streng. Det er separat fra Empty User Registration, der kontrollerer `email === ''` og `password === ''`. Dermed blev begge markeret uden brug af Burp Suite.

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

## Sikkerhedsfund 4 – Product Tampering / Broken Access Control

**Kategori:** Broken Access Control (manglende autorisationskontrol på API-niveau)  
**Status:** Bekræftet løst **30. oktober 2026**, efter den seneste JSON-eksport. Ny samlet challenge-total er ikke kontrolleret med et nyt Score Board-screenshot eller en ny eksport.

### Første forsøg – ændring af browserens DOM

Jeg åbnede produktet **OWASP SSL Advanced Forensic Tool (O-Saft)**, fandt linket i Firefox DevTools' Inspektør og ændrede `href` direkte til `https://owasp.slack.com`. Det ændrede **kun den lokale DOM i browseren**. Challenge-beskrivelsen sagde blot, at linket skulle ændres; den specificerede ikke, at ændringen skulle gemmes server-side og overleve en genindlæsning. Derfor gav dette forsøg ingen challenge-markering.

### Verificeret PoC – ændring af produktet via API

Fra Ubuntu-terminalen blev produkt-ID'et identificeret ved at søge i produkt-API'ets JSON-resultat:

```bash
curl -s http://127.0.0.1:3000/api/Products/ | \
python3 -c 'import json,sys; print(next(p["id"] for p in json.load(sys.stdin)["data"] if "O-Saft" in p["name"]))'
# 9
```

Derefter blev produktbeskrivelsen opdateret **uden login eller Authorization-header**:

```bash
curl -i -X PUT http://127.0.0.1:3000/api/Products/9 \
  -H "Content-Type: application/json" \
  -d '{"description":"<a href=\"https://owasp.slack.com\" target=\"_blank\">More...</a>"}'
```

**Faktisk svar:**

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
```

Serverens JSON indeholdt `"status":"success"`, `"id":9`, den nye `description` og `"updatedAt":"2026-10-30T09:16:33.136Z"`. Juice Shop viste succesnotifikationen for **Product Tampering** (tre ens notifikationer fra samme challenge; ikke tre separate challenges).

### Hvorfor er det en sårbarhed?

Serverens API accepterede en skriveoperation, som ændrede et produkts gemte indhold, fra en **ikke-autentificeret klient**. Forskellen fra den oprindelige DevTools-ændring er, at en API-`PUT` ændrer tilstanden på serveren og dermed påvirker andre brugere. Det kan misbruges til manipulation af indhold, eksempelvis til at indsætte uønskede links.

**Hvorfor er den udkommenterede linje sårbar?** I Juice Shops `server.ts` opretter biblioteket **`finale-rest`** automatisk CRUD-ruter for databasen (blandt andet `/api/Products/:id`). Ovenover står denne middleware, som skulle have beskyttet en allerede eksisterende PUT-rute:

```typescript
// app.put('/api/Products/:id', security.isAuthorized())
```

Fordi linjen begynder med `//`, **registreres adgangskontrollen ikke**. Det betyder ikke, at PUT-ruten er deaktiveret – den automatisk genererede API-rute virker stadig. Derfor kunne en anonym klient opdatere produktet. **Sårbarheden er ikke en kommentar i sig selv, men den aktive skrivefunktion uden nødvendig autorisation.** At fjerne `//` ville kræve autentifikation med `security.isAuthorized()`, men en robust produktionsrettelse bør også kræve den korrekte rolle (fx admin), ikke blot at en bruger er logget ind.

Den sårbare adfærd er direkte verificeret med `HTTP 200` og den ændrede produktbeskrivelse.

**Afhjælpning:** Kræv autentifikation og eksplicit server-side autorisation for produktændringer; begræns skriveadgang til relevante administrative roller, og tilføj regressionstests, hvor en anonym `PUT` skal afvises (fx `401 Unauthorized` eller `403 Forbidden`). Desuden bør administrative ændringer logges.

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

### Privacy Policy

Privacy Policy-challengen blev løst ved at åbne siden gennem brugergrænsefladen: **Account → Privacy & Security → Privacy Policy**, som fører til `http://127.0.0.1:3000/#/privacy-security/privacy-policy`.

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
6. Forsøgte **reverse image lookup via TinEye**, som gav **0 matches**. Derefter blev det samme billede sendt til **Google AI** til visuel identifikation, og Google AI identificerede figuren som **Pickle Rick** fra *Rick and Morty*. Identifikationen var altså **ikke** et match fra TinEye.
7. Navnet blev indsendt via `Contact Us`, hvilket løste `Steganography`-challengen.

**Læring:** Udtræk af skjult information og fortolkning af indholdet er to separate analysetrin. Man kan bruge billedanalyse, når motivet ikke er genkendeligt ud fra egen baggrundsviden.

### Andre challenges og observationer

- **Score Board:** Jeg vidste ikke engang, at Score Board fandtes. Under **Bjoern's Favorite Pet-coding challenge** viste Juice Shop et link til siden. Da jeg trykkede på linket, blev udfordringen registreret som løst. Jeg gennemgik **først derefter** challenge-listen og valgte blandt andet **Reset Jim's Password**, fordi opgavebeskrivelsen eksplicit nævnte Forgot Password. Det var ikke resultatet af en selvstændig rekognoscering efter en skjult rute.
- **Mass Dispel:** `Shift + klik` på et X lukker alle grønne challenge-notifikationer. Den handling udløste en særskilt *Good Practice*-challenge.
- **Repetitive Registration:** Blev løst med samme `curl`-request som Empty User Registration, idet `passwordRepeat` blev udeladt.
- **Juicy the Smart Assistant:** Chatbotten oplyste, at AI-endpointet ikke var konfigureret eller tilgængeligt i denne installation. Det er ikke dokumenteret som en sikkerhedssårbarhed.
- Offentlige brugernavne og e-mailadresser fra anmeldelser er nyttige OSINT-spor, men udgør **ikke automatisk** en sårbarhed.

## Prioriteret plan for afhjælpning

| Prioritet | Fund | Forslag | Verifikation |
| --- | --- | --- | --- |
| P1 | Usikre sikkerhedsspørgsmål | Erstat med kortlivet, engangs-password-reset-link og rate limiting | OSINT-svar alene kan ikke nulstille konto |
| P2 | Tom registrering | Server-side schema-validering og databaseconstraints | Tomme/udeladte felter giver 4xx, ikke 201 |
| P3 | Fejllækage | Central fejlhåndtering og sikre responses | Constraint-fejl giver fx 409 uden stack trace |
| P2 | Product Tampering – anonym produktændring | Autentifikation og rollebaseret autorisation på `PUT /api/Products/:id` | Anonym `PUT` afvises med 401/403, produktindhold uændret |
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
- [x] Fire særskilte sårbarhedsfund med observerede PoC-resultater, herunder Product Tampering fra 30. oktober.
- [x] Konkrete forslag til afhjælpning.
- [x] Flere OSINT- og forensics-øvelser gennemført.
- [ ] Gennemgå den faktiske kildekode og angiv konkrete filer/linjer for de tre hovedfund.
- [ ] Tilføj **redigerede** screenshots af PoC, HTTP-responses og badges.
- [x] Udfyld de 17 hacking-challenges og ni fuldførte coding challenges ud fra den nyeste Juice Shop-eksport.
- [x] Lav præsentationsguide til 10–15 minutter med de tre fund; selve fremlæggelsen er ikke afholdt.
- [ ] Valgfri patch eller regressionstest er **ikke** implementeret.

**Dokumentationshygiejne:** Før screenshots, HAR-filer eller netværkslogs lægges i et offentligt repository, skal de kontrolleres for `Authorization: Bearer`-tokens, cookies, session-ID'er og andre hemmeligheder. Ingen rå autentifikationsdata er medtaget her.

**Samlet resultat:** Opgavens krav om mindst tre fund er opfyldt i den praktiske labafprøvning. Der mangler fortsat kildekodeverifikation og en samlet præsentation, så opgaven er endnu ikke markeret som fuldt afsluttet.
