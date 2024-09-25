# Microblog Deployment on Self-Provisioned VPC, Infrastructure and Monitoring

---
### Purpose

The purpose of this project is to deploy a Microblog Flask application on self-built infrastructure using AWS EC2 instances. Through this workload, we explored various concepts related to cloud infrastructure, Continuous Integration/Continuous Deployment (CI/CD), and application monitoring. By configuring and managing our own servers, we strengthened our skills in system administration, security group management, and application deployment.

This project emphasizes hands-on experience with tools such as Jenkins for automation, Prometheus for monitoring, and Grafana for visualization. Additionally, we learned to troubleshoot and optimize our setup, ensuring that our application operates efficiently and is resilient against potential issues. Overall, this workload provides a comprehensive understanding of how to create and manage a robust application infrastructure from the ground up.

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
    5. Choose 1 AZ zone for this project. You can customize it's region, or leave it at the default setting (mine is in US-east-2a [N. Virginia])
    6. Select 1 Public and Private Subnet each under their respective menus
    7. Select 1 NAT Gateway for your AZ - note that this will cost you money as long as it is active and reachable!
    8. Leave DNS hostnames and resolution enabled under the "DNS Options" setting - this will allow your publicly accessible EC2's to be reached via their Public IP's
    9. Create the VPC!
    10. Now, go back to the VPC service homepage and select Subnets < your Public Subnet < Actions < Edit Subnet Settings < Enable auto-assign public IPv4 addresses. This will give your EC2's in this subnet a Public IP 
        so they can be reachable from the internet.

**Create EC2 Instances and AWS Access Keys**
- **Why**: Similarly to Workload 3, will we be provisioning various EC2 instances, and thus will need an AWS Access Key in order to SSH into these EC2s. For this project, we will be provisioning 4 EC2s in specific VPCs 
  and subnets. THis will allow us to better manage permissions and security groups for the EC2s that are specifically aligned with their purpose in our infrastructure ecosystem. 
  
- **How:**
- **Create the AWS Access Key:**
    1. Navigate to the AWS service: IAM (search for this in the AWS console)
    2. Click on "Users" on the left side navigation panel
    3. Click on your User Name
    4. Underneath the "Summary" section, click on the "Security credentials" tab
    5. Scroll down to "Access keys" and click on "Create access key"
    6. Select the appropriate "use case", and then click "Next" and then "Create access key"

The Access and Secret Access keys are needed for future steps, so safe storage of them is vital to a successful automated CI/CD pipeline. **Never** share your access keys, as a bad actor can get a hold of them and use the keys to access your server, wreaking havoc, compromising data integrity and potentially stealing sensitive information.

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
5. In "Network Settings", select the VPC we configured in Step 1 for this EC2.
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
           
These four EC2s are named after their role within our infrastructure ecosystem. The **Jenkins** EC2 will house our Jenkins workspace where the build and testing will occur; The **Application Server** will host all our Applicatio Source code, and will be where our application is deployed from via a script; the **Web Server** will act as a bridge between our Jenkins and Application Server EC2s and will host the NGINX service that will proxy pass network traffic to our Application Server, which is inaccessible from the internet by itself; and our final EC2, **Monitoring**, will host the Prometheus and Grafana services, which will allow us to scrape vital metrics from the Application Server and visualize them in a helpful dashboard in Grafana, empowering us to take action when resources are taxed and perform pivotal maintenance on the Application Server when needed.

---
### Install Jenkins
- **Why**: Jenkins automates the build and deployment pipeline. It pulls code from GitHub, tests it, and handles deployment once the Jenkinsfile is configured to do so. The big difference with this Jenkins deployment compared to our previous Workloads is that Jenkins will be hosted on its own EC2, separate from the app source code. We will still need to install Python 3.9 and it's dependencies on this Jenkins EC2, however, because Jenkins will need those dependencies in order to build and test the app code's logic.  
  
- **How**: I created and ran the below script to install Jenkins, and it's language prerequisite Java (using Java 17 for this deployment). To save time, the script first updates and upgrades all packages included in the EC2, ensuring they are up-to-date and secure. The script also installs Python3.9 - the langauge our flask app relies on - and all the dependencies necessary for our application (Python3.9 venv and Python3.9-pip) - just as it did in the previous Workload; only difference is there will be no Nginx installation in this script, since Nginx will be installed on the `Web_Server` EC2. SSH into the Jenkins EC2, create a file for the Jenkins install script, and then copy and paste the below into it:

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

