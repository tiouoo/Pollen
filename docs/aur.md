# AUR 包与发布关系

## 渠道与别名包

三个二进制主包分别发布正式版、main 提交构建和 nightly。别名是独立依赖包，不包含应用文件；安装别名时由 AUR helper 拉取对应主包。

| 渠道 | 二进制主包 | 依赖主包的别名包 |
| --- | --- | --- |
| 正式版 | `pollen-bin` | `pollen`、`pollen-mc`、`pollen-stable`、`pollen-stable-bin` |
| commit | `pollen-commit-bin` | `pollen-commit` |
| nightly | `pollen-nightly-bin` | `pollen-nightly` |

每个名称均对应独立 AUR package base，需要成功发布后才能被搜索到。stable 与默认正式版使用同一份二进制，不单独维护发布渠道。暂不创建 beta、alpha 或 CNB 专用包。

```sh
paru -S pollen-stable
# 或直接安装正式版主包
yay -S pollen-bin
```

## 依赖与冲突

- 三个主包两两冲突，包括正式版与 commit，避免覆盖相同安装目录和命令。
- 别名包只依赖对应主包，不固定版本，允许主包独立升级。
- 主包允许自己的渠道别名共存，但与其他渠道主包和别名冲突。
- 所有别名包互相冲突；别名也与其他渠道主包冲突。
- 主包不再通过 provides 声明这些别名，避免绕过实际别名包及其冲突关系。

例如，从 pollen-stable 切换到 pollen-commit，需要移除 pollen-stable 和 pollen-bin，再安装 pollen-commit 与 pollen-commit-bin。用户需要确认冲突移除；具体提示及依赖求解行为由 AUR helper 和 pacman 决定，不使用安装脚本强制卸载。

同渠道切换别名只替换别名，保留主包。直接再次安装已存在的本渠道主包不会移除本渠道别名，因为别名本身依赖它。

## 发布流程

工作流 `.github/workflows/release.yml` 按渠道生成包名矩阵，调用 `.github/.packaging/aur/prepare.sh` 渲染配方：

- `PKGBUILD.in`：二进制主包。正式版下载不可变版本标签下的 AppImage 并计算 SHA-256；commit / nightly 使用移动标签及包含版本的缓存名，AppImage 校验和使用 SKIP。
- `PKGBUILD.alias.in`：只包含依赖与冲突元数据的别名包，不下载二进制。

每个包通过 `tiouoo/tiller/aur@main` 构建验证、运行 `makepkg --printsrcinfo` 生成 `.SRCINFO`，再发布到对应 AUR 仓库。需要配置 AUR_SSH_PRIVATE_KEY 和 AUR_USERNAME。主包与别名分别发布，单个包失败不会取消同渠道其他包的发布；失败包需要重试。

本地修改不会立即创建或更新线上包。2026-10-18 查询时，线上仅有 pollen-commit-bin，版本为 0.100.14.59-1；其余名称需要各渠道工作流成功发布。

## AUR 规则

上述为项目期望的别名依赖包设计。AUR 对重复包和缺乏实际用途的包有限制，这些仅用于别名的包可能被维护团队拒绝或删除；名称能否长期保留取决于 AUR 审核。

参考：

- [AUR 提交指南](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [PKGBUILD](https://wiki.archlinux.org/title/PKGBUILD)
