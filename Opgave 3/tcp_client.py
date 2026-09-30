import socket

HOST = "127.0.0.1"
PORT = 5000

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
    client.connect((HOST, PORT))

    message = b"Hello from TCP client"
    client.sendall(message)

    print(f"Sent bytes: {message!r}")

    response = client.recv(1024)
    print(f"Received bytes: {response!r}")