- **Why:** This workload will require us to SSH from one EC2 into another one, in order to make the deployment of our Microblog Flask Application truly automated. This will serve as our first test of SSH'ing from one server to the other.

- **How:** In order to SSH from the `Jenkins` server into the `Web_Server`, we will need to first create a new key pair. Run the `ssh-keygen ~/.ssh` command from the commandline in the `Jenkins` server to create a new keypair in your .ssh directory, name your key pair something that will remind you it is for accessing the `Web_Server`, and then save the downloaded .pem key somewhere safe. Nano into the .pub key that was just create, and copy all the contents within. Then, go back to your running EC2 instances and connect to the `Web_Server`. Once connected, run `cd .ssh` to get to the `.ssh` directory, than run `nano authorized_keys` and paste the contents of the .pub key into this file in a new line.

	Go back to the tab with your `Jenkins` EC2 instance terminal, and run the following command: `ssh -i <your_.pem_key_filename> ubuntu@<your_Web_Server's_Public_IP>`. Type yes when asked if you trust the host's identity to connect to the `Web_Server` EC2 and save it's unique "fingerprint" in the `known_hosts` folder in the `Jenkins` EC2s .ssh folder. Every subsequent SSH attempt to the `Web_Server` EC2 will check this fingerprint saved in the known_hosts folder and compare it with the fingerprint of the `Web_Server` so we know we're connecting to the correct server. This is an added security step that helps prevent "man-in-the-middle" attacks, wherein a bad actor attempts to impersonate a server in order to get your credentials. 

### Configure the NGINX Location block

- **Why:** NGINX is a reverse proxy server between the client browser and our Microblog application. It is a gatekeeper, managing incoming traffic to assist with load balancing in the case of scalability, strengthening security by validating SSL/TLS certificates for incoming HTTPS requests, and increasing performance by caching certain static content (images, JavaScript files) and forwarding all dynamic content to Gunicorn.

As noted in the Jenkins installation step, NGINX is installed on the `Web_server` EC2, and thus we must specifically configure the location block to route incoming HTTPS requests from NGINX Port 80 on the `Web_Server` to the Gunicorn Port 5000 on the `Application_Server`. The Location block below will show you how. 

- **How:** Since we are already SSH'd into the `Web_Server` EC2 from the `Jenkins` EC2, we can nano into the NGINX Configuration file at this location: `/etc/nginx/sites-enabled/default` and add the following to the Location block. Note that unlike the previous workload, the url for the proxy_pass **must use the Private IP of your Application Server** in order to route the necessary traffic to Gunicorn:
  
```bash
  location / {
proxy_pass http://<your_App_Server_Private_IP>:5000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}  
```
---
### SSH Into the Application_Server

- **Why:** Now, we will connect to the `Application_Server` EC2 for the first time. Since the 'Application_Server' resides in our Private Subnet, it does not have a Public IP associated with it - so we cannot connect to it from the AWS GUI like we would our `Jenkins` and `Web_Server` EC2. To connect, we will need the .pem file that was downloaded to your local computer when you first created the `Application_Server` EC2 and it's associated Key Pair.

- **How:** There is a method to copy the key directly from your local machine to the `Web_Server`...That I will show you next time! For now, navigate to the `~/.ssh` in your `Web_Server` EC2, and nano a new file called App_Server_Key.pem. Then, locate the .pem file you saved when you created the `Application_Server`, open it with your word proccessor of choice, and copy the **full** contents of that .pem file, including the beginning and ending RSA lines. Then, navigate back to your `Web_Server` and paste the contents into the App_Server_Key.pem. This key now holds the .pem key that pairs to the .pub key already in the `Application_Server`, and you can use the following command to SSH into the `Application_Server`: `ssh -i App_Server_Key.pem ubuntu@<your_App_Server's_Private_IP>`. Note that we are using the Private IP here because the Application and Web Servers are in the same VPC, and thus are able to communicate to one another via their Private IP's. No need for VPC Peering just yet! 
---
### Create Gunicorn Daemon

