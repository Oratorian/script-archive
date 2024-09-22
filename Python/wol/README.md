# Wake-on-LAN (WOL) Server

This Python-based Wake-on-LAN server allows users to wake up computers in their local network via a web interface. It also supports remote shutdowns of network devices. The server includes user authentication for added security and can be configured using environment variables.

## Features

- **Wake-on-LAN Support**: Trigger WOL requests for devices in your network using their MAC addresses.
- **Remote Shutdown Support**: Includes PowerShell and executable scripts to trigger remote shutdown commands.
- **User Authentication**: Secure access to the server using Flask-Login and bcrypt for password management.
- **Web Interface**: Built-in web interface using Flask to send WOL and shutdown requests.
- **Database Integration**: Stores user and device information in a local JSON-based database.

## Requirements

- **Python 3.11+**

##  Installation Instructions
- Download script to your local machine:

```
Goto https://github.com/Oratorian/script-archive/releases
```
- Unpack files

- Navigate to the unpacked directory

- Set up a virtual environment (optional but recommended):
```
python -m venv venv
source venv/bin/activate   # On Windows use: venv\Scripts\activate
```

-Install the dependencies from the requirements.txt file:

```
pip install -r requirements.txt
```
- Create a .env file in the root directory of the project:

```
touch .env
```

- Add the following contents to the .env file:

```
WOL_SERVER_PORT=5000
SECRET_KEY=your_secret_key
```

- Run the server:

```
gunicorn --bind 0.0.0.0:5000 wol_server:app
```

- Access the server in your web browser at:
```
http://localhost:5000
```

## License

This script is released under the GPL-3.0 license. You are free to reproduce, modify, and distribute this script as long as the original author is credited.

---

**Author**: Oration 'Mahesvara'  
**GitHub**: [Oratorian@github.com](https://github.com/Oratorian)