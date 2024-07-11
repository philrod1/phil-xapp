cat << 'EOF'
################################################################################
#          Welcome to OAIC Traffic Steering xApp Fast Installation             #
#                                                                              #
#   This script installs Nginx and configures the necessary files for running  #
#   the Traffic Steering (TS) xApp on OAIC Testbed.                                            #
#                                                                              #
#   The Traffic Steering (TS) xApp is a specialized tool designed for the      #
#   OAIC O-RAN testbed. Its primary purpose is to efficiently manage and       #
#   optimize traffic flow within cellular networks. By utilizing real-time     #
#   metrics and adhering to dynamic policies, this xApp ensures optimal        #
#   network performance by making informed decisions about user equipment      #
#   (UE) handovers between cells. This xApp can be onboarded through the       #
#   xApp Onboarder.                                                            #
#                                                                              #
#   Licensed under the Apache License, Version 2.0 (the "License");            #
#   you may not use this file except in compliance with the License.           #
#   You may obtain a copy of the License at:                                   #
#       http://www.apache.org/licenses/LICENSE-2.0                             #
#                                                                              #
#   Unless required by applicable law or agreed to in writing, software        #
#   distributed under the License is distributed on an "AS IS" BASIS,          #
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
#   See the License for the specific language governing permissions and        #
#   limitations under the License.                                             #
################################################################################
EOF
################################################################################
create_docker_network() {
    local network_name="$1"
    
    # Check if the Docker network already exists
    DOCKER_NETWORK_EXISTS=$(docker network ls | grep "$network_name")
    
    if [ -z "$DOCKER_NETWORK_EXISTS" ]; then
        echo "Creating Docker network '$network_name'..."
        docker network create "$network_name"
        echo "Docker network '$network_name' created successfully."
    else
        echo "Docker network '$network_name' already exists. Proceeding to the next steps..."
    fi
}
#################################################################################
create_docker_network "my_network"
#################################################################################
# Function to check if the script encounters any issues and prompts the user to continue or exit
function check_continue() {
    read -p "An issue occurred. Do you want to continue? (y/n): " choice
    case "$choice" in 
      y|Y ) echo "Continuing...";;
      n|N ) echo "Exiting..."; exit 1;;
      * ) echo "Invalid input"; check_continue;;
    esac
}

# Check if the script is being run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if the current directory is /home/ubnt/oaic/ts-xapp
if [ "$(pwd)" != "/home/ubnt/main-file-repo/oaic/ts-xapp" ]; then
    echo "This script must be run from the /home/ubnt/oaic directory"
    exit 1
fi

echo "Installing iperf3..."
sudo apt install iperf3 || { echo 'iperf3 installation failed'; check_continue; }
echo "iperf3 installation completed."

echo "Installing vim..."
sudo apt install vim || { echo 'vim installation failed'; check_continue; }
echo "vim installation completed."
apt install python3-pip

oaic=`pwd`
echo "Installing nginx..."
sudo apt-get install nginx || { echo 'nginx installation failed'; check_continue; }
echo "nginx installation completed."  # Corrected here (added closing quotation mark)
sleep 5
sudo systemctl start nginx.service || { echo 'Failed to start nginx'; check_continue; }
# New command to check the status of nginx
sudo systemctl status nginx --no-pager || { echo 'nginx service is not running'; check_continue; }
cd /etc/nginx/sites-enabled
if [ -e "default" ]; then
    sudo unlink default || { echo 'Failed to unlink default'; check_continue; }
else
    echo "'default' file does not exist, skipping unlink."
fi
cd ../
cd ../../var/www
# Check if directory exists, if not create it
if [ ! -d "xApp_config.local" ]; then
  sudo mkdir xApp_config.local || { echo 'Failed to create directory xApp_config.local'; check_continue; }
else
  echo "Directory xApp_config.local already exists."
fi
cd xApp_config.local/
# Check if directory exists, if not create it
if [ ! -d "config_files" ]; then
  sudo mkdir config_files || { echo 'Failed to create directory config_files'; check_continue; }
else
  echo "Directory config_files already exists."
fi
cd ../../../etc/nginx/conf.d
# Overwrite the file if it exists
sudo sh -c "echo 'server {
listen 5010 default_server;
server_name xApp_config.local;
location /config_files/ {
root /var/www/xApp_config.local/;
}
}' >xApp_config.local.conf"

echo ">>> reloading nginx..."
sleep 3

