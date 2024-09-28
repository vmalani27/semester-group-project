import flask

app = flask.Flask(__name__)


@app.route("/")
def hello():
    return "Hello World"


if __name__ == "__main__":  # There is an error on this line
    app.run(debug=True, host='0.0.0.0')
    print("test")