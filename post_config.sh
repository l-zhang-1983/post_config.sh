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
	sudo systemctl restart privoxy
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
	unzip -d files files/web_ui.zip
	mv files/web_ui ~/.aria2
}

# 9. 搜狗拼音输入法
function sogou {
	sudo apt install -y fcitx libfcitx-qt0 fcitx-libs-qt libopencc2 fcitx-libs libqtwebkit4
	im-config -n fcitx
	sudo dpkg -i files/sogoupinyin_*_amd64.deb
}

# 10. 安装gnome-tweaks
function gnome_tweaks {
	sudo apt install -y gnome-tweaks
}

# 11. 安装字体
function install_fonts {
	sudo tar -zcvf /etc/fonts/fonts.tar.gz -C /etc/ fonts
	sudo cp -r files/zh_CN /usr/share/fonts/X11/
	sudo fc-cache -frv
}

# 12. 修改登录界面背景图
function loginBackground {
	cp files/iLUECx.jpg ~/Pictures/
	sudo cp /usr/share/gnome-shell/theme/ubuntu.css{,.bak}
	sudo sed -i "/^#lockDialogGroup/,/}$/d" /usr/share/gnome-shell/theme/ubuntu.css
	sudo cat >> ubuntu.css<<-EOF
#lockDialogGroup {
    background: #2c001e url(file:///home/USER/Pictures/iLUECx.jpg);
    background-repeat: no-repeat;
    background-size: cover;
    background-position: center; }
EOF
	sudo sed -i "s/USER/$(whoami)/g" /usr/share/gnome-shell/theme/ubuntu.css 
}

# 13. 安装google-chrome
# wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
function chrome {
	sudo dpkg -i files/google-chrome-stable_current_amd64.deb
}

#disable_kernel_moudle
#change_apt_sources
update_apt_cache
setup_shadowsocks
setup_privoxy
apt_proxy
upgrade_system
aria2
sogou
