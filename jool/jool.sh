#!/bin/sh

opkg update
opkg install kmod-veth ip-full kmod-jool-netfilter jool-tools-netfilter

#### Config NAT64 for IPV6####
sed -i 's/exit 0//' /etc/rc.local
echo '/etc/jool/setupjool.sh' >> /etc/rc.local
echo '' >> /etc/rc.local
echo 'exit 0' >> /etc/rc.local

uci set firewall.@zone[1].masq="1"
uci set firewall.@zone[1].masq6="1"

uci set dhcp.wan6=dhcp
uci set dhcp.wan6.interface='wan6'
uci set dhcp.wan6.ignore='1'
uci set dhcp.wan6.ra='relay'
uci set dhcp.wan6.dhcpv6='relay'

uci set network.wan6.reqaddress='try'
uci set network.wan6.reqprefix='auto'
uci set network.wan6.sourcefilter="0"



uci set network.lan=interface
uci set network.lan.proto='static'
uci set network.lan.device='br-lan'
uci set network.lan.ip6assign='64'
uci set network.lan.ip6hint='64'

uci set dhcp.lan=dhcp
uci set dhcp.lan.interface='lan'
uci set dhcp.lan.start='100'
uci set dhcp.lan.limit='150'
uci set dhcp.lan.leasetime='12h'
uci set dhcp.lan.ignore='1'
uci set dhcp.lan.ra='server'
uci set dhcp.lan.ra_default='1'
uci set dhcp.lan.dhcpv6='server'
uci add_list network.lan.ip6class='local'
uci add_list firewall.@zone[0].network='lan'
uci add_list network.lan.dns='::1'

wget https://raw.githubusercontent.com/ramonalvesmodesto/openwrt-config/main/jool/setupjool.sh -O /etc/jool/setupjool.sh
chmod +x /etc/jool/setupjool.sh

/etc/jool/setupjool.sh

cat << EOF >> /etc/sysupgrade.conf
/etc/jool/setupjool.sh
EOF

uci set dhcp.jool=dhcp
uci set dhcp.jool.interface='jool'
uci set dhcp.jool.start='100'
uci set dhcp.jool.limit='150'
uci set dhcp.jool.leasetime='12h'
uci set dhcp.jool.ignore='1'
uci set dhcp.jool.ra='server'
uci set dhcp.jool.ra_default='2'
uci add_list dhcp.jool.ra_flags='managed-config'
uci add_list dhcp.jool.ra_flags='other-config'
# uci set dhcp.jool.dhcpv6='server'
# /etc/config/network
uci set network.jool=interface
uci set network.jool.proto='static'
uci set network.jool.device='jool'
uci set network.jool.ipaddr='192.168.164.1'
uci set network.jool.netmask='255.255.255.0'
uci set network.jool.ip6assign='64'
uci set network.jool.ip6hint='64'
uci add_list network.jool.ip6class='local'

uci add network route6 # =cfg0ddf6a
uci set network.@route6[-1].interface='jool'
uci set network.@route6[-1].target='64:ff9b::/96'
uci set network.@route6[-1].gateway='fe80::64'

uci add firewall zone # =cfg0fdc81
uci set firewall.@zone[-1].name='jool'
uci set firewall.@zone[-1].input='ACCEPT'
uci set firewall.@zone[-1].output='ACCEPT'
uci set firewall.@zone[-1].forward='REJECT'
uci add firewall forwarding # =cfg10ad58
uci set firewall.@forwarding[-1].src='jool'
uci set firewall.@forwarding[-1].dest='wan'
uci add_list firewall.@zone[2].network='jool'

uci add firewall forwarding # =cfg11ad58
uci set firewall.@forwarding[-1].src='lan'
uci set firewall.@forwarding[-1].dest='jool'

uci set dhcp.lan.ra_pref64='64:ff9b::/96'

uci add_list dhcp.lan.dhcp_option='108,0:0:7:8'
uci add_list dhcp.lan.dhcp_option='108,0:0:7:8'
uci add_list network.lan.dns='::1'

uci set unbound.ub_main.dns64='1'
uci set unbound.ub_main.dns64_prefix='64:ff9b::/96'

uci commit
