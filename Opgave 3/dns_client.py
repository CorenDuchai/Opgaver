import socket
import struct

DNS_SERVER = "127.0.0.53"
DNS_PORT = 53
DOMAIN = "google.com"

# Fast transaction ID så den er nem at genkende i Wireshark
transaction_id = 0x1234

# DNS header:
# ID, flags, questions, answers, authority, additional
header = struct.pack(
    "!HHHHHH",
    transaction_id,
    0x0100,   # Standard query + recursion desired
    1,        # Questions
    0,        # Answers
    0,        # Authority
    0         # Additional
)

# google.com -> 6 bytes "google", 3 bytes "com", 0 terminator
qname = b""

for label in DOMAIN.split("."):
    encoded = label.encode("ascii")
    qname += bytes([len(encoded)]) + encoded

qname += b"\x00"

# QTYPE 1 = A
# QCLASS 1 = IN (Internet)
question = qname + struct.pack("!HH", 1, 1)

packet = header + question

print(f"DNS query bytes: {packet.hex()}")
print(f"Sending query for {DOMAIN} to {DNS_SERVER}:{DNS_PORT}")

with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
    sock.settimeout(5)
    sock.sendto(packet, (DNS_SERVER, DNS_PORT))
    response, addr = sock.recvfrom(4096)

print(f"Received {len(response)} bytes from {addr}")
print(f"Response bytes: {response.hex()}")

# Parse DNS header
(
    response_id,
    flags,
    qdcount,
    ancount,
    nscount,
    arcount
) = struct.unpack("!HHHHHH", response[:12])

print()
print("DNS header:")
print(f"Transaction ID : 0x{response_id:04x}")
print(f"Flags          : 0x{flags:04x}")
print(f"Questions      : {qdcount}")
print(f"Answers        : {ancount}")
print(f"Authority      : {nscount}")
print(f"Additional     : {arcount}")


def read_name(data, offset):
    labels = []
    jumped = False
    original_offset = offset

    while True:
        length = data[offset]

        # DNS compression pointer
        if length & 0xC0 == 0xC0:
            pointer = ((length & 0x3F) << 8) | data[offset + 1]

            if not jumped:
                original_offset = offset + 2

            offset = pointer
            jumped = True
            continue

        if length == 0:
            offset += 1
            break

        offset += 1
        labels.append(data[offset:offset + length].decode("ascii"))
        offset += length

    if jumped:
        return ".".join(labels), original_offset

    return ".".join(labels), offset


offset = 12

# Skip questions
for _ in range(qdcount):
    name, offset = read_name(response, offset)
    qtype, qclass = struct.unpack("!HH", response[offset:offset + 4])
    offset += 4

    print()
    print(f"Question: {name}")
    print(f"QTYPE   : {qtype}")
    print(f"QCLASS  : {qclass}")

print()
print("Answers:")

for _ in range(ancount):
    name, offset = read_name(response, offset)

    rtype, rclass, ttl, rdlength = struct.unpack(
        "!HHIH",
        response[offset:offset + 10]
    )

    offset += 10
    rdata = response[offset:offset + rdlength]
    offset += rdlength

    if rtype == 1 and rdlength == 4:
        ip = socket.inet_ntoa(rdata)
        print(f"{name} -> {ip} (TTL {ttl})")
    else:
        print(
            f"{name} -> type {rtype}, "
            f"{rdlength} bytes of data"
        )
