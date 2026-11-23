# Haaukins Notes — SOC/Forensics Training

Samlede noter fra Specialisterne Academy / Haaukins-opgaver. Metode + løsninger, så de kan genbesøges.

---

## 1. RansomGang (Reverse Engineering) — 40p — LØST

**Opgave:** Binær login-service på `ransomgang.hkn:1337`. To "codes" skal findes: en "dynamisk" og en "statisk".

### Binary-info
```
ELF 64-bit LSB pie executable, x86-64, dynamically linked, stripped
```
Ingen `rand`/`srand`/`time` i imports → "dynamisk" betyder ikke tids-/tilfældighedsbaseret, men *afledt af brugerens eget input*.

### Metode
1. `strings` afslørede lore-tekst (base64 → ROT13 → DogeCoin-tema) og en mistænkelig isoleret streng `CDOGE`.
2. `objdump -d -M intel | grep "call.*<"` fandt lokale (ikke-PLT) funktioner: `11b5`, `130f`, `124e`.
3. Disassemblerede `130f` (level 1-tjek) og `124e` (level 2 XOR-tjek) manuelt.

### Level 1 — "dynamisk" kode
Funktionen scorer 6 bytes af input mod hinanden/konstanter. Point tildeles pr. tjek (+1/+2/-1), mål = præcis 7 (max score):

| Byte | Krav |
|---|---|
| `[0]` | `== 'B'` |
| `[1]` | `> 0x60` |
| `[2]` | `≠ '4'` |
| `[3]` | `== input[1] - input[2]` |
| `[4]` | `== (input[2]+input[3]) / 2` |
| `[5]` | `≠ 'a'` |

**Løsning:** `Bb021Z`

### Level 2 — "statisk" kode (XOR-cipher)
Funktion `124e` XOR'er input med en 21-byte nøgle fra `.data` (0x4070) og sammenligner med target (0x4090). Nøglens sidste 5 bytes var `CDOGE` i strings, men det var kun halvdelen af den reelle nøgle.

```
objdump -s -j .data ransomGang
```
gav key + target bytes. `input[i] = key[i] XOR target[i]`.

**Løsning:** `DogeCoinToTheMoon1337`

### Test lokalt før server
```bash
chmod +x ransomGang
./ransomGang      # indtast Bb021Z, derefter DogeCoinToTheMoon1337
# eller:
nc ransomgang.hkn 1337
```

### Lærdom
- Opaque scoring (flere betingelser med point) kan ligne simpel strcmp udefra, men er en sum af delbetingelser.
- Statisk XOR-obfuskering: en delvist synlig streng i `strings` (`CDOGE`) kan narre til at tro man har hele secret — altid tjek hele nøglens længde/omgivelser.

---

## 2. SQL Injection — 50p — LØST

**Opgave:** Find og udnyt SQLi på `netsec-forum.dk` (Internal Forum, comment-formular).

### Metode
1. `'` gav ingen reaktion, `"` gav reaktion → input er indlejret i **dobbelte anførselstegn** i SQL.
2. `" OR "1"="1` vs `" AND "1"="2` gav begge "falsk" (0) — mistænkeligt, da OR burde give sandt.
   - **Rodårsag:** inputtet starter med en tom streng (`""`) før selve injektionen. `"" AND X` er altid falsk pga. short-circuit (`0 AND X = 0`). `"" OR X` derimod reflekterer X korrekt.
3. Byttede til `OR`/`||` (concatenation i SQLite) i stedet for `AND`.
4. `sqlite_version()` bekræftede **SQLite** som DBMS.
5. Brugte `||` (string-concat) til at injicere subquery-resultater **direkte ind i output** (in-band, ikke blind):

```sql
" || (SELECT sql FROM sqlite_master WHERE name="comments"));-- -
" || (SELECT group_concat(name) FROM sqlite_master WHERE type="table"));-- -
" || (SELECT group_concat(email || ':' || password) FROM users));-- -
```

6. Fandt tabeller: `users`, `sqlite_sequence`, `comments`.
7. Udtrak direkte: `you@found.it:HKN{SI-xG-gJy4Pc}` — password-feltet var selve flaget i klartekst.

