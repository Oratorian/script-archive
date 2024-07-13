import os
import json
from cryptography.fernet import Fernet
import secrets
import config

def load_encryption_key():
    with open(config.key_file, 'rb') as f:
        encryption_key = f.read()
    return encryption_key

encryption_key = load_encryption_key()
cipher = Fernet(encryption_key)

def load_sudo_password():
    with open(config.sudo_password_file, 'rb') as f:
        encrypted_sudo_password = f.read()
    return cipher.decrypt(encrypted_sudo_password).decode()

sudo_password = load_sudo_password()

def encrypt_json(data):
    json_data = json.dumps(data).encode()
    encrypted_data = cipher.encrypt(json_data)
    return encrypted_data

def decrypt_json(encrypted_data):
    decrypted_data = cipher.decrypt(encrypted_data)
    data = json.loads(decrypted_data.decode())
    return data

def encrypt_string(data):
    encrypted_data = cipher.encrypt(data.encode())
    return encrypted_data

def decrypt_string(encrypted_data):
    decrypted_data = cipher.decrypt(encrypted_data)
    return decrypted_data.decode()

def load_api_keys():
    if os.path.exists(config.api_keys_file):
        with open(config.api_keys_file, 'rb') as f:
            encrypted_api_keys = f.read()
        return decrypt_json(encrypted_api_keys)
    return {}

def save_api_keys(api_keys):
    encrypted_api_keys = encrypt_json(api_keys)
    with open(config.api_keys_file, 'wb') as f:
        f.write(encrypted_api_keys)

def generate_api_key(api_keys):
    import random
    import string
    part1 = ''.join(random.choices(string.ascii_uppercase, k=2))
    while True:
        part2 = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
        if (sum(c.isalpha() for c in part2) >= 3 and sum(c.isdigit() for c in part2) >= 3):
            break
    part3 = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(35, 35)))
    key = f'{part1}_{part2}-{part3}'
    api_keys[key] = True
    save_api_keys(api_keys)
    return key

def load_initial_api_key():
    if os.path.exists(config.master_key_file):
        with open(config.master_key_file, 'rb') as f:
            encrypted_initial_api_key = f.read()
        return decrypt_string(encrypted_initial_api_key)
    return None

initial_api_key = load_initial_api_key()
api_keys = load_api_keys()

def is_master_key(key):
    return key == initial_api_key

def bytes_to_human_readable(num, suffix="B"):
    for unit in ["", "K", "M", "G", "T", "P", "E", "Z"]:
        if abs(num) < 1024.0:
            return f"{num:3.1f} {unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f} Y{suffix}"