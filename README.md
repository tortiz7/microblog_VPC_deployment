# Microblog Deployment on Self-Provisioned VPC, Infrastructure and Monitoring

---
### PURPOSE

	Hello! If you've been following my Workload series for deploying Flask Applications using AWS infrastructure, then welcome to the fourth entry. The purpose of Workload 4 is to design and implement a robust cloud infrastructure for the Microblog Flask Application we deployed in Workload 3, this time focusing on deploying a scalable, secure, and efficient mutli-tiered architecture using AWS services. This Workload emphasizes best practices in cloud deployment, including continuous integration and continuous delivery (CI/CD) with Jenkins, effective resource management across multiple EC2 insances, and a strong emphasis on monitoring and security. By establishing a clear separation between deployment and production environments, this project aims to enhance system reliability while optimizing resource utilization and operational efficiency.

---
## STEPS

**Create the Virtual Private Cloud for the Project**
- **Why**: Workload 3 had us configuring our own infrastructure to deploy and maintain a Microblog Flask application. While it was a good first start, Workload 4 will see us creating a more resilient ecosystem of infrastructure in order to more effectively manage and scale the Microblog application. The first step in creating this ecosystem is configuring a Virtual Private Cloud (VPC) for our infrastructure to reside in. The VPC is an isolated portion of the AWS Cloud that will allow us to more effectively manage network traffic to and from our various EC2's, and allow us to define how our infrastucture will be able to communicate to each other. The VPC will have various components configured: an Availability Zone (AZ), Public Subnet, Private Subnet, Internet Gateway and NAT Gateway. We will go over each of their functions and how to configure them below. There are other services we will need to configure for the project, such as VPC Peering and Route Tables, but we will tackle those when they come up. 
  
- **How:**
- **Create the VPC:**
    1. Navigate to the VPC Services page in the AWS Console
    2. Select "Create VPC"
    3. Select "VPC and More" in the "Resources to create" section to provision the VPC, AZ, Public and Private Subnets, and NAT Gateway in one go
    4. Choose your IPv4 CIDR Block, which will determine the size of your VPC and available IPs within it. I chose 10.0.0.0/16, which allots 65,536 IP blocks for my needs. More than enough for scaling the application!
    5. Choose 1 AZ zone for this project. You can customize it's region, or leave it at the default setting (mine is in US-east-2a (Ohio))
    6. Select 1 Public and Private Subnet each under their respective menus
    7. Select 1 NAT Gateway for your AZ - note that this will cost you money as long as it is active and reachable!
    8. Leave DNS hostnames and resolution enabled under the "DNS Options" setting - this will allow your publicly accessible EC2's to be reached via their Public IP's
    9. Create the VPC!
    10. Now, go back to the VPC service homepage and select Subnets < your Public Subnet < Actions < Edit Subnet Settings < Enable auto-assign public IPv4 addresses. This will give your EC2's in this subnet a Public IP 
so they can be reachable from the internet.

**Create the four EC2's and their Security Groups:**

**The Jenkins EC2**
1. Navigate to the EC2 services page in AWS and click "Launch Instance".
2. Name the EC2 `Jenkins` and select "Ubuntu" as the OS Image.
3. Select a t3.medium as the instance type.
4. Select the key pair you just created as your method of SSH'ing into the EC2.
5. In "Network Settings", keep the default VPC selected for this EC2, with Auto-Assign Public IP enabled.
6. Create a Security Group that allows inbound traffic to the services and applications the EC2 will need and name it after the EC2 it will control.
7. The Inbound rules should allow network traffic on Ports 22 (SSH) and 8080 (Jenkins), and all Outbound traffic.
8. Launch the instance!

**The Web Server EC2**
1. Go back to the EC2 services page in AWS and click "Launch Instance" to create our second EC2.
2. Name the EC2 `Web_Server` and select "Ubuntu" as the OS Image.
3. Select a t3.micro as the instance type.
4. Select the key pair you just created as your method of SSH'ing into the EC2.
5. In "Network Settings", select the VPC we configured in the previous step for this EC2 to reside in.
6. For the Subnet field, select the Public Subnet you created. Auto-Assign Public IP will be disabled, because we already enabled auto-assigning for the Public Subnet.
7. Create a Security Group that allows inbound traffic to the services and applications the EC2 will need and name it after the EC2 it will control.
8. The Inbound rules should allow network traffic on Ports 22 (SSH) and 80 (NGINX), and all Outbound traffic.
9. Launch the instance!

**The Application Server EC2**
1. Go back to the EC2 services page in AWS and click "Launch Instance" to create our third EC2.
2. Name the EC2 `Application_Server` and select "Ubuntu" as the OS Image.
3. Select a t3.micro as the instance type.
4. We will create a new Key Pair for this instance. Ensure you save the `.pem` file that is downloaded upon creation in a safe place, as we will need it later!
5. In "Network Settings", select the VPC we configured in Step 1 for this EC2.
6. For the Subnet field, select the Private Subnet you created. This EC2 will not need a Public IP, so do not enable the auto-assigning of one.
7. Create a Security Group that allows inbound traffic to the services and applications the EC2 will need and name it after the EC2 it will control.
8. The Inbound rules should allow network traffic on Ports 22 (SSH), 80 (Gunicorn), and 9100 (Node Exporter), and allow all Outbound traffic.
9. Launch the instance!

