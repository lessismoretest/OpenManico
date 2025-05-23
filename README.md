# OpenManico

<div align="center">
  <img src="OpenManico/Assets.xcassets/AppIcon.appiconset/mac128.png" width="128" height="128" alt="OpenManico Icon">
  <p><strong>MacOS App/Web 快捷启动工具</strong></p>
</div>

OpenManico 是一个纯 Cursor 编写的轻量级的 macOS 应用程序，通过 Option + 数字/字母键快速切换应用程序，Option + Command + 数字/字母键快速打开网站，提高工作效率。

重要：
悬浮窗功能参考 Manico [https://manico.im/](https://manico.im/)，圆环模式参考 Kando [https://github.com/kando-menu/kando](https://github.com/kando-menu/kando)
有能力的还是支持下原作者！

如有侵权，请联系我下架！纯免费应用，无任何收费项目！

## 应用截图

<div align="center">
  <img src="Screenshots/floating.png" width="800" alt="悬浮窗">
  <p><em>悬浮窗界面</em></p>
  <img src="Screenshots/floating2.png" width="800" alt="悬浮窗2">
  <p><em>悬浮窗界面1</em></p>
  <img src="Screenshots/float2.png" width="800" alt="悬浮窗2">
  <p><em>悬浮窗界面2</em></p>
  <img src="Screenshots/circlering-setting.png" width="800" alt="圆环模式界面">
  <p><em>圆环模式界面</em></p>
  <img src="Screenshots/支持自定义gif.gif" width="800" alt="圆环内支持自定义gif">
  <p><em>圆环内支持自定义gif</em></p>
  <img src="Screenshots/ringsetting.png" width="800" alt="圆环模式界面2 ">
  <p><em>圆环模式界面</em></p>
  <img src="Screenshots/appsetting.png" width="800" alt="通用设置界面">
  <p><em>App快捷键设置界面</em></p>
  <img src="Screenshots/webset.png" width="800" alt="网站快捷键设置界面">
  <p><em>网站快捷键设置界面</em></p>
  <img src="Screenshots/setting.png" width="800" alt="通用设置界面">
  <p><em>通用设置界面</em></p>
  <img src="Screenshots/floatset.png" width="800" alt="悬浮窗设置界面">
  <p><em>悬浮窗设置界面</em></p>
  <img src="Screenshots/data.png" width="800" alt="数据统计界面">
  <p><em>数据统计界面</em></p>


</div>

## 特性

- 🚀 快速切换：使用 Option + 数字键(1-9)或字母键(A-Z)快速切换应用
- 🌐 网站快捷键：使用 Option + Command + 数字键(1-9)或字母键(A-Z)快速打开网站
- 🎯 场景管理：应用快捷键和网站快捷键支持场景管理，每个场景可以有不同的快捷键配置
- 📂 分组管理：支持将应用和网站分组管理
- 🔄 双向切换：
  - 再次按下相同快捷键切换回上一个应用
  - 单击 Option 键快速切换到上一个应用
  - 在悬浮窗中点击当前运行的应用可切换回上一个应用
  - 在圆环模式中点击当前运行的应用也可切换回上一个应用
- 🎨 主题切换：支持浅色/深色主题，可跟随系统
- 📌 悬浮窗：支持丰富的显示模式和样式自定义
   - 支持多种显示模式:
     - 显示所有已安装应用
     - 显示运行中应用
   - 支持双击 Option 键快速显示/隐藏悬浮窗
   - 支持窗口置顶固定和自动隐藏
   - 支持自定义窗口尺寸、位置和圆角
   - 支持自定义主题(跟随系统/浅色/深色)
   - 支持毛玻璃效果和透明度调节
   - 支持工具栏显示和快速操作
   - 支持应用图标大小和名称显示设置
   - 支持快捷键标签样式自定义
   - 支持分割线显示和样式设置
   - 支持鼠标悬停动画效果
   - 支持鼠标滑过菜单栏自动显示悬浮窗
- 🔵 圆环模式：按住Option键触发圆环快速启动界面
   - 支持自定义圆环大小、内圈直径、扇区数量和透明度
   - 支持自定义圆环主题、扇区高亮颜色和不透明度
   - 支持自定义显示位置（跟随鼠标或屏幕中心）
   - 支持键盘快捷键和鼠标点击/悬停操作
   - 支持鼠标悬停音效和触感反馈
   - 支持圆环动画效果和图标出现动画
   - 支持显示应用图标和应用名称
   - 支持在圆环中心显示自定义GIF/图片
   - 支持自定义中心指示器大小和内圈填充
   - 支持长按触发和动画速度调节
- 📊 数据统计：
  - 支持数据可视化展示
  - 支持统计快捷键使用次数
  - 支持统计悬浮窗使用次数
  - 支持统计圆环模式使用次数
  - 支持统计 Option 单击和双击次数
  - 支持统计每个快捷键的使用频率
  - 支持统计每个应用的切换频率
- ⚡️ 性能优异：后台运行，资源占用极低
   - 📦 安装包较大：主要是因为预置了圆环模式的背景图片资源
- 🔒 安全可靠：无需网络连接，数据本地存储
- 💾 配置备份：支持从 JSON 文件导入导出快捷键和分组

## 安装

1. 从 [Releases](https://github.com/lessismoretest/OpenManico/releases) 下载最新版本
2. 将应用拖入应用程序文件夹
3. 首次运行时授予必要的权限

<details>
<summary><strong>首次运行权限设置指南</strong></summary>

1. 辅助功能权限
   - 首次运行时会提示授予辅助功能权限
   - 或手动前往：系统设置 > 隐私与安全性 > 辅助功能
   - 勾选 OpenManico
</details>

## 使用方法

1. 应用快捷键设置：
   - 打开应用后，在左侧选择"App快捷键"
   - 点击"选择应用"为数字键或字母键绑定目标应用
   - 使用 Option + 对应按键切换到目标应用
   - 在目标应用中再次按下相同快捷键可返回上一个应用

2. 网站快捷键设置：
   - 在左侧选择"网站快捷键"
   - 在对应的数字键或字母键行输入目标网址
   - 使用 Option + Command + 对应按键快速打开网站
   - 支持网站图标显示，方便识别

3. 悬浮窗使用：
   - 在通用设置中开启悬浮窗功能
   - 悬浮窗会显示当前已设置的快捷键
   - 支持自定义悬浮窗大小、位置和外观
   - 位置支持九宫格预设位置和自定义坐标
   - 支持毛玻璃效果和不透明度调节
   - 支持实时预览窗口效果
   - 可以通过拖拽调整悬浮窗位置
   - 支持自定义悬浮窗透明度
   - 支持多种显示模式：
     * 显示所有快捷键应用
     * 只显示已打开的快捷键应用
     * 显示所有已安装应用
     * 显示应用切换器应用（类似 Command+Tab）

4. 圆环模式使用：
   - 在设置中启用圆环模式
   - 按住Option键触发圆环界面
   - 圆环会显示当前已配置的快捷键应用
   - 可通过数字/字母键或鼠标点击选择应用
   - 支持自定义圆环外观：
     * 调整圆环大小和透明度
     * 设置圆环颜色和边框样式
     * 选择显示位置（跟随鼠标或屏幕中心）
     * 配置是否显示应用图标或仅显示数字/字母

5. 配置导入导出：
   - 在通用设置中点击导出按钮（向上箭头）可导出当前所有快捷键配置
   - 点击导入按钮（向下箭头）可导入之前导出的配置文件
   - 支持导入导出 App 快捷键和网站快捷键及场景配置,可单选多选
   - 导入时会自动合并现有配置


## 权限说明

应用需要以下权限才能正常工作：
- 辅助功能权限：用于监听全局快捷键

## 系统要求

- macOS 12.0 或更高版本
- Apple Silicon 或 Intel 处理器
- 约 10MB 可用空间

## 开发环境

- Xcode 15.0+
- SwiftUI
- Swift 5.9+

## 反馈与贡献

- 提交 Issue：[GitHub Issues](https://github.com/lessismoretest/OpenManico/issues)
- 功能建议：欢迎提交 Pull Request

## 许可证

[MIT License](LICENSE)

## 致谢

感谢所有为这个项目提供反馈和建议的用户。 