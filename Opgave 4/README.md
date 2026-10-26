# Opgave 4 – Introduktion til HTTP

**Specialisterne Academy · 26. oktober 2026**  
**Status:** Opgave 1–5 gennemført; opgave 6 (valgfri parøvelse) sprunget over, da der ikke var en anden lokal akademist at gennemføre den med.

## Formål og miljø

Undersøge HTTP som tekstbaseret applikationsprotokol oven på TCP ved at sende requests med cURL og Netcat, sammenligne svar med browserens Network-panel og implementere både HTTP-klient og -server med Pythons standardbibliotek.

- Ubuntu Server VM i Hyper-V: `linux101-securebase`; bruger `axel`
- Lokalt HTTP-endpoint: `127.0.0.1:8000/index.html`
- Python 3.14.4, cURL 8.18.0, OpenBSD Netcat 1.234, Git 2.53.0
- Edge DevTools på Windows via SSH-local-port-forwarding
- Projekt på VM: `~/specialisterne/http-intro/`
- Al HTTP-labtrafik er lokal på VM'en. Kun SSH er nødvendigt fra Windows.

De afprøvede kodeeksempler findes som [index.html](./index.html), [client.py](./client.py) og [server.py](./server.py). De svarer til versionerne, der blev gennemgået og testet i øvelsen; GitHub-kopierne er ikke efterfølgende kørt direkte fra dette repository.

## Opsætning og indledende øvelser

Fra projektmappen:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Serveren blev holdt åben i sin egen SSH-terminal, så requests kunne aflæses i loggen, mens en anden terminal fungerede som klient.

### Øvelse 1 – HTTP GET med cURL

```bash
curl http://127.0.0.1:8000/index.html
```

**Resultat:** Indholdet af `index.html` blev returneret. Standardvisningen fra cURL indeholdt bodyen, ikke svarheaders.

### Øvelse 2 – Statuslinje og headers

```bash
curl -i http://127.0.0.1:8000/index.html
```

Udvalgt faktisk output:

```http
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.4
Content-type: text/html
Content-Length: 325
```

**Observation:** `200 OK` betyder at ressourcen blev leveret; `Content-Length: 325` gælder bodyen, ikke statuslinje og headers. `Server`-headeren oplyser serverimplementering og versionsnummer.

### Øvelse 3 – Verbose cURL

```bash
curl -v http://127.0.0.1:8000/index.html
```

Udvalgt faktisk output:

```text
* Established connection to 127.0.0.1 (127.0.0.1 port 8000) from 127.0.0.1 port 45430
> GET /index.html HTTP/1.1
> Host: 127.0.0.1:8000
> User-Agent: curl/8.18.0
> Accept: */*
< HTTP/1.0 200 OK
< Content-Length: 325
```

`*` angiver cURLs forbindelsesinformation, `>` sendte HTTP-linjer, og `<` modtagne HTTP-headers. Selve HTML-bodyen udskrives uden disse præfikser. Klientens request anvendte HTTP/1.1, men den indbyggede Python-server svarede med HTTP/1.0; det er ikke i sig selv en fejl.

### Øvelse 4 – Manuel request med Netcat

```bash
nc -C 127.0.0.1 8000
```

Manuelt input, afsluttet med en tom linje:

```http
GET /index.html HTTP/1.1
Host: 127.0.0.1:8000

```

**Resultat:** `HTTP/1.0 200 OK` og hele HTML-filen blev returneret. `-C` bruger CRLF som linjeafslutning, som HTTP/1.1 foreskriver. Tom linje markerer afslutningen på headersektionen.

En separat test udelod `Host`:

```bash
printf 'GET /index.html HTTP/1.1\r\n\r\n' | nc -N 127.0.0.1 8000
```

**Resultat:** Python-serveren returnerede stadig `200 OK`. Det viser, at denne implementering accepterede requesten, ikke at den var gyldig efter HTTP/1.1. En tidligere `Broken pipe` opstod ved at skrive en shellkommando inde i en allerede afsluttet Netcat-session.

## Besvarelse af PDF-opgaverne

### Opgave 1 – Hvor bestemmes serveradressen?

TCP-forbindelsens destination vælges af klienten, eksempelvis `nc 127.0.0.1 8000` eller URL'en i cURL. I HTTP/1.1 angiver `Host`-headeren, hvilken HTTP-vært der ønskes på forbindelsen. TCP-destinationsadresse og HTTP-værtsnavn er separate størrelser; flere virtuelle hosts kan dele en IP.

### Opgave 2 – Hvordan brydes HTTP-standarden i Netcat-øvelsen?

PDF-eksemplet viser en HTTP/1.1-requestlinje uden `Host`-headeren. En HTTP/1.1-klient skal sende en `Host`-header. En manuel interaktiv request kan desuden bruge forkerte linjeafslutninger, hvis terminalen sender LF i stedet for CRLF. I den gennemførte korrekte test sendte vi både `Host` og CRLF; i den særskilte fejltest udelod vi bevidst `Host`. Serveren accepterede den alligevel.

### Opgave 3 – Præcis størrelse, browser og formål

Komplet HTTP-svar målt som rå modtagne bytes:

```bash
printf 'GET /index.html HTTP/1.1\r\nHost: 127.0.0.1:8000\r\nConnection: close\r\n\r\n' \
  | nc -N 127.0.0.1 8000 | tee response.raw | wc -c
# 511
```

