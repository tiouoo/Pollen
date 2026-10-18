# Native AOT 构建与检查

`Pollen.Desktop` 的 Release 发布默认使用 Native AOT，其引用的 Pollen、本地化和运行库一起编译为原生程序。源码生成器只在构建时运行，不需要发布为 AOT；尚未被主程序引用的子模块不属于桌面发布产物。

日常开发仍可使用普通 Debug 构建和调试：

```powershell
dotnet build src/Pollen.Desktop/Pollen.Desktop.csproj -c Debug
```

在目标系统上发布，例如 Windows x64：

```powershell
dotnet publish src/Pollen.Desktop/Pollen.Desktop.csproj -c Release -r win-x64 --self-contained true -o dist
```

Windows 需要 Visual Studio 的 C++ 桌面开发工具及 Windows SDK；Linux 需要 clang 和 zlib 开发包；macOS 需要 Xcode 命令行工具。不同操作系统在对应系统上构建。发布目录中的原生依赖必须与主程序一起打包，不能只复制 exe。

## 自动检查

`.github/workflows/test-aot.yml` 在 PR、main 分支推送及手动触发时执行，覆盖 Windows x64、Linux x64、macOS x64/arm64。

1. 实际发布 Native AOT 程序，将编译、裁剪和 AOT 兼容警告作为错误。
2. 直接运行发布后的程序，通过 `--aot-smoke-test <报告路径>` 检查原生运行时、主窗口、图标、欢迎文本布局、语言切换和回退、嵌入的构建信息。
3. 60 秒内未完成、异常退出、断言失败或缺少成功报告均判定失败；保存发布日志和测试报告，保留 7 天。

测试使用固定构建信息，`scripts/test-aot.py` 会清除运行时的构建变量，确保测试的是编译时嵌入的信息。普通启动不会执行这些检查。Linux 使用 Xvfb 提供显示环境。

## 后续开发

- 新增依赖后关注 PR 的 `test/aot` 结果。不要通过全局屏蔽 IL2026、IL3050 等警告绕过检查；优先使用兼容 AOT 的 API、显式类型和源码生成的 JSON 序列化上下文。
- XAML 默认使用编译绑定，新增绑定时声明相应的 `x:DataType`。
- 新增页面或功能后，在 `src/Pollen.Desktop/AotSmokeTest.cs` 补上有代表性的运行检查。当前检查覆盖现有欢迎页，并不能自动验证未来所有功能或外部服务。
- 测试失败时，在该次 Actions 运行中下载 `aot-test-<RID>` 查看报告。这里测试原生发布目录，不包含安装器安装、系统集成或真实游戏启动。
