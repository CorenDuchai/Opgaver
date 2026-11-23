# Haaukins SOC/CTF – arbejdsnoter og løsningsmetoder

Denne fil samler de Haaukins-opgaver, vi har arbejdet med sammen, med fokus på målet med opgaven, hvordan vi fandt løsningen, hvilke værktøjer vi brugte, og hvad der er værd at huske.

## ELF
**ELF = Executable and Linkable Format.** Det er standardformatet for kompilerede Linux-programmer, lidt som `.exe` på Windows. En ELF kan bl.a. undersøges med `file`, `strings`, `readelf`, `objdump` og `gdb`.

---

## Introduction
**Mål:** Lære flag-format og Haaukins-flowet.

Flag:
```text
HKN{l3ts_st4rt_h4ck1ng}
```

## Hashle
**Mål:** Genkende/cracke en hash/adgangskode.

Kandidat: `myra13`

Flag:
```text
HKN{1_l1k3_y0ur_Funny_w0rd5_m4g1c_m4n}
```

## Attacks over Attacks
**Mål:** Find hvilket program angriberen injicerede payload i.

Spor: `evidence/journal.md` indeholdt `Injected payload into WebFormBuilder v3.2.1`.

Flag:
```text
HKN{WebFormBuilder}
```

## Ransomware Hits Hard
**Mål:** Identificere ransomware-målet.

Resultat: `MedCore`

Flag:
```text
HKN{medcore}
```

## Crypto Wallet
**Mål:** Find wallet-adressen i bevismaterialet.

Flag:
```text
HKN{1K4nTrA5z8F9xyvECz6M7jEpGfHG9LpQYd}
```

## Broken but not Lost
**Mål:** Identificere en fil med forkert extension.

Fil: `evidence/corrupted/01-3xt`

Kommando:
```bash
file evidence/corrupted/01-3xt
```

Filen viste sig at være JPEG trods forkert extension.

Flag:
```text
HKN{1mp0rt4nc3_0f_3xt3nsi0ns}
```

## Wizard Activities
**Mål:** Reparere ødelagte magic bytes i en PNG.

Fil: `evidence/corrupted/02-m4g1c.png`

PNG-signatur:
```text
89 50 4e 47 0d 0a 1a 0a
```

Reparation:
```bash
cp corrupted/02-m4g1c.png corrupted/02-m4g1c-fixed.png
printf '\x89PNG\r\n\x1a\n' | dd of=corrupted/02-m4g1c-fixed.png bs=1 count=8 conv=notrunc
```

Flag:
```text
HKN{m4g1c_h3ed3rs}
```

## Winter is The Best Time of Year
**Mål:** Find whitespace-steganografi i `03-sn0w.txt`.

Synligt password: `8329`.

Flag:
```text
HKN{wh1t3sp4ce_st3g0}
```

## Who Wants to Live in a Castle Pt. 1
**Mål:** Udtrække skjult billede og identificere stedet.

Fra `bitwise_secrecy.jpeg` fandt vi password `41659` og brugte:
```bash
steghide extract -sf bitwise_secrecy.jpeg -p 41659
```

Det gav `meeting-point.png`, som viste Pena Palace.

Flag:
```text
HKN{Pena_Palace}
```

## Who Wants to Live in a Castle Pt. 2
**Mål:** Find safehouse/destination fra planmateriale.

Spor: `plan.txt` pegede på Lisbon.

Flag:
```text
HKN{4_n3w_st4rt}
```

## The Escape
**Mål:** Find destinationen i browserhistorikken.

Spor:
```text
Flight Confirmation for M. Christensen - Copenhagen to Lisbon
```

Flag:
```text
HKN{Lisbon}
```

## The Accomplice
**Mål:** Identificere medskyldig via browserhistorik/tidslinje.

Spor: encrypted DM -> Facebook-profil `Joao Da Silva` -> Lisbon weather.

Flag:
```text
HKN{Joao_Da_Silva}
```

## Based Passwords (PW1)
**Mål:** Genkende Base64.

Data:
```text
dGhlY3JpbWluYWxsaWZl
```

Decode:
```bash
echo 'dGhlY3JpbWluYWxsaWZl' | base64 -d
```

Resultat: `thecriminallife`

Flag:
```text
HKN{thecriminallife}
```

## Is Hashing Illegal? (PW2)
**Mål:** Cracke en MD5-hash med ordliste.

Hash:
```text
380fbafd2a92eb8d442b419f18e43fce
```

Kommando:
```bash
john --format=raw-md5 ./evidence/credentials/pw-02.txt --wordlist=/usr/share/wordlists/rockyou.txt
```

Resultat: `canttouchme`

Flag:
```text
HKN{canttouchme}
```

## AD Security is Great (PW3)
**Mål:** Cracke Windows NT-hash.

Hash:
```text
43239E3A0AF748020D5B426A4977D7E5
```

Kommando:
```bash
john --format=NT ...
```

Resultat: `supersecret`

Flag:
```text
HKN{supersecret}
```

## Trashed Secrets
**Mål:** Dekryptere `flag.bin` med en fundet RSA private key.

Filer:
```text
evidence/disk/root/private_key.pem
evidence/disk/.backup/root/flag.bin
```

Kommando:
```bash
openssl pkeyutl -decrypt -inkey ./evidence/disk/root/private_key.pem -in ./evidence/disk/.backup/root/flag.bin
```

Flag:
```text
HKN{d3crypti0n_m4st3r}
```

## Dots and Dashes
**Mål:** Udlede Morse fra en WAV-fil.

Fil: `evidence/experiments/m0rse.wav`

Timing viste ca. `0.06 s = dot`, `0.18 s = dash`. Resultat: `MOMMYSBOY`.

Flag:
```text
HKN{mommysboy}
```

