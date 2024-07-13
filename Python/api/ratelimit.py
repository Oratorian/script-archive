import os
import json
from datetime import datetime, timedelta

usage_file = 'usage_records.json'
usage_records = {}

def load_usage_records():
    global usage_records
    if os.path.exists(usage_file):
        with open(usage_file, 'r') as f:
            usage_records = json.load(f)
            # Convert string timestamps to datetime objects
            for key, usage in usage_records.items():
                usage['hourly'] = [datetime.fromisoformat(ts) if isinstance(ts, str) else ts for ts in usage['hourly']]
                usage['monthly'] = [datetime.fromisoformat(ts) if isinstance(ts, str) else ts for ts in usage['monthly']]
    else:
        usage_records = {}

def save_usage_records():
    global usage_records
    # Convert datetime objects to strings before saving
    for key, usage in usage_records.items():
        usage['hourly'] = [ts.isoformat() for ts in usage['hourly']]
        usage['monthly'] = [ts.isoformat() for ts in usage['monthly']]
    with open(usage_file, 'w') as f:
        json.dump(usage_records, f)

def update_usage(key):
    now = datetime.now()
    if key not in usage_records:
        usage_records[key] = {"hourly": [], "monthly": []}
    # Ensure all timestamps are datetime objects before comparison
    usage_records[key]["hourly"] = [datetime.fromisoformat(time) if isinstance(time, str) else time for time in usage_records[key]["hourly"]]
    usage_records[key]["monthly"] = [datetime.fromisoformat(time) if isinstance(time, str) else time for time in usage_records[key]["monthly"]]
    # Remove timestamps older than an hour
    usage_records[key]["hourly"] = [time for time in usage_records[key]["hourly"] if time > now - timedelta(hours=1)]
    # Remove timestamps older than a month
    usage_records[key]["monthly"] = [time for time in usage_records[key]["monthly"] if time > now - timedelta(days=30)]
    # Add the current timestamp
    usage_records[key]["hourly"].append(now)
    usage_records[key]["monthly"].append(now)
    save_usage_records()

def check_limits(key, is_master_key):
    if is_master_key:
        return True  # Always allow if it's the master key
    load_usage_records()
    now = datetime.now()
    # Ensure all timestamps are datetime objects before comparison
    hourly_times = [datetime.fromisoformat(time) if isinstance(time, str) else time for time in usage_records.get(key, {}).get("hourly", [])]
    monthly_times = [datetime.fromisoformat(time) if isinstance(time, str) else time for time in usage_records.get(key, {}).get("monthly", [])]
    # Count the number of requests in the last hour and the last month
    hourly_count = len([time for time in hourly_times if time > now - timedelta(hours=1)])
    monthly_count = len([time for time in monthly_times if time > now - timedelta(days=30)])
    return hourly_count < 50 and monthly_count < 1000

def reset_hourly_limits():
    global usage_records
    now = datetime.now()
    for key in usage_records:
        usage_records[key]["hourly"] = [time for time in usage_records[key]["hourly"] if time > now - timedelta(hours=1)]
    save_usage_records()
    print("Hourly limits reset.")

def reset_monthly_limits():
    global usage_records
    now = datetime.now()
    for key in usage_records:
        usage_records[key]["monthly"] = [time for time in usage_records[key]["monthly"] if time > now - timedelta(days=30)]
    save_usage_records()
    print("Monthly limits reset.")