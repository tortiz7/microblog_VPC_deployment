#!/bin/bash

ssh -i ~/.ssh/app_server_key.pem ubuntu@10.0.2.226 'source start_app.sh'