- **Why**: Now that we are connected to the `Application_Server`, we will create a Gunicorn daemon. We did so in the previous Workload, and we will do so again for the same reason: to ensure the Microblog app runs as a service and automatically starts on boot. This helps manage the app's lifecycle, ensuring that Gunicorn starts, stops, and restarts as needed without manual intervention. We have not installed gunicorn unto the `Application_Server` yet, but we need the Gunicorn daemon first because we will Clone the GitHub Repository with the source code, install all needed programs and dependencies, and run the Flask application all in one script during the next step. 
  
- **Where**: The Gunicorn service file will be created in the `/etc/systemd/system/` directory on the Applicatio Server EC2. This is where system-level services are managed on Linux systems.

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

Two things of note with this one-line script: the use of source to run the script, rather than ./ like we normally would, and the wrapping of the command in single quotations. First, the latter - we wrap the command in single quotations to ensure that it is treated as a single command by the shell environment that it is executed in (in this case, the `Application_Server`). If we don't wrap the command in the single quotes, than the shell that we are running the `setup.sh` script in (the `Web_Server`) will attempt to run the command, even after SSH'ing into the `Application_Server` - you will receive a "No File" error upon returning to the `Web_Server`. We use `source start_app.sh` to ensure that the changes made to the `Application_Server` by the script persist after the script is finished. This is important because the script sets an environment variable (`FLASK_APP=microblog.py`) that we need to persist in order for the Microblog app to function correctly. 

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

**Deploy Stage**: Deploys the app starting the chain of scripts that automates the deployment, outlined above

[You can view the Jenkinsfile here to see the Deployment command and other aspects of the pipeline](/Jenkinsfile)
Note the use of source and quotation wraparounds in the `Deploy` command, for the same reasons we used them when SSH'ing into the `Application Server` and running the `start_app.sh` script. This time, it's not an environment variable we need to persist, but rather the SSH session!

Now the moment of truth: input your 'Web_Server' Public IP into your browser's address bar and hit Enter. Is the Microblog Application running? If so, then good job! You've automated the deployment of this application. But the jobs not done yet...

---
### Install Prometheus and Grafana on the Monitoring EC2

- **Why**: Prometheus and Grafana are critical for monitoring the health and performance of servers. Prometheus scrapes system metrics from the Jenkins EC2, while Grafana visualizes those metrics for easier analysis. Monitoring helps identify performance bottlenecks, resource usage trends, and potential system failures before they impact the app.

