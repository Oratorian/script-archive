import os
import json
import bcrypt
from flask import Flask, request, jsonify, send_from_directory, redirect, url_for, session, render_template, abort
from flask_login import LoginManager, login_user, logout_user, current_user, login_required, UserMixin
import logging
import subprocess
import glob

import user

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

DB_DIR = '/opt/wol/db/'  # Directory where JSON files are stored
USERS_FILE = os.path.join(DB_DIR, 'users.json')  # Path to users.json
PC_DATA_DIR = os.path.join(DB_DIR, 'pcs')  # Directory where user-specific JSON files will be stored
STATIC_DIR = '/opt/wol'

if not os.path.exists(PC_DATA_DIR):
    os.makedirs(PC_DATA_DIR)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = "login"

# Configure logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

@login_manager.user_loader
def load_user(user_id):
    return user.User.get(user_id)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        # Try to get JSON data
        if request.is_json:
            data = request.get_json()
            username = data.get('username')
            password = data.get('password')
        else:
            # Fall back to form data
            username = request.form.get('username')
            password = request.form.get('password')

        logging.debug(f"Attempting to authenticate user: {username}")

        users = user.User.authenticate(username, password)
        if user:
            logging.debug(f"Authentication successful for user: {username}")
            login_user(users)
            if request.is_json:
                return jsonify({"message": "Login successful"}), 200
            return redirect(url_for('index'))
        else:
            logging.debug(f"Authentication failed for user: {username}")
            if request.is_json:
                return jsonify({"message": "Invalid credentials"}), 401
            return render_template('login.html', error='Invalid credentials')

    return render_template('login.html')


@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    return render_template('index.html', user_permission=current_user.permission)

