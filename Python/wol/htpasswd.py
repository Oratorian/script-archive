import hashlib
import getpass
import os

HTPASSWD_FILE = '.htpasswd'

def hash_password(password):
    """Hash a password using SHA-256."""
    return hashlib.sha256(password.encode()).hexdigest()

def save_to_htpasswd(username, hashed_password):
    """Save the username and hashed password to the htpasswd file."""
    with open(HTPASSWD_FILE, 'a') as f:
        f.write(f"{username}:{hashed_password}\n")

def main():
    print("Create a new user")
    username = input("Enter username: ")
    password = getpass.getpass("Enter password: ")

    # Check if the username already exists in the htpasswd file
    if os.path.exists(HTPASSWD_FILE):
        with open(HTPASSWD_FILE, 'r') as f:
            for line in f:
                if line.startswith(username + ":"):
                    print("Error: Username already exists.")
                    return

    hashed_password = hash_password(password)
    save_to_htpasswd(username, hashed_password)
    print("User added successfully.")

if __name__ == "__main__":
    main()