- **How**: 
    1. **Install Prometheus**:
       ```bash
       sudo apt update
       sudo apt install -y wget tar
       wget https://github.com/prometheus/prometheus/releases/download/v2.36.0/prometheus-2.36.0.linux-amd64.tar.gz
       tar -xvzf prometheus-2.36.0.linux-amd64.tar.gz
       sudo mv prometheus-2.36.0.linux-amd64 /usr/local/prometheus
       ```
    2. **Create a service daemon for Prometheus**:
       - To ensure Prometheus starts automatically:
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
         ExecStart=/home/ubuntu/prometheus-2.54.1.linux-amd64/prometheus \
         --config.file=/home/ubuntu/prometheus-2.54.1.linux-amd64/prometheus.yml \
         --storage.tsdb.path=/home/ubuntu/prometheus-2.54.1.linux-amd64/data
         Restart=always

         [Install]
         WantedBy=multi-user.target
         ```
         - Start and enable the service:
           ```bash
           sudo systemctl daemon-reload
           sudo systemctl start prometheus
           sudo systemctl enable prometheus
           ```

    3. **Install Grafana**:
       - Add the Grafana APT repository:
         ```bash
         sudo apt install -y software-properties-common
         sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
         wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add
         sudo apt update
         sudo apt install -y grafana
         ```
       - Start and enable Grafana:
         ```bash
         sudo systemctl start grafana-server
         sudo systemctl enable grafana-server
	 ```
  
---
### Install Node Exporter on the Jenkins EC2

- **Why**: Node Exporter is a Prometheus exporter that collects system-level metrics such as CPU, memory, and disk usage from the Jenkins EC2. This is essential for monitoring system health and resource usage on the Jenkins server.

- **How**: 
    1. **Install Node Exporter**:
       ```bash
       wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
       tar xvfz node_exporter-1.3.1.linux-amd64.tar.gz
       sudo mv node_exporter-1.3.1.linux-amd64/node_exporter /usr/local/bin/
       ```
    2. **Create a service daemon for Node Exporter**:
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
       - Start and enable the Node Exporter service:
         ```bash
         sudo systemctl daemon-reload
         sudo systemctl start node_exporter
         sudo systemctl enable node_exporter
         ```

---
### Configure Prometheus to Scrape Metrics from Jenkins EC2

- **Why**: Prometheus scrapes system metrics from the Jenkins EC2 (through Node Exporter) for monitoring purposes. The `prometheus.yml` file needs to be updated to include the private IP of the Jenkins EC2 as a target to ensure Prometheus pulls data from it. By default, Node Exporter exposes metrics on Port 9100, hence why we had to add an Inbound Rule to our Jenkins EC2 security group to allow traffic on Port 9100. Without this rule in place, Prometheus would be unable to collect the metrics exposed by Node Exporter. 

- **How**:
    1. **Edit the `prometheus.yml` file**:
       ```bash
       sudo nano /usr/local/prometheus/prometheus.yml
       ```
       Add the following section under `scrape_configs` to target the Jenkins EC2:
       ```yaml
       scrape_configs:
         - job_name: 'jenkins'
           static_configs:
             - targets: ['<Pivate_IP_Of_Jenkins_EC2>:9100']
        ```
    2. **Restart Prometheus** to apply the changes:
       ```bash
       sudo systemctl restart prometheus
       ```

---
### Add Prometheus as a Data Source in Grafana and Create Dashboards

- **Why**: Once Prometheus is scraping metrics, Grafana provides a user-friendly way to visualize the data. Creating a dashboard with graphs of system metrics (like CPU usage, memory usage, etc.) enables easy monitoring and helps track the health of the Jenkins EC2 in real time. By visualizing metrics in Grafana, we can track system health and detect anomalies or resource exhaustion on the Jenkins EC2 in real time. This ensures that Jenkins operates smoothly and that any issues are quickly identified before they impact the application's performance or availability.

- **How**:
    1. **Add Prometheus as a data source in Grafana**:
       - Open Grafana in the browser: `http://<MONITORING_EC2_PUBLIC_IP>:3000`
       - Login with default credentials (`admin/admin`).
       - Navigate to **Configuration > Data Sources**, click **Add data source**, and select **Prometheus**.
       - In the **URL** field, enter: `http://localhost:9090` (since Prometheus is running locally on the Monitoring EC2).
       - Click **Save & Test**.

    2. **Create a dashboard with relevant graphs**:
       - Go to **Dashboards > New Dashboard**.
       - Select **Add new panel**, and choose **Prometheus** as the data source.
       - For each graph, write Prometheus queries like:
         - CPU Usage: `node_cpu_seconds_total`
         - Memory Usage: `node_memory_MemAvailable_bytes`
       - Save the dashboard with an appropriate name (e.g., **Jenkins Monitoring**).

---
## SYSTEM DESIGN DIAGRAM

[The System Architecture Diagram for the Microblog Application can be found here](/diagram.jpg)

---
## ISSUES/TROUBLESHOOTING

### Issue: Jenkins Build Fails Due to Virtual Environment
- **Problem**: Jenkins build failed during the `Build` stage with a `bad interpreter: permission denied` error. This presented a subtantial roadblock for me early in the workload's lifepsan, as I could not for the life of me figure out what the `bad interpreter: permission denied` was referring to. I tried removing and reinstalling Python and all it's dependencies, changing Jenkins ownership permissions of both the workload's source code directory and the project workspace created by Jenkins during the Build stage, and even terminated and rebuilt the EC2 twice to wipe away any additional issues I may have introduced with my myriad attempts at resolving the issue, to no avail. 
  
- **Solution**: After terminating and recreating the Jenkins EC2 for the third time, I took a step back, took my nose off the grindstone, and took stock. What could possibly be introducing the same problem in three different EC2's? The problem was with my GitHub repository. In my testing and launching of the Microblog Flask Application from the Jenkins EC2 Terminal prior to attempting the Jenkins build, I had created a `venv` in the Workload source code and inadvertently pushed that `venv` to GitHub, committing it to the repo. This conflicted with Jenkins attempts to create it's own `venv` in the workspace directory created during a Jenkins build, this leading to the `bad interpreter: permission denied` issue. The solution was to delete the venv directory from the GtitHub repo and exclude any future `venv` directory from version control (using `.gitignore`), thus ensuring Jenkins was able to create the virtual environment and install the necessary dependencies without conflict.