sudo nginx -t || { echo 'nginx configuration test failed'; check_continue; }
cd ${oaic}
# Overwrite the file if it exists
sudo cp -f /home/ubnt/main-file-repo/oaic/ts-xapp/init/ts-xapp-config-file.json /var/www/xApp_config.local/config_files/ || { echo 'Failed to copy config file'; check_continue; }
[ -r "/var/www/xApp_config.local/config_files/ts-xapp-config-file.json" ] || { echo 'Config File not found or is not readable'; check_continue; }
ls -l /var/www/xApp_config.local/config_files/
pwd
#sudo chmod 755 /var/www/xApp_config.local/config_files/ts-xapp-config-file.json || { echo 'Failed to change file permissions'; check_continue; }
sudo systemctl reload nginx || { echo 'Failed to reload nginx'; check_continue; }
echo ">>> getting machine IP..."
export MACHINE_IP=`hostname  -I | cut -f1 -d' '`
sleep 3
echo "Machine IP: $MACHINE_IP"
echo ">>> checking for config-file"
curl http://${MACHINE_IP}:5010/config_files/ts-xapp-config-file.json || { echo 'Failed to fetch config-file'; check_continue; }
echo ">>> building docker image...."
cd ${oaic}/ts-xapp
echo ">>> checking directory"
ls
echo ">>> Creating ts-xapp Docker image"
echo ">>> Now, we create a docker image of the ts-xApp using the given docker file."
sudo docker build . -t xApp-registry.local:5008/ts-xapp:1.0.0 || { echo 'docker build failed'; check_continue; }

# Check if the Docker image was successfully created
IMAGE_EXISTS=$(sudo docker image ls | grep "xApp-registry.local:5008/ts-xapp" | grep "1.0.0")

# Check if the image exists
if [ -n "$IMAGE_EXISTS" ]; then
    # Print the result in a rectangle with '#'
    echo "################################################################################################################################"
    echo "#                                                                                                                              #"
    echo "#    Docker Image Found:                                                                                                       #"
    echo "#    $IMAGE_EXISTS                                                                                                             #"
    echo "#                                                                                                                              #"
    echo "################################################################################################################################"
else
    echo "################################################################################################################################"
    echo "#                                                                                                                              #"
    echo "#    No Docker Image Found for ts-xapp !                                                                                       #"
    echo "#                                                                                                                              #"
    echo "################################################################################################################################"
fi

if [ -z "$IMAGE_EXISTS" ]; then
  echo "Docker image build failed. Do you want to exit the script? (y/n): "
  read response
  if [[ "$response" == "y" || "$response" == "Y" ]]; then
    echo "Exiting script."
    exit 1
  else
    echo "Continuing script."
    # Continue with other operations or retry logic
  fi
else
  echo "Docker image built successfully. Here are the details:"
  echo "################################################################################################################################"
  echo "#                                                                                                                              #"
  # Execute the command and display its output
  sudo docker images --filter=reference='xApp-registry.local:5008/ts-xapp:1.0.0'
  echo "#                                                                                                                              #"
  echo "################################################################################################################################"
   
fi

echo "Pausing for 20 seconds to allow system processes to stabilize before continuing..."
sleep 20

###############################################################################
# Function to check the status of the last command executed
check_status() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >&2
        exit 1
    fi
}
##############################################################################
# Set the namespace and service name
NAMESPACE="ricxapp"
SERVICE_NAME="ts-xapp-service"

# Check if the service already exists
if kubectl get svc $SERVICE_NAME -n $NAMESPACE > /dev/null 2>&1; then
    echo "$SERVICE_NAME already exists in namespace $NAMESPACE."
else
    # Apply the configuration
    kubectl apply -f ts-xapp-service.yaml
    
    # Check if the service creation was successful
    if kubectl get svc $SERVICE_NAME -n $NAMESPACE > /dev/null 2>&1; then
        echo "$SERVICE_NAME successfully created in namespace $NAMESPACE."
    else
        echo "Failed to create $SERVICE_NAME in namespace $NAMESPACE."
        exit 1
    fi
fi

# Describe the service
kubectl describe svc $SERVICE_NAME -n $NAMESPACE
##############################################################################
echo ">>> Enter to xApp onboarder deployment process..."
echo ">>> Before Deploying the xApp, it is essential to make sure the 5G Network Up and Running. Otherwise the subscription procedure will not be successful."

# Retrieve service IPs and check the status of each command
export KONG_PROXY=$(sudo kubectl get svc -n ricplt -l app.kubernetes.io/name=kong -o jsonpath='{.items[0].spec.clusterIP}')
check_status "Failed to retrieve KONG_PROXY"

