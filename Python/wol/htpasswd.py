import bcrypt
import getpass
import os
import json

DB_DIR = '/opt/wol/db/'
USERS_FILE = os.path.join(DB_DIR, 'users.json')

def load_users():
    """Load users from the JSON file."""
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_users(users):
    """Save users to the JSON file."""
    with open(USERS_FILE, 'w') as f:
        json.dump(users, f, indent=4)

def hash_password(password):
    """Hash a password using bcrypt."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    return hashed

def save_to_users_json(username, hashed_password, permission="user"):
    """Save the username, hashed password, and permission to the users.json file."""
    users = load_users()
    users[username] = {
        'username': username,
        'password_hash': hashed_password,
        'permission': permission
    }
    save_users(users)

def user_exists(username):
    """Check if the username already exists in the users.json file."""
    users = load_users()
    return username in users

def main():
    print("Create a new user")
    username = input("Enter username: ")
    if user_exists(username):
        print("Error: Username already exists.")
        return

    password = getpass.getpass("Enter password: ")
    confirm_password = getpass.getpass("Confirm password: ")

    if password != confirm_password:
        print("Error: Passwords do not match.")
        return

    hashed_password = hash_password(password)
    permission = input("Enter permission level (e.g., 'admin', 'user'): ")
    save_to_users_json(username, hashed_password, permission)
    print("User added successfully.")

if __name__ == "__main__":
    main()