## Experimental web design
**Mål:** Find skjult tekst i HTML/JavaScript.

JavaScript indeholdt ASCII/Unicode code points. Vi dekodede dem med:
```bash
python3 -c 'print("".join(map(chr,[115,111,109,97,110,121,119,97,121,115,116,111,104,105,100,101,115,116,117,102,102])))'
```

Resultat: `somanywaystohidestuff`

Flag:
```text
HKN{somanywaystohidestuff}
```

## Recovering Files
**Mål:** Find slettet malware i et VHD-diskimage.

Disk: `drive1.vhd`

Partition startede ved sektor `128`, dvs. byte-offset `65536`.

Mount read-only:
```bash
sudo mkdir -p /mnt/drive
sudo mount -o ro,loop,offset=65536 drive1.vhd /mnt/drive
```

Slettesøgning:
```bash
fls -r -d -o 128 drive1.vhd
```

Fund:
```text
Pictures/picsfrominternet/cryptolocker.exe
```

MFT-reference: `211-128-1`.

**Læring:** Slettet betyder ofte blot, at filsystemets reference er fjernet; data kan stadig være recoverable.

---

# Reverse Engineering – `game`

## Mål
Reverse engineere en Linux ELF-binary og finde den korrekte input-rute til en shell.

## Vigtige værktøjer
```bash
file game
strings -t x game
objdump -d -M intel game
objdump -s -j .rodata game
```

## Centrale instruktioner
```text
mov   = kopier/flyt værdi
cmp   = sammenlign
jne   = jump if not equal
je    = jump if equal
call  = kald funktion
lea   = hent adresse
```

På Linux x86-64 bruges typisk:
```text
rdi/edi = første argument
rsi/esi = andet argument
rdx/edx = tredje argument
```

## Input 1: 42
Programmet accepterede `42` som første værdi.

## Input 2: 911
I `more_values_here`:
```asm
call atoi
cmp eax,0x38f
jne failure
```

`0x38f = 911`, derfor input `911`.

## Branch: 69 eller 96
I `the_split_oh_no`:
```asm
mov DWORD PTR [rbp-0x4],0x45
mov DWORD PTR [rbp-0x8],0x60
```

```text
0x45 = 69
0x60 = 96
```

`69 -> split_one`, `96 -> split_two`.

Vi så, at `split_one` sluttede med:
```asm
mov edi,0x0
call atoi_was_here
```

mens `split_two` sluttede med:
```asm
mov edi,0x1
call atoi_was_here
```

I `atoi_was_here`:
```asm
mov DWORD PTR [rbp-0x4],edi
cmp DWORD PTR [rbp-0x4],0x1
jne failure
```

Det svarer omtrent til:
```c
if (argument != 1)
    fail();
```

Derfor er `96` den rigtige branch.

## Input 3: 120
I `split_two`:
```asm
mov DWORD PTR [rbp-0x4],0x62
mov DWORD PTR [rbp-0x8],0x16
```

```text
0x62 = 98
0x16 = 22
98 + 22 = 120
```

## Input 4: 1337
Derefter:
```asm
mov eax,[rbp-0xc]
add eax,0x4c1
```

```text
120 + 0x4c1
120 + 1217
= 1337
```

## Sidste string: GTFO
Assemblyen pegede på adressen `0x4020c4` i et `strcmp`-kald.

Vi brugte:
```bash
strings -t x ./game | grep -E '2010|204b|2053|2070|20c4|20c9'
```

Output:
```text
2010 Yay, here is a shell, go get the flag, y0u 1337 h4x0r!
204b /bin/sh
2053 Welcome to the second split
20c4 GTFO
20c9 Welcome to the end!
```

Så programmet sammenlignede brugerinput med `GTFO`.

## Shell
Success-pathen pegede på `0x40204b`, som `strings` viste var `/bin/sh`.

Programmet gjorde derfor i praksis:
```c
system("/bin/sh");
```

## Flag
Efter shell:
```bash
ls -la /root
cat /root/flag.txt
```

Flag:
```text
HKN{m44_m1kk3lH057_k0mm3_ud_0g_l363}
```

## Hele reverse-pathen
```text
42 -> 911 -> 96 -> 120 -> 1337 -> GTFO -> /bin/sh -> /root/flag.txt
```

---

# Cheatsheet

## Identificér fil
```bash
file FIL
```

## Strings
```bash
strings FIL
strings -t x FIL
```

## Assembly
```bash
objdump -d -M intel FIL
```

## Read-only data / strings
```bash
objdump -s -j .rodata FIL
```

## Hex til decimal
```bash
printf '%d\n' 0x38f
```

## Metadata
```bash
exiftool FIL
```

## Base64
```bash
echo 'DATA' | base64 -d
```

## Find filer
```bash
find . -type f
```

## Søg tekst rekursivt
```bash
grep -RniI 'tekst' .
```

## Disk forensics
```bash
fls -r -d -o PARTITION_START IMAGE
```

---

# Generel arbejdsmetode

Når en ny challenge starter:

1. Identificér filtypen med `file`.
2. Kig efter strings med `strings`.
3. Tjek metadata med `exiftool`.
4. Brug `grep` til at lede efter relevante spor.
5. Hvis det er en binary: `strings -t x` + `objdump -d -M intel`.
6. Hvis det er et billede: metadata, `binwalk`, `steghide`, evt. LSB/bitplanes.
7. Hvis det er en hash: identificér hash-type og brug John/Hashcat.
8. Hvis det er et diskimage: find partition offset, mount read-only, brug `fls`/`icat`.
9. Byg en tidslinje når der er browserhistorik, mails og logs.
10. Skriv ikke kun flaget ned: skriv hvorfor hvert spor førte til næste trin.
