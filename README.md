# Setup V2Ray


Script for automatic setup of V2Ray. Feature of this scrip :

* Install Nginx
* Install acme.sh
* Request cert from Let's Encrypt
* Enable TLS 1.3 in Nginx
* Install V2Ray
* Config V2Ray to work with WebSocket and TLS
* Generate client config
* SSL Server Test Rating: A Plus

Tested on Ubuntu 18.04.4 LTS.

## How To Use


Before you use this script, make sure your domain name resolve to the right IP. Login in your GoDaddy account to get API Key and Secret. https://developer.godaddy.com/keys/
You can use `root` user or other user with `sudo` privilege. Download the script. You only need to modify the `DOMAIN_NAME`. 

```
wget https://raw.githubusercontent.com/greyby/setup-v2ray/master/setup_v2ray.sh
chmod +x setup_v2ray.sh
# vi setup_v2ray.sh, change DOMAIN_NAME  
# prefer domain.com, not http://domain.com or www.domain.com
export GD_Key="key_xxxx"
export GD_Secret="secret_xxxx"
./setup_v2ray.sh
```

**NOTE:**  Need to choose **production** Environment 


## Useful command

```
systemctl status nginx.service
systemctl restart nginx.service
systemctl status v2ray.service
systemctl restart v2ray.service
```

## TODO


- [ ] Cert renew test
- [ ] Check more exception and handle them
- [ ] Do not install if app already existed
- [ ] More distro support
- [ ] Check port conflict before install
- [ ] Request cert with other modes