pipeline {
  agent any 
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash             
	         python3.9 -m venv venv
                 source venv/bin/activate
                 pip install -r requirements.txt
		 pip install gunicorn pymysql crptography
		 FLASK_APP=microblog.py
		 flask translate compile
		 flask db upgrade
                '''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
		export PYTHONPATH=.
                pytest ./tests/unit/ --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
      stage ('OWASP FS SCAN') {
            steps {
                withCredentials([string(credentialsId: '126213e1-9cf1-4ad6-ae55-ad8db0edab3e', variable: 'NVD_API_KEY')]) {
                    dependencyCheck additionalArguments: "--scan ./ --disableYarnAudit --disableNodeAudit --apiKey ${NVD_API_KEY}", odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }
      stage ('Clean') {
            steps {
                sh '''#!/bin/bash
                if [[ $(ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2) != 0 ]]
                then
                 ps aux | grep -i "gunicorn" | tr -s " " | head -n 1 | cut -d " " -f 2 > pid.txt
                 kill $(cat pid.txt)
                exit 0
                fi
                '''
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
		ssh -i ~/.ssh/web_server_key.pem ubuntu@10.0.1.27 'source setup.sh'
                '''
            }
        }
    }
}
