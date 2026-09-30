import socket

# Serveren bindes kun til loopback, så tjenesten ikke eksponeres
# på VM'ens øvrige netværksinterfaces.
HOST = "127.0.0.1"
PORT = 5000

# AF_INET = IPv4
# SOCK_STREAM = TCP
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    # Knyt socketen til den lokale adresse og port.
    server.bind((HOST, PORT))

    # Sæt socketen i listening state.
    # 1 betyder, at én forbindelse kan vente i kø.
    server.listen(1)

    print(f"Listening on {HOST}:{PORT}")

    # accept() blokerer, indtil en TCP-klient forbinder.
    # conn er den etablerede forbindelse, addr er klientens adresse/port.
    conn, addr = server.accept()

    with conn:
        print(f"Connection from {addr}")

        # Modtag op til 1024 bytes fra klienten.
        data = conn.recv(1024)
        print(f"Received bytes: {data!r}")

        # TCP sender bytes, så beskeden angives som et bytes-literal med b"".
        response = b"Hello from TCP server"
        conn.sendall(response)

        print(f"Sent bytes: {response!r}")