---
### Issue: PYTHONPATH Not Set for Jenkins Test Stage
- **Problem**: Another roadblock for me was ensuring Jenkins could successfully use pytest to test my `test_app.py` script and thus pass the `Test` stage. Jenkins was unable to run any of the tests in my test script because it kept running into a `Module not Found` error when beginning the test. My test script is in a separate directory from the application module (`microblog.py`), so python had to be told explicitly where to look for the application module. To accomplish this, the PYTHONPATH environment variable had to be set.
  
- **Solution**: I declared the `PYTHONPATH` variable in the Jenkinsfile's `Test` stage, directly before Jenkins activates the venv in it's workspace. Since the venv and the application module are in the same directory, I set the Python path as `PYTHONPATH="."`. This allowed the testing script to find and import the application module and run the tests, allowing the Jenkins build to move to the next stage of the jenkinsfile - where my biggest roadblock yet lied in wait!

---
### Issue: The Neverending OWASP Scan
- **Problem**: This workload was the first time I enocuntered the `OWASP Scan` in a Jenkisfile. I had to install it from the list of available plugins in the Jenkins UI, and configure it to check all of the dependencies the application needed to run. When running the Jenkins build, the `OWASP Scan` actually outputs a warning that the scan will take a long time, so I knew I had to exercise some patience with scan to allow it time to download the National Vulnerability Database in order to determine if any of our libraries or packages were out of date and thus posing a security risk. What I was not prepared for was the freezing, unresponsiveness and crashing that this would cause for my measly t3.micro EC2 instance. At the outset of the scan, Jenkins would show that it would take around 4 hours to complete, so I waited and hoped that the freezing I saw in my Jenkins UI and EC2 instance meant that the scan was still happening in the background, where I could not see it's progress. This was not the case.

- **Solution**: The OWASP scan required more memory than my t3.micro EC2 instance could allot it in order to complete the `OWASP Scan` stage, and the feezing would invaribly lead to a hard crash of the EC2 instance, and thus the Jenkins build, after hours of supposed progress. I would reboot the instance, log back into Jenkins, and attempt to restart the build at the OWASP Scan phase, to no avail - it would always crash before completion. The only solution was to upgrade the EC2 instance to a t3.medium, which more than tripled the available memory for the `OWASP Scan` to use, allowing the Scan stage to complete (and pass with flying colors!) in an hour and a half. Upgrading your EC2 instance is not a decision you should make likely - it will incur additional costs for your project, so you must make sure dependency and assured security for higher cost is a tradeoff you are willing to make before upgrading. 

---
### Issue: Handling Gunicorn in the Deploy Stage
- **Problem**: The Jenkins build and it's associated Jenkinsfile posed a number of challenges for me during this workload, much more than the previous two, and this was (thankfully) the final issue I grappled with. I erroneously used the same command I had used during my manual launch of the Microblog Flask application in the Jenkins EC2 terminal as the command to deploy the application in the Jenkinsfile: `gunicorn -b :5000 -w 4 microblog:app`. There are two issues with deploying the application with this command : 1) The Jenkins build will never end, because the gunicorn process is meant to listen in for any incoming requests, effectively running indefinitely. iF the process is not set to run in the background, then it will lock up the terminal, and thus lock up the Jenkins build. Appending an '&' at the end of the command will allow it to run in the background, but then the second issue occurs. 2) The Gunicorn process ends when the Jenkins build completes because Jenkins kills all processes used during the pipeline, and the Flask app is no longer served. Leading to a 502 NGINX error when you attempt to visit the website. So I had to find a new solution. Can you guess what it is? 
  