**The Monitoring EC2**
1. Go back to the EC2 services page in AWS and click "Launch Instance" to create our final EC2.
2. Name the EC2 "Monitoring" and select "Ubuntu" as the OS Image.
3. Select a t3.micro as the instance type.
4. Select the initial Key Pair you created at the beginning of this step for SSH'ing into this EC2.
5. In "Network Settings", select the default VPC that the Jenkins EC2 also resides in. Leave "Auto-Assign Public IP" enabled.
6. Create a Security Group that allows inbound traffic to the services and applications the EC2 will need and name it after the EC2 it will control.
7. The Inbound rules should allow network traffic on Ports 22 (SSH), 9000 (Prometheus), 3000 (Grafana), and 9100 (Node Exporter), and allow all Outbound traffic.
8. Launch the instance!
           
	These four EC2s are named after their role within our infrastructure ecosystem. The **Jenkins** EC2 will house our Jenkins workspace where the build and testing will occur; The **Application Server** will host all our Application Source code, and will be where our application is deployed from via a script; the **Web Server** will act as a bridge between our Jenkins and Application Server EC2s and will host the NGINX service that will proxy pass network traffic to our Application Server, which is inaccessible from the internet by itself; and our final EC2, **Monitoring**, will host the Prometheus and Grafana services, which will allow us to scrape vital metrics from the Application Server and visualize them in a helpful dashboard in Grafana, empowering us to take action when resources are taxed and perform necessary maintenance on the Application Server when needed.

---
### Install Jenkins
- **Why**: Jenkins automates the build and deployment pipeline. It pulls code from GitHub, tests it, and handles deployment once the Jenkinsfile is configured to do so. The big difference with this Jenkins deployment compared to our previous Workloads is that Jenkins will be hosted on its own EC2, separate from the app source code. We will still need to install Python 3.9 and it's dependencies on this Jenkins EC2, however, because Jenkins will need those dependencies in order to build and test the app code's logic.  
  
- **How**: I created and ran the below script to install Jenkins, and it's language prerequisite Java (using Java 17 for this deployment). To save time, the script first updates and upgrades all packages included in the EC2, ensuring they are up-to-date and secure. The script also installs Python3.9 - the langauge our flask app relies on - and all the dependencies necessary for our application (Python3.9 venv and Python3.9-pip) - just as it did in the previous Workload; only difference is there will be no Nginx installation in this script, since Nginx will be installed on the `Web_Server` EC2. SSH into the `Jenkins` EC2, create a file for the Jenkins install script, and then copy and paste the below into it:

``` bash
#!/bin/bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y openjdk-17-jdk
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA
sudo apt update -y
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -y
sudo apt install -y python3.9 python3.9-venv python3-pip
echo "Jenkins initial password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

`chmod +x` the script to make it executable, and then run it to install everything within.

---

### Testing SSH from the `Jenkins` EC2 into the `Web_Server` EC2

- **Why:** This workload will require us to SSH from one EC2 into another one, in order to automate the deployment of our Microblog Flask Application. This will serve as our first test of SSH'ing from one server to the other.

- **How:** In order to SSH from the `Jenkins` server into the `Web_Server`, we will need to first create a new key pair. Run the `ssh-keygen ~/.ssh` command from the commandline in the `Jenkins` server to create a new keypair in your .ssh directory, name your key pair something that will remind you it is for accessing the `Web_Server`, and then save the downloaded .pem key somewhere safe. Nano into the .pub key that was just created, and copy all the contents within. Then, go back to your running EC2 instances and connect to the `Web_Server`. Once connected, run `cd .ssh` to get to the `.ssh` directory, than run `nano authorized_keys` and paste the contents of the .pub key into this file in a new line.

	Go back to the tab with your `Jenkins` EC2 instance terminal, and run the following command: `ssh -i <your_.pem_key_filename> ubuntu@<your_Web_Server's_Public_IP>`. Type yes when asked if you trust the host's identity to connect to the `Web_Server` EC2 and save it's unique "fingerprint" in the `known_hosts` folder in the `Jenkins` EC2s .ssh folder. Every subsequent SSH attempt to the `Web_Server` EC2 will check this fingerprint saved in the known_hosts folder and compare it with the fingerprint of the `Web_Server` so we know we're connecting to the correct server. This is an added security step that helps prevent "man-in-the-middle" attacks, wherein a bad actor attempts to impersonate a server in order to get your credentials. 

### Configure the NGINX Location block

