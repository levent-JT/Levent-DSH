---
name: delegate-code-to-agent
description: 当用户要求写/实现/修复/重构代码时，先出一份可审阅的方案，然后（在写任何代码之前）问用户要用哪个 agent 来写码——Qoder / Claude Code / Codex / DSH 自己写。用户选定后才交给对应子 agent 实现，DSH 负责审阅与验收。绝不在未询问前自动调用任何子 agent。
whenToUse: 当用户想写代码、实现功能、修 bug、重构，且可能委托给本地子 agent（Qoder / Claude Code / Codex）时使用。凡涉及“写代码”的任务都应先走“方案 → 询问用哪个 agent → 委托（可选）→ 审阅”的流程，不要在没问用户前就直接动手写或直接调用子 agent。
user-invocable: true
---

# 把写码委托给所选 agent（DSH 当编导+审阅，子 agent 当写码手）

你（DSH）负责方案与验收；写码这个动作交给用户选定的子 agent（Qoder / Claude Code / Codex），或由你自己写。**任何代码落盘之前必须先经用户确认，并先确认“由谁来写”。**

## 流程

1. **先定方案。** 把用户需求整理成一份具体、可审阅的方案（做什么、改哪些文件/模块、怎么设计、验收标准、怎样算“完成”）。要简短具体，别写成小说。

2. **写任何代码之前，先问用户。** 用面向用户的提问工具（ask_user / ask_user_question）确认两件事：
   - 方案对不对？要不要改？（给一个“改方案”选项）
   - **要用哪个 agent 写码？** 选项典型为：
     - `用 Qoder 写` → 走 `subagent_qoder`
     - `用 Claude Code 写` → 走 `subagent_claude_code`
     - `用 Codex 写` → 走 `subagent_codex`
     - `你自己写` → DSH 直接写

3. **若用户选了某个子 agent，** 用下面任一路径把方案交给它，**该 agent 自己决定怎么实现**（读仓库、选文件、写码、跑命令）；这一步你不要自己写代码：
   - **路径一（首选，DSH 原生工具）**：调用对应的 `subagent_qoder(description, prompt)` / `subagent_claude_code(...)` / `subagent_codex(...)` 工具。`prompt` 必须是**自包含**的——子 agent 看不到本次会话，只拿到 prompt 文本 + 工作目录（见下方「子 agent 的 prompt 模板」）。
   - **路径二（备用，直接命令）**：执行下方已验证的命令。

4. **审阅产出。** 子 agent 是直接在磁盘上改文件的。用 `git diff`（或 `read` 被改的文件）查看改动，跑相关测试/构建，再向用户汇报。若有问题，问用户要不要让该子 agent 继续改。

## 子 agent 能力速览

| agent | 工具 | Provider | 走什么 | 依赖 |
|---|---|---|---|---|
| Qoder (CN) | `subagent_qoder` | `qoder` | 本机 `qoderclicn.exe` | `~/.qoder-cn/` 授权 |
| Claude Code | `subagent_claude_code` | `claude-code` | Claude Agent SDK / 本机 `@anthropic-ai/claude-code` | `~/.claude/` 授权 |
| Codex | `subagent_codex` | `codex` | Codex org 协议 / `@openai/codex` | `~/.codex/` 授权 |

> 三个子 agent 都走**你自己的账号/授权**，会消耗 credits / tokens，任务越大花得越多。

## 委托命令（本机已验证/可用）

- **Qoder (CN)**：`& "$env:USERPROFILE\.qoder-cn\bin\qoderclicn\qoderclicn.exe" -p "<任务>" --output-format json --permission-mode accept_edits -w "<项目目录>"`
- **Claude Code**：`claude -p "<任务>" --output-format stream-json --permission-mode accept_edits -w "<项目目录>"`（按本机 `claude` CLI 实际支持的参数校准）
- **Codex**：`codex exec --json "<项目目录>"`（或本机 Codex CLI 对应的非交互 exec 形态；以已安装版本参数为准）

> `--output-format json/stream-json` 只是各 agent 的**自述**，真正的改动在磁盘上——务必用 `git diff`/读文件核对，别只看 `result` 文本。

