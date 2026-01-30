# Code and Data for TK-Informed Seawater Cd Thresholds for Seafood Safety

This repository contains the R code and supporting dataset(s) used in the manuscript:

**When Water Quality Criteria Are Not Enough: Toxicokinetic Back-Calculation of Seawater Cadmium Thresholds for Seafood Safety**

---

## Authors
Beiyun Chen; Guangbin Zhong; **Xue Cao**\*; **Qiao-Guo Tan**\*  
\*Corresponding authors: xuecao@stu.edu.cn; tanqg@xmu.edu.cn

**Affiliations**  
1. Department of Materials and Environmental Engineering, Shantou University, Shantou 515063, China  
2. Fujian Provincial Key Laboratory for Coastal Ecology and Environmental Studies, State Key Lab of Marine Environmental Science, College of the Environment and Ecology, Xiamen University, Xiamen, Fujian 361102, China  
3. China Quality Mark Certification Group Xiamen Co., Ltd., Xiamen, Fujian 361020, China  

---

📄 Overview
Coastal water quality criteria (WQC) protect aquatic life from toxicity, but meeting WQC does not necessarily ensure aquaculture products comply with food safety maximum levels (MLs).  
This repository provides a **toxicokinetic (TK) inversion** workflow that translates edible-tissue limits into **species-specific seawater Cd thresholds (Cw\*)** at a defined exceedance probability (default: 5%).

The workflow is parameterized using stable-isotope tracer TK experiments for two ark clams:
- *Anadara kagoshimensis*
- *Tegillarca granosa*

**Core calculations (steady-state inversion):**
```text
Css = ku * Cw / ((ke + g) * (1 - f))

Exceedance(Cw) = P(Css > thr)

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

## ▶️ Usage
1) Install R packages

Open R / RStudio and run:

install.packages(c("readxl","dplyr","ggplot2","scales"))

2) Run the script

Option A (interactive): if the script uses file.choose()

source("TK_Cd_exceedance.R")


When prompted, select Supporting data.xlsx.

Option B (fully reproducible; recommended): edit the script to use a fixed path
Replace:

dat0 <- read_excel(file.choose())


with:

dat0 <- read_excel("Supporting data.xlsx")


Then run:

source("TK_Cd_exceedance.R")

3) Key settings (edit in the script if needed)

Growth dilution: g <- 0.003

Cw grid: Cw_min, Cw_max, Cw_step

Dietary contribution fraction f (choose one):

Range (propagate uncertainty): f_values <- seq(0.1, 0.9, by = 0.1)

Fixed value (single scenario): f_values <- 0.5

Tissue threshold: thr <- ... (set to your tissue limit after unit conversion)

Target exceedance: target_exceed <- 0.05

## 📊 Outputs

Console output:

Cw_at_5pct (Cw* at 5% exceedance; NA if target exceedance is not bracketed by the Cw grid)

Plots:

Css vs Cw (median + uncertainty bands)

Exceedance vs Cw (with 5% line and Cw*)

Optional CSV export lines are included in the script (commented).


Cw* = Cw at which Exceedance(Cw) = target_exceed (default: 0.05)
