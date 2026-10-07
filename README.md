# Does gold really react to geopolitics? An event study, 2015–2026

**Short version:** Gold is widely called the ultimate geopolitical hedge. Across 15 major shocks since 2015, it moved *no more* around those shocks than around an ordinary Fed meeting — and the difference isn't statistically significant. The safe-haven premium people assume isn't visible in the data.

## The question

The project started as a different one: *does gold react differently to the Fed depending on who's in the White House?* An early cut suggested a "Trump effect" on gold's FOMC-day moves — but it vanished once I controlled for the Iran war running through the same period. Chasing that confound led to the actual question worth asking: **does gold move more around geopolitical shocks than around monetary-policy events at all?**

## Data

- **Gold:** daily XAU/USD (OANDA, via TradingView), Jan 2015 – Jun 2026, ~3,000 trading days.
- **FOMC:** 93 meeting announcement dates (Federal Reserve calendar).
- **Geopolitical shocks:** 15 dateable market-impact events — Brexit, Soleimani, Russia's invasion of Ukraine, the Israel–Hamas war, both Iran wars, and others.

## Method

A standard event study. For each event I take the cumulative log return on gold in a ±2 trading-day window around the announcement, then compare the average absolute move across event types. The formal test pools all 108 events and regresses the window move on a "geopolitical shock" dummy, with HC1 heteroskedasticity-robust standard errors.

## Findings

1. **Gold reacts to geopolitical shocks no more than to a routine Fed meeting.** Average ±2-day move: 1.47% around shocks vs 1.88% around FOMC meetings. The gap is directional but **not statistically significant** (coefficient −0.42pp, p = 0.26).
2. **The biggest mover wasn't a war — it was Brexit (+4.1%).** The shocks that actually moved gold were surprises and financial-systemic events, not anticipated military escalation. By the time missiles fly, the market has usually priced the tension in.
3. **Gold's geopolitical sensitivity has shrunk, not grown,** across the decade — cutting against the popular "structural geopolitical supercycle" narrative.

## Honest caveats

- Only 15 geopolitical shocks, and Brexit is a large outlier — hence the wide standard errors. The defensible claim is the **null**: shocks move gold *no more* than the Fed, not that they move it *less*.
- "Shock" dating involves judgment. I used unambiguous, widely-reported event dates; multi-day events (COVID, the wars) are dated to onset.
- Daily data can't speak to intraday or headline-level moves.

## Reproduce it

```r
install.packages(c("ggplot2", "sandwich", "lmtest"))
source("gold_event_study.R")
```

Point the `read.csv` path at your own gold export (any daily OHLC CSV with a unix-seconds `time` column works). The script prints the summary tables, draws the ranked-shock chart, and runs the robust regression.

## Files

- `gold_event_study.R` — full analysis: data load, event windows, comparison, regression, plot.
- `OANDA_XAUUSD_1D.csv` — gold price data (daily OHLC, from TradingView).
