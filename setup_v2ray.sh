#!/bin/bash

# Script for automatic setup of v2ray

# The latest version of this script is available at:
# https://github.com/greyby/setup-v2ray

# VARIABLES
NGINX_VERSION="1.17.9"
OPENSSL_VERSION="1.1.1e"
ZLIB_VERSION="1.2.11"
PCRE_VERSION="8.44"
DISTRIBUTION=""
CODENAME="bionic"
PRE_PACK="build-essential libgeoip-dev libgd-dev libxml2-dev libxslt1-dev zlib1g-dev libpcre3-dev libperl-dev"
PACKAGE_PATH="/tmp/nginxapp"
APP_USER="root"
APP_GROUP="root"
DOMAIN_NAME=""
WS_PATH=""
PORT=""
UUID=""
ALTER_ID="61"
CLIENT_PORT=1080
CLIENT_CONFIG="/etc/v2ray/client_config.json"

CONFIGURE_OPTIONS="--user=${APP_USER} --group=${APP_GROUP} 
									 --prefix=/usr/local/nginx 
									 --sbin-path=/usr/sbin/nginx 
									 --conf-path=/etc/nginx/nginx.conf 
									 --pid-path=/var/run/nginx.pid 
									 --lock-path=/var/run/nginx.lock 
									 --http-log-path=/var/log/nginx/access.log 
									 --error-log-path=/var/log/nginx/error.log 
									 --with-http_ssl_module 
									 --with-http_v2_module 
									 --with-http_realip_module 
									 --with-http_geoip_module 
									 --with-http_auth_request_module 
									 --with-http_slice_module 
									 --with-http_sub_module 
									 --with-http_flv_module 
									 --with-http_mp4_module 
									 --with-http_dav_module 
									 --with-threads 
									 --with-file-aio 
									 --with-http_stub_status_module 
									 --with-http_gunzip_module 
									 --with-http_gzip_static_module 
									 --with-http_secure_link_module 
									 --with-http_image_filter_module=dynamic 
									 --with-stream=dynamic 
									 --with-stream_ssl_module 
									 --with-stream_realip_module 
									 --with-stream_geoip_module 
									 --with-stream_geoip_module=dynamic 
									 --with-debug 
									 --with-http_stub_status_module 
									 --with-http_perl_module 
									 --with-http_perl_module=dynamic 
									 --with-compat 
									 --with-openssl=../openssl 
									 --with-pcre=../pcre
									 --with-zlib=../zlib"

COLOR_PREFIX="\033["
# color code
RED="31"      # error
GREEN="32"    # success
YELLOW="33"   # warning
BLUE="34"     # info
CYAN="36"     # instruction
NORMAL="0"		# reset


colorEcho(){
	echo -e "${COLOR_PREFIX}${1}m${@:2}${COLOR_PREFIX}${NORMAL}m"
}

check_distribution_support(){
	#TODO more linux distribution support
	colorEcho ${BLUE} "Checking system support..."
	if cat /proc/version | grep -Eqi "deiban"; then
		DISTRIBUTION="debian"
	elif cat /proc/version | grep -Eqi "ubuntu"; then
		DISTRIBUTION="ubuntu"
	fi

	if [ $DISTRIBUTION != "ubuntu" ]; then
		colorEcho ${RED} "The script does not support this distribution yet..."
		exit 1
	fi

	if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
		colorEcho ${RED} "The script does not support this release yet..."
		exit 1
	fi
	colorEcho ${GREEN} "Your system is supported"
}

