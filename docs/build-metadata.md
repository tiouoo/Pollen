# 构建版本信息

Pollen 使用 `src/ovo.dotnet/src/Standard` 内置的构建值功能将构建值写入 Pollen 程序集的 `AssemblyMetadataAttribute`，通过 `Pollen.BuildInfo` 读取，不再嵌入或读取 `version.txt`、`version-ci.txt`、`package-type.txt`。

PR、commit、nightly 的滚动版本基准为北京时间 **2026-10-18 00:00:00（UTC+08:00）**，格式仍为 `0.天数.小时.分钟`。正式版本继续使用 Tiller 的稳定版本计算。

基础版本统一在 `src/app/Pollen/BuildValues.props` 的 `PollenBaseVersion` 中维护。准备任务读取这个构建配置，Tiller 生成的 JSON 仅用于工作流任务间传值；各打包任务把字段拆成环境变量，交给通用 targets 在编译时注入：

| 环境变量 | BuildInfo 属性 |
| --- | --- |
| `POLLEN_BUILD_TYPE` | `Type` |
| `POLLEN_BUILD_VERSION` | `Version` |
| `POLLEN_BUILD_TIME` | `BuildTime` |
| `POLLEN_BUILD_ACTION` | `Action` |
| `POLLEN_BUILD_COMMIT` | `Commit` |
| `POLLEN_BUILD_TIMESTAMP` | `Timestamp` |
| `POLLEN_BUILD_VERSION_TITLE` | `VersionTitle` |
| `POLLEN_PACKAGE_TYPE` | `PackageType` |

`Version` 对应原元数据 JSON 的 `version`（正式版为发布版本，滚动版为基础版本）。打包用的四段滚动版本仍由工作流的 `app_version` 传给 `-p:Version`。正式版本不注入 `Timestamp`。

环境变量放在打包 job 上，使直接执行的 dotnet、PupNet 和 macOS BundleApp 构建都能读取。程序运行后修改环境变量不影响这些版本属性。

本地未设置变量时，`Type`、`PackageType` 为 `development`，`Version` 使用基础版本，其余可选字段为 null。例如本地验证注入：

```powershell
$env:POLLEN_BUILD_TYPE = 'nightly'
$env:POLLEN_BUILD_COMMIT = 'abcdef0'
$env:POLLEN_PACKAGE_TYPE = 'portable'
dotnet build src/app/Pollen.Desktop/Pollen.Desktop.csproj -c Debug
```

Standard 的项目引用、NuGet 使用方式与凭据读取示例见 `src/ovo.dotnet/src/Standard/Build/README.md`。
