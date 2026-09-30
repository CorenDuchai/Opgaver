import socket

HOST = "127.0.0.1"
PORT = 5000

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.bind((HOST, PORT))
    server.listen(1)

    print(f"Listening on {HOST}:{PORT}")

    conn, addr = server.accept()

    with conn:
        print(f"Connection from {addr}")

        data = conn.recv(1024)
        print(f"Received bytes: {data!r}")

        response = b"Hello from TCP server"
        conn.sendall(response)

        print(f"Sent bytes: {response!r}")
