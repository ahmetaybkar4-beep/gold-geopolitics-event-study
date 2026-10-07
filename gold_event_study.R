# =============================================================================
# Gold around geopolitical shocks vs Fed meetings, 2015-2026
# Event study on daily XAU/USD.
#
# Input : OANDA_XAUUSD__1D.csv exported from TradingView
#         (columns: time [unix seconds], open, high, low, close)
# Output: console tables + one plot reproducing the LinkedIn chart.
#
# Needs ggplot2, sandwich, lmtest. Install once with:
#   install.packages(c("ggplot2","sandwich","lmtest"))
# =============================================================================

library(ggplot2)

# ---- 1. Load price data -----------------------------------------------------
# Point this at wherever you saved the TradingView export.
px <- read.csv("OANDA_XAUUSD_1D.csv")

# TradingView gives the timestamp in unix seconds. Convert to a Date.
px$date  <- as.Date(as.POSIXct(px$time, origin = "1970-01-01", tz = "UTC"))
px <- px[order(px$date), ]                  # ensure chronological
px <- px[!duplicated(px$date), ]            # one row per day

# Daily log return. log(P_t / P_{t-1}) is the standard return for event studies
# because windowed log returns add up cleanly.
px$ret <- c(NA, diff(log(px$close)))

# Give every row an integer position so we can grab "i-3 ... i+2" windows by index.
px$idx <- seq_len(nrow(px))

# ---- 2. Event window function ----------------------------------------------
# For one event date, find the first trading day on/after it (the reaction day),
# then measure the cumulative log move across a +/- `win` day window and the
# realised volatility (sd of daily returns) inside that window.
window_move <- function(event_date, win = 2) {
  event_date <- as.Date(event_date)
  after <- px[px$date >= event_date, ]
  if (nrow(after) == 0) return(NULL)
  i <- after$idx[1]                                  # reaction-day index
  if (i - win < 1 || i + win > nrow(px)) return(NULL)# need a full window
  pre  <- px$close[px$idx == i - win - 1]            # close just before window
  post <- px$close[px$idx == i + win]               # close at window end
  win_rows <- px[px$idx >= (i - win) & px$idx <= (i + win), ]
  data.frame(
    date      = event_date,
    cum_ret   = log(post / pre),                     # signed window move
    abs_cum   = abs(log(post / pre)),                # size of window move
    decision_ret = px$ret[px$idx == i],              # the reaction-day move
    win_vol   = sd(win_rows$ret, na.rm = TRUE)
  )
}

run_events <- function(dates, win = 2) {
  do.call(rbind, lapply(dates, window_move, win = win))
}

# ---- 3. Event dates ---------------------------------------------------------
# FOMC announcement dates (statement release day), Jan 2015 - Jun 2026.
fomc_dates <- as.Date(c(
  "2015-01-28","2015-03-18","2015-04-29","2015-06-17","2015-07-29","2015-09-17",
  "2015-10-28","2015-12-16","2016-01-27","2016-03-16","2016-04-27","2016-06-15",
  "2016-07-27","2016-09-21","2016-11-02","2016-12-14","2017-02-01","2017-03-15",
  "2017-05-03","2017-06-14","2017-07-26","2017-09-20","2017-11-01","2017-12-13",
  "2018-01-31","2018-03-21","2018-05-02","2018-06-13","2018-08-01","2018-09-26",
  "2018-11-08","2018-12-19","2019-01-30","2019-03-20","2019-05-01","2019-06-19",
  "2019-07-31","2019-09-18","2019-10-30","2019-12-11","2020-01-29","2020-03-03",
  "2020-03-15","2020-04-29","2020-06-10","2020-07-29","2020-09-16","2020-11-05",
  "2020-12-16","2021-01-27","2021-03-17","2021-04-28","2021-06-16","2021-07-28",
  "2021-09-22","2021-11-03","2021-12-15","2022-01-26","2022-03-16","2022-05-04",
  "2022-06-15","2022-07-27","2022-09-21","2022-11-02","2022-12-14","2023-02-01",
  "2023-03-22","2023-05-03","2023-06-14","2023-07-26","2023-09-20","2023-11-01",
  "2023-12-13","2024-01-31","2024-03-20","2024-05-01","2024-06-12","2024-07-31",
  "2024-09-18","2024-11-07","2024-12-18","2025-01-29","2025-03-19","2025-05-07",
  "2025-06-18","2025-07-30","2025-09-17","2025-10-29","2025-12-10","2026-01-28",
  "2026-03-18","2026-04-29","2026-06-17"
))