### Lærdom
- Test altid **både** `AND`- og `OR`-baserede payloads; en forkert konklusion ("AND virker ikke, så feltet er ikke sårbart") kan skyldes short-circuit-logik, ikke manglende sårbarhed.
- SQLite har ingen `information_schema` — brug `sqlite_master` og `pragma_table_info(tabelnavn)`.
- `||` i SQLite er string-concatenation (ikke logisk OR som i mange andre sprog) — kan bruges til direkte dataudtræk i stedet for blind boolean-teknik.
- Boolean-blind generelt: brug `SUBSTR`/binær søgning til at udtrække ukendte værdier tegn for tegn, eller automatisér med `sqlmap`.

---

## 3. RansomGang Returns (Reverse Engineering) — 40p — LØST

**Opgave:** Ny version af login-service, nu på `ransomgangreturns.hkn:1338`. Binary er denne gang statisk linket og **UPX-pakket**.

### Trin udført
1. `file` viste "statically linked, no section header" → tegn på packing.
2. `strings` bekræftede UPX 3.96.
3. Unpacked:
```bash
upx -d ransomgangreturns -o ransomgangreturns_unpacked
```
4. Unpacked binary er **not stripped, with debug_info** → alle symbolnavne bevaret.
5. `objdump --disassemble=main` viste flowet:

```
A = ransomGang5()          # time(NULL) — nuværende Unix-timestamp
B = ransomGang4(A)         # ctime(A) — menneskelæselig tidsstreng, printes til bruger
ransomGang1(A)             # spawner tråd der kører ransomGang3(A), joiner tråden
                            # -> ransomGang3 sætter formentlig den globale "ransomGang1337"
fgets(input, 11)           # bruger indtaster max 10 tegn
code = ransomGang2(input)  # strtol(input) — forventer et TAL som tekst
if (code == ransomGang1337) -> system() -> shell
```

6. Disassemblerede hjælpefunktionerne:
   - `ransomGang5`: `time(NULL)` → returnerer timestamp A
   - `ransomGang4`: `ctime(A)` → tekststreng (det du ser printet)
   - `ransomGang1`: `pthread_create(ransomGang3, A)` + `pthread_join` — kører `ransomGang3` i en tråd
   - `ransomGang2`: `strtol(input)` med overflow-check — konverterer din tekst til et tal

### `ransomGang3` — selve formlen
```
srandom(A);        // seeder PRNG med timestamp A (det tal serveren selv printer)
r1 = rand();
r2 = rand();
code = A - (r1 % 10000) + (r2 % 10000);
ransomGang1337 = code;
```
De lange `imul`/`sar`-sekvenser i disassemblyen er bare compilerens optimerede `% 10000` (magic-number division i stedet for `div`).

**Hvorfor det er udregneligt:** `rand()` er ikke kryptografisk tilfældig — samme seed (`srandom(A)`) giver altid samme `r1`/`r2` på samme glibc-version, så vi kan reproducere beregningen lokalt.

### Python-script til at beregne koden
```python
import ctypes, sys
libc = ctypes.CDLL("libc.so.6")

def compute_code(A: int) -> int:
    libc.srandom(ctypes.c_uint(A))
    r1 = libc.rand()
    r2 = libc.rand()
    return A - (r1 % 10000) + (r2 % 10000)

A = int(sys.argv[1])   # tallet serveren printer som "Script boot EPOCH"
print(compute_code(A))
```

### Løsning
```
nc ransomgangreturns.hkn 1338
# server printer fx: "Script boot EPOCH: 1791806548"
python3 computer_code.py 1791806548   # giver fx 1791801124
# indtast resultatet som login-kode -> "Correct! Welcome!" -> shell
```
Testet og bekræftet virkende mod den rigtige server.

### Lærdom
- `rand()`/`srandom()` er **deterministisk** givet samme seed — aldrig brug til sikkerhedskritiske "tilfældige" værdier. Et klassisk PRNG-svaghedsmønster i CTF'er og i virkelige systemer.
- UPX-packing er triviel at fjerne (`upx -d`) og giver typisk en **not stripped** binary bagefter, hvilket gør efterfølgende analyse markant lettere (fulde symbolnavne i stedet for rå adresser).

---

## 4. Change Direction (Network Forensics / JWT) — 45p — I GANG