- **Why:** NGINX is a reverse proxy server between the client browser and our Microblog application. It is a gatekeeper, managing incoming traffic to assist with load balancing in the case of scalability, strengthening security by validating SSL/TLS certificates for incoming HTTPS requests, and increasing performance by caching certain static content (images, JavaScript files) and forwarding all dynamic content to Gunicorn.

	As noted in the Jenkins installation step, NGINX is installed on the `Web_server` EC2, and thus we must specifically configure the location block to route incoming HTTPS requests from NGINX Port 80 on the `Web_Server` to the Gunicorn Port 5000 on the `Application_Server`. The Location block below will show you how. 

- **How:** Since we are already SSH'd into the `Web_Server` EC2 from the `Jenkins` EC2, we can edit o the NGINX Configuration file at this location like so: `sudo nano /etc/nginx/sites-enabled/default` and add the following to the Location block. Note that unlike the previous workload, the url for the proxy_pass **must use the Private IP of your Application_Server** in order to route the necessary traffic to Gunicorn:
  
```bash
  location / {
proxy_pass http://<your_App_Server_Private_IP>:5000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}  
```
---
### SSH Into the Application_Server

- **Why:** Now, we will connect to the `Application_Server` EC2 for the first time. Since the 'Application_Server' resides in our Private Subnet, it does not have a Public IP associated with it - so we cannot connect to it from the AWS GUI like we would our `Jenkins` and `Web_Server` EC2's. To connect, we will need the .pem file that was downloaded to your local computer when you first created the `Application_Server` EC2 and it's associated Key Pair.

- **How:** There is a method to copy the key directly from your local machine to the `Web_Server`...That I will show you next time! For now, navigate to the `~/.ssh` in your `Web_Server` EC2, and nano a new file called `App_Server_Key.pem`. Then, locate the .pem file you saved when you created the `Application_Server`, open it with your word proccessor of choice, and copy the **full** contents of that .pem file, including the beginning and ending RSA lines. Then, navigate back to your `Web_Server` and paste the contents into the App_Server_Key.pem. This key now holds the .pem key that pairs to the .pub key already in the `Application_Server`, and you can use the following command to SSH into the `Application_Server`: `ssh -i App_Server_Key.pem ubuntu@<your_App_Server's_Private_IP>`. Note that we are using the Private IP here because the Application and Web Servers are in the same VPC, and thus are able to communicate to one another via their Private IP's. No need for VPC Peering just yet! 
---
### Create Gunicorn Daemon

- **Why**: Now that we are connected to the `Application_Server`, we will create a Gunicorn daemon. We did so in the previous Workload, and we will do so again for the same reason: to ensure the Microblog app runs as a service and automatically starts on boot. This helps manage the app's lifecycle, ensuring that Gunicorn starts, stops, and restarts as needed without manual intervention. We have not installed gunicorn unto the `Application_Server` yet, but we need the Gunicorn daemon first because we will clone the GitHub Repository with the source code, install all needed programs and dependencies, and run the Flask application all in one script during the next step. 
  
- **Where**: The Gunicorn service file will be created in the `/etc/systemd/system/` directory on the Application Server EC2. This is where system-level services are managed on Linux systems.

Below is the configuration for the Gunicorn daemon:
  
```bash
[Unit]
Description=Gunicorn instance to serve my application
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/microblog_VPC_deployment
Environment="FLASK_APP=microblog.py"
ExecStart=/home/ubuntu/microblog_VPC_deployment/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 microblog:app
Restart=always

[Install]
WantedBy=multi-user.target
```

	One notable difference between this Gunicorn daemon and the last one we used is the IP allowed to communicate to Gunicorn via it's binding port. Before, we bound Gunicorn to `127.0.0.1:5000`, with the IP portion allowing request traffic from within the same EC2 instance. Since NGINX is on a different EC2 in this Workload, we must use an IP that exposes traffic from other IPs in the VPC. Since we only have one instance that hosts NGINX, and our Application EC2 is secure in our Private Subnet, we can safely expose Gunicorn to all IP's in the VPC in order for NGINX to properly serve it requests.

---
### Create the `start_app.sh`
- **Why:** The purpose of this workload is to truly automate the deployment of the Microblog Application. As such, we will create a script that does just that! This script will update and upgrade all the packages on the EC2, install python3.9 and it's dependencies, clone the App source code repository (and delete the old repository and reclone it upon successive runs), create the venv within the App directory and install all required dependencies for the Application to function, and then restart the Gunicorn system to ensure it is serving our Flask application in the background. 

 - **How:** Run `nano start_app.sh` in the home directory of the `Application_Server` EC2 and copy and paste the following script into it:

```bash
#!/bin/bash

sudo apt update -y
sudo apt upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -y
sudo apt install -y python3.9 python3.9-venv python3-pip

repo_dir="microblog_VPC_deployment"
repo_url="https://github.com/tortiz7/microblog_VPC_deployment.git"

if [ -d "$repo_dir" ]; then
        rm -rf "$repo_dir"
fi

git clone "$repo_url"
cd $repo_dir

python3.9 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install gunicorn pymysql cryptography
FLASK_APP=microblog.py
flask translate compile
flask db upgrade
sudo systemctl restart gunicorn
```

	This powerful script has everything you need to launch the Microblog application from any EC2 you provision (provided you create the Gunicorn daemon first). Ensure the Microblog Application is now up and running by copying and pasting the Public IP of your `Web_Server` EC2 into your browser's address bar. Success?

