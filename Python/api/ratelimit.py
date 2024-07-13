import os
import json

usage_file = 'usage_records.json'
usage_records = {}

def load_usage_records():
    global usage_records
    if os.path.exists(usage_file):
        with open(usage_file, 'r') as f:
            usage_records = json.load(f)
    else:
        usage_records = {}

def save_usage_records():
    global usage_records
    with open(usage_file, 'w') as f:
        json.dump(usage_records, f, indent=4)

def update_usage(key):
    if key not in usage_records:
        usage_records[key] = {"hourly": 0, "monthly": 0}
    usage_records[key]["hourly"] += 1
    usage_records[key]["monthly"] += 1
    save_usage_records()

def check_limits(key, is_master_key):
    if is_master_key:
        return True, 0, 0
    load_usage_records()
    hourly_count = usage_records.get(key, {}).get("hourly", 0)
    monthly_count = usage_records.get(key, {}).get("monthly", 0)
    within_limits = hourly_count < 50 and monthly_count < 1000
    return within_limits, hourly_count, monthly_count

def reset_hourly_limits():
    global usage_records
    load_usage_records()
    for key in usage_records:
        usage_records[key]["hourly"] = 0
    save_usage_records()
    print("Hourly limits reset.")

def reset_monthly_limits():
    global usage_records
    load_usage_records()
    for key in usage_records:
        usage_records[key]["monthly"] = 0
    save_usage_records()
    print("Monthly limits reset.")


def schedule_resets():
    pass

if __name__ == '__main__':
    schedule_resets()