### 解析返回值
- `result`：agent 对自己做了什么的总结。
- `is_error` / `subtype` / `stop_reason`：成功/失败/结束原因。
- `permission_denials`：被权限拦下的操作清单。
- `session_id`：可用于续接（`-r <id>`）。

### 如果子 agent 还需要跑命令（不只是改文件）
`accept_edits` 会挡住 shell 命令。只在用户同意后放宽，例如：
```
--allowed-tools "Read,Edit,Write,Bash(git status)"
```
或仅在完全可信环境用 `--dangerously-skip-permissions` / `--yolo`。

## git 归属（git-ai / git-ai-attribution）——不归 DSH 管

**DSH 不为子 agent 的产物跑 `git-ai-attribution` 的 pre/post，也不要改 git notes。** 这部分交给**各子 agent 自己在目标仓库里配置**。所以：

- 委托给子 agent 的任务里，**明确要求它在 `-w` 指向的仓库里先给自己配好归属**，再写码。把「如何配」写进任务提示词。
- DSH 之后只做审阅（`git diff`/读文件/跑测试），**不要对子 agent 改过的文件执行 `harness-gitai pre/post`**。

给子 agent 的自配（默认用 B，写进任务提示词）：

**B. 走 DSH 同款 AI 覆盖率法（默认）**——让改动计入 `git-ai blame/stats` 的 `claude` 覆盖率，子 agent 自己在编辑前/后调用本机工具：
```
node "$env:USERPROFILE\.git-ai\harness\harness-gitai.js" pre <文件...>   # 编辑前
node "$env:USERPROFILE\.git-ai\harness\harness-gitai.js" post <文件...>  # 编辑后
```
> 需要给子 agent 放行对应 Bash 权限（例如 `--allowed-tools "Bash(harness-gitai...)"`），否则它跑不了。这是正确的默认。

**A. 简单身份法（备选）**——只想让 `blame` 别显示成用户本人，而不计入 git-ai 覆盖率时，让子 agent 用临时身份提交：
```
git -c user.name="<agent>" -c user.email="<agent>@local" commit -m "..."
```
> 前提：提交仍由**用户手动**完成（DSH 与子 agent 都不自动 commit）。缺点是不进 git-ai `claude` 覆盖率。

## 子 agent 的 prompt 模板（自包含，必须照此组装）

`subagent_*` 工具是“干净房间”：子 agent **只**拿到 prompt 文本 + 工作目录（`-w`），不继承会话、不注入 persona、不自动带 git-ai 指令。所以 `prompt` 必须一次性写全：

```
你是资深工程师，在本仓库内实现以下方案。<方案正文：做什么/改哪些文件/设计/验收标准>

## 硬性要求
- 严格匹配本仓库既有的分层/命名/异常/事务等约定，不引入项目中不存在的模式。
- 逐段写行级注释（说明“为什么”）。

## git-ai 归属（必须执行，顺序不能错）
对每一个你将要编辑的文件 <file>：
1) 编辑前先运行：node "$env:USERPROFILE\.git-ai\harness\harness-gitai.js" pre <file>
2) 然后编辑 <file>
3) 编辑后立即运行：node "$env:USERPROFILE\.git-ai\harness\harness-gitai.js" post <file>
不要 git commit。

## 完成后汇报
列出你改过的文件清单，以及 pre/post 是否都执行成功。
```

要点：
- **pre/post 必须由子 agent 自己跑**；若反馈 pre/post 被拒，**不要**让它继续写码（否则产出无法归属），先向用户说明，或改走“直接命令”路径手动配权。
- 验收时用 `git-ai blame <file>` / `git-ai stats HEAD --json` 核对归属是否记成 `claude`。

## 安全提示
- `-w` 必须指向**真实的项目目录**，子 agent 会在那里直接落盘。
- 子 agent 走你的账号、消耗 credits/tokens，任务越大花得越多。
- 一次运行可能长达数分钟；你自己调用时给足时间或放后台跑。
- 归属按上面「git 归属」一节处理：**DSH 不介入，子 agent 自配**。
- Codex 若走 app-server 协议，需本机 Codex 端已就绪（授权在 `~/.codex/`）；Claude Code 走 Agent SDK，授权在 `~/.claude/`。