| Måling | Resultat |
| --- | ---: |
| HTTP-body / Content-Length | 325 bytes |
| Statuslinje og headers inklusive CRLF | 186 bytes |
| Hele HTTP-svaret med Netcat | **511 bytes** |
| Edge DevTools, `200 OK`, transferred | **511 bytes** |
| Edge DevTools, resource size | **325 bytes** |

Edge blev åbnet via SSH-tunnel **fra Windows PowerShell**:

```powershell
ssh -N -L 8000:127.0.0.1:8000 axel@10.10.10.10
```

Derfra `http://127.0.0.1:8000/index.html` → F12 → Network → Disable cache → genindlæs. Tunnelen eksponerede ikke port 8000 på VM'ens øvrige netværksinterfaces.

**Ekstra observation: HTTP-cache.** Før `Disable cache` blev slået til, sendte Edge `If-Modified-Since`, modtog `304 Not Modified` og viste **104 B transferred**. Serveren sendte da ikke HTML-bodyen; browseren kunne bruge sin lokale kopi.

**Fortolkning:** `Content-Length` er ikke den fulde wire-størrelse. Målinger af overført data skal fortolkes med hensyn til headers, cache og konkrete requests. At begge viste 511 B i denne test er et observeret resultat, ikke en garanti for alle browsere eller requests. PDF'ens formulering om forespørgselslinjen i svarets størrelse er upræcis: requesten og responset er separate HTTP-meddelelser. De 511 bytes her er *responset* inkl. statuslinje, headers og body; request-bytes er ikke lagt til.

### Opgave 4 – Egen HTTP-klient

[client.py](./client.py) bruger en TCP-socket:

```python
socket.socket(socket.AF_INET, socket.SOCK_STREAM)
```

Den forbinder til `127.0.0.1:8000`, sender manuelt konstrueret `GET /index.html HTTP/1.1` med `Host` og `Connection: close`, og modtager data i en `recv(4096)`-løkke, indtil forbindelsen lukkes.

**Faktisk test:** `python3 client.py` gav `HTTP/1.0 200 OK` fra den indbyggede server og senere `HTTP/1.1 200 OK` fra vores egen server, begge med `Content-Length: 325` og HTML-indholdet.

Kør:

```bash
python3 client.py
```

Forudsætter at en af serverne er startet på port 8000.

### Opgave 5 – Egen HTTP-server

[server.py](./server.py) bruger `bind()`, `listen()` og `accept()`, logger klientadresse og rå request og svarer på `GET /index.html` med HTML-filen. Alle andre requestlinjer giver i denne *simple øvelsesimplementering* `404 Not Found`. Svaret indeholder `Content-Type`, `Content-Length` beregnet fra bytes og `Connection: close`.

Stop først den indbyggede server med `Ctrl+C` for at frigive port 8000. Kør derefter **fra mappen med index.html**:

```bash
python3 server.py
```

Test fra en anden terminal:

```bash
python3 client.py
curl -i http://127.0.0.1:8000/missing.html
```

Faktiske resultater:

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 325
Connection: close
```

```http
HTTP/1.1 404 Not Found
Content-Type: text/html; charset=utf-8
Content-Length: 13
Connection: close

404 Not Found
```

Serverloggen registrerede blandt andet klientporte `60540` og `60554` og deres forskellige GET-stier.

**Afgrænsning:** Det er en undervisningsserver, ikke en produktionsklar HTTP-parser. Den læser kun ét `recv(4096)`, validerer ikke en komplet headersektion, fortolker ikke alle HTTP-metoder korrekt og skal ikke eksponeres på internettet. `client.py` decoder modtagne blokke hver for sig i UTF-8, hvilket også er en forenkling (multibyte-tegn kan blive opdelt mellem modtagelser).

### Opgave 6 (valgfri) – Ikke udført

Kræver en anden akademist som server-/klientmakker. Sprunget over, fordi der ikke var en anden lokal akademist at parre med. Ingen påstand om gennemførsel.

## Sikkerhedsrelevans og refleksion

- **HTTP vs. TCP:** TCP leverer en byte-stream; HTTP definerer tekstbaseret requestlinje, headers og body ovenpå. IP/port bruges til at oprette forbindelsen, mens `Host` identificerer den ønskede HTTP-vært.
- **Headers og validering:** HTTP/1.1 kræver `Host`, men en simpel server kan acceptere mangelfulde requests. Forskelle mellem proxy- og backend-fortolkning er potentielt sikkerhedsrelevante.
- **Logging:** `200`, `304`, `404`, klientadresser og requested paths giver spor, som en SOC-analytiker kan bruge. Enkeltstående browserrequests efter `favicon.ico` eller DevTools-metadata kan give `404` uden at være tegn på angreb.
- **Cache:** `If-Modified-Since` og `304` ændrer den faktiske netværkstrafik, selv når den viste side er den samme.
- **Hardening:** Loopback-binding og SSH-tunnel gør det muligt at undersøge HTTP uden at åbne ekstra porte i VM'ens firewall.
- **Næste emne:** Forståelsen af requestlinjer, headers og responses er grundlag for senere at analysere webapplikationsangreb i OWASP Juice Shop.

## Filoversigt

```text
Opgave 4/
├── Introduktion til HTTP.pdf  # Opgaveoplæg
├── README.md                  # Arbejdsgang, svar, målinger og refleksion
├── index.html                 # Lokal testside
├── client.py                  # HTTP GET-klient via rå TCP-socket
└── server.py                  # Minimal HTTP-server via rå TCP-socket
```

**Resultat:** Fem obligatoriske opgaver løst og dokumenteret med faktisk terminaloutput og browsermålinger; valgfri parøvelse fravalgt.
