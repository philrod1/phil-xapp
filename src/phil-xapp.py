
# phil-xapp.py
import json
import os
import sys
sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'src'))
import logging
from flask import Flask, jsonify, request
import subprocess
import signal
from ricxappframe.xapp_frame import RMRXapp
from subscription_manager import SubscriptionManager
import default_handler
from rmr_health_check import rmr_health_check
from sdl_health_check import sdl_health_check
from e2_health_check import e2_health_check
from traffic_steering import traffic_steering
from data_sync import sync_kpimon_data
from A1PolicyHandler import A1PolicyHandler
from A1PolicyManager import A1PolicyManager
from A1_health_check import A1HealthCheck
from whatever import Whatever
from constants import Constants

# Initialize the app and set environment variables
from init_app import init_app
init_app()

# Set up logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s:%(levelname)s:%(message)s',
    handlers=[
        logging.FileHandler('phil-xapp.log'),
        logging.StreamHandler(sys.stdout)
    ]
)

# Create an RMR xApp instance
rmr_xapp = RMRXapp(default_handler.default_rmr_handler, rmr_port=int(os.environ.get("RMR_PORT", 4560)))

# Initialize A1PolicyManager and A1PolicyHandler
a1_policy_manager = A1PolicyManager(rmr_xapp)
a1_policy_handler = A1PolicyHandler(rmr_xapp)
# Initialize the A1 health check handler
a1_health_check_handler = A1HealthCheck(rmr_xapp)
# Startup A1PolicyManager
a1_policy_manager.startup()

# Provide the correct URI for the Subscription Manager
subscription_manager_uri = "http://10.244.0.180:3800/"

# Create an instance of the SubscriptionManager
subscription_manager = SubscriptionManager(uri=subscription_manager_uri, local_address="0.0.0.0", local_port=8088)

# Set the SubscriptionManager in default_handler
default_handler.set_subscription_manager(subscription_manager)

app = Flask(__name__)

@app.route('/sync_kpimon', methods=['POST'])
def run_sync_kpimon_data():
    print("Sync KPI Mon Data endpoint called")
    try:
        sync_kpimon_data()
        logging.info("Data synchronization with KPImon initiated successfully")
        return jsonify(message="Data synchronization with KPImon initiated successfully")
    except Exception as e:
        logging.error(f"Error syncing data with KPImon: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500

@app.route('/rmr_health_check', methods=['POST'])
def run_rmr_health_check():
    print("rmr_health_check endpoint called")
    try:
        message = rmr_health_check(rmr_xapp)
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing RMR Health Check: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500

@app.route('/sdl_health_check', methods=['POST'])
def run_sdl_health_check():
    print("sdl_health_check endpoint called")
    try:
        message = sdl_health_check()
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing SDL Health Check: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500
        
@app.route('/e2_health_check', methods=['POST'])
def run_e2_health_check():
    print("E2 health check endpoint called")
    try:
        message = e2_health_check()
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing E2 Health Check: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500        
        
a1_health_check = A1HealthCheck(rmr_xapp)
@app.route('/a1_health_check', methods=['POST'])
def run_a1_health_check():
    print("A1 health check endpoint called")
    try:
        message = a1_health_check.perform_health_check()
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing A1 Health Check: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500


what = Whatever(rmr_xapp)
@app.route('/whatever', methods=['POST'])
def run_whatever():
    print(f"Whatever endpoint called with {request.form}")
    try:
        message = "HERE" #what.send_rmr_payload(request.form.payload, request.form.mtype)
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing Whatever.  I don't even know how I got here: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500


@app.route('/traffic_steering', methods=['POST'])
def run_traffic_steering():
    print("traffic_steering endpoint called")
    try:
        message = traffic_steering()
        logging.info(message)
        return jsonify(message=message)
    except Exception as e:
        logging.error(f"Error executing Traffic Steering: {str(e)}")
        return jsonify(message=f"Error: {str(e)}"), 500


# Store the subprocess reference
try:
    logging.debug("Attempting to start the dashboard subprocess...")
    dashboard_process = subprocess.Popen(
        ["python3", "/app/phil-xapp/src/dashboard.py"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    logging.debug("Dashboard subprocess started successfully.")
except Exception as e:
    logging.error(f"Failed to start the dashboard subprocess: {str(e)}")

# Define the signal handler function
def terminate_process(signum, frame):
    dashboard_process.terminate()
    logging.info("Dashboard subprocess terminated.")
    exit(0)

# Attach the handler to SIGINT (Ctrl+C) and SIGTERM (termination signal)
signal.signal(signal.SIGINT, terminate_process)
signal.signal(signal.SIGTERM, terminate_process)

if __name__ == "__main__":
    # Log a startup message
    logging.info("phil-xapp starting...")

    # Initialize subscriptions
    subscription_manager.initialize_subscriptions()

    # Attach handlers to Flask's logger if needed
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.DEBUG)
    app.logger.addHandler(handler)
    app.logger.setLevel(logging.DEBUG)

    # Initiate data synchronization from KPImon
    try:
        sync_kpimon_data()
        logging.info("Data synchronization from KPImon initiated successfully")
    except Exception as e:
        logging.error(f"Error initiating data synchronization from KPImon: {str(e)}")

    # Start the Flask app
    app.run(host='0.0.0.0', port=5000)  # go to http://127.0.0.1:5001 in your browser
