from flask import Blueprint, jsonify, request
import subprocess
from utils import initial_api_key, cipher

bp = Blueprint('service_restart', __name__)

@bp.route('/api/service/restart/<servicename>', methods=['POST'])
def restart_service(servicename):
    if request.headers.get('Authorization') != f'Bearer {initial_api_key}':
        return jsonify({"message": "Unauthorized"}), 403

    encrypted_password = request.headers.get('Password')
    if not encrypted_password:
        return jsonify({"message": "Password header is missing"}), 400

    try:
        password = cipher.decrypt(encrypted_password.encode()).decode()
        command = f"echo {password} | sudo -S systemctl restart {servicename}"
        result = subprocess.run(command, shell=True, capture_output=True, text=True)

        if result.returncode == 0:
            return jsonify({"message": f"Service {servicename} restarted successfully", "output": result.stdout}), 200
        else:
            return jsonify({"message": f"Failed to restart service {servicename}", "error": result.stderr}), 500
    except Exception as e:
        return jsonify({"message": f"An error occurred while restarting service {servicename}", "error": str(e)}), 500