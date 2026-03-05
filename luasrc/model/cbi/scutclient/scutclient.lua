-- LuCI by libc0607 (libc0607@gmail.com)
-- 华工路由群 262939451
-- 修复与重构：修复 nettime 控件不显示问题、修复 24 小时制逻辑、移除全局变量污染

-- 【修复 1】: 将 split 改为安全的局部函数，不污染系统原生的 string 库
local function split_string(s, p)
    local rt = {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end)
    return rt
end

scut = Map(
        "scutclient",
        "SCUT Client",
        [[ <input style="margin: 2px;" class="cbi-button cbi-button-apply" type="button" value="Step 1 : 点此处去设置Wi-Fi" onclick="javascript:location.href=']] .. luci.dispatcher.build_url("admin/network/wireless/radio0.network1") .. [['"/>]]
        .. [[ <input style="margin: 2px;" class="cbi-button cbi-button-apply" type="button" value="Step 2 : 点此处去设置IP" onclick="javascript:location.href=']] .. luci.dispatcher.build_url("admin/network/network") .. [['"/>]]
        .. [[ <input style="margin: 2px;" class="cbi-button cbi-button-apply" type="button" value="Step 3 : 点此处去修改路由器管理密码" onclick="javascript:location.href=']] .. luci.dispatcher.build_url("admin/system/admin") .. [['"/>]]
)

function scut.on_commit(self)
    luci.sys.call("uci commit")
    luci.sys.call("rm -rf /tmp/luci-*cache")
end

-- config option
scut_option = scut:section(TypedSection, "option", "选项")
scut_option.anonymous = true
scut_option:option(Flag, "enable", "启用")

-- config scutclient
scut_client = scut:section(TypedSection, "scutclient", "用户信息")
scut_client.anonymous = true
scut_client:option(Value, "username", "拨号用户名", "学校提供的用户名，一般是学号")
scut_client:option(Value, "password", "拨号密码").password = true

-- config drcom
scut_drcom = scut:section(TypedSection, "drcom", "Drcom设置")
scut_drcom.anonymous = true

scut_drcom_version = scut_drcom:option(Value, "version", "Drcom版本")
scut_drcom_version.rmempty = false
scut_drcom_version:value("4472434f4d0096022a")
scut_drcom_version:value("4472434f4d0096022a00636b2031")
scut_drcom_version:value("4472434f4d00cf072a00332e31332e302d32342d67656e65726963")
scut_drcom_version.default = "4472434f4d0096022a"

scut_drcom_hash = scut_drcom:option(Value, "hash", "DrAuthSvr.dll版本")
scut_drcom_hash.rmempty = false
scut_drcom_hash:value("2ec15ad258aee9604b18f2f8114da38db16efd00")
scut_drcom_hash:value("d985f3d51656a15837e00fab41d3013ecfb6313f")
scut_drcom_hash:value("915e3d0281c3a0bdec36d7f9c15e7a16b59c12b8")
scut_drcom_hash.default = "2ec15ad258aee9604b18f2f8114da38db16efd00"

scut_drcom_server = scut_drcom:option(Value, "server_auth_ip", "服务器IP")
scut_drcom_server.rmempty = false
scut_drcom_server.datatype = "ip4addr"
scut_drcom_server:value("202.38.210.131")

scut_drcom_nettime = scut_drcom:option(Value, "nettime", "允许上网时间")
scut_drcom_nettime.description = "允许的上网时间，断网后等待到指定时间重新开始认证。如 06:10"
scut_drcom_nettime.rmempty = true -- 允许为空

scut_drcom_nettime.validate = function(self, value, t)
    -- 【修复 2】: 拦截 nil 和空值，防止 string.find 崩溃导致控件不渲染
    if not value or value == "" then
        return value
    end

    if type(value) == "string" and string.find(value, ":") then
        local sp = split_string(value, ":")
        if (#sp == 2) then
            local hour, minute = tonumber(sp[1]), tonumber(sp[2])
            -- 【修复 3】: 将 hour < 12 修正为 hour < 24，支持 24 小时制设置
            if (hour and minute and hour >= 0 and hour < 24 and minute >= 0 and minute < 60) then
                return value
            end
        end
    end

    return nil, "上网时间格式错误！(正确格式例如 06:10)"
end

-- 主机名列表预置
scut_drcom_hostname = scut_drcom:option(Value, "hostname", "向服务器发送的主机名")
scut_drcom_hostname.rmempty = false

local random_hostname = "DESKTOP-"
local randtmp
math.randomseed(os.time())
for i = 1, 7 do
    randtmp = math.random(1, 36)
    random_hostname = (randtmp > 10)
            and random_hostname..string.char(randtmp+54)
            or  random_hostname..string.char(randtmp+47)
end

-- 获取dhcp列表，加入第一个主机名候选
local dhcp_hostnames = split_string(luci.sys.exec("cat /tmp/dhcp.leases|awk {'print $4'}"), "\n") or {}

scut_drcom_hostname:value(random_hostname)
if dhcp_hostnames[1] then
    scut_drcom_hostname:value(dhcp_hostnames[1])
end
scut_drcom_hostname.default = random_hostname

return scut