# TokKit v0.1.0

Local AI token ledger for desktop coding tools.

面向桌面 AI 编码工具的本地 Token 台账。

## English

### Highlights

- Local-first token accounting across Codex, Warp, Kaku proxy, and CodeBuddy
- Daily reports grouped by date, terminal, model, source, and client
- Explicit `exact`, `partial`, and `estimated` coverage instead of flattening everything into one misleading total
- macOS `launchd` automation for hourly scans and daily report generation
- `tok` helper flow for Kaku and zsh users, including inline hints, autosuggest, and completion

### What is included

- `tokkit` CLI
- `tok` operator shortcut
- `tokstat` compatibility alias
- local SQLite usage ledger
- Kaku-compatible OpenAI proxy for precise upstream usage capture
- Warp and CodeBuddy local ingesters
- product brief and GitHub publish plan

### Known limits

- Codex local logs currently expose provider-level metadata but not an exact model name
- Warp historical day splits are conversation-based, so older backfill is approximate by day
- Some desktop clients are still untracked or only partially covered

## 中文

### 亮点

- 以本地优先的方式统一统计 Codex、Warp、Kaku 代理和 CodeBuddy 的 Token 数据
- 支持按日期、终端、模型、来源、客户端多维度查看日报和区间报表
- 明确区分 `exact`、`partial`、`estimated`，避免把不同精度的数据混成一个误导性的总数
- 支持 macOS `launchd` 自动化，每小时扫描、每天自动生成日报
- 为 Kaku 和 zsh 用户提供 `tok` 快捷流，包括灰色提示、自动建议和补全

### 本次发布包含

- `tokkit` CLI
- `tok` 快捷命令
- `tokstat` 兼容别名
- 本地 SQLite 使用台账
- 面向 Kaku 的 OpenAI 兼容代理
- Warp 与 CodeBuddy 本地采集器
- 产品简介和 GitHub 发布说明

### 当前限制

- Codex 本地日志目前只有 provider 级别信息，还没有稳定的精确模型名
- Warp 的历史补扫以 conversation 为单位，所以旧数据按天拆分时是近似值
- 部分桌面客户端仍然未接入，或者只有部分覆盖
