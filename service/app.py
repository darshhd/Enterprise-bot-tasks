import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

APP_NAME = os.environ.get("APP_NAME", "unknown")
VERSION = os.environ.get("VERSION", "1.0.0")


@app.route("/")
def root():
    return jsonify({
        "app": APP_NAME,
        "version": VERSION,
        "pod": socket.gethostname(),
    })


@app.route("/healthz")
def healthz():
    return "", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)