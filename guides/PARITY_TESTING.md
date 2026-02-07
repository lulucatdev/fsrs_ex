# Parity Testing

This guide describes how to verify the Elixir implementation against the Python baseline.

## Files

- Generator script: `test/fixtures/generate_py_fixture.py`
- Fixture output: `test/fixtures/py_fsrs_v6_3_0_fixture.json`
- Elixir parity tests: `test/fsrs_py_parity_test.exs`

## Requirements

- Python 3
- `fsrs==6.3.0` installed in a virtual environment

## Regenerate Fixture

```bash
python3 -m venv .venv
.venv/bin/pip install fsrs==6.3.0
.venv/bin/python test/fixtures/generate_py_fixture.py test/fixtures/py_fsrs_v6_3_0_fixture.json
```

## Run Parity Tests

```bash
mix test test/fsrs_py_parity_test.exs
```

## What Is Compared

- default scheduler dictionary shape and values
- custom scheduler normalization behavior
- JSON and map interoperability
- per-review trace output (`card` and `review_log` values)
- `reschedule_card/3` replay results
- retrievability points under day-based elapsed behavior

## When to Re-run

- after any scheduler formula or bounds update
- after any serialization-related change
- before every release
