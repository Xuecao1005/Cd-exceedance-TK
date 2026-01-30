# ============================================================
# TK-informed seawater Cd threshold (Cw*) at target exceedance
#
# Goal:
#   1) Compute steady-state tissue Cd (Css) vs seawater Cd (Cw)
#   2) Compute exceedance curve: Exceedance(Cw) = P(Css > thr)
#   3) Solve for Cw* where Exceedance(Cw*) = target_exceed (e.g., 5%)
#
# Model (steady state):
#   Css = ku * Cw / ((ke + g) * (1 - f))
#
# Notes:
#   - ku, ke are treated as uncertain (MCMC draws from Excel).
#   - f can be fixed or a range to propagate uncertainty in dietary contribution.
#   - Css is linear in Cw for fixed parameters: Css = b * Cw, where
#       b = ku / ((ke + g) * (1 - f))
# ============================================================

# ---- packages ----
# install.packages(c("readxl","dplyr","ggplot2","scales","tibble"))
library(readxl)
library(dplyr)
library(ggplot2)
library(scales)
library(tibble)

# ============================================================
# 1) User settings
# ============================================================

# ---- species selection (Excel sheet name) ----
# Put your Excel file in the same folder as this script (recommended).
# Choose ONE species sheet:
species_sheet <- "A. kagoshimensis"
# species_sheet <- "Tegillarca granosa"

# ---- input file ----
input_xlsx <- "Supporting data.xlsx"

# ---- growth dilution (per day) ----
g <- 0.003

# ---- Cw grid (ug/L) ----
Cw_min  <- 0.01
Cw_max  <- 1
Cw_step <- 0.001
Cw_grid <- seq(Cw_min, Cw_max, by = Cw_step)

# ---- food contribution fraction f (dimensionless) ----
# Option A: propagate uncertainty in f across a range (recommended)
f_values <- seq(0.1, 0.9, by = 0.1)

# Option B: use a single fixed f (uncomment)
# f_values <- 0.5

# ---- tissue threshold (same units as Css) ----
# Example: thr = ML(wet wt) * conversion factor (adjust to your definition)
thr <- 2 * 5.96       # = 11.92 in your current unit system
target_exceed <- 0.05 # 5% exceedance probability

