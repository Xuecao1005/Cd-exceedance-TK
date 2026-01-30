# Code and Data for TK-Informed Seawater Cd Thresholds for Seafood Safety

This repository contains the R script and supporting dataset used to compute **TK-informed seawater Cd thresholds (Cw\*)** for seafood safety based on **steady-state tissue Cd (Css)** and the **exceedance probability** under parameter uncertainty.

**Manuscript:** *When Water Quality Criteria Are Not Enough: Toxicokinetic Back-Calculation of Seawater Cadmium Thresholds for Seafood Safety*

---

## 👤 Authors
Beiyun Chen; Guangbin Zhong; **Xue Cao**\*; **Qiao-Guo Tan**\*  
\*Corresponding authors: xuecao@stu.edu.cn; tanqg@xmu.edu.cn

---

## 📄 Overview
Coastal water quality criteria (WQC) protect aquatic life from toxicity, but WQC compliance does not necessarily ensure that aquaculture products meet food safety maximum levels (MLs).  
This repository provides a **toxicokinetic (TK) inversion** workflow that translates edible-tissue limits into a **risk-defined seawater Cd threshold (Cw\*)** at a target exceedance probability (default: 5%).

Species in the manuscript:
- *Anadara kagoshimensis*
- *Tegillarca granosa*

**Core calculations (steady-state inversion):**

```text
Css = ku * Cw / ((ke + g) * (1 - f))
Exceedance(Cw) = P(Css > thr)
Cw* = Cw where Exceedance(Cw) = target_exceed (default: 0.05)
```
---
## 📁 Repository Contents

TK_Cd_exceedance.R
Main R script for:

Css summary (median + uncertainty bands) vs Cw

Exceedance probability vs Cw

Cw* at target exceedance (e.g., 5%)

Supporting data.xlsx
Parameter samples (MCMC draws) used for uncertainty propagation
Required columns: ku, ke (case-insensitive)

figures/ (optional but recommended)
Output figures for quick viewing on GitHub:

exceedance_vs_Cw.png

Css_vs_Cw.png

---

## ▶️ Usage

### 1) Install R packages
Open R / RStudio and run:

```text
install.packages(c("readxl","dplyr","ggplot2","scales"))
```

### 2) Run the script
Download this repository and open `TK_Cd_exceedance.R` in RStudio.
Set the target species by specifying the Excel sheet name:

```text
dat0 <- read_excel("Supporting data.xlsx", sheet = "SPECIES_NAME")
```
Replace "SPECIES_NAME" with:
"A. kagoshimensis" or "T. granosa"

### 3) Key settings (edit in the script if needed)

Growth dilution: g <- 0.003

Cw grid: Cw_min, Cw_max, Cw_step

Food contribution fraction (f) (choose one):

Range (propagate uncertainty): f_values <- seq(0.1, 0.9, by = 0.1)

Fixed value (single scenario): f_values <- 0.5

Tissue threshold: thr <- 2 * 5.96 (example; adjust to your food limit and unit conversion)

Target exceedance: target_exceed <- 0.05



## 📊 Outputs

Console output:

Cw_at_5pct (Cw* at 5% exceedance; NA if target exceedance is not bracketed by the Cw grid)

Plots:

Css vs Cw (median + uncertainty bands)

Exceedance vs Cw (with 5% line and Cw*)

Optional CSV export lines are included in the script (commented).

---

## 📝 Notes

The exceedance curve is expected to be monotonic increasing in Cw. If the target risk (e.g., 5%) is not bracketed by your Cw_min–Cw_max range, the script will return NA.

If your Excel file uses different column names, rename them to ku and ke (recommended) or edit the mapping section in the script.






