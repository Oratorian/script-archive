from flask import Blueprint, jsonify, request
from utils import api_keys, initial_api_key

bp = Blueprint('view_keys', __name__)

@bp.route('/api/view_keys', methods=['GET'])
def view_keys():
    if request.headers.get('Authorization') != f'Bearer {initial_api_key}':
        return jsonify({"message": "Unauthorized"}), 403
    filtered_keys = [key for key in api_keys.keys() if key != initial_api_key]
    return jsonify({"api_keys": filtered_keys}), 200