# ---- output (optional) ----
save_plots <- TRUE
out_dir <- "outputs"
if (save_plots && !dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# ============================================================
# 2) Read MCMC samples from Excel
# ============================================================

# Expect columns named ku and ke (case-insensitive).
# Read the selected species sheet directly (no file.choose()).
dat0 <- read_excel(path = input_xlsx, sheet = species_sheet)

nm <- names(dat0)
ku_col <- nm[match("ku", tolower(nm))]
ke_col <- nm[match("ke", tolower(nm))]

if (is.na(ku_col) || is.na(ke_col)) {
  stop("Could not find columns named 'ku' and 'ke' (case-insensitive) in the selected sheet.")
}

dat <- dat0 %>%
  transmute(
    ku = as.numeric(.data[[ku_col]]),
    ke = as.numeric(.data[[ke_col]])
  ) %>%
  filter(
    is.finite(ku), is.finite(ke),
    ku >= 0,
    (ke + g) > 0
  )

if (nrow(dat) < 10) {
  warning("Very few valid MCMC draws after filtering. Check your Excel sheet / columns / units.")
}

# ============================================================
# 3) Convert parameter draws to b-draws (Css = b * Cw)
# ============================================================

# For each f, build b = ku / ((ke + g) * (1 - f))
# This propagates uncertainty from (ku, ke) and optionally from f.
b_draws <- unlist(
  lapply(f_values, function(f) dat$ku / ((dat$ke + g) * (1 - f))),
  use.names = FALSE
)

b_draws <- b_draws[is.finite(b_draws) & b_draws >= 0]

if (length(b_draws) < 10) {
  stop("Too few valid b draws. Check ku/ke values, g, and f settings.")
}

# Quantiles of b (compute once; then scale by Cw)
b_q <- as.numeric(quantile(
  b_draws,
  probs = c(0.025, 0.25, 0.50, 0.75, 0.975),
  na.rm = TRUE,
  type = 7
))
names(b_q) <- c("q2.5","q25","q50","q75","q97.5")

# Css summary bands vs Cw
css_summ <- tibble(
  Cw = Cw_grid,
  Css_q2.5  = b_q["q2.5"]  * Cw,
  Css_q25   = b_q["q25"]   * Cw,
  Css_med   = b_q["q50"]   * Cw,
  Css_q75   = b_q["q75"]   * Cw,
  Css_q97.5 = b_q["q97.5"] * Cw
)

# ============================================================
# 4) Exceedance curve: Exceedance(Cw) = P(Css > thr)
# ============================================================

# Because Css = b*Cw, exceedance(Cw) = P(b > thr/Cw)
exceed_df <- tibble(
  Cw = Cw_grid,
  exceed = vapply(Cw_grid, function(cw) mean(b_draws > (thr / cw), na.rm = TRUE), numeric(1))
)

# ============================================================
# 5) Solve for Cw* at target exceedance (linear interpolation)
# ============================================================

# Exceedance should increase with Cw (numerical noise may occur but usually monotone).
# We solve for Cw where exceed = target_exceed using approx().
if (min(exceed_df$exceed) <= target_exceed && max(exceed_df$exceed) >= target_exceed) {
  Cw_star <- approx(
    x = exceed_df$exceed,
    y = exceed_df$Cw,
    xout = target_exceed,
    ties = "ordered"
  )$y
} else {
  Cw_star <- NA_real_
  warning("Target exceedance not bracketed by your Cw range; Cw_star set to NA. Consider expanding Cw_min/Cw_max.")
}

cat("\n====================================\n")
cat("Species sheet: ", species_sheet, "\n", sep = "")
cat("Target exceedance: ", target_exceed, "\n", sep = "")
cat("Threshold thr: ", thr, "\n", sep = "")
cat("Cw* at target exceedance: ", signif(Cw_star, 4), "\n", sep = "")
cat("====================================\n\n")

# ============================================================
# 6) Plots
# ============================================================

# Plot 1: Css bands vs Cw
p_css <- ggplot(css_summ, aes(x = Cw)) +
  geom_ribbon(aes(ymin = Css_q2.5,  ymax = Css_q97.5), alpha = 0.20) +
  geom_ribbon(aes(ymin = Css_q25,   ymax = Css_q75),   alpha = 0.35) +
  geom_line(aes(y = Css_med), linewidth = 0.8) +
  geom_hline(yintercept = thr, linetype = 2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    x = expression(C[w]~"(Cd in water)"),
    y = expression(C[ss]~"(steady-state Cd)"),
    title = "Css vs Cw (median and uncertainty bands)",
    subtitle = paste0(
      "Species: ", species_sheet,
      " | g=", g,
      " | f=", paste(f_values, collapse = ", "),
      " | thr=", thr
    )
  ) +
  theme_classic()

print(p_css)

# Plot 2: exceedance vs Cw
p_exc <- ggplot(exceed_df, aes(x = Cw, y = exceed)) +
  geom_line(linewidth = 0.8) +
  geom_hline(yintercept = target_exceed, linetype = 2) +
  { if (!is.na(Cw_star)) geom_vline(xintercept = Cw_star, linetype = 2) } +
  scale_x_log10() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = expression(C[w]~"(Cd in water)"),
    y = paste0("Exceedance rate: P(Css > ", thr, ")"),
    title = "Exceedance rate vs Cw",
    subtitle = if (!is.na(Cw_star)) paste0("Cw* @ ", target_exceed * 100, "% exceedance = ", signif(Cw_star, 4)) else NULL
  ) +
  theme_classic()

print(p_exc)

# ---- save outputs (optional) ----
if (save_plots) {
  ggsave(file.path(out_dir, paste0("Css_vs_Cw_", gsub(" ", "_", species_sheet), ".png")),
         p_css, width = 7, height = 5, dpi = 300)
  ggsave(file.path(out_dir, paste0("Exceedance_vs_Cw_", gsub(" ", "_", species_sheet), ".png")),
         p_exc, width = 7, height = 5, dpi = 300)
  
  # Optional CSV exports
  # write.csv(css_summ, file.path(out_dir, paste0("Css_summary_vs_Cw_", gsub(" ", "_", species_sheet), ".csv")), row.names = FALSE)
  # write.csv(exceed_df, file.path(out_dir, paste0("Css_exceedance_vs_Cw_", gsub(" ", "_", species_sheet), ".csv")), row.names = FALSE)
}