---
### Create the `setup.sh` Script
- **Why:** If your Microblog Application successfully launched, than you are ready to move onto the next step of truly automating this deployment! Go back to your 'Web_Server' EC2 instance and run 'cd ~ && nano setup.sh'. This script, when run, will SSH into the `Application_Server` EC2 and run the `start_app.sh` script we just created.

- **How:** Copy and paste the following into the file you just created:

```bash
#!/bin/bash

ssh -i ~/.ssh/app_server_key.pem ubuntu@<your_App_Server_Private_IP> 'source start_app.sh'
```

	Two things of note with this one-line script: the use of source to run the script, rather than ./ like we normally would, and the wrapping of the command in single quotations. First, the latter - we wrap the command in single quotations to ensure that it is treated as a single command by the shell environment that it is executed in (in this case, the `Application_Server`). If we don't wrap the command in the single quotes, than the shell that we are running the `setup.sh` script in (the `Web_Server`) will attempt to run the command, even after SSH'ing into the `Application_Server` - you will receive a "No File" error upon returning to the `Web_Server`. We use `source' to execute the `start_app.sh` script to ensure that the changes made to the `Application_Server` by the script persist after the script is finished. This is important because the script sets an environment variable (`FLASK_APP=microblog.py`) that we need to persist in order for the Microblog app to function correctly. 

---
### Time for VPC Peering!

- **Why:** Alright, the moment you've been waiting for - let's peer these VPC's! In the next step, we'll be creating our Jenkins Pipeline by editing the Jenkinsfile. However, before we can do that, we must peer the default VPC Jenkins belongs to and the custom VPC that houses the other EC2's necessary to deploy our application. The VPC peering will allow the EC2's in different VPC's to communicate with each other via their Private IP's - necessary for the Jenkinsfile, and proper monitoring of the `Application_Server` EC2 (more on that later). 

- **How:**
**Create the VPC Peering Connection:**
  1. Navigate to the VPC Dashboard and select "Peering Connections" from the left hand menu
  2. Click "Create Peering Connection"
  3. Select the Default VPC (the one Jenkins and the Monitoring EC2 belong to) as the "Request Connection"
  4. Select the Custom VPC (the one housing the other EC2's) as the "Accepter VPC"
  5. Name it something catchy you'll remember!
  6. Go to the "Peering Connections" tab, click on your new connection, and press "Action < Accept Request"
  7. Now navigate to the "Route Tables" tab and select the Route ID for your Public Subnet in the Custom VPC
  8. Click the "Routes" tab, and then "Edit Routes"
  9. Add a new route in the following page, copy the CIDR Block for your Default VPC and enter it as the 
  "Destination", select "Peering Connection" as the Target, and then choose your Peering Connection from the 
  field dropbox below it.
 10. Go back to "Route Tables" Tab and do the same thing for your Private Subnet (this is for the `Monitoring` EC2)
 11. Go back to "Route Tables" and this time select your Default VPC
 12. Follow the steps to Edit the routes for the Public Subnet and associate the Peering Connection, only this time 
using the CIDR Block for your Custom VPC in the "Destinations" column

	Viola! You can now SSH from your `Jenkins` EC2 into your `Web` EC2 using the Web's Private IP instead of it's Public IP. I'll explain why as we go over the Jenkinsfile configuration. Before we do that, though, we'll need to address another matter.

---
### Another Keygen?!

- **Why:** Yes! Another `ssh keygen`! Only this time, as the Jenkins user! Why? Because when we commence the Jenkins Pipeline via the Jenkins UI, Jenkins performs all the steps mandated by the Jenkinsfile on the `Jenkins` EC2 as the Jenkins user. Our previous Workload had to make allowances for the Jenkins user - in order to run a vital Sudo command during the 'Deploy Stage` of the Jenkinsfile, we had to add the Jenkins user to the `Sudoers` group. The same rule applies here - we have to ensure Jenkins has the proper permissions to deploy the application

