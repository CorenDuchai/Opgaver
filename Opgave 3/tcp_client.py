import socket

HOST = "127.0.0.1"
PORT = 5000

# AF_INET = IPv4
# SOCK_STREAM = TCP
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
    # connect() starter TCP-forbindelsen til serveren.
    # Her kan SYN, SYN-ACK og ACK ses i packet capture.
    client.connect((HOST, PORT))

    # Data sendes som rå bytes over den etablerede TCP-forbindelse.
    message = b"Hello from TCP client"
    client.sendall(message)

    print(f"Sent bytes: {message!r}")

    # Vent på og modtag op til 1024 bytes fra serveren.
    response = client.recv(1024)
    print(f"Received bytes: {response!r}")
