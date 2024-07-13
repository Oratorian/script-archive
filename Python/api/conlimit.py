from collections import defaultdict
from threading import Lock

class ConnectionLimiter:
    def __init__(self, max_connections=200):
        self.max_connections = max_connections
        self.active_connections = 0
        self.key_connections = defaultdict(int)
        self.lock = Lock()

    def acquire(self, key):
        with self.lock:
            if self.active_connections >= self.max_connections:
                return False, "Maximum overall connections limit reached."

            if self.key_connections[key] >= 1:
                return False, "Maximum connection limit for this key reached."

            self.active_connections += 1
            self.key_connections[key] += 1
            return True, None

    def release(self, key):
        with self.lock:
            self.active_connections -= 1
            self.key_connections[key] -= 1
            if self.key_connections[key] == 0:
                del self.key_connections[key]

limiter = ConnectionLimiter()