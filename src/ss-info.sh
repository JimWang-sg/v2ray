[[ -z $ip ]] && get_ip
_country_to_zh() {
	case "$1" in
	CN) echo "中国" ;;
	HK) echo "中国香港" ;;
	MO) echo "中国澳门" ;;
	TW) echo "中国台湾" ;;
	US) echo "美国" ;;
	JP) echo "日本" ;;
	KR) echo "韩国" ;;
	SG) echo "新加坡" ;;
	DE) echo "德国" ;;
	FR) echo "法国" ;;
	GB) echo "英国" ;;
	CA) echo "加拿大" ;;
	AU) echo "澳大利亚" ;;
	NL) echo "荷兰" ;;
	RU) echo "俄罗斯" ;;
	IN) echo "印度" ;;
	*) echo "$1" ;;
	esac
}

_cloud_vendor_zh() {
	local provider="$1"
	case "$provider" in
	*Tencent* | *腾讯* | *QCloud*)
		echo "腾讯"
		;;
	*Alibaba* | *Aliyun* | *阿里* | *阿里云*)
		echo "阿里"
		;;
	*Huawei* | *华为*)
		echo "华为"
		;;
	*Amazon* | *AWS* | *亚马逊*)
		echo "亚马逊"
		;;
	*Google* | *GCP* | *谷歌*)
		echo "谷歌"
		;;
	*Microsoft* | *Azure* | *微软*)
		echo "微软"
		;;
	*Oracle* | *OCI*)
		echo "甲骨文"
		;;
	*DigitalOcean*)
		echo "DigitalOcean"
		;;
	*Vultr*)
		echo "Vultr"
		;;
	*Linode*)
		echo "Linode"
		;;
	*)
		echo ""
		;;
	esac
}

_get_server_tag() {
	# Format: <cores>h<memoryGB>g
	local cores mem_g
	cores="$(nproc 2>/dev/null || echo 1)"
	mem_g="$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 0)"
	echo "${cores}h${mem_g}g"
}

_build_ss_node_name() {
	local lookup_json city org isp as_info provider_raw cloud_vendor server_tag
	lookup_json="$(curl -s --max-time 6 "http://ip-api.com/json/${ip}?lang=zh-CN")"
	city="$(echo "$lookup_json" | jq -r '.city // empty')"
	org="$(echo "$lookup_json" | jq -r '.org // empty')"
	isp="$(echo "$lookup_json" | jq -r '.isp // empty')"
	as_info="$(echo "$lookup_json" | jq -r '.as // empty')"
	[[ -z $city ]] && city="未知城市"
	server_tag="$(_get_server_tag)"

	provider_raw="${org} ${isp} ${as_info}"
	cloud_vendor="$(_cloud_vendor_zh "$provider_raw")"
	# City_2h2g_CloudVendor (cloud_vendor might be empty)
	echo "${city}_${server_tag}_${cloud_vendor}"
}

if [[ $shadowsocks ]]; then
	local node_name node_name_encoded ss
	node_name="$(_build_ss_node_name)"
	node_name_encoded="$(echo -n "$node_name" | jq -sRr @uri)"
	local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#${node_name_encoded}"
	echo
	echo "---------- Shadowsocks 配置信息 -------------"
	echo
	echo -e "$yellow 服务器地址 = $cyan${ip}$none"
	echo
	echo -e "$yellow 服务器端口 = $cyan$ssport$none"
	echo
	echo -e "$yellow 密码 = $cyan$sspass$none"
	echo
	echo -e "$yellow 加密协议 = $cyan${ssciphers}$none"
	echo
	echo -e "$yellow SS 链接 = ${cyan}$ss$none"
	echo
	echo -e " 备注: $red Shadowsocks Win 4.0.6 $none 客户端可能无法识别该 SS 链接"
	echo
	echo -e "提示: 输入 $cyan v2ray ssqr $none 可生成 Shadowsocks 二维码链接"	
	echo
	echo -e "${yellow}免被墙..推荐使用JMS: ${cyan}https://getjms.com${none}"
	echo
fi
