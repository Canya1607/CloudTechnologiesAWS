#!/bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
systemctl enable apache2.service
systemctl start apache2.service
