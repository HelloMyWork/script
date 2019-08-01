#!/bin/bash
# 初始化系统调优脚本

#是否使用root用户执行
if [ "$UID" != "0" ];then
echo "Please run this script by root"
exit 1
fi

#判断是否为64位系统
platform=`uname -i`
if [[ $platform != "x86_64" ]];then
echo "this script is only for 64bit Operating System !"
exit 2
fi
echo "the platform is ok"
cat << EOF
+---------------------------------------+
| your system is CentOS 7 x86_64        |
| start optimizing.......               |
+----------------------------------------
EOF

#设置公网DNS
cat > /etc/resolv.conf << EOF
nameserver 172.16.200.14
nameserver 114.114.114.114
nameserver 172.16.200.11
EOF

# 更改阿里云yum源
cd /etc/yum.repos.d
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

# CentOS7 防火墙关闭
systemctl stop firewalld.service
systemctl disable firewalld.service

# CentOS7 关闭SElinux闭
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config

# 安装系统常用命令
yum install -y \
vixie-cron \
libselinux-python \
gcc \
gcc-c++ \
glibc \
make \
autoconf \
vim \
openssl \
openssl-devel \
lsof \
apr \
apr-util \
tomcat-native \
nfs-utils \
cronolog \
htop \
openssh \
lrzsz \
telnet \
ntpdate \
python-devel \
python-pip \
unzip \
net-tools \
wget \
htop \
rng-tools \
iftop

#设置最大打开文件描述符数
echo "ulimit -SHn 102400" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
* soft nofile 65535
* hard nofile 65535
EOF

# 优化ssh服务
sed -i "s/GSSAPIAuthentication yes/GSSAPIAuthentication no/" /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
systemctl restart sshd.service

# 优化内核参数
cat >> /etc/sysctl.conf << EOF
# 关闭ipv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
# 决定检查过期多久邻居条目
net.ipv4.neigh.default.gc_stale_time=120
# 使用arp_announce / arp_ignore解决ARP映射问题
net.ipv4.conf.default.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.lo.arp_announce = 2
# 避免放大攻击
net.ipv4.icmp_echo_ignore_broadcasts = 1
# 开启恶意icmp错误消息保护
net.ipv4.icmp_ignore_bogus_error_responses = 1
# 处理无源路由的包
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
# 开启SYN洪水攻击保护
net.ipv4.tcp_syncookies = 1
# 修改消息队列长度
kernel.msgmnb = 65536
kernel.msgmax = 65536
net.ipv6.conf.lo.disable_ipv6 = 1
vm.swappiness = 0
# 反向路径过滤
net.ipv4.conf.all.rp_filter=0
net.ipv4.conf.default.rp_filter=0
# timewait的数量，默认180000
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
# 限制仅仅是为了防止简单的DoS 攻击
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_fin_timeout = 2
# 开启重用。允许将TIME-WAIT sockets 重新用于新的TCP 连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
# 启用timewait 快速回收
net.ipv4.tcp_tw_recycle = 1
# 允许系统打开的端口范围
net.ipv4.ip_local_port_range = 1024    65000
# 未收到客户端确认信息的连接请求的最大值
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 1
# 内核放弃建立连接之前发送SYNACK 包的数量
net.ipv4.tcp_synack_retries = 1
# 内核放弃建立连接之前发送SYN 包的数量
net.ipv4.tcp_syn_retries = 1
# 当keepalive 起用的时候，TCP 发送keepalive 消息的频度。缺省是2 小时
net.ipv4.tcp_keepalive_time = 1800
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 15
net.core.somaxconn = 16384
# 每个网络接口接收数据包的速率比内核处理这些包的速率快时，允许送到队列的数据包的最大数目
net.core.netdev_max_backlog = 16384
fs.file-max=65535
EOF

# 下载常用服务安装脚本
mkdir -p /data/script
cd /data/script
wget --quiet ftp://172.16.200.171/pub/install-tomcat.sh
wget --quiet ftp://172.16.200.171/pub/install-zabbix-agent.sh
chmod 777 install-tomcat.sh
chmod 777 install-zabbix-agent.sh

# 创建开发用户
useradd rqkj
echo "rqkj235" |passwd --stdin rqkj

cat << EOF
+-------------------------------------------------+
| optimizer is done                               |
| reboot the server in 5s !                       |
+-------------------------------------------------+
EOF

sleep 5

##重启加载内核修改
#reboot
