#!/usr/bin/env python3

import json
import sys
from datetime import datetime, timezone, timedelta

from fsrs import Card, Rating, ReviewLog, Scheduler, State


def dt(y, m, d, hh=0, mm=0, ss=0):
    return datetime(y, m, d, hh, mm, ss, tzinfo=timezone.utc)


def rating_name(rating):
    return {
        Rating.Again: "again",
        Rating.Hard: "hard",
        Rating.Good: "good",
        Rating.Easy: "easy",
    }[rating]


def build_fixture():
    fixture = {"meta": {"py_fsrs_version": "6.3.0"}}

    scheduler_default = Scheduler(enable_fuzzing=False)
    fixture["scheduler_default_dict"] = scheduler_default.to_dict()

    scheduler_custom = Scheduler(
        desired_retention=0.87,
        learning_steps=[
            timedelta(minutes=1),
            timedelta(seconds=95),
            timedelta(minutes=5),
        ],
        relearning_steps=[timedelta(seconds=90), timedelta(minutes=15)],
        maximum_interval=4000,
        enable_fuzzing=False,
    )
    fixture["scheduler_custom_dict"] = scheduler_custom.to_dict()
    fixture["scheduler_custom_json"] = scheduler_custom.to_json(indent=2)

    card_sample = Card(
        card_id=2024,
        state=State.Review,
        step=None,
        stability=12.34,
        difficulty=6.78,
        due=dt(2024, 5, 1, 12, 0, 0),
        last_review=dt(2024, 4, 30, 12, 0, 0),
    )
    fixture["card_sample_dict"] = card_sample.to_dict()
    fixture["card_sample_json"] = card_sample.to_json(indent=2)

    review_log_sample = ReviewLog(
        card_id=2024,
        rating=Rating.Hard,
        review_datetime=dt(2024, 5, 1, 12, 0, 0),
        review_duration=1234,
    )
    fixture["review_log_sample_dict"] = review_log_sample.to_dict()
    fixture["review_log_sample_json"] = review_log_sample.to_json(indent=2)

    trace_scheduler = Scheduler(enable_fuzzing=False)
    trace_card = Card(card_id=4242, due=dt(2024, 1, 1, 8, 0, 0))
    trace_events = [
        (Rating.Good, dt(2024, 1, 1, 8, 0, 0), 500),
        (Rating.Again, dt(2024, 1, 1, 8, 2, 0), 420),
        (Rating.Good, dt(2024, 1, 4, 8, 3, 0), 610),
        (Rating.Hard, dt(2024, 1, 14, 8, 0, 0), 700),
        (Rating.Easy, dt(2024, 2, 20, 8, 0, 0), 350),
    ]

    trace = []
    for rating, review_datetime, duration in trace_events:
        trace_card, trace_log = trace_scheduler.review_card(
            card=trace_card,
            rating=rating,
            review_datetime=review_datetime,
            review_duration=duration,
        )
        trace.append(
            {
                "rating": int(rating),
                "rating_name": rating_name(rating),
                "review_datetime": review_datetime.isoformat(),
                "review_duration": duration,
                "card": trace_card.to_dict(),
                "review_log": trace_log.to_dict(),
            }
        )

    fixture["review_trace"] = trace

    reschedule_scheduler = Scheduler(enable_fuzzing=False)
    reschedule_card = Card(card_id=777, due=dt(2024, 3, 1, 9, 0, 0))
    reschedule_logs = [
        ReviewLog(
            card_id=777,
            rating=Rating.Good,
            review_datetime=dt(2024, 3, 1, 9, 0, 0),
            review_duration=111,
        ),
        ReviewLog(
            card_id=777,
            rating=Rating.Again,
            review_datetime=dt(2024, 3, 1, 9, 2, 0),
            review_duration=222,
        ),
        ReviewLog(
            card_id=777,
            rating=Rating.Easy,
            review_datetime=dt(2024, 3, 8, 9, 0, 0),
            review_duration=333,
        ),
    ]
    unsorted_logs = [reschedule_logs[2], reschedule_logs[0], reschedule_logs[1]]
    rescheduled_card = reschedule_scheduler.reschedule_card(
        reschedule_card, unsorted_logs
    )

    fixture["reschedule"] = {
        "input_card": reschedule_card.to_dict(),
        "input_logs_unsorted": [log.to_dict() for log in unsorted_logs],
        "result_card": rescheduled_card.to_dict(),
    }

    retr_scheduler = Scheduler(enable_fuzzing=False)
    retr_card = Card(
        card_id=888,
        state=State.Review,
        step=None,
        stability=2.5,
        difficulty=5.0,
        due=dt(2024, 6, 1, 0, 0, 0),
        last_review=dt(2024, 6, 1, 0, 0, 0),
    )
    retr_points = [
        dt(2024, 6, 1, 0, 0, 0),
        dt(2024, 6, 1, 23, 59, 0),
        dt(2024, 6, 2, 0, 0, 0),
        dt(2024, 6, 6, 0, 0, 0),
    ]
    fixture["retrievability"] = [
        {
            "current_datetime": point.isoformat(),
            "value": retr_scheduler.get_card_retrievability(retr_card, point),
        }
        for point in retr_points
    ]

    return fixture


if __name__ == "__main__":
    output = json.dumps(build_fixture(), indent=2)

    if len(sys.argv) > 1:
        with open(sys.argv[1], "w", encoding="utf-8") as f:
            f.write(output)
            f.write("\n")
    else:
        print(output)
