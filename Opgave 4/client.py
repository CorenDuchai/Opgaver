import socket

HOST = "127.0.0.1"
PORT = 8000

request = (
    "GET /index.html HTTP/1.1\r\n"
    f"Host: {HOST}:{PORT}\r\n"
    "Connection: close\r\n"
    "\r\n"
)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as client:
    client.connect((HOST, PORT))
    client.sendall(request.encode("ascii"))

    while True:
        data = client.recv(4096)
        if not data:
            break
        print(data.decode("utf-8"), end="")
