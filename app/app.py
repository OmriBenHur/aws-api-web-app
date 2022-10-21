from flask import *
from mongo_helper import *
from base64 import b64encode

app = Flask(__name__)


@app.route('/')
def index():
    return render_template('homepage.html')


@app.route('/search', methods=['POST', 'GET'])
def search():
    if request.method == 'POST':
        user_inp = request.form['name']

        try:
            Mo_file = mdb.image_cached(user_inp)
            image = b64encode(Mo_file).decode('utf-8')
            url = 'data:image/gif;base64,' + image
            return f'<img src={url} alt={user_inp} width="400" height="500">'
        except Exception as e:
            return render_template('fail.html')
    return render_template('search.html')


if __name__ == "__main__":
    app.run(port=80, host="0.0.0.0")
