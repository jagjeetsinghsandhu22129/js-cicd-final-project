from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def home():
    return app.send_static_file('index.html')

@app.route('/api/data')
def get_data():
    return jsonify({
        'message': 'This is the backend API response',
        'status': 'success'
    })

if __name__ == '__main__':
    app.run(debug=True)
