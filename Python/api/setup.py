import os
import json
import secrets
from cryptography.fernet import Fernet
import config

def load_or_generate_encryption_key():
    if os.path.exists(config.key_file):
        with open(config.key_file, 'rb') as f:
            encryption_key = f.read()
        print("Encryption key already exists. Using the existing key.")
    else:
        encryption_key = Fernet.generate_key()
        with open(config.key_file, 'wb') as f:
            f.write(encryption_key)
        cipher = Fernet(encryption_key)
        print("New encryption key and APIkey Database generated and saved.")
        reset_sudo_password(cipher)
        reset_master_key(cipher)
        exit()
    return encryption_key

def reset_sudo_password(cipher):
    sudo_password = input("Please enter your new sudo password: ")
    encrypted_sudo_password = cipher.encrypt(sudo_password.encode())
    with open(config.sudo_password_file, 'wb') as f:
        f.write(encrypted_sudo_password)
    print("Sudo password saved (encrypted).")
    print(f"Encrypted sudo password: {encrypted_sudo_password.decode()}\n")

def reset_master_key(cipher):
    master_key = generate_api_key()
    encrypted_master_key = cipher.encrypt(master_key.encode())
    with open(config.master_key_file, 'wb') as f:
        f.write(encrypted_master_key)
    print("Master API key saved (encrypted).")
    print(f"New Master API key (save this securely): {master_key}\n")

def generate_api_key():
    import random
    import string
    part1 = 'MAS' #join(random.choices(string.ascii_uppercase, k=2))
    while True:
        part2 = ''.join(random.choices(string.ascii_letters + string.digits, k=6))
        if (sum(c.isalpha() for c in part2) >= 3 and sum(c.isdigit() for c in part2) >= 3):
            break
    part3 = ''.join(random.choices(string.ascii_letters + string.digits, k=random.randint(35, 35)))
    key = f'{part1}_{part2}-{part3}'
    return key

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