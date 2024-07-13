from flask import Blueprint, jsonify, request
from flask_httpauth import HTTPTokenAuth
from utils import api_keys, save_api_keys, initial_api_key

bp = Blueprint('delete_key', __name__)

@bp.route('/api/delete_key/<api_key>', methods=['DELETE'])
def delete_key(api_key):
    if request.headers.get('Authorization') != f'Bearer {initial_api_key}':
        return jsonify({"message": "Unauthorized"}), 403
    if api_key in api_keys:
        del api_keys[api_key]
        save_api_keys(api_key)
        return jsonify({"message": f"API key {api_key} deleted"}), 200
    else:
        return jsonify({"message": "API key not found"}), 404