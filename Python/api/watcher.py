import os
import importlib.util
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class EndpointEventHandler(FileSystemEventHandler):
    def __init__(self, app, endpoints_folder):
        self.app = app
        self.endpoints_folder = endpoints_folder
        self.loaded_modules = {}

    def load_module(self, module_name, module_path):
        try:
            spec = importlib.util.spec_from_file_location(module_name, module_path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            self.app.register_blueprint(module.bp)
            self.loaded_modules[module_name] = module
            print(f"Successfully imported module {module_name}")
        except Exception as e:
            print(f"Error importing {module_name} from {module_path}: {e}")

    def unload_module(self, module_name):
        try:
            if module_name in self.loaded_modules:
                module = self.loaded_modules[module_name]
                self.app.unregister_blueprint(module.bp)
                del self.loaded_modules[module_name]
                print(f"Successfully unloaded module {module_name}")
        except Exception as e:
            print(f"Error unloading {module_name}: {e}")

    def on_created(self, event):
        if event.is_directory:
            return
        module_name = os.path.basename(event.src_path)[:-3]
        self.load_module(module_name, event.src_path)

    def on_deleted(self, event):
        if event.is_directory:
            return
        module_name = os.path.basename(event.src_path)[:-3]
        self.unload_module(module_name)

def start_watching(app, endpoints_folder):
    event_handler = EndpointEventHandler(app, endpoints_folder)
    observer = Observer()
    observer.schedule(event_handler, path=endpoints_folder, recursive=False)
    observer.start()
    return observer