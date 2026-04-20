# V2Ray 一键安装与节点命名说明（JimWang-sg 定制版）

本文档说明如何使用本仓库的 `install.sh` 一键安装，并自动启用节点命名规则：

`城市_<CPU核数>h<内存GB>g_云服务商`

其中：

- `城市`：通过 `ip-api.com` 的 `lang=zh-CN` 返回的城市名（无法识别时显示 `未知城市`）
- `<CPU核数>h<内存GB>g`：从本机自动探测
  - CPU 核数：`nproc`
  - 内存 GB：`/proc/meminfo` 的 `MemTotal` 换算为 GB（向下取整）
- `云服务商`：根据 `org/isp/as` 字段做关键词匹配（无法识别时留空，末尾可能多一个 `_`）

> 说明：本仓库的安装脚本在官方安装流程完成后，会额外下载并覆盖部分脚本文件，并对上游 `core.sh` 做补丁，从而让 **VMess/SS/Socks** 等链接里的节点显示名（例如 VMess 的 `ps`）符合上述规则。

---

## 一键安装（推荐）

在目标服务器以 `root` 执行：

```bash
bash <(wget -qO- -o- https://raw.githubusercontent.com/JimWang-sg/v2ray/master/install.sh)
```

如果你担心 CDN/缓存导致拿到旧脚本，可以固定到某个 commit（示例）：

```bash
bash <(wget -qO- -o- https://raw.githubusercontent.com/JimWang-sg/v2ray/423decd/install.sh)
```

---

## 安装完成后如何验证

### 1) 查看 VMess 链接（重点看 `ps`）

```bash
v2ray url
```

`vmess://` 后面是 base64。你可以把 base64 解码后检查 JSON 里的 `ps` 字段，应该类似：

`东京_2h2g_亚马逊`

### 2) Shadowsocks（如果启用）

```bash
v2ray info
v2ray ssqr
```

SS 链接末尾 `#` 后面的节点名同样应遵循上述格式（中文可能被 URL 编码）。

---

## 本仓库做了哪些“额外动作”

安装脚本会在官方安装完成后：

1. 从本仓库 `master` 分支下载并覆盖：
   - `src/ss-info.sh`
   - `src/qr.sh`
2. 对上游脚本包解压后的 `src/core.sh` 追加 `get_node_name()`，并用 `sed` 替换部分硬编码的 `233boy-...` 命名模板，使 VMess 等链接命名走统一函数。

---

## 常见问题（排查顺序）

### 1) 安装提示“已安装”

说明机器上已有 `/etc/v2ray/sh` 与 `/usr/local/bin/v2ray` 等痕迹。处理方式：

- 使用官方脚本自带卸载（若可用）：

```bash
v2ray uninstall
```

- 或手动清理（更彻底，适合半损坏安装）：

```bash
systemctl stop v2ray 2>/dev/null || true
systemctl disable v2ray 2>/dev/null || true
rm -f /lib/systemd/system/v2ray.service /etc/systemd/system/v2ray.service /usr/lib/systemd/system/v2ray.service
systemctl daemon-reload

rm -f /usr/local/bin/v2ray /usr/local/sbin/v2ray /usr/bin/v2ray
rm -rf /etc/v2ray /var/log/v2ray
```

### 2) 城市显示 `未知城市`

通常是地理信息接口不可用、被拦截、或返回字段为空。可以检查：

```bash
curl -s --max-time 6 "http://ip-api.com/json/$(curl -s --max-time 6 https://one.one.one.one/cdn-cgi/trace | sed -n 's/^ip=//p' | head -n1)?lang=zh-CN" | jq .
```

### 3) `2h2g` 不符合预期

- CPU：`nproc` 在某些容器/虚拟化环境可能不等于你购买的“套餐核数”
- 内存：`MemTotal` 是物理内存总量，不等于可用内存；且为向下取整 GB

如果你希望严格按“套餐规格”而不是探测值命名，需要改为读取你云平台元数据或手工配置（当前实现是自动探测）。

### 4) 云服务商为空

说明 `org/isp/as` 未匹配到已知云厂商关键词。你可以在 `src/ss-info.sh`、`src/qr.sh` 与本仓库 `install.sh` 注入的 `get_node_name()` 中扩展 `_cloud_vendor_zh` 的匹配规则。

---

## 卸载/清理建议

卸载后建议确认：

```bash
command -v v2ray || echo "v2ray 命令已不存在"
test -d /etc/v2ray && echo "/etc/v2ray 仍存在" || echo "/etc/v2ray 已删除"
```

如你曾安装 Caddy（TLS 自动化场景），可额外检查：

```bash
command -v caddy || echo "caddy 不存在"
test -d /etc/caddy && echo "/etc/caddy 仍存在" || echo "/etc/caddy 已删除"
```

---

## 维护与更新建议

- 固定 commit 安装：最稳定，避免 raw 缓存
- 更新本仓库后：重新执行一键安装或重新下载覆盖脚本文件，确保服务器端 `/etc/v2ray/sh/src/*` 与最新版本一致

---

## 相关文件

- `install.sh`：一键安装入口（含补丁逻辑）
- `src/ss-info.sh`：SS 信息输出命名
- `src/qr.sh`：SS 二维码命名
