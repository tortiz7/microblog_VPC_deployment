#!/bin/bash

sudo apt update -y
sudo apt upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update -y
sudo apt install -y python3.9 python3.9-venv python3-pip

repo_dir="microblog_VPC_deployment"
repo_url="https://github.com/tortiz7/microblog_VPC_deployment.git"

if [ -d "$repo_dir" ]; then
        echo "Removing existing repo directory..."
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
