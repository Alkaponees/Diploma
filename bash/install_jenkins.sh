#!/bin/bash

# Update the package list
sudo apt-get update

# Install Java Development Kit (JDK)
sudo apt-get install -y default-jdk

# Add the Jenkins repository key
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg

# Add the Jenkins repository to the system
sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Update the package list to include Jenkins
sudo apt-get update

# Install Jenkins
sudo apt-get install -y jenkins

# Start the Jenkins service
sudo systemctl start jenkins

# Enable the Jenkins service to start on system startup
sudo systemctl enable jenkins
