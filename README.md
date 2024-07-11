# Traffic Steering (TS) xApp

The Traffic Steering (TS) xApp is a specialized tool designed for the [OAIC O-RAN testbed](https://www.openaicellular.org/). Its primary purpose is to efficiently manage and optimize traffic flow within cellular networks. By utilizing real-time metrics and adhering to dynamic policies, this xApp ensures optimal network performance by making informed decisions about user equipment (UE) handovers between cells. 
This xApp can be onboarded through the xApp Onboarder.

## 🌟 Key Features

- **Interface Integration**: 
  - Direct RAN communication and real-time metric acquisition through E2 Interface interactions.
- **Health Check Operations**: 
  - Includes RMR, E2, A1 and SDL health checks.
- **KPIMON xApp Integration**:
  - Responsible for collecting RAN metrics and writing to InfluxDB.
- **Dynamic Policy Management**:
  - Adapts traffic steering policies in response to real-time updates from the A1 interface.
- **Load Balancing**:
  - Redistributes UEs to achieve balanced load across cells when overload is detected.
- **UE Profiling**:
  - Captures detailed profiles for each UE, including attributes like ID, cell, priority, type, origin, signal strength, and throughput.
- **InfluxDB Integration**:
  - Logs metrics and policies for historical data analysis and visualization with tools like Grafana.
- **Flask API Support**:
  - Enables external xApps to dynamically push or modify policies, supporting ML/RL/DRL plugins.
- **Scalability**:
  - Accommodates a growing number of UEs and cells while maintaining efficiency.
- **Modular Design**:
  - Allows for easy integration of future features.

## 🛠 Prerequisites

- Installation of [OAIC and SRSRAN](https://openaicellular.github.io/oaic/).
- Setup of multiple UEs with initiated network traffic flow.
- KPImon xApp running in the environment.

## 🚀 Getting Started
Start with root permission and:

1. Execute the RIC installation:
   ```bash
   chmod +x ./ricinstallation.sh
   ./ricinstallation.sh
2. move ssrsran script to oaic folder and Start SRSRAN:
   ```bash
   chmod +x srsrandeploy.sh
   ./srsrandeploy.sh

   After this step you should run the below command and see 14 pods
   sudo kubectl get pods -A
3. Execute KPImon-xApp in oaic folder:
   ```bash
   chmod +x kpimon.sh
   ./kpimon.sh
4. Clone TS xApp fro the below repo
   ```bash
   git clone https://github.com/natanzi/ts-xapp
   
5. Go to ts-xapp folder and run it:
   ```bash
   chmod +x ts-xapp.sh
   ./ts-xapp.sh
6. Open the below address in your browser to see the ts-xapp dashboard and grafana:
   ```bash
   http://localhost:5001/
   http://localhost:3000/
   
7. To remove the ts-xapp:
   ```bash
   chmod +x del-tsxapp.sh
   ./del-tsxapp.sh   
> **Note:**
> 
> ### xApp Re-Deployment & Undeployment
> To redeploy the xApp on the near-RT RIC side, run:
> ```bash
> sudo kubectl -n ricxapp rollout restart deployment ricxapp-ts-xapp
> ```
> To undeploy the xApp, first retrieve the IP address of the App Manager:
> ```bash
> export APPMGR_HTTP=`sudo kubectl get svc -n ricplt --field-selector metadata.name=service-ricplt-appmgr-http -o jsonpath='{.items[0].spec.clusterIP}'`
> curl -L -X DELETE http://${APPMGR_HTTP}:8080/ric/v1/xapps/ts-xapp
> ```
> To remove the xApp descriptors from the Chart Museum, execute:
> ```bash
> curl -L -X DELETE "http://${ONBOARDER_HTTP}:8080/api/charts/ts-xapp/1.0.0"
> ```
> To delete a Docker image
> ```bash
> sudo docker rmi -f xApp-registry.local:5008/ts-xapp:1.0.0
> ```
> To see the Docker image
> ```bash
> docker images

get the name of the pod where your container is running:
kubectl get pods -n ricxapp

 need to know the container's name or ID?
 docker ps
 
to run commands inside the container
 docker exec -it <container-name-or-id> /bin/bash


## 🤝 Contributing
We welcome your contributions to enhance this xApp! Feel free to fork the repository and submit a pull request with your improvements.
