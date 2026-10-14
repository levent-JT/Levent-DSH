---
name: idea-mcp-first
description: 读代码/查调用链/定位符号必须优先走 IDEA MCP（mcp__idea__*）；IDEA MCP 不可用时不得擅自降级，必须先询问用户——由用户负责打开 IDEA，还是改用 grep/read 等文本方式读代码（改用其他方式时结论须显式标注置信度下降）。
when-to-use: 任何需要读 Java 或其他语言代码、查方法/API 上下游调用、定位符号、看编译问题、读文件内容时；无论当前会话工作目录是哪个项目都适用。
---

# 读代码优先走 IDEA MCP（不通必问，不擅自降级）

凡是「读代码 / 读工程 / 查调用」相关任务（Java 优先，其他语言同样适用），一律**优先走 IDEA MCP**。
IDEA MCP 一旦不可用，**不许默默降级**——必须先询问用户怎么处理，二选一。

## 一、优先工具映射（先想这些）

| 想做什么 | 用 IDEA MCP 的哪个工具 |
|---|---|
| 定位符号（只知短名/片段） | `mcp__idea__search_symbol` → 拿到全限定名再走调用链 |
| 谁调用它 / 它调用谁 | `mcp__idea__analyze_calls`（`INCOMING_CALLS` 上游 / `OUTGOING_CALLS` 下游） |
| 单点语义 / 声明 / 文档 | `mcp__idea__get_symbol_info` |
| 编译错误与告警 | `mcp__idea__get_file_problems` / `mcp__idea__lint_files` |
| 读文件内容 | `mcp__idea__read_file`（含 jar/jrt/反编译） |
| 定位/浏览文件 | `mcp__idea__search_text` / `search_regex` / `search_file` / `list_directory_tree` |
| 在编辑器打开文件 | `mcp__idea__open_file_in_editor` |

- **`projectPath` 必须传 IDEA 当前实际打开的工程根**（以 IDE 为准，不是本会话工作目录）。
  本会话目录 ≠ IDE 打开的工程时，以 IDE 打开的为准；不确定就随调用带上 IDE 打开的工程路径。
- 名字含糊时：`analyze_calls` 会返回精确签名，把它原样回传，不要自己拼签名。

## 二、什么算「IDEA MCP 不通」（触发询问的判定）

出现以下任一情况即视为不通，进入第三节：

1. `mcp__idea__*` 工具根本不在当前工具列表（插件未加载 / 未连接）。
2. 调用报错 / 超时 / 连接失败。
3. 返回「project not found」「工程未打开」之类错误。
4. 目标代码不在任何已打开工程的索引里（IDEA 只索引打开中的工程）。

## 三、不通时：必须问用户，二选一（禁止自动降级）

用 `ask_user` / `ask_user_question` 问用户，两个选项：

- **选项 A：用户负责打开/切换 IDEA。**
  用户去 IDE 打开（或切换到）目标工程后，重试 IDEA MCP；
  若工具本会话已注册，直接重试即可；若工具未注册（第 1 种情况），用户打开后需**新开会话**才会带上 `mcp__idea__*`。
- **选项 B：用其他方式读代码。**
  只有用户明确选了这个，才允许走文本降级路径：
  1. `grep` 一次找全（定义 + 调用方 + 被调用方）——注意会混入同名字段访问与 import；
  2. `read` 定向精读确认；
  3. 结论必须显式标注「**本次未走 IDEA MCP，调用链为文本匹配结果，置信度下降**」，不得当作已确认的调用关系。

**禁止：**
- 不问用户就自动降级到 grep/read。
- 把 grep 文本匹配结果直接当已确认的调用链结论。
- 自行假设「IDEA 一定打不开 / 用户一定不想开」然后替用户做决定。

## 四、已知边界（要说出来，不要默认覆盖全）

- IDEA MCP 只能看到 **IDE 当前已打开**工程的内存索引；未打开的工程它看不见，哪怕目录在工作区里。
- 反射、Spring 注解装配、SPI、配置驱动的调用，IDEA MCP 也可能跟不到——这类断点要显式说明。
- 多个 IDEA 窗口同时打开时，以用户指定的那个工程为准。

## 五、与其他配置的关系

- 与 `~/.dsh/AGENTS.md` 的「Java 代码导航」段落配套：AGENTS.md 是常驻工作守则（对所有会话生效），本 skill 是触发式细则；两者都坚持「IDEA MCP 优先、不通必问用户」。
- 本 skill 触发时以本文件为准；未触发时 AGENTS.md 的守则仍生效。
