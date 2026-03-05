# luci-app-scutclient
* 解压放到feeds/luci/applications
* 再执行./scripts/feeds install -a -p luci
* 然后make menuconfig
* 就可以在Luci的Applications看到编译选项

---

## 🚀 Modern Edition Update (2026) / 现代化版本更新说明

This fork has been significantly refactored to support **Modern OpenWrt/ImmortalWrt** (v21.02, v23.05, v24.10 and later). The original 10-year-old code has been modernized to fix critical UI and routing issues.

本分支经过深度重构，旨在完美支持 **现代 OpenWrt/ImmortalWrt 固件**（如 21.02、23.05、24.10 及更高版本）。针对原版代码在现代 LuCI 架构下的兼容性问题进行了专项修复。

### ✨ Key Improvements / 核心改进

* **Fixed LuCI 404 Errors**: Refactored `build_url` logic in `status.htm` and `logs.htm` to match modern dispatcher requirements. No more 404 errors when clicking "Redial" or "Logoff".
    * **修复 404 报错**：重构了状态页与日志页的路径构建逻辑，彻底解决了“重拨”、“下线”及“打包下载”按钮失效的问题。
* **Fixed CBI Rendering Crash**: Added null-checks for the `nettime` variable. This prevents the "Allowed Online Time" option from being silently hidden due to Lua runtime errors.
    * **修复界面崩溃**：解决了因空值导致的 CBI 渲染失败，恢复了“允许上网时间”设置项的显示。
* **24-Hour Logic Support**: Updated the `nettime` validation to support the full 24-hour range (`00:00-23:59`), allowing users to set wake-up times for midnight disconnections.
    * **24 小时制支持**：修正了上网时间校验逻辑，现在支持全天候设置（如设置 06:10 自动唤醒），完美应对校园网深夜断网。
* **Environment Cleanup**: Replaced global `string.split` with a local implementation to prevent pollution of the global Lua environment.
    * **环境规范化**：移除了对全局变量的污染，提高了插件在复杂固件环境下的稳定性。
* **Restored UI Tabs**: Fixed routing issues to restore the "About" and "Logs" tabs in the LuCI services menu.
    * **恢复功能选项卡**：修复了路由寻址错误，重新找回了丢失的“日志”与“关于”页面。

### 🛠 Installation / 安装建议

For ImmortalWrt 24.10+ users, it is recommended to compile this version using the latest SDK to ensure all dependencies (like `ucode` mapping) are correctly handled.

对于 ImmortalWrt 24.10+ 用户，建议使用本仓库源码重新编译 IPK，以确保其与现代 `rpcd` 权限机制完美兼容。