- **How:** If you haven't figured out the dillema here yet - the Jenkins user **is not authorized** to use the `.pem` we created during the inital `ssh keygen` command that was executed to allow us to SSH from `Jenkins` into `Web_Server`. It's not as simple as giving the Jenkins user permissions to use the current `.pem` file we have, as the Key must also be in a particular directory in order for the Jenkins user to access it while running the Jenkinsfile (you'll see where when you inspect my Jenkinsfile). Therefore, it is simplier to do the following:

1. Ensure you are connected to the `Jenkins` EC2
2. run the following to become the Jenkins User: `sudo -u jenkins -i`
3. Once you are Jenkins (the commandline will display so where `ubuntu` used to be) run: `ssh keygen`
4. Save the key with a name you will remember is for accessing the `Web_Server` as Jenkins
5. Nano into the `.pub` key that was created and copy it's contents
6. Connect to your `Web_Server` EC2, run `cd ~/.ssh && nano authorized_keys` and paste the contents into the file
7. Test SSH'ing into the `Web_Server EC2` as the Jenkins user by running the following:
`ssh -i <Your_Jenkins_Web_Server_Key.pem ubuntu@<Your_Web_Server_Private_IP>'

If it worked, then you are ready to configure the Jenkins Pipeline!

---
### Configure Jenkins Pipeline
- **Why**: The Jenkins pipeline builds the application, tests it's logic to ensure no errors, and deploys the Microblog application to the web for us. Just like the previous workload, a `Clean Stage` is implemented to clean stale Gunicorn proccesses, and the `OWASP Dependency Check` scans our third-party libraries and dependencies (such as our Python packages) against the National Vulnerability Database, generating a report that informs us what packages might be at risk and allowing us update or replace them before an issue can arise. The biggest difference between this Jenkinsfile and the one for the previous workload is the `Deploy Stage` - unlike that one, Jenkins is not deploying the application itself; it will SSH into the `Web_Server` EC2 and run the `setup.sh` script that's in the home directory there, which will cause the `Web_Server` to SSH into the `Application_Server` EC2 and run the `start_app.sh` script, which will actually deploy the Microblog Flask Application. This, my friend, is automation!
  
- **How**: Note that you will need to log into Jenkins (<Public_IP_of_Jenkins_Server:8080> in address bar) and add the OWASP Plugin by navigating to "Manage Jenkins < Available Plugins < Search 'OWASP' < Select 'OWASP Dependency Check'". This time around, we downloaded an API Key from the NVD website (https://nvd.nist.gov/developers/request-an-api-key), added that into our Jenkins Credentials Manager, and then referenced it in our `OWASP Scan` stage to speed up the OWASP scan. The Jenkinsfile should be configured as such:

**Build Stage**: Creates virtual environment, installs dependencies, runs migrations, and compiles translations.

**Test Stage**: Configures Pytest to run [the same pytest as WL3](tests/unit/test_app.py) 

**Clean Stage**: Stops running Gunicorn instances before each new deploy.

**OWASP Dependency Check**: Adds the OWASP plugin to check for known vulnerabilities.

**Deploy Stage**: Deploys the app by starting the chain of scripts that automates the deployment, outlined above

	[You can view the Jenkinsfile here to see the Deployment command and other aspects of the pipeline](/Jenkinsfile)
Note the use of source and quotation wraparounds in the `Deploy` command, for the same reasons we used them when SSH'ing into the `Application Server` and running the `start_app.sh` script. This time, it's not an environment variable we need to persist, but rather the SSH session!

	Now the moment of truth: input your 'Web_Server' Public IP into your browser's address bar and hit Enter. Is the Microblog Application running? If so, then good job! You've automated the deployment of this application. But the jobs not done yet...

---
### Install Prometheus and Grafana on the Monitoring EC2

- **Why**: Did you forget about the `Monitoring` EC2? Prometheus and Grafana are critical for monitoring the health and performance of servers. Prometheus will scrape system metrics from the `Application_Server` EC2, and Grafana will visualize those metrics for easier analysis. Monitoring helps identify performance bottlenecks, resource usage trends, and potential system failures before they impact the app.

- **How**:

**1. Install Prometheus**:
```bash
sudo apt update
sudo apt install -y wget tar
wget https://github.com/prometheus/prometheus/releases/download/v2.36.0/prometheus-2.36.0.linux-amd64.tar.gz
tar -xvzf prometheus-2.36.0.linux-amd64.tar.gz
sudo mv prometheus-2.36.0.linux-amd64 /usr/local/prometheus
```

**2. Create a service daemon for Prometheus**:
To ensure Prometheus starts automatically:
```bash
sudo nano /etc/systemd/system/prometheus.service
```
Add the following to the file:
```bash
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/prometheus/prometheus \
--config.file=/usr/local/prometheus/prometheus.yml \
--storage.tsdb.path=/usr/local/prometheus/data
Restart=always

[Install]
WantedBy=multi-user.target
```
**3. Start and enable the service:**
```bash
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

**4. Install Grafana**:
Add the Grafana APT repository:
```bash
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add
sudo apt update
sudo apt install -y grafana
```
**5. Start and enable Grafana:**
```bash
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
```
  
---
### Install Node Exporter on the Application_Server EC2

- **Why**: Node Exporter is a Prometheus exporter that collects system-level metrics such as CPU, memory, and disk usage from the `Application_Server` EC2. This is essential for monitoring system health and resource usage on the server that is running our Microblog Flask Application.

- **How**:
  
**1. Install Node Exporter**:
  
```bash
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
sudo mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
```
**2. Create a service daemon for Node Exporter**:

```bash
sudo nano /etc/systemd/system/node_exporter.service
```
Add the following to the file:
```bash
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target

```
**3. Start and enable the Node Exporter service:**

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

---
### Configure Prometheus to Scrape Metrics from Application_Server EC2

- **Why**: Prometheus scrapes system metrics from the 'Application_Server' EC2 (through Node Exporter) for monitoring purposes. The `prometheus.yml` file needs to be updated to include the private IP of the 'Application_Server' EC2 as a target to ensure Prometheus pulls data from it. By default, Node Exporter exposes metrics on Port 9100, hence why we had to add an Inbound Rule to our 'Application_Server' EC2 security group to allow traffic on Port 9100. Without this rule in place, Prometheus would be unable to collect the metrics exposed by Node Exporter. This is also why we needed to enable VPC Peering for our VPCs and add the Peering Connection to the Private Subnet Route Table - without that step, the `Monitoring` EC2 would be unable to communicate to the Private IP of our `Application_Server` EC2. 

- **How**:
  
**1. Edit the `prometheus.yml` file**:

```bash
sudo nano /usr/local/prometheus/prometheus.yml
```

Add the following section under `scrape_configs` to target the 'Application_Server' EC2:
```bash
scrape_configs:
         - job_name: 'jenkins'
           static_configs:
             - targets: ['<Pivate_IP_of_App_Server_EC2>:9100']
```
**2. Restart Prometheus to apply the changes:**

```bash
sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

---
### Add Prometheus as a Data Source in Grafana and Create Dashboards

- **Why**: Once Prometheus is scraping metrics, Grafana provides a user-friendly way to visualize the data. Creating a dashboard with graphs of system metrics (like CPU usage, memory usage, etc.) enables easy monitoring and helps track the health of the 'Application_Server' EC2 in real time. This ensures that 'Application_Server' operates smoothly and that any issues are quickly identified before they impact the application's performance or availability.

- **How**:
  
**1. Add Prometheus as a data source in Grafana**:
  - Open Grafana in the browser: `http://<App_Server_Public_IP>:3000`
  - Login with default credentials (`admin/admin`).
  - Navigate to **Configuration > Data Sources**, click **Add data source**, and select **Prometheus**.
  - In the **URL** field, enter: `http://localhost:9090` (since Prometheus is running locally on the Monitoring EC2).
  - Click **Save & Test**.

**2. Create a dashboard with relevant graphs**:
  - Go to **Dashboards > New Dashboard**.
  - Select **Add new panel**, and choose **Prometheus** as the data source.
  - Select "Import a Dashboard" and download this: https://grafana.com/grafana/dashboards/1860-node-exporter-full/
  - Drag the downloaded dashboard to the dropbox for Importing Dashboards
  - Save the dashboard with an appropriate name (e.g., **Application Server Monitoring**).

---
## SYSTEM DESIGN DIAGRAM

[The System Architecture Diagram for the Microblog Application can be found here](/diagram.jpg)

---
## ISSUES/TROUBLESHOOTING

	Most of the issues I ran into while building the infrastructure for this workload and deploying the Microblog Flask Application via Jenkins were documented above, as I went through the steps where the issues were confronted. This section will serve as a quick roundup of all those issues, so you can avoid them!

### Issue: Gunicorn IP and Port Binding
- **Problem**: As I mentioned above in the **Create Gunicorn Daemon** step, the IP/Port binding configuration for every Flask app deployment we've done so far has been 127.0.0.1:5000 - meaning Gunicorn listens to requests routed from an NGINX port **on the local EC2**. This posed an issue with this Workload, because for the first time NGINX and Gunicorn were not installed on the same EC2 - there is a separate `Web_Server` EC2 that serves to route requests to the `Application_Server`EC2 where the Gunicorn and the source code for the Flask application resides. 
  
- **Solution**: The solution, also stated in that step, is to use the `0.0.0.0:5000` as the IP/Port binding configuration. This allows Gunicorn to listen to incoming requests from any IP associated with infrastrucre within the same VPC as our `Application_Server`, allowing NGINX to properly route HTTP requests to Gunicorn. 

---
### Issue: Using `source` to run scripts
- **Problem**: This workload is the first time I've encountered the need to use `source` to run a script, rather than `./script_name.sh` or using appending `bash` to the beginning of the command. The concept reinforced my understanding of what is happening on the system level when you run a script - without `source`, the script creates a subprocess, where the script is executed and any variables created or changed are contained solely within the subprocess that was created when the script was executed. `source` runs the script in the main process, or main shell, not a subshell, so it can effect the current shells environment, with variables and changes persisting after the execution of the script. When I ran the `setup.sh` script without sourcing it on the `Web_Server` EC2, for instance, than the SSH session that establishes connection into the `Application_Server` would not persist past the execution of the script. We also needed to wrap the `source start_app.sh` command found within that scrip in single quotations for a similar reason - which I explained in the **Create the `setup.sh` Script** step. 
  
- **Solution**: `Source` was needed to keep environment changes persistent in our main shell on two occassions in automating this deployment: Jenkins had to SSH into the `Web_Server` EC2 and use `source setup.sh` to execute that script in order for the SSH session established in that script to persist, and the `setup.sh` script uses `source` to execute the `start_app.sh` script in order to ensure the environment variable persists in the main shell of the `Application_Serve` EC2 after it is run. This is as good a place as any to reveal - we didn't necessarily need the Gunicorn daemon in this workload. We could have simply used `gunicorn -b 0.0.0.0:5000 -w 4 microblog:app &` to deploy the app in our `start_app.sh` script, as it would ensure Gunicorn binds to the proper port and serves our Flask app in the background (`&` takes care of the 'running in background' part). Since Jenkins isn't executing the command - it's instead starting the chain of scripts that will execute the command - it would not have forced the Gunicorn program to stop running upon completion of the Pipeline. What can I say - I like creating daemons!

---
### Issue: Jenkins Pipeline Failing at `Test` Stage
- **Problem**: My Jenkins Pipeline kept failing at the `Test` Stage, and I for the life of me could not figure out while. It's the same exact `test_app.py` script that worked for the Workload 3 deployment, so why would it not work now?

- **Solution**: The source code for this Microblog Flask Application looked exactly the same as the source code that was provided for Workload 3, so I did not go snooping through all the files and folders to confirm this. This was a big mistake! Missing from the `requirements.txt` file in the source code for Workload 4 was the `pytest` testing framework, necessary for executing the pytest command that allows the terminal (and Jenkins) to properly run the tests in `test_app.py`. Don't worry! I've added it back into the `requirements.txt` file, so your Jenkins will be able to run the test script just fine. Lesson learned - always check the files and folders of a given project repo before setting out to build and deploy the application!

---
### Issue: Jenkins Pipeline Failing at `Deploy` Stage
- **Problem**: As referenced in the **Another Keygen?!** steps, Jenkins (the user profile on the `Jenkins` EC2, not the program) was unable to use the key that I had generated at the beginning of the project to allow myself (the `ubuntu` user) to SSH into the `Web_Server` EC2. I tried to give the Jenkins user ownership to use the key by running `sudo chown jenkins:jenkins name_of_key.pem`, but this would take away ownership away from my own `ubuntu` user (unless I created a group they both belonged to and gave that group ownership, which I did not want to do). 
  
- **Solution**: As I stated in that same step I referred to above, the solution I decided on was to create a new key pair **specifically for the Jenkins user to use in the Deploy stage**. This allowed both the `ubuntu` and `jenkins` users to have a means of SSH'ing into the `Web_Server`. Note that the `jenkins` user has a different home than the `ubuntu` user, and thus also has a different `.ssh` directory as well. The .pem key needed for SSH'ing from the `jenkins` user needs to be in the following path to be usable: `/var/lib/jenkins/.ssh`.

---
## Using Private Instead of Public IP for Communication 
- **Problem:** There are two instances in this Workload where EC2 Instances in the Default VPC (`Jenkins` and `Monitoring`) had to communicate with instances in the Custom VPC (`Web_Server` and `Application_Server`). It was clear to me from the beginning that we would need to implement VPC Peering for the `Monitoring` EC2 to scrape metrics from the `Application_Server`, since that EC2 was housed in a Private Subnet and therefore did not have a Public IP to set as the Target in the `promtheus.yml` file. But we should be able to just use the Public IP for the `Web_Server` to establish the SSH connection between it and `Jenkins` in the final `Deploy` Stage of our Jenkins Pipeline, right?

- **Solution:** Wrong! To save money, our EC2's do not have Elastic IP's - meaning that whenever the EC2 is stopped and restarted, it is assigned a new Public IP. So if you were using the `Web_Server` EC2's Public IP for that `Deploy` stage SSH command, then you would need to update the Jenkinsfile **every single time the EC2 is stopped and restarted**, otherwise the `Deploy` stage would fail and your Microblog Flask Application will not work. There are ways to write a script that would pull the Public IP of an Instance, if you had the `AWS CLI` installed on your EC2, but those are cumbersome, and more work than needed for this particular EC2. VPC Peering allows us to use the Private IP's of EC2's in different VPC's instead of having to finangle for the Public IP's. Don't forget to add the Peering Connection to **both** the Public and Private Subnet tables, since we will need to be able to use the Private IP from the EC2's from both Publci and Private Subnets in our Custom VPC. 

---  
### OPTIMIZATION

**Advantages of Separating Deployment and Production Environments**

1. **Risk Mitigation:** Isolating deployment from production significantly reduces the risk of errors affecting users, allowing us to comprehensively test and validate new features before they go live.

2. **Improved Testing:** A dedicated deployment environment facilitates testing in conditions similar to production without impacting actual users, helping us identify issues early in development.

3. **Faster Rollbacks:** Having distinct environments allows for quick rollbacks to stable versions in case of deployment failures, minimizing user disruption. Out `start_app.sh` script, for instance, will always pull the latest build of the source code from this GitHub Repo, allowing us to tweak the code or revert to and older commit whenever necessary/ 

4. **Resource Management:** Tailoring resource allocation for different environments ensures optimal performance and cost-effectiveness. We took advantage of this when provisioning our EC2's - only the `Application_Server` is hosted on the more-expensed t3.medium tier, while the others are hosted on t3.micros.

**Infrastructure Addressing Concerns**

The infrastructure we've created for this workload effectively addresses these concerns through:

- **Dedicated EC2 Instances:** Separate instances for Jenkins and the application, web and monitoring servers prevent deployment activities from interfering with production operations, ensuring stability for end users.
  
- **Version Control and CI/CD Pipeline:** Implementing a Jenkins pipeline allows for controlled deployments, ensuring that only thoroughly tested and approved code reaches the production environment.

- **Monitoring Tools:** Integration of monitoring solutions like Prometheus and Grafana provides real-time insights into the production environment, enabling swift issue identification and resolution.

**Good System Evaluation**

	The infrastructure we've provisioned in this project can be considered a "good system" as it follows best practices for separation of concerns, implements CI/CD for automated deployments, and incorporates monitoring for proactive issue management. However, there are areas where we can make enhancements.

**Optimization Suggestions**

1. **Implement Blue-Green Deployment:** Adopting a blue-green deployment strategy allows for seamless transitions between versions of applications with minimal downtime. This method can provide a backup (the "blue" environment) to revert to if issues occur in the live (the "green" environment). In the context of this project, it would mean having two `Application_Servers`, one always ready to go should the other fail. It would incur more costs, but would increase our fault tolerance significantly.

2. **Utilize AWS Fargate for Containerization:** Transitioning to a containerized approach using AWS Fargate can significantly enhance flexibility and scalability. Fargate allows applications to run in containers without having to manage the underlying infrastructure, making it easier to implement a microservices architecture. This would enable individual components of the application to be updated or scaled independently. Our start_app.sh script is already designed with containerization in mind—it can turn any server into the Application_Server, as long as the Jenkinsfile is properly configured to support container orchestration.

3. **Centralized Logging with AWS CloudWatch:** Implementing a centralized logging solution using AWS CloudWatch Logs to aggregate logs from all services and environments would provide us with a single point of access for troubleshooting and monitoring application performance across all our environments.

4. **Optimize Security Groups:** While Workload 4 already necessitates us creating four security groups, we can stand to ensure that they are configured to use the principle of least privilege. All security groups should be egularly audited and refined to ensure only necessary traffic is allowed, and implementing AWS WAF (Web Application Firewall) would give us additional protection against common web exploits.

	By implementing these optimizations, our cloud infrastructure ecosystem can achieve improved resilience, scalability, and security, ensuring a robust deployment and production environment capable of adapting to changing demands while maintaining high availability for our users.

---
### CONCLUSION

	Workload 4 ably builds upon the workloads we've deployed before, successfully demonstrating the deployment and management of a multi-tier architecture for our Microblog Flask Application. Through the creation of dedicated EC2 instances for deployment, production, and monitoring, we ensured minimal disruption during updates and established a streamlined CI/CD pipeline using Jenkins for efficient code integration and testing.

Throughout the Workload, we learned the importance of separating environments to mitigate risks, as well as the advantages of utilizing monitoring tools like Prometheus and Grafana to maintain system health. Additionally, the integration of security best practices and a structured approach to resource management has contributed to a more resilient and scalable infrastructure.

Looking ahead, the suggested optimizations, such as adopting containerization with AWS Fargate, implementing blue-green deployments, and enhancing security protocols, will further strengthen the infrastructure's capabilities, allowing it to adapt to evolving user demands while ensuring high availability and performance. This Workload serves as a valuable foundation for future developments and improvements, paving the way for a robust cloud-based application environment.

---
## Documentation

**Successful Jenkins Build Pipeline**

![WL4 Pipeline Overview](https://github.com/user-attachments/assets/71e9a28e-4047-44e4-803a-454ebff5cd80)


**Grafana Visualization of Application_Server EC2 Metrics**

![WL4 Grafana Dashboard](https://github.com/user-attachments/assets/67bf3370-09fc-470e-b6d9-f9ea5c751d38)

**Grafana Visualization of Application_Server EC2 Metrics During Deployment**

![WL4 Grafana Dashboard Max](https://github.com/user-attachments/assets/ace7f0a5-8dc5-46c7-88e1-479d64936ef7)

**Prometheus Targets Online**

![WL4 Prometheus Targets Up](https://github.com/user-attachments/assets/c0a7652d-50b4-4db7-b2d2-3279bd05314a)

**Microblog Login page**

![image](https://github.com/user-attachments/assets/3479abdf-e2a3-474a-849c-8b5829b5112b)

**Successful OWASP Dependency Check**

![WL4 OWASP Passed](https://github.com/user-attachments/assets/8411bdc2-3ccc-40d6-85b5-6ed6bfd1b891)

**Successful Pytest**

![WL4 Test Passed](https://github.com/user-attachments/assets/dfa6e829-b0c4-4139-a47d-2baa49b675be)

