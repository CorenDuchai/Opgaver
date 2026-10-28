# Opgave 5 – OWASP Juice Shop

**Specialisterne Academy · 28. oktober 2026**  
**Status:** I gang – 18/186 deludfordringer ifølge Juice Shop-eksporten fra 28. oktober 2026: 14 hacking-challenges og fire coding-dele (Find It/Fix It). Et tidligere screenshot viste 17/186 og 11 % Hacking Challenges.

## Formål

Opgaven handler om at identificere og udnytte mindst tre konkrete sårbarheder i OWASP Juice Shop, dokumentere proof-of-concept (PoC), forklare årsager og anbefale afbødende tiltag. Resultaterne skal kunne bruges til en præsentation på 10–15 minutter.

Applikationen er med vilje usikker. Alle forsøg er udført i mit autoriserede, lokale undervisningsmiljø. Opgaveoplægget findes i [OWASP Juice-shop.pdf](./OWASP%20Juice-shop.pdf).

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

Juice Shop-eksporten `owasp_juice_shop-2026-10-28.json` indeholder kodede status-ID'er, som kan knyttes til applikationens officielle challenge-liste. Den bekræfter **14 hacking-challenges** og **fire løste coding-dele** (Find It og Fix It for hver af to coding challenges), i alt **18/186**. Tidligere screenshot viste **17/186**; eksporten repræsenterer en senere status.

| Sværhedsgrad | Løst | Total |
| --- | ---: | ---: |
| 1 stjerne | 8 | 27 |
| 2 stjerner | 2 | 29 |
| 3 stjerner | 5 | 51 |
| 4 stjerner | 2 | 40 |
| 5 stjerner | 1 | 25 |
| 6 stjerner | 0 | 14 |
| **I alt** | **18** | **186** |

### Bekræftede løste hacking-challenges

| Challenge | Stjerner | Juice Shop-kategori | Metode og begrænsning |
| --- | ---: | --- | --- |
| Bjoern's Favorite Pet | 3 | Broken Authentication | OSINT om Zaya og password reset |
| Empty User Registration | 2 | Improper Input Validation | POST med tom e-mail og adgangskode → 201 |
| Error Handling | 1 | Security Misconfiguration | Sletning af adresse → 500 med stack trace |
| **Login Jim** | **3** | **Injection** | **Løst ved normalt login med password, der først blev nulstillet via OSINT. Ingen SQL-injection afprøvet eller påvist.** |
| Privacy Policy | 1 | Miscellaneous | Løst ifølge eksport; præcis fremgangsmåde ikke noteret |
| Repetitive Registration | 1 | Improper Input Validation | Løst ifølge eksport; præcis fremgangsmåde ikke noteret |
| Reset Jim's Password | 3 | Broken Authentication | Star Trek-spor → Samuel |
| Reset Morty's Password | 5 | Broken Anti Automation | Obfuskeret svar: `5N0wb41L`; ingen særskilt rate-limit-bypass påvist |
| Score Board | 1 | Miscellaneous | Åbnet via link fra appen |
| Security Policy | 2 | Miscellaneous | `/security.txt` åbnet og læst |
| Steganography | 4 | Security through Obscurity | OpenStego på `5.png`, identificerede Pickle Rick |
| Missing Encoding | 1 | Improper Input Validation | Kodede `#` i billede-URL som `%23` |
| Reset Uvogin's Password | 4 | Sensitive Data Exposure | OSINT om yndlingsfilm |
| Mass Dispel | 1 | Miscellaneous | Shift + klik på X |

**Vigtig skelnen:** Juice Shops kategorier beskriver *den tilsigtede* sårbarhed for en challenge, men ikke nødvendigvis den metode, der udløste løsningsmarkeringen. Eksempelvis blev **Login Jim** registreret som løst efter password-reset og almindeligt login. Dette er **ikke dokumentation for SQL Injection**, selv om challenge-kategorien er Injection.

### Coding challenges

Eksporten angiver **to coding challenges** med både `Find It` og `Fix It` løst. De er knyttet til **Bjoern's Favorite Pet** og **Score Board**. Ved Bjoern blev en sikker reset-løsning med kortlivet engangslink valgt; den konkrete kodebesvarelse for Score Board er ikke dokumenteret i arbejdsnoterne.

Den rå eksport indeholder `continueCode`-felter til gendannelse af progression. Disse er ikke gengivet i et offentligt repository.
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
- [x] Udfyld navnene på de 14 løste hacking-challenges ud fra Juice Shop-eksporten.
- [ ] Forbered 10–15 minutters præsentation ud fra de tre fund og ét forensics-eksempel.
- [ ] Valgfri patch eller regressionstest er **ikke** implementeret.

**Dokumentationshygiejne:** Før screenshots, HAR-filer eller netværkslogs lægges i et offentligt repository, skal de kontrolleres for `Authorization: Bearer`-tokens, cookies, session-ID'er og andre hemmeligheder. Ingen rå autentifikationsdata er medtaget her.

**Samlet resultat:** Opgavens krav om mindst tre fund er opfyldt i den praktiske labafprøvning. Der mangler fortsat kildekodeverifikation og en samlet præsentation, så opgaven er endnu ikke markeret som fuldt afsluttet.
