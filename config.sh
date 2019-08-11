#!/bin/bash

# 0. 添加ideapad_laptop到黑名单
function disable_kernel_moudle {
	count=$(grep ideapad_laptop /etc/modprobe.d/* | wc -l)
	if [[ $count -gt 0 ]]; then
		echo "Kernel moudle [ideapad_laptop] already blacklisted, skipping...."
	else
		echo "blacklist ideapad_laptop" | sudo tee -a /etc/modprobe.d/blacklist.conf
		echo "Kernel moudle ideapad_laptop is blacklisted"
	fi
}

# 1. 更换apt源为aliyun
function change_apt_sources {
	sudo cp /etc/apt/sources.list{,.bak}
	sudo cp files/sources.list.aliyun /etc/apt/sources.list
	echo "apt source set to aliyun"
}

# 2. 更新apt缓存
function update_apt_cache {
	sudo apt update
}

# 3. 安装shadowsocks-libev和simple-obfs
function setup_shadowsocks {
	sudo systemctl stop shadowsocks-libev-local@config-obfs.service
	sudo systemctl disable hadowsocks-libev-local@config-obfs.service
	sudo apt remove -y simple-obfs
	sudo apt purge -y simple-obfs
	sudo apt remove -y shadowsocks-libev
	sudo apt purge -y shadowsocks-libev

	sudo apt install -y shadowsocks-libev simple-obfs
	sudo systemctl stop shadowsocks-libev.service
	sudo systemctl disable shadowsocks-libev.service
	sudo cp /lib/systemd/system/shadowsocks-libev-local@.service /etc/systemd/system/shadowsocks-libev-local@config-obfs.service
	sudo cp files/config-obfs.json /etc/shadowsocks-libev/
	sudo systemctl enable shadowsocks-libev-local@config-obfs.service
	sudo systemctl start shadowsocks-libev-local@config-obfs.service 
	echo "shadowsocks setup finished, port 1080"
}

# 4. 安装privoxy
function setup_privoxy {
	sudo apt -y install privoxy
	sudo cp /etc/privoxy/config{,.bak}
	sudo cp files/config /etc/privoxy/
	echo "privoxy setup finished, port 1081"

}

# 5. 配置apt代理
function apt_proxy {
	sudo cp files/01proxy /etc/apt/apt.conf.d
	echo "apt proxy setup finished, flow of launchpad.net will go via proxy"
}

# 6. 更新系统
function upgrade_system {
	sudo apt -y update
	sudo apt -y upgrade
}

# 7. 安装NVIDIA驱动
function nvidia_driver {
	version=$(apt search ^nvidia-driver-* | gawk -F / '{print $1}' | sort | grep ^nvidia-driver- | tail -n 1)
	if [[ -n $version ]]; then
		echo "Tryin' to install $version"
		sudo apt install -y $version
	else
		echo "Can not find a candidate NVIDIA driver"
	fi
}

# 8. 安装aria2
function aria2 {
	sudo apt install -y aria2
	sudo tar -zxvf files/aria.tar.gz -C files
	sed -i "s/HOME_DIR/$(whoami)/g" files/.aria2/aria2.conf
	mv files/.aria2 ~/
	cp files/aria2.service{.example,}
	sed -i "s/USER/$(whoami)/g" files/aria2.service
	sudo mv files/aria2.service /etc/systemd/system
	sudo systemctl enable aria2.service
	sudo systemctl start aria2.service
}

#disable_kernel_moudle
#change_apt_sources
#setup_shadowsocks
#setup_privoxy
#apt_proxy