from flask import Flask, render_template, request


def create_app() -> Flask:
    app = Flask(__name__)

    @app.route("/", methods=["GET", "POST"])
    def landing():
        if request.method == "POST":
            submitted = {
                "full_name": request.form.get("full_name", "").strip(),
                "email": request.form.get("email", "").strip(),
                "password": request.form.get("password", ""),
                "notes": request.form.get("notes", "").strip(),
            }
            return render_template("result.html", submission=submitted)
        return render_template("index.html")

    @app.route("/healthz")
    def healthcheck():
        return {"status": "ok"}

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True)