download_nginx(){
	colorEcho ${BLUE} "Preparing download..."
	sudu rm -rf ${PACKAGE_PATH}
  mkdir -p ${PACKAGE_PATH}
  cd ${PACKAGE_PATH}

	colorEcho ${BLUE} "Downloading Nginx ${NGINX_VERSION}..."
	curl -s -L -H "Cache-Control: no-cache" -o nginx.tar.gz https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
	tar zxvf nginx.tar.gz > /dev/null && rm -f nginx.tar.gz > /dev/null
	if [ "$?" != '0' ]; then
	    colorEcho ${RED} "Failed to download, please check your network"
	    exit 3
	fi
	mv nginx-${NGINX_VERSION} nginx
	colorEcho ${GREEN} "Finished download Nginx ${NGINX_VERSION}"

	colorEcho ${BLUE} "Downloading OpenSSL ${OPENSSL_VERSION}..."
	curl -s -L -H "Cache-Control: no-cache" -o openssl.tar.gz https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
	tar zxvf openssl.tar.gz > /dev/null && rm -f openssl.tar.gz > /dev/null
	if [ "$?" != '0' ]; then
	    colorEcho ${RED} "Failed to download, please check your network"
	    exit 3
	fi
	mv openssl-${OPENSSL_VERSION} openssl
	colorEcho ${GREEN} "Finished download OpenSSL"

	colorEcho ${BLUE} "Downloading PCRE..."
	curl -s -L -H "Cache-Control: no-cache" -o pcre.tar.gz https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
	tar zxvf pcre.tar.gz > /dev/null && rm -f pcre.tar.gz > /dev/null
	if [ "$?" != '0' ]; then
	    colorEcho ${RED} "Failed to download, please check your network"
	    exit 3
	fi
	mv pcre-8.44 pcre
	colorEcho ${GREEN} "Finished download PCRE"

	colorEcho ${BLUE} "Downloading zlib..."
	curl -s -L -H "Cache-Control: no-cache" -o zlib.tar.gz https://www.zlib.net/zlib-1.2.11.tar.gz
	tar zxvf zlib.tar.gz > /dev/null && rm -f zlib.tar.gz > /dev/null
	if [ "$?" != '0' ]; then
	    colorEcho ${RED} "Failed to download, please check your network"
	    exit 3
	fi
	mv zlib-1.2.11 zlib
	colorEcho ${GREEN} "Finished download zlib"

}

update_package_indexes(){
	colorEcho ${BLUE} "Resynchronize package index files..."
	sudo apt-get update -y -q  > /dev/null 
	# && sudo apt-get upgrade -y -q > /dev/null
}

install_nginx_from_source(){
	download_nginx
	compile_nginx_and_install
}

compile_nginx_and_install(){
	#TODO check nginx had already installed
	cd "${PACKAGE_PATH}/nginx"
	colorEcho ${BLUE} "Installing development packages..."
  sudo apt-get install -y -q ${PRE_PACK} > /dev/null
  if [ "$?" != '0' ]; then
		colorEcho ${RED} "Failed to install development packages. Probably privilege problem."
    exit 4
  fi
  colorEcho ${GREEN} "Development packages installed"

  colorEcho ${BLUE} "Please wait, configuring Nginx!"
	./configure $CONFIGURE_OPTIONS > /dev/null
	if [ "$?" != '0' ]; then
		colorEcho ${RED} "Something went wrong while configuring Nginx"
	  exit 1
	fi
	colorEcho ${BLUE} "Making Nginx... This process may be very slow!"
	make > /dev/null
	if [ "$?" != '0' ]; then
    colorEcho ${RED} "Something went wrong while making Nginx"
    exit 1
	fi
	colorEcho ${BLUE} 'Installing Nginx...'
	sudo make install > /dev/null
	if [ "$?" != '0' ]; then
    colorEcho ${RED} "Something went wrong while installing Nginx"
    exit 1
	fi
	colorEcho ${GREEN} "Finished install nginx."
}

# binary_package
install_nginx_from_apt_repository(){
	colorEcho ${BLUE} "Preparing install Nginx..."
	sudo wget -q https://nginx.org/keys/nginx_signing.key
	sudo apt-key add nginx_signing.key
	sudo echo "deb https://nginx.org/packages/mainline/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list
	sudo echo "deb-src https://nginx.org/packages/mainline/ubuntu/ ${CODENAME} nginx" >> /etc/apt/sources.list
	sudo rm nginx_signing.key
	update_package_indexes
	sudo apt-get install nginx
	colorEcho ${GREEN} "Finished install Nginx..."
}

setup_nginx(){
	# nginx_config_main
	nginx_config_https
	# nginx_systemd
	install_cert
	start_nginx
}