# Major geopolitical shocks, dated to clearest market-impact day.
geo <- data.frame(
  date = as.Date(c(
    "2016-06-24","2017-04-07","2017-08-09","2018-04-13","2019-09-16","2020-01-03",
    "2020-02-24","2021-08-16","2022-02-24","2023-10-09","2024-04-15","2024-10-01",
    "2025-06-13","2025-06-23","2026-02-28")),
  label = c(
    "Brexit referendum","US Tomahawk strike on Syria","North Korea fire and fury",
    "US/allied Syria strikes","Abqaiq oil attack","Soleimani killing",
    "COVID crash begins","Kabul falls","Russia invades Ukraine",
    "Israel-Hamas war begins","Iran 1st strike on Israel","Iran Oct barrage",
    "Twelve-Day War begins","US strikes Iran sites","2026 Iran war begins"),
  stringsAsFactors = FALSE
)

# ---- 4. Run the event studies ----------------------------------------------
F <- run_events(fomc_dates)
G <- run_events(geo$date)
G <- merge(G, geo, by = "date")            # attach labels

ordinary_abs <- mean(abs(px$ret), na.rm = TRUE) * 100

cat("\n=== Gold: geopolitical shocks vs FOMC, 2015-2026 ===\n")
cat(sprintf("Ordinary day avg |move|:        %.2f%%\n", ordinary_abs))
cat(sprintf("FOMC  (n=%d) avg window |move|: %.2f%%\n", nrow(F), mean(F$abs_cum)*100))
cat(sprintf("Geo   (n=%d) avg window |move|: %.2f%%\n", nrow(G), mean(G$abs_cum)*100))
cat(sprintf("Geo shocks with gold UP:        %.0f%%\n", mean(G$cum_ret > 0)*100))

cat("\nShocks ranked by size of window move:\n")
print(G[order(-G$abs_cum), c("date","label","cum_ret")], row.names = FALSE)

# ---- 5. The formal test, with HC1 robust standard errors --------------------
# Pool both event types and test whether geo shocks move gold differently from
# Fed days. The 'geo' coefficient is the average difference; HC1 robust SEs
# guard against the unequal variance you'd expect between event types.
# Needs: install.packages(c("sandwich","lmtest"))
library(sandwich); library(lmtest)
F$type <- "fomc"; G$type <- "geo"
pooled <- rbind(F[, c("abs_cum","type")], G[, c("abs_cum","type")])
pooled$geo <- as.integer(pooled$type == "geo")
m <- lm(I(abs_cum*100) ~ geo, data = pooled)
cat("\n=== Geo vs FOMC, formal test (HC1 robust SEs) ===\n")
print(coeftest(m, vcov = vcovHC(m, type = "HC1")))
cat("\nRead: intercept = avg FOMC window move; 'geo' = avg extra move for a\n")
cat("geopolitical shock. p > 0.05 means we cannot distinguish the two.\n")

# ---- 6. Plot (reproduces the LinkedIn chart) -------------------------------
G$label <- factor(G$label, levels = G$label[order(G$abs_cum)])  # sort bars
fed_line <- mean(F$abs_cum) * 100
ord_line <- ordinary_abs

ggplot(G, aes(x = abs_cum*100, y = label,
              fill = abs_cum*100 >= fed_line)) +
  geom_col() +
  geom_vline(xintercept = fed_line, colour = "#185FA5", linewidth = 1) +
  geom_vline(xintercept = ord_line, colour = "#888780",
             linewidth = 0.8, linetype = "dashed") +
  scale_fill_manual(values = c(`TRUE` = "#D85A30", `FALSE` = "#B4B2A9"),
                    guide = "none") +
  labs(x = "Absolute gold move, +/-2-day window (%)", y = NULL,
       title = "Gold moves more around the Fed than around most wars",
       subtitle = "Blue = avg FOMC meeting; dashed = ordinary day") +
  theme_minimal(base_size = 12)

# ggsave("gold_shocks_vs_fed.png", width = 9, height = 6, dpi = 150)
