# Linux 101 – Modul 4: Firewall og netværkssikkerhed

## Formål

Formålet med modulet er at reducere serverens angrebsflade ved kun at tillade den netværkstrafik, der er nødvendig.

Serveren anvender UFW som firewall. Politikken er sat til **default deny** for indgående trafik og **allow** for udgående trafik.

---

## 1. Standardpolitik

Før konfigurationen var UFW inaktiv:

```bash
sudo ufw status verbose
```

Resultat:

```text
Status: inactive
```

Standardpolitikken blev derefter sat til:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Det betyder:

- al indgående trafik blokeres som udgangspunkt
- udgående trafik er tilladt
- nødvendige services åbnes eksplicit

Dette følger princippet om **default deny** og reducerer serverens angrebsflade.

---

## 2. SSH-regel

Serverens management-interface bruger det interne netværk:

```text
10.10.10.0/24
```

Ubuntu-serverens management-IP er:

```text
10.10.10.10
```

Windows-hosten bruger:

```text
10.10.10.1
```

SSH blev derfor kun tilladt fra management-nettet:

```bash
sudo ufw allow from 10.10.10.0/24 to any port 22 proto tcp
```

Reglen blev kontrolleret før aktivering:

```bash
sudo ufw show added
```

Resultat:

```text
ufw allow from 10.10.10.0/24 to any port 22 proto tcp
```

---

## 3. Aktivering af firewall

UFW blev aktiveret med:

```bash
sudo ufw enable
```

Efter aktivering blev konfigurationen kontrolleret:

```bash
sudo ufw status verbose
```

Resultat:

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    10.10.10.0/24
```

Det dokumenterer, at kun SSH på TCP port 22 er åbnet, og kun fra det interne management-net.

**Dokumentation:** `ufw-firewall-konfiguration.png`

---

## 4. Test af SSH efter aktivering

Efter UFW blev aktiveret, blev SSH-forbindelsen testet fra Windows-hosten:

```powershell
ssh axel@10.10.10.10
```

Login lykkedes, hvilket viser at firewall-reglen tillader management-trafik fra `10.10.10.1`.

**Dokumentation:** `ssh-test-efter-firewall.png`

---

## Portbegrundelsestabel

| Port | Protokol | Tjeneste | Tilladt fra | Begrundelse | Risiko |
|---|---|---|---|---|---|
| 22 | TCP | SSH | `10.10.10.0/24` | Nødvendig til fjernadministration af serveren | En åben SSH-port kan udsættes for loginforsøg og angreb. Risikoen reduceres ved kun at tillade management-nettet samt ved at bruge nøglebaseret login og deaktivere password- og root-login |

Der er ikke åbnet andre indgående porte, da serveren på nuværende tidspunkt ikke har andre services, der kræver ekstern adgang.

---

## Sikkerhedsmæssige valg

### Default deny

Indgående trafik blokeres som standard. En service skal derfor aktivt tillades, før den kan nås fra netværket.

Det reducerer risikoen for, at en ny eller fejlkonfigureret service bliver eksponeret automatisk.

### Begrænset SSH-adgang

SSH er ikke åbnet fra alle netværk, men kun fra:

```text
10.10.10.0/24
```

Dette betyder, at SSH-adgang kun kan ske via det interne management-net.

### SSH på port 22

SSH er beholdt på standardport 22.

Sikkerheden er i stedet baseret på:

- adgang kun fra management-nettet
- nøglebaseret autentifikation
- deaktiveret password-login
- deaktiveret direkte root-login
- default deny firewall-politik

At flytte SSH til en ikke-standard port ville primært reducere støj fra automatiske scanninger, men ville ikke i sig selv erstatte egentlig adgangskontrol.

---

## Resultat

Modul 4 er gennemført med:

- UFW aktiveret
- default deny for indgående trafik
- udgående trafik tilladt
- SSH som eneste åbne indgående service
- SSH begrænset til management-nettet `10.10.10.0/24`
- aktiv firewall dokumenteret med `ufw status verbose`
- SSH testet efter aktivering af firewall
- portbegrundelsestabel udarbejdet