export APPMGR_HTTP=$(sudo kubectl get svc -n ricplt --field-selector metadata.name=service-ricplt-appmgr-http -o jsonpath='{.items[0].spec.clusterIP}')
check_status "Failed to retrieve APPMGR_HTTP"

export ONBOARDER_HTTP=$(sudo kubectl get svc -n ricplt --field-selector metadata.name=service-ricplt-xapp-onboarder-http -o jsonpath='{.items[0].spec.clusterIP}')
check_status "Failed to retrieve ONBOARDER_HTTP"
############################################################################
# Display the retrieved variables
RED='\033[0;31m' # Red color
NC='\033[0m' # No Color
GREEN='\033[0;32m' # Green color

# This line will be displayed in red
echo -e ">>> Get Variables.....First, we need to get some variables of RIC Platform ready. The following variables represent the IP addresses of the services running on the RIC Platform."

# These lines display the variables with their values in red
export MACHINE_IP=$(hostname  -I | cut -f1 -d' ')
echo -e "KONG_PROXY = ${GREEN}$KONG_PROXY${NC}"
echo -e "APPMGR_HTTP = ${GREEN}$APPMGR_HTTP${NC}"
echo -e "ONBOARDER_HTTP = ${GREEN}$ONBOARDER_HTTP${NC}"
echo -e "Machine IP: ${GREEN}$MACHINE_IP${NC}"
############################################################################
# Check for helm charts
echo ">>> getting charts ... Check for helm charts"
curl -v --location --request GET "http://$KONG_PROXY:32080/onboard/api/v1/charts"
check_status "Failed to get charts"

############################################################################
# Prepare the JSON file for xApp onboarding
echo '{"config-file.json_url":"http://'$MACHINE_IP':5010/config_files/ts-xapp-config-file.json"}' > ts-xapp-onboard.url
check_status "Failed to create ts-xapp-onboard.url"

echo ">>> ts-xapp-onboard.url"
cat ts-xapp-onboard.url

# Attempt to onboard the xApp
echo ">>> curl POST... Now we are ready to deploy the xApp"
curl -v -L -X POST "http://$KONG_PROXY:32080/onboard/api/v1/onboard/download" --header 'Content-Type: application/json' --data-binary "@ts-xapp-onboard.url"
check_status "Failed to post onboard download"

# Check the onboarded charts
echo ">>> curl GET..."
curl -v -L -X GET "http://$KONG_PROXY:32080/onboard/api/v1/charts"
check_status "Failed to get charts after onboarding"


# Colors for output
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check the status of the previous command
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}$1${NC}"
        exit 1
    fi
}

# Colors for output
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check the status of the previous command
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}$1${NC}"
        exit 1
    fi
}

# Attempt to post the xApp
echo ">>> curl POST..."
curl -v -L -X POST "http://$KONG_PROXY:32080/appmgr/ric/v1/xapps" --header 'Content-Type: application/json' --data-raw '{"xappName": "ts-xapp"}'
check_status "Failed to post xApp"

# Verifying xApp Deployment
echo 'Verifying xApp Deployment...'
sudo kubectl get pods -A
echo "################################################################################################################################"
echo "#                                                                                                                              #"
echo "# Verifying xApp Deployment...                                                                                                 #"

# Capture the output of the command you want to run
POD_STATUS=$(sudo kubectl get pods -A | grep ricxapp-ts-xapp)

# Check if the variable doesn't contain anything
if [ -z "$POD_STATUS" ]; then
    echo "# No ricxapp-ts-xapp pods found in the ricxapp namespace.                                                                     #"
else
    # If the variable contains output, print it
    echo "# $POD_STATUS                                                                                                                #"
fi

RED='\033[0;31m'
NC='\033[0m' # No Color

echo "################################################################################################################################"
echo "######################################### Setting up Grafana... ################################################################"
echo "################################################################################################################################"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl and try again.${NC}"
    exit 1
fi

# Set your namespace and service names here
NAMESPACE="ricplt"
INFLUXDB_SERVICE="ricplt-influxdb"
GRAFANA_SERVICE="grafana" # Name of Grafana service or Docker container

# Check if InfluxDB is running in Kubernetes
if ! kubectl get pods -n $NAMESPACE | grep -q "$INFLUXDB_SERVICE"; then
    echo -e "${RED}InfluxDB is not running in Kubernetes. Please deploy InfluxDB and try again.${NC}"
    exit 1
fi
echo "InfluxDB is running."

# Port-forward InfluxDB
kubectl port-forward svc/$INFLUXDB_SERVICE 8086:8086 -n $NAMESPACE &
echo "InfluxDB port-forwarding setup complete."

