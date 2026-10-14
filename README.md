# dsh-config-backup · DSH 全家桶配置备份

DeepSeek Harness（DSH）的全家桶配置备份仓库，用于**在一台新 PC 上一键复现本机 DSH 环境**。

只包含**全局设置类**配置：插件清单、profile 配置、Agent 预设、全局 skills、以及各插件的私有配置。**不包含**任何会话数据、本地代码、登录凭据、公司/私人品牌配置。

## 仓库结构

```
dsh-config-backup/
├── install.ps1                  # ★ Windows 一键恢复脚本
├── README.md
├── config/                      # 全局配置（拷到 ~/.dsh 对应位置）
│   ├── desktop/                 # desktop profile 配置
│   │   ├── package.json         # 插件依赖清单（恢复时据此逐个 dsh plugin add）
│   │   ├── cordis.yml
│   │   ├── cordis.patch.yml
│   │   └── pnpm-workspace.yaml
│   ├── boot-animation/          # 视频片头（dsh-boot-animation）配置
│   ├── status-rotator/          # 状态行文案（dsh-status-rotator）配置
│   └── .agent-presets/          # Agent 预设（liangshen / plan / review）
└── skills/                      # 全局 skills（SKILL.md）
```

## 用法（新 PC 一键恢复）

1. 安装 DSH：
   - 桌面端：安装 **DeepSeek Harness Desktop**；或
   - CLI：`npm i -g @deepseek-ai/dsh`
2. 克隆本仓库：

   ```bash
   git clone https://github.com/levent-JT/dsh-config-backup
   cd dsh-config-backup
   ```

3. 运行恢复脚本：

   ```powershell
   .\install.ps1
   ```

4. 重启 DSH（桌面端完全退出再打开；web 端重启进程 + `Ctrl+Shift+R` 硬刷新）

5. 补充本机私有配置（脚本不涉及）：
   - 登录凭据：`~/.dsh/.credentials.yaml`（手动登录）
   - API Key / 内部模型 Provider：设置页里配
   - 工作区 / 会话：自行新建

## 恢复的内容

| 类别 | 内容 |
|---|---|
| 插件 | desktop profile 全部依赖（从 `config/desktop/package.json` 逐个 `dsh plugin add`）|
| 启动动画 | 从独立仓库安装：`github:levent-JT/dsh-ritual-animation` |
| Profile 配置 | `cordis.yml` / `cordis.patch.yml` / `pnpm-workspace.yaml` |
| Agent 预设 | `liangshen` / `plan` / `review` |
| 全局 Skills | `delegate-code-to-agent` / `idea-mcp-first` / `java-dev` / `requirement-analysis` |
| 插件私有配置 | `boot-animation` / `status-rotator` |

## 明确不备份

- ❌ 会话数据（`~/.dsh/sessions`）、附件、日志、缓存
- ❌ 登录凭据（`.credentials.yaml`）—— **绝不进 git**
- ❌ 本地代码、工作区内容
- ❌ `node_modules`（恢复时由 pnpm/dsh 重新安装）
- ❌ 用量统计（`.dsh-usage-*.json`）
- ❌ **本机绝对路径、私人身份配置**（如启动动画的 identity、内部 Provider 端点）—— 这类配置本机自留，不进仓库

## 更新备份（本机改完配置后）

重新拷贝最新配置到仓库并提交：

```powershell
# 在仓库目录执行（示例，按需拷贝对应文件）
Copy-Item "$env:USERPROFILE\.dsh\profiles\desktop\package.json"      .\config\desktop\
Copy-Item "$env:USERPROFILE\.dsh\profiles\desktop\cordis.patch.yml"  .\config\desktop\
# ... 其它同理
git add -A
git commit -m "chore: sync dsh config"
git push
```

> 提示：`dsh plugin add` 会写 profile 的 `package.json`，每次装了新插件后记得重新同步 `config/desktop/package.json`。

## 启动动画插件

- 独立仓库：[levent-JT/dsh-ritual-animation](https://github.com/levent-JT/dsh-ritual-animation)
- 配置：`~/.dsh/jt-startup.json`（**本机自留，不进本仓库**——含品牌/身份配置）
- 设置入口：DSH 设置页 →「启动动画」
