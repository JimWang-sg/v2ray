_qr_create() {
	if [[ $v2ray_transport == 33 ]]; then
		local vmess="$(cat /etc/v2ray/vmess_qr.json)"
	else
		local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
	fi
	local link="https://233boy.github.io/tools/qr.html#${vmess}"
	echo
	echo "---------- V2Ray 二维码 -------------"
	echo
	qrencode -s 1 -m 1 -t ansi "${vmess}"
	echo
	echo "如果无法正常显示二维码，请使用下面的链接来生成二维码:"
	echo -e ${cyan}$link${none}
	echo
	echo
	echo -e "$red 友情提醒: 请务必核对扫码结果 (V2RayNG 除外) $none"
	echo
	echo
	echo " V2Ray 客户端使用教程: https://233v2.com/post/4/"
	echo
	echo
	rm -rf /etc/v2ray/vmess_qr.json
}

_cloud_vendor_zh() {
	local provider="$1"
	case "$provider" in
	*Tencent* | *腾讯* | *QCloud*) echo "腾讯" ;;
	*Alibaba* | *Aliyun* | *阿里* | *阿里云*) echo "阿里" ;;
	*Huawei* | *华为*) echo "华为" ;;
	*Amazon* | *AWS* | *亚马逊*) echo "亚马逊" ;;
	*Google* | *GCP* | *谷歌*) echo "谷歌" ;;
	*Microsoft* | *Azure* | *微软*) echo "微软" ;;
	*Oracle* | *OCI*) echo "甲骨文" ;;
	*DigitalOcean*) echo "DigitalOcean" ;;
	*Vultr*) echo "Vultr" ;;
	*Linode*) echo "Linode" ;;
	*) echo "" ;;
	esac
}

_build_ss_node_name() {
	local lookup_json country city node_ip org isp as_info provider_raw cloud_vendor
	lookup_json="$(curl -s --max-time 6 "http://ip-api.com/json/${ip}?lang=zh-CN")"
	country="$(echo "$lookup_json" | jq -r '.country // "未知国家"')"
	city="$(echo "$lookup_json" | jq -r '.city // "未知城市"')"
	node_ip="$(echo "$lookup_json" | jq -r '.query // empty')"
	org="$(echo "$lookup_json" | jq -r '.org // empty')"
	isp="$(echo "$lookup_json" | jq -r '.isp // empty')"
	as_info="$(echo "$lookup_json" | jq -r '.as // empty')"
	[[ -z $node_ip ]] && node_ip="$ip"
	provider_raw="${org} ${isp} ${as_info}"
	cloud_vendor="$(_cloud_vendor_zh "$provider_raw")"
	echo "${country}_${city}_${node_ip}_${cloud_vendor}"
}

_ss_qr() {
	local node_name node_name_encoded ss_link
	node_name="$(_build_ss_node_name)"
	node_name_encoded="$(echo -n "$node_name" | jq -sRr @uri)"
	local ss_link="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#${node_name_encoded}"
	local link="https://233boy.github.io/tools/qr.html#${ss_link}"
	echo
	echo "---------- Shadowsocks 二维码 -------------"
	echo
	qrencode -s 1 -m 1 -t ansi "${ss_link}"
	echo
	echo "如果无法正常显示二维码，请使用下面的链接来生成二维码:"
	echo -e ${cyan}$link${none}
	echo
	echo -e " 温馨提示...$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该二维码"
	echo
	echo
}
