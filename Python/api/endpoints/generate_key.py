from flask import Blueprint, jsonify, request
from utils import initial_api_key, generate_api_key, api_keys

bp = Blueprint('generate_key', __name__)

@bp.route('/api/generate_key', methods=['POST'])
def generate_key():
    if request.headers.get('Authorization') != f'Bearer {initial_api_key}':
        return jsonify({"message": "Unauthorized"}), 403
    new_key = generate_api_key(api_keys)
    return jsonify({"api_key": new_key}), 201