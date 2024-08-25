import bcrypt
import logging
from flask_login import UserMixin

AUTH_FILE = '/opt/wol/.htpasswd'

class User(UserMixin):
    def __init__(self, id, username, password_hash):
        self.id = id
        self.username = username
        self.password_hash = password_hash

    @staticmethod
    def get(user_id):
        """Retrieve a user by ID."""
        with open(AUTH_FILE, 'r') as f:
            for line in f:
                logging.debug(f"Raw line read from file: {line.strip()}")

                try:
                    stored_username, stored_hash = line.strip().split(':', 1)
                    logging.debug(f"Parsed username: {stored_username}")
                    logging.debug(f"Parsed hash: {stored_hash}")

                    if stored_username == user_id:
                        logging.debug(f"User matched: {stored_username}")
                        return User(user_id, stored_username, stored_hash)
                except ValueError as e:
                    logging.error(f"Error processing line: {line.strip()}")
                    logging.error(f"Error details: {e}")
        return None

    @staticmethod
    def authenticate(username, password):
        """Authenticate a user based on username and password."""
        try:
            logging.debug(f"Authenticating user: {username}")
            with open(AUTH_FILE, 'r') as f:
                for line_number, line in enumerate(f, start=1):
                    logging.debug(f"Processing line {line_number}: {line.strip()}")

                    try:
                        stored_username, stored_hash = line.strip().split(':', 1)
                        logging.debug(f"Stored Username: {stored_username}")
                        logging.debug(f"Stored Hash: {stored_hash}")

                        if stored_username == username:
                            logging.debug(f"Attempting to verify password for user: {stored_username}")
                            if User.verify_bcrypt_password(stored_hash, password):
                                logging.debug(f"Password verification succeeded for user: {stored_username}")
                                return User(stored_username, stored_username, stored_hash)
                            else:
                                logging.debug(f"Password verification failed for user: {stored_username}")
                    except ValueError as ve:
                        logging.error(f"Error on line {line_number}: {line.strip()}")
                        logging.error(f"Error details: {ve}")
                        continue
        except Exception as e:
            logging.error(f"Exception in authenticate method: {e}")
        return None

    @staticmethod
    def verify_bcrypt_password(stored_password, provided_password):
        """Verify a password against a bcrypt hash."""
        try:
            logging.debug(f"Verifying stored password: {stored_password}")
            return bcrypt.checkpw(provided_password.encode('utf-8'), stored_password.encode('utf-8'))
        except ValueError as e:
            logging.error(f"Error during password verification: {e}")
            return False

    @staticmethod
    def create(username, password):
        """Create a new user and store it in the AUTH_FILE."""
        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
        
        logging.debug(f"Creating user: {username}")
        logging.debug(f"Storing hash: {password_hash}")

        with open(AUTH_FILE, 'a') as f:
            f.write(f"{username}:{password_hash}\n")
        return User(username, username, password_hash)