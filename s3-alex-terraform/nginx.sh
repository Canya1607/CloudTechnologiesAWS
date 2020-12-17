#!/bin/bash

sudo apt install -y nginx

sudo echo "
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, 
    Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>This is my page number 2 </p>
</body>
</html>
" > /var/www/html/index.nginx-debian.html 

sudo service nginx restart