@app.route('/api/load', methods=['GET'])
@login_required
def load_pcs():
    user_pc_file = user.User.get_user_pc_file(current_user.username)
    logging.debug(f"loading PCs for user {current_user.username} from {user_pc_file}")
    try:
        if os.path.exists(user_pc_file):
            with open(user_pc_file, 'r') as file:
                pcs = json.load(file)
            return jsonify({'success': True, 'pcs_list': pcs})
        else:
            return jsonify({'success': True, 'pcs_list': []})  # Return an empty list if no file exists
    except Exception as e:
        logging.error(f"Error loading PCs for user {current_user.username}: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/add', methods=['POST'])
@login_required
def add_pc():
    user_pc_file = user.User.get_user_pc_file(current_user.username)
    try:
        post_data = request.get_json()
        if post_data is None:
            return jsonify({'success': False, 'message': 'No JSON data received or incorrect Content-Type'}), 400

        mac = post_data.get('mac')
        ip = post_data.get('ip')
        hostname = post_data.get('hostname')

        if not mac or not ip or not hostname:
            return jsonify({'success': False, 'message': 'Missing required parameters'}), 400

        new_pc = {'mac': mac, 'ip': ip, 'hostname': hostname}

        pcs = []
        if os.path.exists(user_pc_file):
            with open(user_pc_file, 'r') as file:
                pcs = json.load(file)

        pcs.append(new_pc)

        with open(user_pc_file, 'w') as file:
            json.dump(pcs, file, indent=4)

        return jsonify({'success': True, 'message': 'PC added successfully', 'pcs_list': pcs})

    except ValueError as e:
        logging.error(f"ValueError while adding PC for user {current_user.username}: {e}")
        return jsonify({'success': False, 'message': str(e)}), 400
    except Exception as e:
        logging.error(f"Unexpected error while adding PC for user {current_user.username}: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/delete', methods=['GET'])
@login_required
def delete_pc():
    mac = request.args.get('mac')
    if mac:
        try:
            # Get the path to the user's PC JSON file
            user_json_file = user.User.get_user_pc_file(current_user.username)

            # Load the PCs from the file
            with open(user_json_file, 'r') as file:
                pcs = json.load(file)

            # Filter out the PC with the matching MAC address
            pcs_before = len(pcs)
            pcs = [pc for pc in pcs if pc['mac'] != mac]
            pcs_after = len(pcs)

            # If the length hasn't changed, the MAC wasn't found
            if pcs_before == pcs_after:
                return jsonify({'success': False, 'message': f'MAC address {mac} not found'}), 404

            # Save the updated list back to the file
            with open(user_json_file, 'w') as file:
                json.dump(pcs, file, indent=4)

            return jsonify({'success': True, 'message': f'Deleted PC with MAC {mac}', 'pcs_list': pcs})
        except Exception as e:
            logging.error(f"Error deleting PC: {e}")
            return jsonify({'success': False, 'message': 'Internal server error'}), 500
    else:
        return jsonify({'success': False, 'message': 'MAC address not provided'}), 400


@app.route('/api/shutdown', methods=['POST'])
@login_required
def shutdown_pc():
    try:
        data = request.get_json()
        pc_ip = data.get('pc_ip')
        if not pc_ip:
            return jsonify({'success': False, 'message': 'PC IP address is required'}), 400

        username = data.get('username')
        password = data.get('password')  # You might want to hash this and verify it instead of sending it directly

        command = f"echo '{username}|{password}|shutdown' | nc {pc_ip} 8080"
        logging.debug(f"Executing command: {command}")

        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            return jsonify({'success': True, 'message': 'Shutdown command sent successfully'}), 200
        else:
            logging.error(f"Command failed: {result.stderr}")
            return jsonify({'success': False, 'message': 'Failed to send shutdown command'}), 500

    except Exception as e:
        logging.error(f"Exception in shutdown_pc: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/create_user', methods=['POST'])
@login_required
def create_user():
    logging.info('Create user route accessed')
    if current_user.permission != 'admin':
        logging.error('Unauthorized access attempt by user: %s', current_user.username)
        return jsonify({"error": "Unauthorized"}), 403

    data = request.get_json()
    logging.info('Received data: %s', data)
    username = data.get('username')
    password = data.get('password')
    permission = data.get('permission')
    try:
        user.User.create(username, password, permission)
        logging.info('User %s created successfully', username)
        return jsonify({'success': True, 'message': 'User added successfully'}), 200
    except Exception as e:
        logging.error('Error creating user: %s', str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/api/users', methods=['GET'])
@login_required
def get_users():
    try:
        users_file = os.path.join(DB_DIR, 'users.json')
        if os.path.exists(users_file):
            with open(users_file, 'r') as f:
                users = json.load(f)
            return jsonify({'success': True, 'users': users})
        else:
            return jsonify({'success': False, 'message': 'Users file not found.'}), 404
    except Exception as e:
        logging.error(f"Error retrieving users: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/change_permission', methods=['POST'])
@login_required
def change_permission():
    if current_user.permission != 'admin':
        return jsonify({'success': False, 'message': 'Unauthorized access'}), 403
    try:
        data = request.get_json()
        username = data['username']  # Correctly access the dictionary
        new_permission = data['permission']

        users_file = os.path.join(DB_DIR, 'users.json')
        if os.path.exists(users_file):
            with open(users_file, 'r') as f:
                users = json.load(f)  # Users is a dictionary, as confirmed by your debug log

            if username in users:
                users[username]['permission'] = new_permission
            else:
                return jsonify({'success': False, 'message': 'User not found'}), 404

            with open(users_file, 'w') as f:
                json.dump(users, f)

            return jsonify({'success': True, 'message': 'Permission updated successfully'})

        else:
            return jsonify({'success': False, 'message': 'Users file not found.'}), 404
    except Exception as e:
        logging.error(f"Error changing permission: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/api/delete_user', methods=['POST'])
@login_required
def delete_user():
    if current_user.permission != 'admin':
        return jsonify({'success': False, 'message': 'Unauthorized access'}), 403

    try:
        data = request.get_json()
        username = data.get('username')

        users_file = os.path.join(DB_DIR, 'users.json')
        if os.path.exists(users_file):
            with open(users_file, 'r') as f:
                users = json.load(f)  # Users is a dictionary

            if username in users:
                del users[username]  # Remove the user from the dictionary
            else:
                return jsonify({'success': False, 'message': 'User not found'}), 404

            # Save the updated users dictionary back to the file
            with open(users_file, 'w') as f:
                json.dump(users, f)

            # Delete all files related to the user in the PC_DATA_DIR
            user_pc_files_pattern = os.path.join(PC_DATA_DIR, f'{username}_pcs.json')
            for file_path in glob.glob(user_pc_files_pattern):
                os.remove(file_path)

            return jsonify({'success': True, 'message': 'User and associated PC files deleted successfully'})

        else:
            return jsonify({'success': False, 'message': 'Users file not found.'}), 404
    except Exception as e:
        logging.error(f"Error deleting user: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500


@app.route('/api/change_password', methods=['POST'])
@login_required
def change_password():
    if current_user.permission != 'admin':
        return jsonify({'success': False, 'message': 'Unauthorized access'}), 403

    try:
        salt = bcrypt.gensalt()
        data = request.get_json()
        username = data.get('username')
        new_password = data.get('password')

        users_file = os.path.join(DB_DIR, 'users.json')
        if os.path.exists(users_file):
            with open(users_file, 'r') as f:
                users = json.load(f)

            if username in users:
                users[username]['password_hash'] = bcrypt.hashpw(new_password.encode('utf-8'), salt).decode('utf-8')
            else:
                return jsonify({'success': False, 'message': 'User not found'}), 404

            with open(users_file, 'w') as f:
                json.dump(users, f)

            return jsonify({'success': True, 'message': 'Password updated successfully'})

        else:
            return jsonify({'success': False, 'message': 'Users file not found.'}), 404
    except Exception as e:
        logging.error(f"Error changing password: {e}")
        return jsonify({'success': False, 'message': 'Internal server error'}), 500

@app.route('/<path:filename>')
def serve_static(filename):
    """Serve static files from the STATIC_DIR."""
    return send_from_directory(STATIC_DIR, filename)

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

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=8889, debug=True)