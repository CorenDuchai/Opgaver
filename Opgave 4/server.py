import socket

HOST = "127.0.0.1"
PORT = 8000

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen()

    print(f"HTTP-server lytter på {HOST}:{PORT}")

    while True:
        connection, address = server.accept()

        with connection:
            request = connection.recv(4096).decode("utf-8")
            print(f"\nRequest fra {address}:")
            print(request)

            if request.startswith("GET /index.html "):
                with open("index.html", "rb") as file:
                    body = file.read()

                status = "200 OK"
            else:
                body = b"404 Not Found"
                status = "404 Not Found"

            headers = (
                f"HTTP/1.1 {status}\r\n"
                "Content-Type: text/html; charset=utf-8\r\n"
                f"Content-Length: {len(body)}\r\n"
                "Connection: close\r\n"
                "\r\n"
            )

            connection.sendall(headers.encode("ascii") + body)
