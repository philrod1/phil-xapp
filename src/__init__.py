#__init__.py
import json
import os
import sys
import subprocess
import logging
import signal
logging.basicConfig(
    level=logging.INFO,  # You can set this to DEBUG for more verbose output
    format='%(asctime)s:%(levelname)s:%(message)s',
    handlers=[
        logging.FileHandler('init-ts-xapp.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
print("Running __init__.py")
def load_config():
    # Use the absolute path to the configuration file
    config_path = '/app/ts-xapp/init/ts-xapp-config-file.json'
    
    # Print the computed config path to verify it's correct
    print("Config path:", config_path)
    
    # Check if the config file exists at the specified path
    if not os.path.exists(config_path):
        logging.error(f"Config file does not exist at {config_path}")
        sys.exit(1)

    try:
        with open(config_path, 'r') as f:
            config = json.load(f)
            if not validate_config(config):
                sys.exit(1)
            return config
    except Exception as e:
        logging.error(f"Error loading json file from {config_path}. Reason = {str(e)}")
        sys.exit(1)

def validate_config(config):
    required_keys = ["xapp_name", "version", "rmr"]
    for key in required_keys:
        if key not in config:
            logging.error(f"Missing required key in config: {key}")
            return False
    return True

def set_environment_variables(config):
    try:
        os.environ["XAPP_NAME"] = config["xapp_name"]
        os.environ["VERSION"] = config["version"]
        os.environ["RMR_PORT"] = str(config["rmr"]["protPort"])
        # Add any other environment variables you need to set here
        return True
    except Exception as e:
        logging.error(f"Error setting environment variables. Reason = {str(e)}")
        return False

def start_ts_xapp():
    cmd = ["python3", "ts-xapp.py"]
    process = subprocess.Popen(cmd)
    return process

def terminate_process(process):
    if process:
        process.terminate()
        logging.info("ts-xapp.py terminated.")
    sys.exit(0)

if __name__ == "__main__":
    config = load_config()
    
    if set_environment_variables(config):
        logging.info("Environment variables set successfully")
        process = start_ts_xapp()
        
        # Attach the handler to SIGINT (Ctrl+C) and SIGTERM (termination signal)
        signal.signal(signal.SIGINT, lambda signum, frame: terminate_process(process))
        signal.signal(signal.SIGTERM, lambda signum, frame: terminate_process(process))
        
        process.wait()
    else:
        logging.error("Failed to set environment variables")
