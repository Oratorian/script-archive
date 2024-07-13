import os
import json
import secrets
from cryptography.fernet import Fernet

api_keys_file = 'api_keys.enc'
initial_key_file = 'initial_api_key.enc'
sudo_password_file = 'sudo_password.enc'
key_file = 'encryption_key.bin'

def load_or_generate_encryption_key():
    if os.path.exists(key_file):
        with open(key_file, 'rb') as f:
            encryption_key = f.read()
        print("Encryption key already exists. Using the existing key.")
    else:
        encryption_key = Fernet.generate_key()
        with open(key_file, 'wb') as f:
            f.write(encryption_key)
        api_keys = {initial_api_key: True}
        encrypted_api_keys = cipher.encrypt(json.dumps(api_keys).encode())
        with open(api_keys_file, 'wb') as f:
            f.write(encrypted_api_keys)
        print("New encryption key and APIkey Database generated and saved.")
        cipher = Fernet(encryption_key)
        reset_sudo_password(cipher)
        reset_master_key(cipher)
        exit()
    return encryption_key

def reset_sudo_password(cipher):
    sudo_password = input("Please enter your new sudo password: ")
    encrypted_sudo_password = cipher.encrypt(sudo_password.encode())
    with open(sudo_password_file, 'wb') as f:
        f.write(encrypted_sudo_password)
    print("Sudo password saved (encrypted).")
    print(f"Encrypted sudo password: {encrypted_sudo_password.decode()}\n")

def reset_master_key(cipher):
    initial_api_key = secrets.token_urlsafe(32)
    encrypted_initial_api_key = cipher.encrypt(initial_api_key.encode())
    with open(initial_key_file, 'wb') as f:
        f.write(encrypted_initial_api_key)
    print("Master APIkey saved (encrypted).")
    print(f"New Master APIkey (save this securely): {initial_api_key}\n")

def main():
    encryption_key = load_or_generate_encryption_key()
    cipher = Fernet(encryption_key)

    print("Choose an action:")
    print("1. Reset sudo password")
    print("2. Reset master key")
    print("3. Exit")

    choice = input("Enter the number of your choice: ")

    if choice == '1':
        reset_sudo_password(cipher)
    elif choice == '2':
        reset_master_key(cipher)
    else:
        print("Exiting.")

if __name__ == '__main__':
    main()