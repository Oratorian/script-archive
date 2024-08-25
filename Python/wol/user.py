import os
import json
import bcrypt
from flask import Flask, request, jsonify, send_from_directory, redirect, url_for, session, render_template, abort
from flask_login import LoginManager, login_user, logout_user, current_user, login_required, UserMixin
import logging
import subprocess
import glob

DB_DIR = '/opt/wol/db/'  # Directory where JSON files are stored
USERS_FILE = os.path.join(DB_DIR, 'users.json')  # Path to users.json
PC_DATA_DIR = os.path.join(DB_DIR, 'pcs')  # Directory where user-specific JSON files will be stored
STATIC_DIR = '/opt/wol'

class User(UserMixin):
    def __init__(self, id, username, password_hash, permission):
        self.id = id
        self.username = username
        self.password_hash = password_hash
        self.permission = permission

    @staticmethod
    def load_users():
        """Load users from the JSON file."""
        if os.path.exists(USERS_FILE):
            with open(USERS_FILE, 'r') as f:
                return json.load(f)
        return {}

    @staticmethod
    def save_users(users):
        """Save users to the JSON file."""
        with open(USERS_FILE, 'w') as f:
            json.dump(users, f, indent=4)

    @staticmethod
    def get(user_id):
        """Retrieve a user by ID."""
        users = User.load_users()
        user_data = users.get(user_id)
        if user_data:
            return User(id=user_id, username=user_data['username'], password_hash=user_data['password_hash'], permission=user_data['permission'])
        return None

    @staticmethod
    def authenticate(username, password):
        users = User.load_users()
        user_data = users.get(username)
        if user_data and User.verify_bcrypt_password(user_data['password_hash'], password):
            return User(id=username, username=user_data['username'], password_hash=user_data['password_hash'], permission=user_data['permission'])
        return None

    @staticmethod
    def verify_bcrypt_password(stored_password, provided_password):
        try:
            logging.debug(f"Verifying stored password: {stored_password}")
            return bcrypt.checkpw(provided_password.encode('utf-8'), stored_password.encode('utf-8'))
        except ValueError as e:
            logging.error(f"Error during password verification: {e}")
            return False

    @staticmethod
    def create(username, password, permission):
        users = User.load_users()
        salt = bcrypt.gensalt()
        password_hash = bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')
        users[username] = {
            'username': username,
            'password_hash': password_hash,
            'permission': permission
        }
        User.save_users(users)
        return User(username, username, password_hash, permission)

    @staticmethod
    def get_user_pc_file(username):
        return os.path.join(PC_DATA_DIR, f'{username}_pcs.json')