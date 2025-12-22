#!/bin/bash
yum update -y
yum install -y tomcat
systemctl start tomcat
systemctl enable tomcat
echo "Hello from Terraform" > /var/lib/tomcat/webapps/ROOT/index.html

aws s3 cp /var/log/messages s3://${bucket_name}/$(hostname)-messages.log