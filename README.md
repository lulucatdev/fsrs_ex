# fsrs_ex (Fsrs)

> Direct Elixir port of `open-spaced-repetition/py-fsrs` (`v6.3.0`, FSRS-6).
>
> 中文说明：这是 `py-fsrs v6.3.0` 的 Elixir 直接移植版本。

`fsrs_ex` provides the FSRS scheduler API for Elixir applications with a strong focus on **behavior parity** with the Python reference implementation.

## Highlights

- FSRS-6 (21 parameters) default model constants
- Day-based elapsed-time behavior aligned with `py-fsrs`
- `Scheduler`, `Card`, `ReviewLog`, `Rating`, and `State` modules
- `reschedule_card/3` for replaying historical review logs
- Cross-language serialization (`to_dict`/`from_dict`, `to_json`/`from_json`)
- Python-vs-Elixir parity fixtures and tests included in this repository

## Port Scope

This project intentionally ports and aligns with:

- Source baseline: `open-spaced-repetition/py-fsrs` `v6.3.0`
- Algorithm generation: FSRS-6
- Defaults: 21 default parameters and bounds-compatible validation
- Scheduler semantics: `review_card`, `reschedule_card`, retrievability behavior
- Data interoperability: Python-compatible field names and UTC timestamp formatting (`+00:00`)

For details, see `guides/PORTING_POLICY.md`.

## Installation

Add `fsrs_ex` to your dependencies:

```elixir
def deps do
  [
    {:fsrs_ex, "~> 0.1.1"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Quick Start

```elixir
alias Fsrs

scheduler = Fsrs.new_scheduler(enable_fuzzing: false)
card = Fsrs.new_card()

{card, review_log} = Fsrs.review_card(scheduler, card, :good)

card.due
review_log.rating
```

Chinese note: `:again | :hard | :good | :easy` correspond to FSRS rating buttons.

## Scheduler Options

```elixir
scheduler = Fsrs.new_scheduler(
  desired_retention: 0.9,
  learning_steps: [{:minutes, 1}, {:seconds, 95}, 300],
  relearning_steps: [{:seconds, 90}, {:minutes, 15}],
  maximum_interval: 36500,
  enable_fuzzing: true
)
```

`learning_steps` and `relearning_steps` accept:

- integer seconds (for example `600`)
- `{:seconds, value}`
- `{:minutes, value}`

Internally they are normalized to seconds.

## Serialization and Interop

```elixir
json = Fsrs.Card.to_json(card)
card2 = Fsrs.Card.from_json(json)

scheduler_map = Fsrs.Scheduler.to_dict(scheduler)
scheduler2 = Fsrs.Scheduler.from_dict(scheduler_map)
```

Chinese note: the exported data shape is designed for Python interoperability.

## Python Parity Testing

This repository includes full parity assets:

- fixture generator: `test/fixtures/generate_py_fixture.py`
- fixture data: `test/fixtures/py_fsrs_v6_3_0_fixture.json`
- Elixir parity tests: `test/fsrs_py_parity_test.exs`

Re-generate fixtures and re-run parity tests:

```bash
python3 -m venv .venv
.venv/bin/pip install fsrs==6.3.0
.venv/bin/python test/fixtures/generate_py_fixture.py test/fixtures/py_fsrs_v6_3_0_fixture.json
mix test test/fsrs_py_parity_test.exs
```

More details: `guides/PARITY_TESTING.md`.

## Release Automation (Makefile)

Use these targets:

```bash
make help
make preflight
make publish-interactive
```

For CI or non-interactive publishing:

```bash
export HEX_API_KEY=...
make release
```

See `guides/RELEASE_PROCESS.md`.

## Pre-release Checklist

Before publishing a new version:

1. Bump `version` in `mix.exs`.
2. Run `make preflight`.
3. Confirm package file list with `mix hex.build` output.
4. Ensure docs render correctly (`mix docs`, inspect `doc/index.html`).
5. Publish with `make publish` (or `make publish-interactive`).
6. Create and push a Git tag (for example `v0.1.1`).

Chinese note: 建议每次发布前都跑 `make preflight`，避免遗漏格式、测试和文档问题。

## HexDocs

- Package: https://hex.pm/packages/fsrs_ex
- Docs: https://hexdocs.pm/fsrs_ex

## Acknowledgements and References

### Core Sources

- `open-spaced-repetition/py-fsrs` (direct port baseline)
  - https://github.com/open-spaced-repetition/py-fsrs
- FSRS algorithm wiki (`fsrs4anki`)
  - https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm
- `open-spaced-repetition/free-spaced-repetition-scheduler`
  - https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler

### Author and Community

- Jarrett Ye (L-M-Sherlock)
  - GitHub: https://github.com/L-M-Sherlock
  - X: https://x.com/JarrettYe

This project is a community Elixir port and is not an official Open Spaced Repetition repository.

## License

MIT. See `LICENSE`.