- **Solution**: The solution was already spoiled above, outlined in the steps portion: I had to create a Gunicorn daemon (a service file) to control the Gunicron process, turning it into a service that can be started alongsided the EC2. This allows us to use systemctl commands to control the service, such as starting it, stopping it, and checking it's status. For our Jenkinsfile, the most important command it gives us is `sudo systemctl restart gunicorn`. This restars the Gunicorn serivice upon ending the Jenkins build, allowing it to run indefinitely once Jenkins has completed the build stage. In conjunction with the solution, Jenkins must also be added as a Sudoer so it can execute sudo commands, which is necessary because service files exists in the root directory of Linux systems (in this case, the path is `/etc/systemd/system/`). By adding the `sudo systemctl restart gunicorn` command to our `Deployment` stage, we are finally able to deploy the Microblog Flask Application.

---
## Configuring Node Exporter as a Scrape Target 
- **Problem:** My final pain point with the deployment of the Microblog Flask Application and the set up of the Monitoring apparatus was with the configuration of Node Exporter as a target for Prometheus to scrape. I initially used my Jenkins EC2's Public IP as the target for the scrapping. The issue with this is that the PUblic IP changes every single time the EC2 is stopped and started again. I cannot leave the EC2 on indefinitely, so a solution had to be found.

- **Solution:** The solution was to use the Jenkins EC2's **Private IP** instead of the Public IP. The Private IP remains the same regardless of how many the times the EC2 is stopped and restarted. This dovetails perfectly with the lessons I have been learning about VPC's - since both of the EC2's exists within the smae VPC, they are able to communicate to eachother via their Private IP's, without needing internet access via their Public IP's to do so. We still need to configure an Inbound Rule for the Jenkins EC2 to allow Incoming Traffic over Port 9100 because the security group acts as a firewall, and even though internet factor does not factor in to the scrappin of metrics, Prometheus still needs to be allows to scrape the exposed metrics on Port 9100 by the firewall.

---  
### OPTIMIZATION

#### **Advantages of Provisioning Our Own Infrastructure**
**Why this is a "Good System"**
1. **Full Control Over Infrastructure**: Provisioning our own resources allows for granular control over every aspect of the infrastructure. From configuring the EC2 instances, installing services like Jenkins, Prometheus, and Grafana, to managing security groups and networking. This level of control offers flexibility, especially in troubleshooting and custom configuration that might not be possible with managed services like Elastic Beanstalk.
   
2. **Cost Efficiency**: By manually provisioning resources, you can optimize your spending. You can choose smaller instance types, manage start/stop schedules, and ensure you're only paying for what you actually need. With managed services, you're paying for convenience, but sometimes at a higher cost.

3. **Customization**: This system allows the integration of tools like Prometheus and Grafana for monitoring, a custom CI/CD pipeline using Jenkins, and the flexibility to adjust configurations as per the workload's unique requirements. Such customization might not be as easy or even possible with managed services.

4. **Enhanced Learning and Skill Development**: Building infrastructure from scratch strengthens fundamental DevOps skills, including cloud infrastructure management, networking, system monitoring, and CI/CD pipeline creation. This project provided hands-on experience with AWS, system architecture, monitoring, and deployment strategies.

---

#### **Disadvantages of Provisioning Our Own Infrastructure**
**Why this could be a "Bad System"**
1. **Increased Management Overhead**: Provisioning our own resources requires constant oversight. We must handle patching, updates, monitoring, and scaling on our own. This can lead to inefficiencies and missed opportunities for automated optimizations that managed services provide out-of-the-box.

2. **Scalability Concerns**: While we can scale manually by adding more instances or adjusting instance types, the lack of automatic scaling might lead to resource bottlenecks or underutilization during varying traffic loads. Elastic Beanstalk or other managed services provide auto-scaling, making it easier to handle fluctuating workloads without intervention.

3. **Risk of Misconfiguration**: As we manage all components ourselves, there is a higher chance of misconfigurations that could compromise security, stability, or performance. For example, improperly configured Security Groups or network permissions could expose the system to unnecessary risk.

4. **Time-Consuming Setup**: Deploying an entire infrastructure manually, including monitoring and CI/CD pipelines, takes significantly more time compared to using Elastic Beanstalk or a similar service where much of the setup is automated.

---

