#!/bin/bash

# Define variables
MYSQL_ROOT_PASSWORD='root'
DB_NAME='petclinic'
DB_USER='petclinic'
DB_PASSWORD='petclinic'

# Update the package index
sudo apt-get update

# Install MySQL and set root password
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
sudo apt-get -y install mysql-server

# Start MySQL service
sudo systemctl start mysql

# Secure the MySQL installation
sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

# Create new database and user
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE $DB_NAME;
EOF
