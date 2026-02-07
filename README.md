# fsrs_ex (Fsrs)

_在 Elixir 中使用 FSRS（Free Spaced Repetition Scheduler）构建间隔重复系统。_

`fsrs_ex` 是一个面向 Elixir 的 FSRS 调度器实现，模块名为 `Fsrs`。

本项目定位非常明确：**直接对齐并移植 `open-spaced-repetition/py-fsrs` 的调度器行为**，当前基线为 **py-fsrs v6.3.0（FSRS-6）**。

## 项目状态

- 算法版本：FSRS-6（21 参数）
- 对齐基线：`py-fsrs v6.3.0`
- 许可证：MIT
- 仓库定位：公开仓库（public）

## 这个库做了什么

- 提供 `Scheduler` / `Card` / `ReviewLog` / `Rating` / `State` 的完整建模
- 支持学习、复习、再学习三种状态迁移
- 支持 `reschedule_card/3`（按历史日志重放重排）
- 支持 `to_dict` / `from_dict` 与 `to_json` / `from_json`
- 与 Python 版本保持跨语言数据互通字段格式（含 `+00:00` 时间格式）

## 直接移植（Port）范围说明

本项目明确是从 Python 版本移植，重点对齐如下：

- 默认参数（21 个）与 py-fsrs v6.3.0 一致
- 参数数量和边界校验与 py-fsrs 行为一致
- 可回忆性计算使用“按天 elapsed days”语义（非小数天）
- `reschedule_card` 语义与 py-fsrs 保持一致（校验 card_id、排序日志后重放）
- 序列化字段名与结构保持一致

## 安装

在 `mix.exs` 中加入依赖：

```elixir
def deps do
  [
    {:fsrs_ex, "~> 0.1.0"}
  ]
end
```

然后执行：

```bash
mix deps.get
```

## 快速开始

```elixir
alias Fsrs

# 1) 创建调度器
scheduler = Fsrs.new_scheduler(enable_fuzzing: false)

# 2) 创建卡片
card = Fsrs.new_card()

# 3) 评分复习（:again | :hard | :good | :easy）
{updated_card, review_log} = Fsrs.review_card(scheduler, card, :good)

updated_card.due
review_log.rating
```

## 常用用法

### 自定义调度器

```elixir
scheduler = Fsrs.new_scheduler(
  desired_retention: 0.9,
  learning_steps: [{:minutes, 1}, {:seconds, 95}, 300],
  relearning_steps: [{:seconds, 90}, {:minutes, 15}],
  maximum_interval: 36500,
  enable_fuzzing: true
)
```

说明：

- `learning_steps` / `relearning_steps` 内部统一保存为秒
- 支持三种输入：`60`、`{:seconds, 60}`、`{:minutes, 1}`

### 计算可回忆性

```elixir
retrievability = Fsrs.get_card_retrievability(scheduler, updated_card)
```

### 使用历史日志重排卡片状态

```elixir
rescheduled = Fsrs.reschedule_card(scheduler, card, review_logs)
```

### 序列化（跨语言互通）

```elixir
json = Fsrs.Card.to_json(updated_card)
card2 = Fsrs.Card.from_json(json)

map = Fsrs.Scheduler.to_dict(scheduler)
scheduler2 = Fsrs.Scheduler.from_dict(map)
```

## Port 对拍验证（Python vs Elixir）

本仓库包含完整对拍资产，均已纳入版本管理：

- Python 生成脚本：`test/fixtures/generate_py_fixture.py`
- 固定夹具文件：`test/fixtures/py_fsrs_v6_3_0_fixture.json`
- Elixir 对拍测试：`test/fsrs_py_parity_test.exs`

你可以本地复现：

```bash
python3 -m venv .venv
.venv/bin/pip install fsrs==6.3.0
.venv/bin/python test/fixtures/generate_py_fixture.py test/fixtures/py_fsrs_v6_3_0_fixture.json
mix test test/fsrs_py_parity_test.exs
```

## 致谢与参考

### 核心来源（Port 基线）

- `open-spaced-repetition/py-fsrs`（本项目直接移植基线）
  - https://github.com/open-spaced-repetition/py-fsrs

### 算法文档与官方生态

- `open-spaced-repetition/fsrs4anki` Wiki: The Algorithm（FSRS-6 公式与参数）
  - https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm
- `open-spaced-repetition/free-spaced-repetition-scheduler`
  - https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler
- `open-spaced-repetition/fsrs-rs`
  - https://github.com/open-spaced-repetition/fsrs-rs

### 算法作者与社区贡献者

- Jarrett Ye（L-M-Sherlock）
  - GitHub: https://github.com/L-M-Sherlock
  - X: https://x.com/JarrettYe

> 感谢 open-spaced-repetition 社区及所有贡献者。本项目是面向 Elixir 生态的工程化移植实现，不是官方仓库。

## 许可证

MIT，详见 `LICENSE`。