#### **How to Optimize the System to Address These Issues - Managed Services Edition**
1. **Introduce Automation**:
   - **Infrastructure as Code (IaC)**: We could tilize tools like **Terraform** or **AWS CloudFormation** to automate the provisioning of resources. This would reduce manual effort and ensure consistency across deployments.
   - **CI/CD Automation**: Further optimize the Jenkins pipeline by adding automatic triggers for scaling the infrastructure based on demand (e.g., leveraging AWS Lambda functions or CloudWatch Alarms to provision resources as needed).
   
2. **Auto-Scaling and Load Balancing**:
   - Incorporate **Auto Scaling Groups (ASGs)** and **Elastic Load Balancers (ELBs)** to ensure that the infrastructure can handle varying traffic loads dynamically. This would eliminate the need for manual scaling and reduce the risk of bottlenecks or downtime during traffic spikes.
   
3. **Security Best Practices**:
   - Implement more robust security practices, such as **AWS Secrets Manager** to handle sensitive data and **AWS Key Management Service (KMS)** to encrypt data in transit and at rest.
   - Audit the **Security Groups** and **IAM roles** to ensure the principle of least privilege is being followed.

4. **Monitoring and Alerting**:
   - While Prometheus and Grafana offer great monitoring, adding **AWS CloudWatch** or similar monitoring services could provide additional real-time insights and more automated alerting capabilities.
   - Set up custom **CloudWatch alarms** that can trigger based on resource utilization metrics or any performance anomalies detected through Prometheus.

5. **Consider Managed Services for Certain Components**:
   - For example, using a managed database service like **Amazon RDS** or **AWS Elasticache** can offload the management of database scaling, backups, and patching. Similarly, **AWS Fargate** or **Elastic Beanstalk** could handle scaling and deployment of the application without needing to manage EC2 instances directly.

---

### Additional Optimizations Without Full Reliance on Managed Services

1. **Use Docker Containers**: Containerizing the Microblog application with Docker can help streamline deployments and improve consistency across environments. Containers can be orchestrated with tools like **Docker Compose** or **Kubernetes** without fully relying on managed services.

2. **Caching Strategies**: Implement caching mechanisms using tools like **Redis** or **Memcached** to reduce load on the database and speed up response times without relying on managed caching services.

3. **Regular Backups**: Implement a backup strategy using tools like **rsync** or **cron jobs** to automate backups of application data and configurations, ensuring that you can restore quickly in case of failure without relying on managed backup solutions.

By implementing these optimizations, we would maintain the benefits of provisioning our own infrastructure while addressing many of the shortcomings that come with manual management.

## Conclusion

The successful deployment of the Microblog application on self-provisioned infrastructure marks a significant step in our understanding of cloud computing and application deployment. By leveraging EC2 instances, we not only gained hands-on experience with essential tools such as Jenkins, Prometheus, and Grafana, but we also explored the intricacies of managing our own infrastructure.

Throughout this project, we faced various challenges, from configuring security groups to optimizing build processes. Each issue encountered served as a learning opportunity, enhancing our problem-solving skills and deepening our knowledge of CI/CD pipelines.

By implementing a monitoring solution with Prometheus and Grafana, we ensured the reliability of our application, providing real-time insights into system performance. This project has demonstrated the importance of having a robust infrastructure, tailored to our specific needs, while also highlighting the advantages of understanding the underlying technologies rather than solely relying on managed services.

As we move forward, the skills and knowledge gained from this workload will be invaluable in our future endeavors in cloud computing and application development. We are now better equipped to tackle complex deployments and optimize system performance, laying a strong foundation for further exploration in the world of DevOps.


## Documentation

*****

**Inbound Rules for Jenkins & Monitoring Security Groups**

![image](https://github.com/user-attachments/assets/32a7c388-3ce9-44d0-9d9f-9c67ea5c87b4)

**Grafana Visualization of Jenkins EC2 Metrics**

![image](https://github.com/user-attachments/assets/9848df17-a3fe-4838-9de9-ed9ce9b0b36e)

**Microblog Login page**

![image](https://github.com/user-attachments/assets/3479abdf-e2a3-474a-849c-8b5829b5112b)

**Successful OWASP Dependency Check**

![image](https://github.com/user-attachments/assets/59b6ae5b-6d8f-41e8-a216-a752cab49bac)

**Successful Pytest**

![image](https://github.com/user-attachments/assets/df888839-c8eb-4f07-ba06-e2ac5fd0ac8b)