**Opgave:** pcap (`magic.pcapng`, 22MB) der viser to servere kommunikere om "dele af en password-lignende streng". Hint: stien er vigtig, `http://magic-key.hkn` er relevant.

### Værktøjer installeret undervejs
```bash
apt-get install -y tshark hashcat
```

### Trin 1 — Protocol hierarchy
```bash
tshark -r magic.pcapng -q -z io,phs
```
Mest trafik er TLS (YouTube/Google — **baggrundsstøj**, bekræftet via DNS/SNI). Det interessante er ren **HTTP** til `secret-server.hkn` (kun ~50 frames).

### Trin 2 — HTTP-trafik til secret-server.hkn
```bash
tshark -r magic.pcapng -Y http -T fields -e frame.number -e http.request.full_uri -e http.request.method -e http.file_data
```
Mønster: gentagne `GET /next_chars?char=X` (to servere spørger hinanden på skift), en `GET /` (viser "Give me your magic key!"-formular → POST `/keycheck`), og til sidst `GET /flag`.

**Faser i trafikken:**
1. **Decoy-fase** — sjove tilfældige sætninger som svar, ingen reel info.
2. **Fragment-fase 1** (frame 10650–12513) — JSON-arrays med tekst-fragmenter. Forsøgt rekonstrueret via overlap/de Bruijn-kædning til noget i retning af `password:my-p...`/`assword:my-p` — **usikkert, indeholdt modstridende fragmenter** (fx `"wd:"` passede intet sted). `POST /keycheck` med `key=my-password` fik svaret *"Use what you received carefully on the other server!"* — men testet direkte på `magic-key.hkn` som sti gav **403 "This is not part of the challenge"**. **Konklusion: dette spor er en bevidst red herring/decoy.**
3. **Fragment-fase 2** (frame 17433–17477) — fragmenter der konkatenerer **perfekt uden overlap**:
   ```
   "Session-To" + "ken: very-goo" + "d-session-token" = "Session-Token: very-good-session-token"
   ```
   Høj tillid til denne rekonstruktion pga. den rene sammenkædning.

### Trin 3 — Opdagelse: custom `JWT:` HTTP-header
Alle "rigtige" requests i fragment-fase 2 bar en header `JWT: <token>`. Fundet **3 JWT'er** i pcap'en (søgt efter `eyJ` base64url-mønster):

| JWT | Payload | Resultat på secret-server.hkn |
|---|---|---|
| JWT1 | `{"admin":false,"timestamp":1300000000}` | 401 — "You are not admin" |
| JWT2 | `{"admin":true,"timestamp":1300000000}` | **200 — gav de rigtige Session-Token-fragmenter!** |
| JWT3 | `{"admin":true,"timestamp":2003432675}` | 400 — forkert/ugyldigt timestamp |

→ JWT2 er en **allerede forfalsket admin-token**, opsnappet fra klartekst-HTTP (ingen TLS). Nøglelæring: timestamp skal matche en **specifik forventet værdi**, ikke bare være "gyldig"/aktuel.

```python
# JWT-dekoder brugt til at læse payloads
import base64, json
def b64url_decode(s):
    s += '=' * (-len(s) % 4)
    return base64.urlsafe_b64decode(s)
h, p, sig = jwt.split(".")
print(b64url_decode(p).decode())
```

