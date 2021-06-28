#!/bin/bash

#update
sudo apt-get update

#isntall nginx, mysql and php
sudo apt-get install nginx mysql-server php-fpm php-mysql -y

#config php
sudo mkdir /var/www/wordpress
sudo chown -R $USER:$USER /var/www/your_domain

# ssl
## Create the SSL Certificate
sudo openssl req -x509 -nodes -subj "/CN=Sandbox/" -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
sudo openssl dhparam -out /etc/nginx/dhparam.pem 2048

## Create a Configuration Snippet
touch self-signed.config
cat<<EOT >> self-signed.conf
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOT
sudo mv self-signed.conf /etc/nginx/snippets/

## create configuration Snippet with strong encryption settings
touch ssl-params.conf
cat<<EOT >> ssl-params.conf
ssl_protocols TLSv1.2;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/nginx/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
ssl_session_timeout  10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off; # Requires nginx >= 1.5.9
ssl_stapling on; # Requires nginx >= 1.3.7
ssl_stapling_verify on; # Requires nginx => 1.3.7
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
EOT
sudo mv ssl-params.conf /etc/nginx/snippets/

## configuration file
touch wordpress
cat<<EOT > wordpress
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    server_name wp.josef.rack.gold;

    root /var/www/wordpress/;
    index index.html index.htm index.nginx-debian.html;

    location /hc {
        return 200;
    }
    location / {
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
     }
    location ~ /\.ht {
        deny all;
    }
    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; access_log off; allow all; }
    location ~* \.(css|gif|ico|jpeg|jpg|js|png)$ {
        expires max;
        log_not_found off;
    }
}
EOT
sudo mv -f wordpress /etc/nginx/sites-available/
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo unlink /etc/nginx/sites-enabled/default
sudo systemctl restart nginx

#logging and monitoring agents
curl -sSO https://dl.google.com/cloudagents/add-logging-agent-repo.sh
sudo bash add-logging-agent-repo.sh --also-install
curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
sudo bash add-monitoring-agent-repo.sh --also-install

#install wordpress
sudo apt install php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip -y
sudo systemctl restart php7.4-fpm
cd /tmp
curl -LO https://wordpress.org/latest.tar.gz
tar xzvf latest.tar.gz
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
sudo cp -a /tmp/wordpress/. /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress


#wordpress config file
touch wp-config.php
cat<<EOT > wp-config.php
<?php
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'wordpressuser' );
define( 'DB_PASSWORD', 'password' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define( 'FS_METHOD', 'direct' );
EOT

curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

cat<<EOT >> wp-config.php
\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );
if ( ! defined( 'ABSPATH' ) ) {
        define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
?>
EOT

sudo mv -f wp-config.php /var/www/wordpress

sudo systemctl restart nginx
sudo systemctl restart php7.4-fpm