from flask import Flask, jsonify


def create_app():
    app = Flask(__name__)

    @app.get("/")
    def index():
        return jsonify(message="Application is running"), 200

    @app.get("/health")
    def health():
        return jsonify(status="healthy"), 200

    return app


app = create_app()