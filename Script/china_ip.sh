#!/bin/bash

ROOT_PATH="/root/china_ip_list/"
TEMP_FILE_PATH="/root/china_ip_list/temp/"
SURGE_PATH="/root/china_ip_list/Surge/"
SSR_PATH="/root/china_ip_list/SSR/"
ACL_PATH="/root/china_ip_list/ACL/"
PCAP_DNSPROXY_PATH="/root/china_ip_list/Pcap_DNSProxy/"
SCRIPT_PATH="/root/china_ip_list/Script"

CurrentDate=$(date +%Y-%m-%d)

downloadOriginIPList() {
	mkdir $TEMP_FILE_PATH
	cd $TEMP_FILE_PATH

	wget -O apnic https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest
	wget -O ipip https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt
}

handelChinaIPv4List() {
	# APNIC
	cat apnic | grep ipv4 | grep CN | awk -F\| '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' >>apnic_1
	echo -e "\n" >>apnic_1

	# IPIP
	echo -e "\n" >>ipip

	# 合并 & 去重
	cat apnic_1 ipip | sort | uniq >apnic_and_ipip_1

	# 去空行
	grep -v '^$' apnic_and_ipip_1 >apnic_and_ipip_2

	# 排序
	sort -t "." -k1n,1 -k2n,2 -k3n,3 -k4n,4 apnic_and_ipip_2 >china_ipv4_list

	cp china_ipv4_list $ROOT_PATH
}

handelChinaIPv6List() {
	cat apnic | grep ipv6 | grep CN | awk -F\| '{printf("%s/%d\n", $4, $5)}' >china_ipv6_list

	cp china_ipv6_list $ROOT_PATH
}

handelChinaIPv4IPv6List() {
	cat china_ipv4_list >china_ipv4_ipv6_list
	cat china_ipv6_list >>china_ipv4_ipv6_list

	cp china_ipv4_ipv6_list $ROOT_PATH
}

handelPcapDNSProxyRules() {
	echo -e "[Local Routing]\n## China mainland routing blocks\n## Sources: https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" >Pcap_DNSProxy_Routing.txt
	echo -n "## Last update: " >>Pcap_DNSProxy_Routing.txt
	echo $CurrentDate >>Pcap_DNSProxy_Routing.txt
	echo -e "\n" >>Pcap_DNSProxy_Routing.txt

	# IPv4
	echo "## IPv4" >>Pcap_DNSProxy_Routing.txt
	cat china_ipv4_list >>Pcap_DNSProxy_Routing.txt
	echo "\n" >>Pcap_DNSProxy_Routing.txt

	# IPv6
	echo "## IPv6" >>Pcap_DNSProxy_Routing.txt
	cat china_ipv6_list >>Pcap_DNSProxy_Routing.txt

	mv Pcap_DNSProxy_Routing.txt Routing.txt

	mv Routing.txt $PCAP_DNSPROXY_PATH
}

handelSurgeRules() {
	echo -e "// China IP" >surge_rules.txt
	echo -n "// Last update: " >>surge_rules.txt
	echo $CurrentDate >>surge_rules.txt

	sed 's/^/IP-CIDR,/g' china_ipv4_list >surge_ipv4_rules_header.txt
	sed 's/$/,DIRECT/g' surge_ipv4_rules_header.txt >surge_ipv4_rules.txt

	sed 's/^/IP-CIDR6,/g' china_ipv6_list >surge_ipv6_rules_header.txt
	sed 's/$/,DIRECT/g' surge_ipv6_rules_header.txt >surge_ipv6_rules.txt

	echo -n "// IPv4" >>surge_rules.txt
	echo -e "" >>surge_rules.txt
	cat surge_ipv4_rules.txt >>surge_rules.txt
	echo -e "" >>surge_rules.txt
	echo -n "// IPv6" >>surge_rules.txt
	echo -e "" >>surge_rules.txt
	cat surge_ipv6_rules.txt >>surge_rules.txt

	mv surge_rules.txt Rules.conf

	sed 's/^/IP-CIDR,/g' china_ipv4_list >surge_ipv4_rules_set.list
	sed 's/^/IP-CIDR6,/g' china_ipv6_list >surge_ipv6_rules_set.list

	mv Rules.conf surge_ipv4_rules_set.list surge_ipv6_rules_set.list $SURGE_PATH
}

handelACLRules() {
	echo -n "# Last update: " >acl_rules.txt
	echo $CurrentDate >>acl_rules.txt
	echo -e "[proxy_all]\n" >>acl_rules.txt
	echo "[bypass_list]" >>acl_rules.txt
	echo "# 局域网 IP" >>acl_rules.txt
	echo "^(.*\.)?local$" >>acl_rules.txt
	echo "^(.*\.)?localhost$" >>acl_rules.txt
	echo "10.0.0.0/8" >>acl_rules.txt
	echo "127.0.0.0/8" >>acl_rules.txt
	echo "172.16.0.0/12" >>acl_rules.txt
	echo "192.168.0.0/16" >>acl_rules.txt
	echo "" >>acl_rules.txt
	echo "# China IP" >>acl_rules.txt
	cat china_ipv4_list >>acl_rules.txt

	mv acl_rules.txt china_ip_list.acl

	mv china_ip_list.acl $ACL_PATH
}

handelSSRRules() {
	cd $SCRIPT_PATH
	python ssr_chn_ip.py
}

cleanTempFile() {
    cd $ROOT_PATH
    rm -rf $TEMP_FILE_PATH
}

commit() {
	git add --all .
	git commit -m "update"
	git push origin master
}

downloadOriginIPList
handelChinaIPv4List
handelChinaIPv6List
handelChinaIPv4IPv6List
handelPcapDNSProxyRules
handelSurgeRules
handelACLRules
handelSSRRules
cleanTempFile
commit