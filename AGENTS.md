# AGENTS.md

## 提交与署名
- 除非用户明确要求，否则禁止自行提交（commit）或推送（push）。禁止将 AI 助手自身信息加入作者、共同作者或合作者信息，包括 `Co-authored-by` 署名。

## 异步任务与 UI
- 长时间操作必须支持取消：使用 ovo.dotnet 的 `Standard.Mvvm.Tasks.TaskManager`，将 `TaskExecutionContext.CancellationToken` 传递到所有下游异步 API；循环和阶段切换时检查取消，不吞掉取消异常，不继续启动后续步骤。取消父任务以联动子任务。
- 文件下载需持续报告进度（0–1）、已下载量和下载速度；总长度未知时使用不确定进度。合理节流，避免刷屏。
- UI 回调通过 `Dispatcher.UIThread` 调度；按钮触发的异步工作交给任务管理器，使用其状态通知 UI。沿用现有控件与回调 API，不凭名称猜测接口。
- 修改前先读 `src/ovo.dotnet/src/Standard.Mvvm/Tasks/`：`ReportProgress`、`SetRunning`、`SetWaiting` 在取消或终态会抛异常；`Complete`/`Fault` 只允许 Running、Waiting、Cancelling 状态。带执行回调的任务由执行器自动收尾，不在回调或 finally 中重复结束任务，也不把取消报告为成功。
- 排队的 UI/进度回调执行时重新检查 `!task.IsTerminal`、`!task.IsCancellationRequested` 且状态不是 `Cancelling`（取消令牌可能稍后才生效）。检查与更新仍存在竞态，需串行协调状态更新并处理预期取消；任务结束后丢弃迟到回调，包括描述更新。

## 本地化
- 用户可见文本使用本地化资源，不在 UI 代码中硬编码 (在所有语言下相同的时候，允许使用硬编码)。新增 UI 文案先添加到子模块 `src/pollen.localization/zh-hans/`，仅添加简体中文，其他语言由用户翻译；通过 `src/app/Pollen.Localization` 与现有 OvoUi.Lang API 使用。
- 按功能拆分 JSON 文件；功能增长时新增文件，不把所有文案堆进 `App.json`。JSON 支持多层嵌套，按页面、功能和操作合理分组，保持层级清晰；不要手改生成代码。

## 构建
在仓库根目录使用 .NET 10 SDK：
```powershell
dotnet build src/app/Pollen.Desktop/Pollen.Desktop.csproj -c Debug
```
主 UI 在 `src/app/Pollen`，控件子模块为 `src/ovoui.avalonia`；改动相关子模块后也用上述入口验证。Linux 构建前必须先确认 `dotnet` 的实际位置。不要假设它已经在 `PATH` 中；如果 SDK 安装在用户目录（例如 `/home/<user>/.dotnet/dotnet`），要把其目录加入当前 Shell 的 `PATH`，因为项目的构建目标可能会继续调用裸 `dotnet`：

## 文档扩展
本文件保持简短；规则增多时按主题拆到 `docs/agents/` 并在此添加入口，目录专属规则可放到对应目录的 `AGENTS.md`。
