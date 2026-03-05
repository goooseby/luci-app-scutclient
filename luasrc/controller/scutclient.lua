module("luci.controller.scutclient", package.seeall)

function index()
    entry({"admin", "services", "scutclient"}, alias("admin", "services", "scutclient", "settings"), _("SCUTClient"), 10).dependent = true
    
    entry({"admin", "services", "scutclient", "settings"}, cbi("scutclient/scutclient"), _("设置"), 10).leaf = true
    -- 状态页面：交由 action_status 处理逻辑并渲染模板
    entry({"admin", "services", "scutclient", "status"}, call("action_status"), _("状态"), 20).leaf = true
    entry({"admin", "services", "scutclient", "logs"}, template("scutclient/logs"), _("日志"), 30).leaf = true
    -- About 页面
    entry({"admin", "services", "scutclient", "about"}, template("scutclient/about"), _("关于"), 40).leaf = true
    -- API 接口（不显示在菜单上）
    entry({"admin", "services", "scutclient", "netstat"}, call("get_netstat")).leaf = true
    entry({"admin", "services", "scutclient", "get_log"}, call("get_log")).leaf = true
    entry({"admin", "services", "scutclient", "scutclient-log.tar"}, call("get_dbgtar")).leaf = true
end

function action_status()
    local sys = require "luci.sys"
    local http = require "luci.http"
    
    -- 处理网页前端传来的“重拨”和“下线”动作
    if http.formvalue("logoff") == "1" then
        sys.call("/etc/init.d/scutclient stop > /dev/null 2>&1")
    elseif http.formvalue("redial") == "1" then
        sys.call("/etc/init.d/scutclient restart > /dev/null 2>&1")
    end
    
    -- 处理完动作后，渲染状态页面
    luci.template.render("scutclient/status")
end

function get_netstat()
    local sys = require "luci.sys"
    local http = require "luci.http"
    local hcontent = sys.exec("wget -qO- http://whatismyip.akamai.com 2>/dev/null | head -n1")
    local nstat = { stat = 'no_login' }
    
    if hcontent and hcontent:find("(%d+)%.(%d+)%.(%d+)%.(%d+)") then
        nstat.stat = 'internet'
    elseif hcontent == '' then
        nstat.stat = 'no_internet'
    end
    
    http.prepare_content("application/json")
    http.write_json(nstat)
end

function get_log()
    local fs = require "nixio.fs"
    local http = require "luci.http"
    local log = fs.readfile("/tmp/scutclient.log") or "还没有日志记录"
    http.prepare_content("text/plain")
    http.write(log)
end

function get_dbgtar()
    local sys = require "luci.sys"
    local fs = require "nixio.fs"
    local http = require "luci.http"

    local tar_dir = "/tmp/scutclient-log"
    local tar_files = {
        "/etc/config/network",
        "/etc/config/scutclient",
        "/tmp/dhcp.leases"
    }

    fs.mkdirr(tar_dir)
    -- 修复：现代 Lua 已弃用 table.foreach，改用标准的 ipairs
    for _, v in ipairs(tar_files) do
        sys.call("cp " .. v .. " " .. tar_dir .. " 2>/dev/null")
    end
    sys.call("cat /tmp/scutclient.log* >> " .. tar_dir .. "/scutclient.log 2>/dev/null")

    http.header("Content-Disposition", "attachment; filename=\"scutclient-log.tar\"")
    http.prepare_content("application/octet-stream")
    http.write(sys.exec("tar -C " .. tar_dir .. " -cf - ."))
    sys.call("rm -rf " .. tar_dir)
end