nginx_config_main(){
	colorEcho ${BLUE} "Setup nginx main config"
	#TODO remove sudo, -d check
	sudo mkdir -p /etc/nginx/conf.d/
	if [ "$?" != '0' ]; then
    colorEcho ${RED} "May be privilege problem"
    exit 4
	fi
	sudo bash -c "cat > /etc/nginx/nginx.conf" <<EOF
user  ${APP_USER};
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    keepalive_timeout  65;
    include /etc/nginx/conf.d/*.conf;
}
EOF
}

generate_port_path_and_uuid(){
	colorEcho ${BLUE} "Programing is fun, generate variable"
	PORT="$(($RANDOM + 10000))"
	UUID="$(cat '/proc/sys/kernel/random/uuid')"
	WS_PATH=$(cat /dev/urandom | head -1 | md5sum | head -c 4)
}

nginx_config_https(){
	colorEcho ${BLUE} "Setup Nginx HTTPS config"
	sudo bash -c "cat > /etc/nginx/conf.d/default.conf" <<EOF
server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ${DOMAIN_NAME};

  ssl_certificate /etc/nginx/certs/${DOMAIN_NAME}_fullchain.cer;
  ssl_certificate_key /etc/nginx/certs/${DOMAIN_NAME}.key;
  # verify chain of trust of OCSP response using Root CA and Intermediate certs
  ssl_trusted_certificate /etc/nginx/certs/${DOMAIN_NAME}_ca.cer;

  ssl_session_timeout 1d;
  ssl_session_cache shared:MozSSL:10m; # about 40000 sessions
  ssl_session_tickets off;

  ssl_dhparam /etc/nginx/certs/dhparam.pem;

  # modern configuration
  ssl_protocols TLSv1.3;
  # ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers on;
  # HSTS (ngx_http_headers_module is required) (63072000 seconds)
  add_header Strict-Transport-Security "max-age=63072000" always;

  # OCSP stapling
  ssl_stapling on;
  ssl_stapling_verify on;

  # replace with the IP address of your resolver
  resolver 127.0.0.1;

  location / {
    root   html;
    index  index.html index.htm;
  }

  location /${WS_PATH} {
    if (\$http_upgrade != "websocket") {
        return 404;
    }
    proxy_redirect off;
    proxy_pass http://127.0.0.1:${PORT};
    proxy_http_version 1.1;
    proxy_set_header upgrade \$http_upgrade;
    proxy_set_header connection "upgrade";
    proxy_set_header host \$host;
    # Show real IP in v2ray access.log
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  }
}
EOF
}

nginx_systemd(){

	colorEcho ${BLUE} "Setup Nginx systemd"
	sudo bash -c "cat > /etc/systemd/system/nginx.service" <<EOF
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target
[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF
}

start_nginx(){
	colorEcho ${BLUE} "Starting Nginx..."
	sudo systemctl start nginx.service
	sudo systemctl enable nginx.service
}

install_cert(){
	colorEcho ${BLUE} "Preparing install cert..."
	sudo apt-get install -y -q socat > /dev/null
	sudo mkdir -p /etc/nginx/certs
	sudo chown -R ${APP_USER}:${APP_GROUP} /etc/nginx/certs
	#TODO cert
	curl -s https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/nginx/certs/dhparam.pem
	curl -s https://get.acme.sh | sh
	# different DNS API
	#TODO check acme.sh return value
	colorEcho ${BLUE} "Requesting cert..."
	$HOME/.acme.sh/acme.sh --issue --dns dns_gd -d "${DOMAIN_NAME}" -d "*.${DOMAIN_NAME}" --keylength ec-256
	colorEcho ${BLUE} "Installing cert..."
	$HOME/.acme.sh/acme.sh --install-cert -d "${DOMAIN_NAME}" --key-file "/etc/nginx/certs/${DOMAIN_NAME}.key" --fullchain-file "/etc/nginx/certs/${DOMAIN_NAME}_fullchain.cer" --ecc
	# --reloadcmd "sudo systemctl restart nginx.service"
	#TODO check cert issued
	colorEcho ${BLUE} "Copy intermediate CA cert"
	cp $HOME/.acme.sh/${DOMAIN_NAME}_ecc/ca.cer "/etc/nginx/certs/${DOMAIN_NAME}_ca.cer" > /dev/null
}

install_v2ray(){
	colorEcho ${BLUE} "Installing v2ray"
	sudo apt-get install -y -q unzip > /dev/null
	curl -s https://install.direct/go.sh | sudo bash
}

setup_v2ray(){
	colorEcho ${BLUE} "Setup v2ray"
	#TODO port, uuid, alterId, wspath
	sudo bash -c "cat > /etc/v2ray/config.json" <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log"
  },
  "inbounds": [
    {
      "port": ${PORT},
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${UUID}",
            "alterId": ${ALTER_ID}
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "connectionReuse": true,
          "path": "/${WS_PATH}"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF
	sudo systemctl start v2ray.service > /dev/null 2>&1
	sudo systemctl enable v2ray.service > /dev/null 2>&1
}

generate_client_config(){
	colorEcho ${BLUE} "Generating client config..."
	sudo bash -c "cat > ${CLIENT_CONFIG}" <<EOF
{
  "inbounds": [
    {
      "port": ${CLIENT_PORT},
      "listen": "127.0.0.1",
      "protocol": "socks",
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      },
      "settings": {
        "auth": "noauth",
        "udp": false
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "${DOMAIN_NAME}",
            "port": 443,
            "users": [
              {
                "id": "${UUID}",
                "alterId": ${ALTER_ID}
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "wsSettings": {
          "path": "/${WS_PATH}"
        }
      },
      "mux": {
        "enabled": true
      }
    }
  ]
}
EOF
}

check_dns(){
	colorEcho ${BLUE} "Checking dns..."
	real_addr=`ping ${DOMAIN_NAME} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
  local_addr=`curl -s -4 ifconfig.co`
  if [ $real_addr == $local_addr ] ; then
		colorEcho ${GREEN} "DNS set correct..."
  else
    colorEcho ${RED} "DNS set incorrect..."
    exit 3
	fi
}

stop_systemd_process(){
	colorEcho ${BLUE} "Stop systemd process"
	sudo systemctl stop nginx
	sudo systemctl disable nginx
	sudo systemctl stop v2ray
	sudo systemctl disable v2ray
}

remove_all_app() {
  stop_systemd_process
  colorEcho ${BLUE} "Preparing remove app"
  nginx_systemd_file="/etc/systemd/system/nginx.service"
	nginx_config_path="/etc/nginx"
	nginx_install_path="/usr/local/nginx"
	nginx_log_path="/var/log/nginx"
	nginx_bin_file="/usr/sbin/nginx"
	
	v2ray_systemd_path="/etc/systemd/system/v2ray.service"
	v2ray_bin_path="/usr/bin/v2ray"
	v2ray_config_path="/etc/v2ray"
	v2ray_log_path="/var/log/v2ray"
  
  [[ -f $nginx_systemd_file ]] && sudo rm -f $nginx_systemd_file
  [[ -d $nginx_config_path ]] && sudo rm -rf $nginx_config_path
  [[ -d $nginx_install_path ]] && sudo rm -rf $nginx_install_path
  [[ -d $nginx_log_path ]] && sudo rm -rf $nginx_log_path
  [[ -f $nginx_bin_file ]] && sudo rm -rf $nginx_bin_file

  [[ -f $v2ray_systemd_path ]] && sudo rm -f $v2ray_systemd_path
  [[ -d $v2ray_bin_path ]] && sudo rm -rf $v2ray_bin_path
  [[ -d $v2ray_config_path ]] && sudo rm -rf $v2ray_config_path
  [[ -d $v2ray_log_path ]] && sudo rm -rf $v2ray_log_path

  remove_acme
  sudo systemctl daemon-reload
  colorEcho ${GREEN} "Nginx, V2Ray and ACME had uninstalled "
}

remove_acme() {
	colorEcho ${BLUE} "Preparing uninstall ACME..."
  [[ -f $HOME/.acme.sh/acme.sh ]] && $HOME/.acme.sh/acme.sh uninstall > /dev/null 2>&1
  [[ -d $HOME/.acme.sh ]] && rm -rf "$HOME/.acme.sh"
  colorEcho ${GREEN} "ACME had already uninstalled "
}

open_bbr(){
	colorEcho ${BLUE} "Preparing open bbr..."
	sudo bash -c "echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf"
	sudo bash -c "echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf"
	sudo sysctl -p
}

show_info(){
	colorEcho ${BLUE} "================================="
	colorEcho ${BLUE} "your domain name : ${DOMAIN_NAME}"
	colorEcho ${BLUE} "the uuid : ${UUID}"
	colorEcho ${BLUE} "v2ray listen port : ${PORT}"
	colorEcho ${BLUE} "websocket path : ${WS_PATH}"
	colorEcho ${BLUE} "alterId : ${ALTER_ID}"
	colorEcho ${BLUE} "client config file : ${CLIENT_CONFIG}"
	colorEcho ${BLUE} "================================="
}

main(){
	colorEcho ${CYAN} "=============================="
	colorEcho ${CYAN} "Ready to fly?"
	colorEcho ${CYAN} "1. install all your needs"
	colorEcho ${CYAN} "2. install Nginx"
	colorEcho ${CYAN} "3. request a cert"
	colorEcho ${CYAN} "4. install V2Ray"
	colorEcho ${CYAN} "5. open bbr"
	colorEcho ${CYAN} "9. uninstall all app, be carefull"
	colorEcho ${CYAN} "0. exit"
	colorEcho ${CYAN} "=============================="
	colorEcho ${CYAN} "your can only choose 9 here"
	read -p "enter your choice: " number
	generate_port_path_and_uuid
	case "$number" in

	1)
	check_distribution_support
	update_package_indexes
	check_dns
	install_nginx_from_apt_repository
	setup_nginx
	install_v2ray
	setup_v2ray
	generate_client_config
	show_info
	;;
	5)
	open_bbr
	;;
	9)
	remove_all_app
	;;
	0)
	exit 1
	;;
	esac
}

main