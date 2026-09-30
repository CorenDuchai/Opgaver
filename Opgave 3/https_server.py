import socket
import ssl

HOST = "127.0.0.1"
PORT = 8443

CERT_FILE = "cert.pem"
KEY_FILE = "key.pem"


def build_response(status_code, reason, body):
    body_bytes = body.encode("utf-8")

    headers = [
        f"HTTP/1.1 {status_code} {reason}",
        "Content-Type: text/plain; charset=utf-8",
        f"Content-Length: {len(body_bytes)}",
        "Connection: close",
        "",
        ""
    ]

    return "\r\n".join(headers).encode("ascii") + body_bytes


# TLS-context for en server.
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)

# Certifikatet identificerer serveren.
# Den private nøgle bruges under TLS-handshaket.
context.load_cert_chain(
    certfile=CERT_FILE,
    keyfile=KEY_FILE
)


with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:

    # Stadig kun loopback.
    server.bind((HOST, PORT))
    server.listen(5)

    print(f"HTTPS server listening on https://netlab.test:{PORT}")

    while True:
        tcp_conn, addr = server.accept()

        try:
            # TCP-forbindelsen bliver wrapped i TLS.
            with context.wrap_socket(
                tcp_conn,
                server_side=True
            ) as tls_conn:

                print(f"\nTLS connection from {addr}")
                print(f"TLS version : {tls_conn.version()}")
                print(f"Cipher      : {tls_conn.cipher()}")

                # HTTP ligger nu INDEN I den krypterede TLS-forbindelse.
                raw_request = tls_conn.recv(4096)

                print("Decrypted HTTP request:")
                print(raw_request.decode("iso-8859-1"))

                response = build_response(
                    200,
                    "OK",
                    "Hello from my TLS protected HTTP server!\n"
                )

                tls_conn.sendall(response)

        except ssl.SSLError as error:
            print(f"TLS error: {error}")
            tcp_conn.close()
