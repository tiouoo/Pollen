# AUR 包与发布关系

## 当前决定

正式版的唯一实际发布包为 **`pollen-bin`**。不带渠道后缀的 Pollen 就是正式版，`stable` 与默认正式版使用同一份二进制，不单独维护发布渠道。此外启用 `pollen-commit-bin`、`pollen-nightly-bin` 两个独立预发布渠道包。

| 名称 | 关系 | AUR 发布方式 |
| --- | --- | --- |
| `pollen-bin` | 正式版二进制包，唯一实际上传包 | 独立的 AUR package base |
| `pollen` | 默认正式版，指向 `pollen-bin` | 由 `pollen-bin` 的 `provides` 声明 |
| `pollen-mc` | 默认正式版的 MC 别名，指向 `pollen-bin` | 由 `pollen-bin` 的 `provides` 声明 |
| `pollen-stable` | 正式版别名，指向 `pollen-bin` | 由 `pollen-bin` 的 `provides` 声明 |
| `pollen-stable-bin` | 正式版二进制别名，指向 `pollen-bin` | 由 `pollen-bin` 的 `provides` 声明 |
| `pollen-commit-bin` | main 提交构建 | 独立 AUR package base，提供 `pollen-commit` |
| `pollen-nightly-bin` | nightly 构建 | 独立 AUR package base，提供 `pollen-nightly` |

项目名称为“花粉”，英文统一使用 `pollen`，MC 别名为 `pollen-mc`。

`pollen-beta`、`pollen-alpha` 及各自的 `-bin` 变体暂不创建，也不创建 CNB 专用变体。commit / nightly 不声明为正式版别名，三个实际包互相冲突，避免覆盖同一安装目录和命令。

## 别名的实际含义

`provides` 用于声明包提供的能力和满足依赖，不是 AUR 网站的重定向，也不会为这些名称创建 AUR 页面、独立仓库或占用名称。不同 AUR helper 对虚拟名称的搜索和安装支持不同，安装说明统一使用实际名称：

```sh
paru -S pollen-bin
# 或
yay -S pollen-bin
```

不要为了别名单独上传内容相同的包或空壳包。AUR 提交规则要求包有实际用途，并明确禁止重复包。将来若真正引入源码包 `pollen`，需重新定义它与二进制包的关系，不能继续将其仅视为别名。

## 初始化与检查记录

2026-10-18：

- 项目上游：<https://github.com/tiouoo/Pollen>。
- 使用本机 `C:\Users\84067\.ssh\aur` 验证 SSH，AUR 返回账号 `tiouo`；未读取或复制私钥内容。
- AUR RPC 查询 `pollen`、`polllen-mc`、`pollen-bin`、`pollen-stable`、`pollen-stable-bin`，未返回现存包。查询不代表名称已被保留，也不能保证发布时仍可用。
- GitHub Releases API 未返回可发布的 Release，尚无正式版 Linux 二进制附件可供编写和验证实际安装配方。
- **尚未向 AUR 上传任何包，未占用任何名称。** 渠道配方模板位于 `packaging/aur/PKGBUILD.in`，由发布工作流填入真实版本、下载地址和校验和。

## 首次正式发布

1. 发布可用的 Linux 正式版二进制，确定版本、架构、许可证、依赖、下载 URL、校验和与归档内的启动文件路径。
2. 工作流自动渲染 `PKGBUILD`。正式版使用对应不可变 `vX.Y.Z` 标签的 AppImage，并计算 SHA-256；commit / nightly 使用移动标签和包含版本的本地缓存名，其 AppImage 校验和使用 `SKIP`。图标、桌面文件、许可证随配方上传。
3. 在 Arch Linux 干净构建环境中运行 `makepkg`，验证构建、安装和启动。以 `makepkg --printsrcinfo > .SRCINFO` 生成元数据，不手工维护。
4. 使用已有 AUR SSH 密钥克隆包仓库：

   ```sh
   GIT_SSH_COMMAND='ssh -i ~/.ssh/aur -o IdentitiesOnly=yes' git clone ssh://aur@aur.archlinux.org/pollen-bin.git
   ```

   Windows 密钥位置为 `C:\Users\84067\.ssh\aur`；在其他环境发布时使用该环境实际配置的安全密钥路径，不把私钥放入项目。

5. 将验证过的 `PKGBUILD`、生成的 `.SRCINFO` 和必要的打包辅助文件放入该仓库，使用维护者自己的署名提交并推送 `master`。不要上传应用二进制、构建产物或密钥。

首次有效推送即可创建 AUR 包；无需先上传空包。克隆新包时出现 “empty repository” 提示是正常现象，不是初始化失败。仅克隆空仓库不能保留名称。

参考：

- [AUR 提交指南](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [PKGBUILD：provides](https://wiki.archlinux.org/title/PKGBUILD#provides)

发布工作流通过 `uses: tiouoo/tiller/aur@main` 执行配方构建、生成 `.SRCINFO`、提交和推送；上述手工步骤用于排查及首次安装验收。尚未在本机执行任何 AUR 推送。新增的 tiller Action 需先发布到工具库的 main。
