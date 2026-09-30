# Opgave 3 – Netværks-lag

Denne opgave bygger centrale dele af en netværksstak fra bunden i Linux: TCP, DNS, HTTP og TLS/HTTPS.

Målet er ikke kun at bruge færdige programmer, men at se hvad der faktisk sendes på netværket. Derfor er TCP-klient/server, DNS-query, HTTP-server og HTTPS-server implementeret med Python standardbiblioteket og analyseret med `ss`, `dig`, `curl`, `openssl s_client`, `tcpdump` og Wireshark.

Al lab-trafik køres på loopback i Linux-VM'en.

## Lab-miljø

- Linux VM: `linux101-securebase`
- Loopback: `127.0.0.1`
- Lokalt testnavn: `netlab.test`
- TCP lab: port `5000`
- HTTP: port `8080`
- HTTPS/TLS: port `8443`
- Packet capture: `tcpdump` på Linux
- Analyse: Wireshark på Windows-hosten

Det lokale navn blev konfigureret med:

```bash
echo "127.0.0.1 netlab.test" | sudo tee -a /etc/hosts
getent hosts netlab.test
```

Resultatet var:

```text
127.0.0.1 netlab.test
```

Ved at binde tjenesterne til `127.0.0.1` i stedet for `0.0.0.0` eksponeres de kun lokalt i VM'en.

---

## 1. TCP

TCP-klienten og serveren er implementeret direkte med Python sockets:

- [tcp_server.py](./tcp_server.py)
- [tcp_client.py](./tcp_client.py)

Serveren bruger:

```python
socket.socket(socket.AF_INET, socket.SOCK_STREAM)
```

hvor `AF_INET` betyder IPv4 og `SOCK_STREAM` betyder TCP.

Serveren binder til:

```text
127.0.0.1:5000
```

og dette blev verificeret med:

```bash
ss -ltnp | grep 5000
```

som viste en listening socket på `127.0.0.1:5000`.

Klienten opretter forbindelsen med `connect()`, sender bytes med `sendall()` og modtager serverens svar med `recv()`.

Testdata:

```text
Client -> Server: Hello from TCP client
Server -> Client: Hello from TCP server
```

### Three-way handshake

Wireshark-capturet viser TCP's three-way handshake:

```text
Client -> Server    SYN
Server -> Client    SYN, ACK
Client -> Server    ACK
```

Derefter sendes data, og forbindelsen afsluttes med FIN/ACK.

Dokumentation:

- [TCP handshake](./tcp-handshake.png)
- [TCP client data](./tcp-data-client.png)
- [TCP server data](./tcp-data-server.png)
- [TCP connection close](./tcp-connection-close.png)
- [TCP packet capture](./tcp-handshake.pcap)

TCP bruges af HTTP, fordi TCP giver en forbindelsesorienteret og ordnet byte-stream med retransmission ved tab. HTTP/1.1 forventer denne pålidelige transport.

---

## 2. DNS

Før den manuelle DNS-klient blev bygget, blev normale DNS-records undersøgt med `dig`.

Eksempler:

```bash
dig google.com A
dig google.com MX
dig google.com NS
dig google.com TXT
dig www.github.com CNAME
```

De vigtigste recordtyper i opgaven er:

| Record | Formål |
| --- | --- |
| A | Mapper et navn til en IPv4-adresse |
| CNAME | Alias fra ét navn til et andet |
| MX | Angiver mailservere for et domæne |
| NS | Angiver navneservere for et domæne |
| TXT | Tekstdata, fx SPF og domæneverifikation |

### Manuel DNS-query

[dns_client.py](./dns_client.py) bygger en DNS-query som rå bytes uden et DNS-bibliotek.

DNS-headeren bygges med `struct.pack()` og indeholder:

```text
Transaction ID
Flags
Questions
Answers
Authority
Additional
```

Domænenavnet `google.com` bliver kodet i DNS-format som længde-prefiksede labels:

```text
06 google
03 com
00
```

Derefter tilføjes:

```text
QTYPE  = 1  -> A
QCLASS = 1  -> IN
```

Queryen sendes over UDP til den lokale resolver:

```text
127.0.0.53:53
```

med en almindelig UDP-socket:

```python
socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
```

Testen brugte den faste Transaction ID:

```text
0x1234
```

Svaret indeholdt seks A-records, som scriptet selv parser tilbage til IPv4-adresser.

Scriptet håndterer også DNS name compression, hvor fx `c0 0c` fungerer som en pointer til et navn tidligere i DNS-pakken.

Dokumentation:

- [DNS query](./dns-query.png)
- [DNS response](./dns-response.png)
- [DNS packet capture](./dns-query.pcap)
- [DNS client source](./dns_client.py)

Wireshark viser tydeligt samme Transaction ID `0x1234` i request og response.

---

## 3. HTTP

HTTP-serveren er implementeret direkte oven på en TCP-socket:

- [http_server.py](./http_server.py)

Der bruges ikke Flask, Apache eller Pythons færdige HTTP-server. Serveren modtager de rå bytes, decoder HTTP-headerne og parser selv:

```text
request method
path
HTTP version
headers
```

Et request kan fx se sådan ud:

```http
GET / HTTP/1.1
Host: netlab.test:8080
User-Agent: curl/8.18.0
Accept: */*
```

Serveren bygger selv HTTP-response med:

```text
status line
headers
blank line
body
```

og beregner `Content-Length` ud fra bodyens byte-længde.

### Statuskoder

Serveren blev testet med:

```bash
curl -v http://netlab.test:8080/
curl -v http://netlab.test:8080/health
curl -v http://netlab.test:8080/does-not-exist
curl -v -X POST http://netlab.test:8080/
```

Resultater:

```text
GET /                 -> 200 OK
GET /health           -> 200 OK
GET /does-not-exist   -> 404 Not Found
POST /                -> 405 Method Not Allowed
```

Dokumentation:

- [HTTP request](./http-request.png)
- [HTTP response](./http-response.png)
- [HTTP packet capture](./http.pcap)

I Wireshark kan både request, headers, response og body læses direkte, fordi almindelig HTTP ikke krypterer indholdet.

---

## 4. TLS / HTTPS

HTTPS-serveren bygger videre på TCP/HTTP-laget og wrapper TCP-forbindelsen i TLS med Python `ssl`:

- [https_server.py](./https_server.py)

Et selvsigneret certifikat blev genereret til labbet:

```bash
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout key.pem \
  -out cert.pem \
  -days 7 \
  -subj "/CN=netlab.test" \
  -addext "subjectAltName=DNS:netlab.test,IP:127.0.0.1"
```

Certifikatet havde:

```text
Subject: CN=netlab.test
Issuer:  CN=netlab.test
SAN:     DNS:netlab.test, IP:127.0.0.1
```

Subject og issuer er ens, fordi certifikatet er selvsigneret.

Den private nøgle `key.pem` er ikke lagt i repository'et. Certifikat og nøgle kan reproduceres med kommandoen ovenfor.

### Test med curl

HTTPS blev testet med:

```bash
curl -vk https://netlab.test:8443/
```

Forbindelsen brugte TLS 1.3, og HTTP-responset blev modtaget korrekt inde i TLS-forbindelsen.

### Test med openssl s_client

TLS blev også undersøgt med:

```bash
openssl s_client \
  -connect netlab.test:8443 \
  -servername netlab.test
```

Den konkrete forbindelse viste blandt andet:

```text
Protocol: TLSv1.3
Cipher: TLS_AES_256_GCM_SHA384
Server public key: RSA 2048 bit
Verify return code: 18 (self-signed certificate)
```

Fejlen om self-signed certificate er forventet i labbet, fordi certifikatet ikke er udstedt af en CA, klienten stoler på.

### HTTP kontra HTTPS i Wireshark

Med almindelig HTTP kunne Wireshark læse:

```text
GET / HTTP/1.1
Host: netlab.test:8080
Hello from my raw Python HTTP server!
```

Med HTTPS kan Wireshark stadig observere TLS-handshaket og trafikmængden, men HTTP-indholdet ses som krypteret `Application Data`.

Dokumentation:

- [TLS Client Hello](./tls-client-hello.png)
- [TLS Server Hello](./tls-server-hello.png)
- [TLS encrypted application data](./tls-encrypted-data.png)
- [HTTPS packet capture](./https.pcap)

Det demonstrerer, hvad TLS ændrer: transporten er stadig TCP, og man kan stadig se forbindelsen og TLS-protokollen, men applikationsdata er ikke længere læselige direkte på netværket.

---

## Samlet protokolforløb

Labbet kan ses som følgende kæde:

```text
netlab.test
    |
    | lokal navneopløsning
    v
127.0.0.1
    |
    | TCP
    | SYN -> SYN/ACK -> ACK
    v
TLS handshake
    |
    | krypteret kanal
    v
HTTP request
    |
    v
HTTP response
```

DNS-testen viser samtidig, hvordan et rigtigt domænenavn kan omsættes til en IP-adresse ved at bygge og parse DNS-pakker på byte-niveau.

## Værktøjer brugt

- Python `socket`
- Python `struct`
- Python `ssl`
- `ss`
- `dig`
- `getent`
- `curl`
- `openssl`
- `tcpdump`
- Wireshark

## Filer

### Kildekode

- [tcp_server.py](./tcp_server.py)
- [tcp_client.py](./tcp_client.py)
- [dns_client.py](./dns_client.py)
- [http_server.py](./http_server.py)
- [https_server.py](./https_server.py)

### Packet captures

- [tcp-handshake.pcap](./tcp-handshake.pcap)
- [dns-query.pcap](./dns-query.pcap)
- [http.pcap](./http.pcap)
- [https.pcap](./https.pcap)

## Resultat

Opgaven demonstrerer:

- TCP three-way handshake og connection teardown
- egen TCP-klient og -server med sockets
- DNS recordtyper og manuel konstruktion af en DNS-query
- parsing af DNS-response og compressed names
- lokal navneopløsning til `netlab.test`
- manuel parsing af HTTP requests
- HTTP statuskoder og korrekt `Content-Length`
- selvsigneret certifikat og TLS 1.3
- forskellen mellem klartekst-HTTP og krypteret HTTPS
- brug af packet capture til at verificere, hvad koden faktisk sender og modtager
