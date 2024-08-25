import os
import json
import bcrypt
from flask import Flask, request, jsonify, send_from_directory, redirect, url_for, session, render_template, abort
from flask_login import LoginManager, login_user, logout_user, current_user, login_required, UserMixin

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

AUTH_FILE = '/opt/wol/.htpasswd'
JSON_FILE = '/opt/wol/db/pcs.json'
STATIC_DIR = '/opt/wol'

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# Configure logging
import logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

class User(UserMixin):
    def __init__(self, id, username, password_hash):
        self.id = id
        self.username = username
        self.password_hash = password_hash

    @staticmethod
    def get(user_id):
        """Retrieve a user by ID."""
        with open(AUTH_FILE, 'r') as f:
            for line in f:
                logging.debug(f"Raw line read from file: {line.strip()}")

                try:
                    stored_username, stored_hash = line.strip().split(':', 1)
                    logging.debug(f"Parsed username: {stored_username}")
                    logging.debug(f"Parsed hash: {stored_hash}")

                    if stored_username == user_id:
                        logging.debug(f"User matched: {stored_username}")
                        return User(user_id, stored_username, stored_hash)
                except ValueError as e:
                    logging.error(f"Error processing line: {line.strip()}")
                    logging.error(f"Error details: {e}")
        return None

    @staticmethod
    def authenticate(username, password):
        """Authenticate a user based on username and password."""
        try:
            logging.debug(f"Authenticating user: {username}")
            with open(AUTH_FILE, 'r') as f:
                for line_number, line in enumerate(f, start=1):
                    logging.debug(f"Processing line {line_number}: {line.strip()}")

                    try:
                        stored_username, stored_hash = line.strip().split(':', 1)
                        logging.debug(f"Stored Username: {stored_username}")
                        logging.debug(f"Stored Hash: {stored_hash}")

                        if stored_username == username:
                            logging.debug(f"Attempting to verify password for user: {stored_username}")
                            if User.verify_bcrypt_password(stored_hash, password):
                                logging.debug(f"Password verification succeeded for user: {stored_username}")
                                return User(stored_username, stored_username, stored_hash)
                            else:
                                logging.debug(f"Password verification failed for user: {stored_username}")
                    except ValueError as ve:
                        logging.error(f"Error on line {line_number}: {line.strip()}")
                        logging.error(f"Error details: {ve}")
                        continue
        except Exception as e:
            logging.error(f"Exception in authenticate method: {e}")
        return None

    @staticmethod
    def verify_bcrypt_password(stored_password, provided_password):
        """Verify a password against a bcrypt hash."""
        try:
            logging.debug(f"Verifying stored password: {stored_password}")
            return bcrypt.checkpw(provided_password.encode('utf-8'), stored_password.encode('utf-8'))
        except ValueError as e:
            logging.error(f"Error during password verification: {e}")
            return False

    @staticmethod
    def create(username, password):
        """Create a new user and store it in the AUTH_FILE."""
        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
        
        logging.debug(f"Creating user: {username}")
        logging.debug(f"Storing hash: {password_hash}")

        with open(AUTH_FILE, 'a') as f:
            f.write(f"{username}:{password_hash}\n")
        return User(username, username, password_hash)

@login_manager.user_loader
def load_user(user_id):
    return User.get(user_id)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        logging.debug(f"Attempting to authenticate user: {username}")
        user = User.authenticate(username, password)
        if user:
            logging.debug(f"Authentication successful for user: {username}")
            login_user(user)
            return redirect(url_for('index'))
        else:
            logging.debug(f"Authentication failed for user: {username}")
            return render_template('login.html', error='Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/api/load', methods=['GET'])
@login_required
def load_pcs():
    try:
        with open(JSON_FILE, 'r') as file:
            pcs = json.load(file)
        return jsonify({'success': True, 'pcs_list': pcs})
    except Exception as e:
        logging.error(f"Error loading PCs: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/wake', methods=['GET'])
@login_required
def wake_pc():
    mac = request.args.get('mac')
    if mac:
        try:
            os.system(f'etherwake -i eno1 -b {mac}')
            return jsonify({'success': True, 'message': f'Wake-up signal sent to {mac}'})
        except Exception as e:
            logging.error(f"Error waking PC: {e}")
            return jsonify({'success': False, 'message': 'Failed to send WOL signal'}), 500
    else:
        return jsonify({'success': False, 'message': 'MAC address not provided'}), 400

@app.route('/api/delete', methods=['GET'])
@login_required
def delete_pc():
    mac = request.args.get('mac')
    if mac:
        try:
            with open(JSON_FILE, 'r') as file:
                pcs = json.load(file)
            pcs = [pc for pc in pcs if pc['mac'] != mac]
            with open(JSON_FILE, 'w') as file:
                json.dump(pcs, file)
            return jsonify({'success': True, 'message': f'Deleted PC with MAC {mac}', 'pcs_list': pcs})
        except Exception as e:
            logging.error(f"Error deleting PC: {e}")
            return jsonify({'success': False, 'message': 'Internal server error'}), 500
    else:
        return jsonify({'success': False, 'message': 'MAC address not provided'}), 400

@app.route('/api/add', methods=['POST'])
@login_required
def add_pc():
    try:
        # Log the raw request data for debugging purposes
        logging.debug(f"Raw request data: {request.data.decode('utf-8')}")

        # Attempt to parse the JSON
        post_data = request.get_json()
        if post_data is None:
            logging.error("No JSON data received or incorrect Content-Type")
            return jsonify({'success': False, 'message': 'No JSON data received or incorrect Content-Type'}), 400

        logging.debug(f"Parsed JSON data: {post_data}")

        # Extract parameters from parsed JSON
        mac = post_data.get('mac')
        ip = post_data.get('ip')
        hostname = post_data.get('hostname')

        logging.debug(f"MAC: {mac}, IP: {ip}, Hostname: {hostname}")

        # Check for missing parameters
        if not mac or not ip or not hostname:
            logging.error("Missing required parameters")
            return jsonify({'success': False, 'message': 'Missing required parameters'}), 400

        # Add new PC entry
        new_pc = {'mac': mac, 'ip': ip, 'hostname': hostname}
        with open(JSON_FILE, 'r') as file:
            pcs = json.load(file)

        pcs.append(new_pc)

        with open(JSON_FILE, 'w') as file:
            json.dump(pcs, file)

        logging.info("PC added successfully")
        return jsonify({'success': True, 'message': 'PC added successfully', 'pcs_list': pcs})

    except ValueError as e:
        logging.error(f"ValueError while adding PC: {e}")
        return jsonify({'success': False, 'message': str(e)}), 400
    except Exception as e:
        logging.error(f"Unexpected error while adding PC: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

from flask import request

@app.errorhandler(404)
def page_not_found(e):
    # Check if the request expects a JSON response (e.g., from AJAX)
    if request.accept_mimetypes.accept_json and not request.accept_mimetypes.accept_html:
        response = jsonify({'success': False, 'message': 'Resource not found'})
        response.status_code = 404
        return response
    else:
        # For regular requests, redirect to the login page
        return redirect(url_for('login'))


@app.route('/<path:filename>')
def serve_static(filename):
    """Serve static files from the STATIC_DIR."""
    return send_from_directory(STATIC_DIR, filename)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8889, debug=True)