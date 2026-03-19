# Sports Science Analytics Pipeline
### Collegiate Football Athlete Monitoring & Injury Risk Classification

Data science project built with real sports performance data from a Division I football program. Covers the complete lifecycle from raw data ingestion through relational database design, exploratory analysis, and machine learning classification.

**Built by:** First-year Master's student, Data Science & Business Analytics (DSBA), UNC Charlotte

> **Note:** The underlying dataset is proprietary and linked to an active collegiate football program. All player data has been excluded from this repository to protect athlete privacy. The notebooks, SQL schema, ETL scripts, and model outputs are included to demonstrate methodology and results.

- [GitHub Repo](https://github.com/Lisan-al-Gaib-Marvin/clt-sports-science)
- [Portfolio & Dashboards] https://pointed-aragon-330.notion.site/Data-Science-Analytics-4cbca0417d3241c58852a3d08856ed40?source=copy_link
---

## Background

Collegiate football programs generate data from multiple sports science platforms every week — force plates, hamstring dynamometers, GPS wearables, grip and tap devices, and daily weigh-ins. This data typically lives in separate systems with different formats, naming conventions, and export structures.

This project consolidates five distinct data sources into a unified MySQL database, then applies descriptive analytics, statistical profiling, and machine learning to support athlete monitoring and injury risk assessment.

### Data Sources

| Source | Device | What It Measures | Records |
|---|---|---|---|
| ForceDecks | Dual force plates | Countermovement jump (CMJ) — jump height, RSI, peak force, L/R asymmetry | 523 tests |
| NordBord | Hamstring dynamometer | Isometric hamstring strength — L/R max force, torque, imbalance % | 358 tests |
| Catapult | GPS/IMU wearable | Practice workload — player load, distance, velocity bands, accel/decel | 446 sessions |
| TAP & Grip | Tap device + dynamometer | CNS readiness (finger tap count) and grip strength (L/R in lbs) | 174 grip, 183 tap |
| Bodyweights | Scale | Daily body mass tracking (lbs) | 845 weigh-ins |

**Total:** 99 athletes, 2,529 records across 7 normalized tables

---

## Pipeline Architecture

```
Raw Data (.csv, .xlsx, .xlsm) — 5 different platforms, 3 naming formats
        │
        ▼
[1] ETL Script (Python)
    • Standardized "Last, First" → "First Last" naming across systems
    • Parsed asymmetry strings ("17.3 R" → numeric value + side)
    • Resolved duplicate players (case-sensitivity)
    • Cleaned junk rows, normalized dates/times
        │
        ▼
[2] MySQL Database (7 normalized tables)
    • Schema with foreign keys, indexes, unique constraints
    • Loaded via SQLAlchemy + PyMySQL + pandas .to_sql()
        │
        ▼
[3] Analysis & Modeling (5 Jupyter Notebooks)
    • Injury risk flagging (threshold-based)
    • Performance profiling (position-based z-scores)
    • Workload monitoring (EWMA-based ACWR)
    • Correlation analysis (Pearson matrix + heatmap)
    • ML classification (Decision Tree + Random Forest)
```

---

## Models

### Model 1 — Injury Risk Flags
**Notebook:** `01_injury_risk.ipynb`

Screens athletes for elevated injury risk using three evidence-based thresholds:

| Flag | Threshold | Source |
|---|---|---|
| Hamstring imbalance (NordBord) | >15% L/R difference | Croisier et al., 2008 — 4.66x injury risk |
| CMJ eccentric braking asymmetry | >15% | Bishop et al., 2021 |
| CMJ positive impulse asymmetry | >15% | Bishop et al., 2021 |

Athletes with 2+ flags are classified as HIGH risk. Also identifies the weak side (L/R) and tracks dual asymmetry (both braking AND impulse elevated simultaneously).

### Model 2 — Performance Profiling
**Notebook:** `02_performance_profile.ipynb`

Compares each athlete to their position group average using z-scores.

**z = (player value − position group mean) / position group std**

| Tier | Z-Score | Meaning |
|---|---|---|
| ELITE | ≥ +1.5 | Top ~7% of position group |
| ABOVE AVG | ≥ +0.5 | Above the middle |
| AVERAGE | -0.5 to +0.5 | Middle ~38% |
| BELOW AVG | ≥ -1.5 | Below the middle |
| CONCERN | < -1.5 | Bottom ~7% of position group |

Applied to CMJ metrics (jump height, RSI, relative force, flight time ratio) and NordBord metrics (total force, weaker leg force) across 9 position groups.

### Model 3 — Workload Monitoring
**Notebook:** `03_workload_monitor.ipynb`

Tracks training load using the Acute:Chronic Workload Ratio (ACWR) with EWMA:

| ACWR Zone | Range | Meaning |
|---|---|---|
| UNDERPREPARED | < 0.8 | Doing less than usual |
| OPTIMAL | 0.8 – 1.3 | Sweet spot — training matches fitness |
| CAUTION | 1.3 – 1.5 | Load increasing — monitor |
| DANGER | > 1.5 | Spike — injury risk elevated |

Based on Gabbett (2016) and Blanch & Gabbett (2016). Uses EWMA over simple rolling averages per Williams et al. (2017). Current dataset has ~9 days of GPS data — the framework scales as more weeks are imported.

### Model 4 — Correlation Analysis
**Notebook:** `04_correlation_analysis.ipynb`

Merges all data sources into one row per player and computes Pearson correlations across all metrics. Generates a heatmap and ranks the strongest relationships.

**Key findings:**
| Metric 1 | Metric 2 | r | Strength |
|---|---|---|---|
| NordBord Force L | NordBord Total Force | +0.961 | STRONG |
| RSI Modified | Force / Bodyweight | +0.807 | STRONG |
| Max Velocity | Accel/Decel Efforts | +0.788 | STRONG |
| Jump Height | Bodyweight | -0.708 | STRONG |

### Model 5 — ML Classification
**Notebook:** `05_ml_classification.ipynb`

Trains Decision Tree and Random Forest classifiers to predict HIGH injury risk from performance metrics.

**Design decisions:**
- Removed asymmetry features from the input to avoid data leakage (the target is derived from those same metrics). This forces the model to find patterns in general performance data.
- Used `class_weight={0: 1, 1: 5}` to penalize missed HIGH risk players 5x more — in sports medicine, missing an at-risk athlete is far worse than a false alarm.
- Kept trees shallow (`max_depth=3`) to prevent overfitting with ~100 samples.

**Results:**

| Model | Accuracy | HIGH RISK Recall | HIGH RISK Precision | CV F1 |
|---|---|---|---|---|
| Decision Tree | 53% | **75%** | 33% | 0.380 ± 0.121 |
| Random Forest | 67% | 38% | 38% | 0.321 ± 0.177 |

The Decision Tree was selected as the preferred model for this use case because it catches 6 out of 8 HIGH risk athletes (75% recall), compared to the Random Forest's 3 out of 8. In athlete monitoring, missing an at-risk player has a higher cost than a false alarm.

**Top features driving predictions (Random Forest feature importance):**
1. Eccentric braking RFD (L)
2. Braking phase duration
3. Countermovement depth
4. NordBord total force
5. Max velocity

---

## Limitations

- **Sample size:** ~100 athletes limits ML model performance. With a full season (500+ observations), accuracy would improve.
- **Target variable:** HIGH risk is defined by threshold-based flags, not actual injury outcomes. Validation against real injuries would test true predictive power.
- **GPS coverage:** ~9 days of GPS data limits the ACWR chronic baseline (ideally needs 28+ days).
- **Asymmetry thresholds:** Recent research (Bishop, 2023) suggests fixed 10-15% cutoffs may be overly simplistic — individual trend monitoring is preferred in practice.
- **ACWR criticism:** Impellizzeri et al. (2020) raised concerns about ACWR's causal validity and statistical properties. The metric remains widely used but should be interpreted as one tool among many.

---

## Data Cleaning Log

| Issue | Source | Resolution |
|---|---|---|
| Name format mismatch | TAP_GRIP uses "Last, First"; others use "First Last" | Standardized to "First Last" |
| Double spaces in names | ForceDecks: "John  Doe", "Jane  Doe" | Collapsed to single space |
| Spelling inconsistency | GPS: "Johnny Doe" vs FD/NB: "John Doe" | Mapped to "John Doe" |
| Case-sensitive duplicates | "DoE" vs "Doe", "J'Hon" vs "J'hon" | Merged player IDs, reassigned data |
| Test device entry | ForceDecks: "Doe Doe" | Filtered out |
| Header row in data | GPS: literal "Date" in session_date column | Filtered out |
| Asymmetry string format | "17.3 R" as single field | Parsed to numeric (17.3) + side (R) |

I used John Jane doe names to protect players

---


## Technologies

- **Python** — ETL, data cleaning, statistical modeling, machine learning
- **MySQL** — relational database design and storage
- **SQLAlchemy + PyMySQL** — database engine and connection
- **pandas** — data manipulation and analysis
- **scikit-learn** — Decision Tree, Random Forest, cross-validation, evaluation metrics
- **matplotlib + seaborn** — correlation heatmap, feature importance, confusion matrices
- **Jupyter Notebooks** — interactive analysis and documentation
- **GitHub** — version control

---

## References

1. Croisier, J.L., et al. (2008). "Strength Imbalances and Prevention of Hamstring Injury in Professional Soccer Players." *American Journal of Sports Medicine*, 36(8), 1469–1475.
2. Bishop, C., et al. (2021). "Interlimb Asymmetries: The Need for an Individual Approach to Data Analysis." *Journal of Strength & Conditioning Research*, 35(3), 695–701.
3. Bishop, C., et al. (2023). "Measuring Interlimb Asymmetry for Strength and Power." *Journal of Strength & Conditioning Research*, 37(3), 745–750.
4. Gabbett, T.J. (2016). "The Training–Injury Prevention Paradox: Should Athletes Be Training Smarter and Harder?" *British Journal of Sports Medicine*, 50(5), 273–280.
5. Blanch, P. & Gabbett, T.J. (2016). "Has the Athlete Trained Enough to Return to Play Safely?" *British Journal of Sports Medicine*, 50(8), 471–475.
6. Hulin, B.T., et al. (2016). "The Acute:Chronic Workload Ratio Predicts Injury." *British Journal of Sports Medicine*, 50(4), 231–236.
7. Williams, S., et al. (2017). "Better Way to Determine the Acute:Chronic Workload Ratio?" *British Journal of Sports Medicine*, 51(3), 209–210.
8. Casa, D.J., et al. (2000). "Fluid Replacement for Athletes." *Journal of Athletic Training*, 35(2), 212–224.
9. Impellizzeri, F.M., et al. (2020). "Acute:Chronic Workload Ratio: Conceptual Issues and Fundamental Pitfalls." *International Journal of Sports Physiology and Performance*, 15(6), 907–913.

---

## Author

DSBA Master's Student, UNC Charlotte


