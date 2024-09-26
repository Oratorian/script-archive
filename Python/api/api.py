#Needs more Tests and some code cleanup

from flask import Flask, jsonify, request, session, abort
from flask_httpauth import HTTPTokenAuth
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_session import Session
from apscheduler.schedulers.background import BackgroundScheduler
import importlib.util
import os
import traceback
import time

from utils import (load_encryption_key, load_api_keys, save_api_keys,
                   load_sudo_password, load_initial_api_key, is_master_key)
from ratelimit import load_usage_records, update_usage, check_limits, reset_hourly_limits, reset_monthly_limits
from conlimit import limiter as connection_limiter
from watcher import start_watching

app = Flask(__name__)
auth = HTTPTokenAuth(scheme='Bearer')
limiter = Limiter(app, key_func=get_remote_address, default_limits=[])

# Load encryption key and set as SECRET_KEY
encryption_key = load_encryption_key()
master_key = load_initial_api_key()
app.config['SECRET_KEY'] = encryption_key
app.config['SESSION_TYPE'] = 'filesystem'
Session(app)

load_usage_records()

active_sessions = {}

@auth.verify_token
def verify_token(token):
    api_keys = load_api_keys()
    if token == master_key:
        session['token'] = token
        return token
    elif token in api_keys:
        if token in active_sessions:
            return jsonify({"error": "Access Denied: Invalid or already active token"}), 403
        else:
            session['token'] = token
            active_sessions[token] = True
            return token
    return None


@app.before_request
@auth.login_required
def check_rate_limit():
    token = auth.current_user()

    if is_master_key(token):
        success, message = connection_limiter.acquire(token)
        if not success:
            return jsonify({"message": message}), 429
        return

    within_limits, hourly_count, monthly_count = check_limits(token, is_master_key=False)
    if not within_limits:
        if hourly_count >= 50:
            return jsonify({
                "error": "Rate limit exceeded",
                "hourly_count": hourly_count,
                "message": "Hourly rate limit exceeded. Please wait before making more requests."
            }), 429
        if monthly_count >= 1000:
            return jsonify({
                "error": "Rate limit exceeded",
                "monthly_count": monthly_count,
                "message": "Monthly rate limit exceeded. Please wait until the next month before making more requests."
            }), 429
    update_usage(token)
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

base_dir = os.path.dirname(os.path.abspath(__file__))
endpoints_folder = os.path.join(base_dir, 'endpoints')
observer = start_watching(app, endpoints_folder)

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

scheduler = BackgroundScheduler()
scheduler.add_job(reset_hourly_limits, 'cron', minute=0)
scheduler.add_job(reset_monthly_limits, 'cron', day=1, hour=0)
scheduler.start()

if __name__ == '__main__':
    try:
        app.run(host='0.0.0.0', port=8080, debug=True)
    except KeyboardInterrupt:
        observer.stop()
        scheduler.shutdown()
    observer.join()
