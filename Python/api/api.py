from flask import Flask, jsonify, request, session
from flask_httpauth import HTTPTokenAuth
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_session import Session
from apscheduler.schedulers.background import BackgroundScheduler
import importlib.util
import os
import traceback
import time

from utils import (load_encryption_key, api_keys, save_api_keys, initial_api_key, 
                   load_sudo_password, sudo_password, cipher, is_master_key)
from ratelimit import load_usage_records, update_usage, check_limits, reset_hourly_limits, reset_monthly_limits
from conlimit import limiter as connection_limiter
from watcher import start_watching

app = Flask(__name__)
auth = HTTPTokenAuth(scheme='Bearer')
limiter = Limiter(app, key_func=get_remote_address, default_limits=[])

# Load encryption key and set as SECRET_KEY
encryption_key = load_encryption_key()
app.config['SECRET_KEY'] = encryption_key
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)

load_usage_records()

active_sessions = {}

@auth.verify_token
def verify_token(token):
    if token in api_keys:
        # Check for existing session
        if token in active_sessions:
            return None
        else:
            session['token'] = token
            active_sessions[token] = True
            return token
    return None

@app.before_request
@auth.login_required
def check_rate_limit():
    token = auth.current_user()
    if not check_limits(token, is_master_key(token)):
        return jsonify({"message": "Rate limit exceeded"}), 429
    update_usage(token)

    # Check for connection limits
    success, message = connection_limiter.acquire(token)
    if not success:
        return jsonify({"message": message}), 429

@app.after_request
def after_request(response):
    token = session.get('token')
    if token:
        connection_limiter.release(token)
        active_sessions.pop(token, None)
    return response

@app.teardown_request
def teardown_request(exception):
    token = session.get('token')
    if token:
        connection_limiter.release(token)
        active_sessions.pop(token, None)

# Start watching the endpoints folder for changes
base_dir = os.path.dirname(os.path.abspath(__file__))
endpoints_folder = os.path.join(base_dir, 'endpoints')
observer = start_watching(app, endpoints_folder)

# Load existing modules in the endpoints folder
for filename in os.listdir(endpoints_folder):
    if filename.endswith('.py') and filename != '__init__.py':
        module_name = filename[:-3]
        module_path = os.path.join(endpoints_folder, filename)
        try:
            spec = importlib.util.spec_from_file_location(module_name, module_path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            app.register_blueprint(module.bp)
            print(f"Successfully imported module {module_name}")
        except Exception as e:
            print(f"Error importing {module_name} from {module_path}: {e}")

# Schedule the rate limit resets
scheduler = BackgroundScheduler()
scheduler.add_job(reset_hourly_limits, 'cron', minute=0)  # Reset hourly limits at the start of every hour
scheduler.add_job(reset_monthly_limits, 'cron', day=1, hour=0)  # Reset monthly limits at the start of every month
scheduler.start()

if __name__ == '__main__':
    try:
        app.run(host='0.0.0.0', port=8080, debug=True)
    except KeyboardInterrupt:
        observer.stop()
        scheduler.shutdown()
    observer.join()