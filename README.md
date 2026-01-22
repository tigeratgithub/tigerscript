# tigerscript
some script for setup env

### 设置拥塞控制算法为bbr
```shell
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/enable_bbr.sh)"
```
或者 简单版本
```shell
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/simple_bbr.sh)"
```
xrdp-xfce.sh

xfce4 + xrdp 
```shell
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/xrdp-xfce.sh)"
```
install  docker
```shell
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/docker_install.sh.sh)"
```

### mqtt证书更新脚本
```shell
# 全量参数
sudo ./renew-mqtt-cert.sh dns=dev.mqtt.com dir=/opt/mosquitto/config/certs cname=mosquitto
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/renew-mqtt-cert.sh)" -- dns=dev.mqtt.com dir=/opt/mosquitto/config/certs cname=mosquitto

# 只传域名（其他使用脚本内的默认值）
sudo ./renew-mqtt-cert.sh dns=iot.myserver.com
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/renew-mqtt-cert.sh)" -- dns=iot.myserver.com

# 改变顺序
sudo ./renew-mqtt-cert.sh cname=my_broker dns=mqtt.xyz.com
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/renew-mqtt-cert.sh)" -- cname=my_broker dns=mqtt.xyz.com

```

### restart gnome-remote-desktop.service

```shell
# sudo systemctl restart gnome-remote-desktop.service
systemctl --user restart gnome-remote-desktop.service
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/tigeratgithub/tigerscript/main/restart_gnome_remote_desktop.sh)"
```


