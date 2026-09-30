import socket

HOST = "127.0.0.1"
PORT = 8080


def build_response(status_code, reason, body, content_type="text/plain; charset=utf-8"):
    """
    Bygger et HTTP-response manuelt.

    HTTP består her af:
      status line
      headers
      blank linje
      body
    """

    # HTTP-body skal ende som bytes.
    body_bytes = body.encode("utf-8")

    # Content-Length skal være antal BYTES, ikke antal tegn.
    headers = [
        f"HTTP/1.1 {status_code} {reason}",
        f"Content-Type: {content_type}",
        f"Content-Length: {len(body_bytes)}",
        "Connection: close",
        "",
        ""
    ]

    header_bytes = "\r\n".join(headers).encode("ascii")

    return header_bytes + body_bytes


with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:

    # Kun loopback: tjenesten eksponeres ikke på andre interfaces.
    server.bind((HOST, PORT))

    server.listen(5)

    print(f"HTTP server listening on http://{HOST}:{PORT}")
    print(f"Also available as http://netlab.test:{PORT}")

    while True:
        conn, addr = server.accept()

        with conn:
            print(f"\nConnection from {addr}")

            # Modtag rå HTTP-data som bytes.
            raw_request = conn.recv(4096)

            print("Raw request bytes:")
            print(repr(raw_request))

            try:
                # HTTP headers er tekst, så decode bytes.
                request_text = raw_request.decode("iso-8859-1")

                # Headers er adskilt med CRLF.
                lines = request_text.split("\r\n")

                # Første linje er fx:
                # GET / HTTP/1.1
                request_line = lines[0]

                method, path, version = request_line.split(" ")

                print(f"Method : {method}")
                print(f"Path   : {path}")
                print(f"Version: {version}")

                # Parse headers.
                headers = {}

                for line in lines[1:]:
                    if not line:
                        break

                    if ":" in line:
                        name, value = line.split(":", 1)
                        headers[name.strip()] = value.strip()

                print("Headers:")

                for name, value in headers.items():
                    print(f"  {name}: {value}")

                # Vi accepterer kun GET i dette lille lab.
                if method != "GET":
                    response = build_response(
                        405,
                        "Method Not Allowed",
                        "Only GET is supported\n"
                    )

                elif path == "/":
                    response = build_response(
                        200,
                        "OK",
                        "Hello from my raw Python HTTP server!\n"
                    )

                elif path == "/health":
                    response = build_response(
                        200,
                        "OK",
                        "OK\n"
                    )

                else:
                    response = build_response(
                        404,
                        "Not Found",
                        "404 - Resource not found\n"
                    )

            except Exception as error:
                print(f"Bad request: {error}")

                response = build_response(
                    400,
                    "Bad Request",
                    "400 - Bad Request\n"
                )

            # Send vores manuelt byggede HTTP-response som bytes.
            conn.sendall(response)

            print("Response sent.")