# Check if Grafana is running in Kubernetes
if kubectl get pods -n $NAMESPACE | grep -q "$GRAFANA_SERVICE"; then
    echo "Grafana is running in Kubernetes."
    # Port-forward Grafana
    kubectl port-forward svc/$GRAFANA_SERVICE 3000:3000 -n $NAMESPACE &
    echo "Grafana port-forwarding setup complete. Grafana is accessible at http://localhost:3000"
else
    # Check if Grafana is running as a Docker container
    if docker ps | grep -q "$GRAFANA_SERVICE"; then
        echo "Grafana is running as a Docker container."
    else
        echo -e "${RED}Grafana is not running. Please start Grafana and try again.${NC}"
        exit 1
    fi
fi

echo "################################################################################################################################"
echo "# Verifying ts-xapp is Running"
echo "################################################################################################################################"


# Function to get the status of ts-xapp pod
get_ts_xapp_status() {
    kubectl get pods -n ricxapp -l app=ricxapp-ts-xapp -o jsonpath='{.items[*].status.phase}'
}

# Wait for ts-xapp pod to be in Running status
TS_XAPP_RUNNING=$(get_ts_xapp_status)
while [[ "$TS_XAPP_RUNNING" != "Running" ]]; do
    echo "Waiting for ts-xapp pod to be in Running status. Current status: $TS_XAPP_RUNNING"
    sleep 5
    TS_XAPP_RUNNING=$(get_ts_xapp_status)
done

echo "ts-xapp pod is running."


echo "################################################################################################################################"
echo "# Listing all running containers with their network connections:"
docker ps --format 'table {{.Names}}\t{{.Networks}}'
echo "# Inspecting 'my_network' Docker network:"
docker network inspect my_network
echo "################################################################################################################################"
# Function to clean up port forwarding on script exit
cleanup() {
  echo "Stopping port forwarding..."
  if [ -n "$PORT_FORWARD_PID" ]; then
    kill $PORT_FORWARD_PID 2>/dev/null
    sleep 2
    if ps -p $PORT_FORWARD_PID > /dev/null; then
      echo "Port forwarding for ricxapp-ts-xapp did not stop gracefully, force stopping..."
      kill -9 $PORT_FORWARD_PID 2>/dev/null
    fi
    echo "Stopped port forwarding for ricxapp-ts-xapp."
  fi
}

# Set the trap function for script exit
trap cleanup EXIT INT TERM

# Check if InfluxDB is running in the Kubernetes cluster
if ! kubectl get svc -n ricplt | grep -q "ricplt-influxdb"; then
  echo "InfluxDB service is not running in the Kubernetes cluster in namespace 'ricplt'. Please deploy InfluxDB and try again."
  exit 1
fi

# Check if port 8086 is already in use
if ! lsof -i :8086 &>/dev/null; then
  echo "Port 8086 is not in use. Please ensure InfluxDB port-forwarding is set up correctly."
  exit 1
fi

# Check if the user wants to see the xApp logs
while true; do
    read -p "Do you see the ricxapp-ts-xapp in the list and want to check its logs? (y/n): " choice
    case "$choice" in 
      y|Y )
        echo 'Checking xApp logs...'

        # Retrieve the Pod Name
        POD_NAME=$(kubectl get pods -n ricxapp -l app=ricxapp-ts-xapp -o jsonpath='{.items[0].metadata.name}')
        if [ -z "$POD_NAME" ]; then
          echo "Error: ricxapp-ts-xapp pod not found in namespace 'ricxapp'."
          exit 1
        fi

        # Check if port 5001 is already in use
        if lsof -i :5001 &>/dev/null; then
          echo "Port 5001 is already in use. Please free up the port or ensure ricxapp-ts-xapp port-forwarding is set up correctly."
          exit 1
        fi

        # Start port-forward in the background
        kubectl port-forward pod/$POD_NAME 5001:5001 -n ricxapp &
        PORT_FORWARD_PID=$!
        echo "Port forwarding for ricxapp-ts-xapp is now running in the background. PID: $PORT_FORWARD_PID"

        # Check xApp logs
        if ! kubectl logs -f -n ricxapp -l app=ricxapp-ts-xapp; then
            echo "Error: Failed to retrieve logs. Make sure your cluster is reachable and the ricxapp-ts-xapp is deployed correctly."
        fi
        
        # Kill the port-forwarding process after checking the logs
        cleanup
        break ;;
      n|N )
        echo "Skipping xApp logs..."
        break ;;
      * ) 
        echo "Invalid input, please enter 'y' for yes or 'n' for no."
    esac
done
