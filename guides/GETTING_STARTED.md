# Getting Started

## Installation

Add `fsrs_ex` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:fsrs_ex, "~> 0.1.2"}
  ]
end
```

Then fetch:

```bash
mix deps.get
```

## Basic Review

Create a scheduler and a new card, then review it:

```elixir
# Create a scheduler (fuzzing disabled for deterministic results)
scheduler = Fsrs.new_scheduler(enable_fuzzing: false)

# Create a new card (starts in :learning state)
card = Fsrs.new_card()

# Review the card with a rating
{card, review_log} = Fsrs.review_card(scheduler, card, :good)

card.state      # :review (graduated after completing learning steps)
card.due        # next review datetime (UTC)
card.stability  # estimated memory stability
card.difficulty # estimated item difficulty

review_log.rating           # :good
review_log.review_datetime  # when the review happened
```

Ratings map to FSRS buttons: `:again`, `:hard`, `:good`, `:easy`.

## Scheduler Options

```elixir
scheduler = Fsrs.new_scheduler(
  desired_retention: 0.9,
  learning_steps: [{:minutes, 1}, {:minutes, 10}],
  relearning_steps: [{:minutes, 10}],
  maximum_interval: 36500,
  enable_fuzzing: true
)
```

Steps accept integers (seconds), `{:seconds, n}`, or `{:minutes, n}`.

## Retrievability

Check the probability of recalling a card at a given time:

```elixir
retrievability = Fsrs.get_card_retrievability(scheduler, card)
# => 0.9 (a float between 0.0 and 1.0)
```

## Rescheduling from History

Replay a sequence of review logs to rebuild card state:

```elixir
card = Fsrs.new_card(card_id: 1)
now = DateTime.utc_now()

logs = [
  Fsrs.new_review_log(card_id: 1, rating: :good, review_datetime: now),
  Fsrs.new_review_log(
    card_id: 1,
    rating: :easy,
    review_datetime: DateTime.add(now, 1, :day)
  )
]

card = Fsrs.reschedule_card(scheduler, card, logs)
```

All logs must share the same `card_id`. They are sorted by `review_datetime` internally.

## Serialization

Cards and schedulers can be exported to JSON for storage or cross-language interop with `py-fsrs`:

```elixir
# Card
json = Fsrs.Card.to_json(card)
card = Fsrs.Card.from_json(json)

# Scheduler
json = Fsrs.Scheduler.to_json(scheduler)
scheduler = Fsrs.Scheduler.from_json(json)
```

Map-based serialization is also available via `to_dict/1` and `from_dict/1`.

## Next Steps

- `Fsrs` module docs for the full public API
- [Porting Policy](PORTING_POLICY.md) for upstream alignment details
- [Parity Testing](PARITY_TESTING.md) for Python-vs-Elixir verification
