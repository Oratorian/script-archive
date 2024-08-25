import bcrypt
import getpass
import os

AUTH_FILE = '/opt/wol/.htpasswd'

def hash_password(password):
    """Hash a password using bcrypt."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
    return hashed

def save_to_htpasswd(username, hashed_password):
    """Save the username and hashed password to the htpasswd file."""
    with open(AUTH_FILE, 'a') as f:
        f.write(f"{username}:{hashed_password}\n")

def user_exists(username):
    """Check if the username already exists in the htpasswd file."""
    if not os.path.exists(AUTH_FILE):
        return False

    with open(AUTH_FILE, 'r') as f:
        for line in f:
            if line.startswith(username + ":"):
                return True
    return False

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
    save_to_htpasswd(username, hashed_password)
    print("User added successfully.")

if __name__ == "__main__":
    main()