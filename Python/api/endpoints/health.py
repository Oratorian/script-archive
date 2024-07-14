from flask import Blueprint, jsonify
import psutil
import os
from utils import bytes_to_human_readable

bp = Blueprint('health', __name__)

@bp.route('/api/health', methods=['GET'])
def health():
    load1, load5, load15 = os.getloadavg()
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    health_info = {
        "load_average": {
            "1m": load1,
            "5m": load5,
            "15m": load15
        },
        "memory": {
            "total": bytes_to_human_readable(memory.total),
            "available": bytes_to_human_readable(memory.available),
            "used": bytes_to_human_readable(memory.used),
            "percent": memory.percent
        },
        "disk": {
            "total": bytes_to_human_readable(disk.total),
            "used": bytes_to_human_readable(disk.used),
            "free": bytes_to_human_readable(disk.free),
            "percent": disk.percent
        }
    }
    return jsonify(health_info), 200