### Trin 4 — Afprøvning mod magic-key.hkn (77.157.57.76)
- `GET /` + JWT2 som header → **200**, viser "Give me your magic key!"-formular. Footer: **"Copyright by Retire Me industries™ 02-01-1970"** (anderledes dato end secret-server.hkn's `24-12-2015` — formentlig et hint om forventet timestamp-værdi, men endnu ikke bekræftet).
- `GET /next_chars` + JWT2 → **401** "You do not have permission to view this content!" (anden fejltekst end secret-server — tyder på anden valideringslogik, fx tjek mod aktuel tid i stedet for fast session-anker).
- `GET /flag` + JWT2 → 401 (samme).
- `GET /very-good-session-token` (forsøgt som sti) → **403** "This is not part of the challenge".

**Vigtig opdagelse:** `magic-key.hkn` svarer **403 på ALLE ukendte stier** (testet bredt: `/app.py`, `/server.py`, `/.git/config`, `/flag.txt`, osv. — kun `/`, `/index.css` og de kendte endpoints giver andet end 403). Det er en bevidst whitelist, ikke en specifik "fælde" for ét gæt — **directory/source-file brute force er en blindgyde her**, confirmed ved systematisk test.

### Trin 5 — Forsøg på at omgå JWT-signaturen
1. **`alg:none`-angreb** (sætte JWT-header til `{"alg":"none","typ":"JWT"}`, tom signatur) — **afvist konsekvent** (401, identisk fejltekst som med ugyldig signatur). Serveren validerer algoritmen korrekt.
2. **HMAC-nøgle cracking med hashcat** (`-m 16500`, JWT-mode):
   - 10k common passwords wordlist → intet fund
   - Fuld `rockyou.txt` (14,3 mio ord) → intet fund
   - Tematiske gæt (`DogeCoinToTheMoon1337`, `ransomgang`, flag-strenge fra tidligere opgaver, osv.) → intet fund
   - `rockyou.txt` + `best64.rule` mutationer → intet fund
   - **Konklusion: nøglen er ikke et almindeligt/gætteligt ord — kan ikke brydes med wordlist alene.**
3. **`/keycheck`-formular på magic-key.hkn** afprøvet med alle hidtil fundne kandidat-strenge (`my-password`, `password:my-password`, `very-good-session-token`, `DogeCoinToTheMoon1337`, m.fl.) → **alle gav samme generiske "Not winning! :("**. Bekræfter dog at endpointet fungerer og kan skelne rigtig/forkert svar (anderledes besked ved korrekt nøgle forventes).

### Trin 6 — VIGTIG KORREKTION: pcap'en er IKKE jeres live-instans
`secret-server.hkn` findes **ikke længere i DNS** (`ping`/`getent hosts` fejler). Pcap'ens server svarede `Server: SimpleHTTP/0.6 Python/3.11.6` — men alt levende i jeres miljø kører `Python/3.9.18`. **Pcap'en er et generisk eksempel/demo af metoden, ikke de faktiske værdier for jeres egen instans.** Derfor har INGEN af de bogstaveligt genbyggede strenge fra pcap'en (`my-password`, `very-good-session-token`, JWT2 osv.) virket live — det er forventet, ikke en fejl i vores metode.

### Trin 7 — Fandt den skjulte secret-server via subnet-scan
```bash
ip -4 addr show          # vi er 77.74.147.4/24
arp -a                   # kendte: .150 (magic-key.hkn), .2, .3
nmap -sn 77.74.147.0/24  # fandt OGSÅ .54 — ukendt, ikke i DNS/ARP før scan
```
`77.74.147.54` er jeres **egen live secret-server** (samme fejltekster/endpoint-struktur som pcap'en, fx `/next_chars` → `400 "Provide exactly one character"` hvis `char` mangler). Kun port 80 åben.

**VIGTIGT:** På `.54` er `/`, `/keycheck` og `/flag` **permanent blacklistet → 403 "This is not part of the challenge"**, uanset hvilke headers/auth der sendes. `POST`/`PUT` på `/keycheck` → `501 Unsupported method`. Kun `/next_chars?char=X` (GET) virker overhovedet på `.54`. Dvs. `.54` er reelt kun et "fragment-orakel" — intet andet er tilgængeligt der, heller ikke med forfalsket JWT.

### Trin 8 — `/next_chars` er en sliding-window-graf, ikke tilfældig støj
Query `char=X` (uden nogen auth) returnerer et array af 3-tegns "vinduer". Fuldt tegnsæt probet (a-z, A-Z, 0-9, symboler) på `.54` gav denne graf (kun ikke-tomme vist):

```
p -> wd:      w -> d:C      d -> :C%      : -> C%{      C -> %{6
%  -> {6b     {  -> 6bS     6 -> bSU      b -> SUA      S -> UAs
U  -> As5     A  -> s52     s -> 52s ELLER I@$   5 -> 2sI   2 -> sI@
I  -> @$K     @  -> $K8     $  -> K8O     K -> 8Ou      8 -> Ouk
O  -> uk0     u  -> k0      k -> 0        0 -> "" (slut)
```

**Reglen:** hvert svars første tegn = næste forespørgselstegn (kæde), og hvert nyt svar deler sine første 2 tegn med forrige svars sidste 2 tegn (sliding window +1 tegn ad gangen). Ved forgrening (`s` har to mulige svar) vælges den kandidat hvis første 2 tegn matcher vinduets sidste 2 tegn — løser entydigt begge forekomster af `s` i kæden.

Start = `p` (det eneste tegn der ALDRIG optræder som første tegn i noget svar = ingen peger på det = unik indgang).

**Rekonstrueret fuld streng (Python-løser i `/tmp/claude-0/pcap_analysis/solve_chain.py`):**
```
pwd:C%{6bSUAs52sI@$K8Ouk0
```
— men `POST /keycheck` på magic-key.hkn med **"pwd:"-præfikset inkluderet** gav kun generisk "Not winning!". **UDEN `pwd:`-præfikset** (altså kun `C%{6bSUAs52sI@$K8Ouk0`) gav derimod den specifikke besked **"Use what you received carefully on the other server!"** — samme kendte besked som i pcap'en ved korrekt nøgle. Konklusion: `pwd:` var kun en **label** ("password:"), ikke del af selve værdien. Den ægte rekonstruerede værdi er:

**`C%{6bSUAs52sI@$K8Ouk0`** ← dette ER secret-server.hkn's (`.54`) rigtige nøgle, bekræftet genkendt af magic-key.hkn's kode — men kan ikke indsendes direkte til `.54` selv, fordi `/keycheck` er blacklistet/metoden ikke er implementeret der (se Trin 7).

### Trin 9 — Hver gang denne nøgle POST'es til magic-key.hkn, udstedes en FRISK JWT
```bash
curl -s -i -X POST http://magic-key.hkn/keycheck -H "Content-Type: text/plain" \
  --data-raw 'key=C%{6bSUAs52sI@$K8Ouk0'
```
giver `200 OK` + response-header:
```
JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhZG1pbiI6ZmFsc2UsInRpbWVzdGFtcCI6PFVOSVhfTk9XPn0.<sig>
```
(`admin:false`, `timestamp` = nutidigt Unix-tidsstempel — ægte, server-signeret, friskt hver gang).

### Trin 10 — JWT-signaturen valideres IKKE på `.54` (men betyder noget på magic-key.hkn)
Testet med Python `requests` direkte mod `.54`:
- `alg:none` + tom signatur, `admin:true` → **200 OK**, identisk fragment-svar som uautentificeret.
- `alg:HS256` + ren garbage-signatur, `admin:true` → **200 OK**, samme.
- `admin` som streng `"True"` (truthy-bug forsøgt) → ingen forskel, samme 200.
- Den gamle JWT2 fra pcap'en (`admin:true, timestamp:1300000000`) → stadig **200**, samme svar.

→ Signaturen tjekkes overhovedet ikke på `.54` i denne live build. MEN: uden nogen JWT-header giver `/next_chars` 200 (det vi byggede kæden med); **MED** en JWT-header hvor `admin:false` giver det derimod **401 "You are not admin"** — dvs. *tilstedeværelsen* af en JWT med `admin:false` er strengere end slet ingen JWT. Med forfalsket `admin:true` (alg:none) er svaret identisk med det uautentificerede (samme fragmenter) — så langt ingen tegn på et ANDET/ægte fragment-sæt bag admin-flaget på `.54`.

Forfalsket `admin:true` JWT testet mod `.54`'s `/`, `/flag`, `/keycheck` → stadig konsekvent **403** (blacklistet uanset auth, jf. Trin 7).

### Trin 11 — VIGTIGT: Lab blev genstartet → nye IP'er, SAMME metode/data genbruges
Når lab resettes (fx efter timeout), får alt nye IP'er, men selve challenge-koden/fragment-grafen er **identisk** (ikke tilfældig per instans). Efter reset:
```bash
ip -4 addr show              # egen IP/subnet
getent hosts magic-key.hkn   # ny IP til magic-key.hkn
nmap -sn <eget-subnet>.0/24  # find den skjulte secret-server (mønster: et ukendt sidste oktet ud over .2/.3/egen/magic-key)
```
I denne omgang: egen IP `77.233.186.4`, `magic-key.hkn` = `77.233.186.91`, skjult secret-server fundet på `77.233.186.137`. Fragment-grafen fra Trin 8 og den rekonstruerede nøgle `C%{6bSUAs52sI@$K8Ouk0` var **identiske** på den nye instans — bekræfter at kun IP'erne er tilfældige, ikke selve puslespillet. **Ved NÆSTE reset: gentag denne proces (find ny IP via nmap-sweep), men genbrug fragment-grafen/nøglen og alt nedenfor uden at skulle udlede det forfra.**

### Trin 12 — Officiel opgavetekst (fra Haaukins-dashboard, 45p, 0 solves)
> "Two servers communicated in the past about some parts of a password-like string. Maybe this is the situation again? I saved a pcap for you about the previous communication, it holds the key to your question! Also, the path is always important! http://magic-key.hkn will be handy!"

Flag-format: `HKN{...}`. Hintet **"maybe this is the situation again?"** var afgørende — det betød bogstaveligt at de to servere **kommunikerer LIVE lige nu**, ikke kun i den gamle pcap.

### Trin 13 — GENNEMBRUD: Passiv aflytning af live server-til-server-trafik
```bash
sudo tcpdump -i eth0 -n "host <magic-key-ip> and host <secret-server-ip>"
```
(kræver `sudo` — almindelig bruger har ikke capture-rettigheder). Dette afslørede: **secret-server (`.137`) er klienten, der løbende spørger magic-key.hkn (`.91`) på `/next_chars?char=X`** — altså omvendt rollefordeling af det, vi antog ("Change Direction" bogstaveligt!). `.137` får **200 OK** tilbage (omend kun decoy-vittigheder i øjeblikket — samme decoy-sætninger som pcap'ens fase 1: "General Kenobi!", "Yesterday it worked...", osv., i en fast cyklus på 13 forespørgselstegn: `d U 0 5 S K @ { u p s C b`).

**Afgørende fund ved at hive de fulde request-headers ud af denne trafik** (`tshark -r live.pcap -Y 'http.request' -V`):
```
GET /next_chars?char=d HTTP/1.1
Host: magic-key.hkn
User-Agent: python-requests/2.31.0
Session-Token: dGhpcyB0b2tlbiBpcyBub3QgZ29vZA
URL-Maybe: /flag
```
To ting vi ALDRIG havde prøvet før:
1. Header-NAVNET **`URL-Maybe:`** (ikke `URL:`, som vi testede tidligere uden effekt).
2. `Session-Token`-værdien er **base64**: `dGhpcyB0b2tlbiBpcyBub3QgZ29vZA` dekodes til **"this token is not good"** — en bevidst dårlig decoy-værdi fra en automatisk test-klient.

**Bekræftet eksperimentelt:** sender man PRÆCIS disse to headers (samme base64-streng + `URL-Maybe: /flag`) til `magic-key.hkn/next_chars`, får man **200 OK** (omend decoy-indhold, fx `"General Kenobi!"`). Ændrer man BLOT Session-Token til noget ikke-base64 (fx `very-good-session-token`) eller fjerner `URL-Maybe`, får man straks **401** igen. Dette er et **helt nyt, bekræftet virkende auth-mekanisme** vi ikke kendte til før live-sniffingen — simpel header-tilstedeværelse + gyldig base64-formatering er nok til at komme forbi 401'eren (indhold kan stadig variere alt efter om Session-Token's AFKODEDE værdi er den "rigtige" eller en decoy).

### Status / næste skridt

- **AFKRÆFTET (Trin 14):** `try_good_base64_token.py` testede 7 kandidater (`"this token is good"`, `"This token is good"`, `"this token IS good"`, `"this is a good token"`, `"very good session token"`, `"very-good-session-token"`, og den rekonstruerede secret-server-nøgle `C%{6bSUAs52sI@$K8Ouk0`) som base64-kodet `Session-Token` + `URL-Maybe: /flag` mod både `/next_chars` og `/flag`. **Alle 7 gav 401** på begge endpoints. Konklusion: serveren validerer IKKE bare "er det gyldig base64" generelt — den sammenligner mod en konkret forventet værdi. Ren indholds-gætning er en blindgyde.
- **Ny hypotese A (token-rotation/udløb):** Session-Token'en kan være kortlivet eller rotere over tid, og skal derfor opsnappes live i det øjeblik den er gyldig og bruges med det samme (replay inden den udløber).
- **Ny hypotese B (IP-binding):** Token'en kan være bundet til afsenderens IP — dvs. kun `.137` (secret-server) får lov til at bruge den, fordi den fik/udstedte den et bestemt sted, og vores Kali-box (`.4`) bliver afvist uanset token-indhold.
- **Afventer (Trin 15):** To nye scripts sendt til brugeren:
  - `grep_original_pcap_for_sessiontoken.sh` — søger den OPRINDELIGE `magic.pcapng` (ikke live-capture) for `Session-Token`, `URL-Maybe` og `/flag`-trafik, samt lister alle unikke HTTP-headers set i filen. Vi har kun kigget på fragment-kæden i denne fil hidtil — måske indeholder den selve token-udvekslingen, som hintet ("it holds the key to your question") kan hentyde til.
  - `capture_full_cycle.sh` — en 5-minutters passiv `sudo tcpdump`-capture af `.137↔.91`-trafik, der udtrækker ALLE requests kronologisk med deres Session-Token-værdier (for at se om værdien roterer) og alle response-bodies i rækkefølge (for at se om der nogensinde sker en decoy→rigtig overgang, ligesom i den oprindelige pcap).
- Overvej også at sniffe/afprøve om `.137` sender ANDRE header-kombinationer ved forskellige lejligheder (fx mod `/flag` direkte, ikke kun `/next_chars`) — kun `/next_chars`-kald er fanget indtil videre.
- `magic-key.hkn`'s gamle generiske-401-mur (custom JWT-headers, cookies, IP-spoof-headers, vhost-spoof, forfalskede JWT'er) er nu FORKLARET: de manglede simpelthen den rigtige header-kombination (`Session-Token` som base64 + `URL-Maybe`), ikke et dybereliggende problem.
- Directory-bruteforce (ffuf, `dirb/common.txt`) mod magic-key.hkn → intet fundet ud over roden. Den sti er lukket (men nu irrelevant, da vi har et bedre spor).
- rockyou.txt + hashcat er installeret i arbejdsmiljøet hvis yderligere cracking skal gentages (nu sandsynligvis overflødigt).
- **Vigtig arbejdsgang-læring:** `sudo tcpdump` + filter på de to kendte IP'er er den mest effektive metode til at finde den rigtige protokol — langt mere produktivt end at gætte header-kombinationer blindt. Gør dette FØRST efter en ny reset, før man begynder at gætte.
- Centrale scripts i `/tmp/claude-0/pcap_analysis/` (sendt til brugeren undervejs, genbrugelige efter reset med opdaterede IP'er): `solve_chain.py` (graf-løser), `rediscover.sh`/`scan_subnet.sh` (find IP'er efter reset), `passive_capture_sudo.sh`/`capture_live_exchange.sh`/`show_137_headers.sh` (live server-til-server sniffing — **brug disse først!**), `try_good_base64_token.py` (afkræftet, se Trin 14), `try_url_maybe_header.sh`, `grep_original_pcap_for_sessiontoken.sh` (NY), `capture_full_cycle.sh` (NY).
- Seneste kendte IP'er (FØR evt. ny reset): `secret-server.hkn` = `77.233.186.137` (uden DNS-navn), `magic-key.hkn` = `77.233.186.91`, egen Kali-box = `77.233.186.4`. **Disse skal genfindes efter enhver ny lab-start.**

---

## Generel SOC/Forensics-arbejdsgang (reference)

1. **Identificér før analyse:** `file`, `exiftool`, `sha256sum`, `strings`, `binwalk`.
2. **Pak ud hvis nødvendigt:** tjek for UPX/packers (`strings | grep -i upx`), `upx -d`.
3. **Statisk analyse:** `objdump -d -M intel`, `nm`, `readelf -s` — brug symbolnavne når de findes (not stripped).
4. **Isolér egen kode fra libc-støj:** filtrer `nm`-output, brug `--disassemble=<funktionsnavn>` til målrettet disassembly.
5. **Lokal test før produktion:** kør binary/exploit lokalt, bekræft virkning, før den rammer den rigtige server/port.
6. **Dokumentér:** hvad blev gjort, hvorfor, og hvad blev fundet — reproducerbart for andre.
