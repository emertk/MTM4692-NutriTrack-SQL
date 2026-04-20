# 🏋️ NutriTrack — Fitness & Nutrition Tracking System

> **MTM4692 Applied SQL** · Spring 2026 · Yıldız Technical University  
> Department of Mathematical Engineering
> 
> 20058611 Ender Mert Kutbay
>
> 22058601 Berkay Mutlu
>
> 23052612 Kenan Pehlivan

---

## 📋 Project Overview

**NutriTrack** is a fully relational fitness and nutrition tracking system built in **SQLite**, designed to give users a complete picture of their health — from every meal eaten and every exercise performed, to daily water intake, sleep quality, step count, and body composition changes.

The system supports **barcode scanning** and **AI-powered photo recognition** to log food with minimal friction, and automatically calculates **Basal Metabolic Rate (BMR)** and **Total Daily Energy Expenditure (TDEE)** every time the user's weight or activity level changes.

---

## 🎯 Problem Statement

Tracking health and fitness data is fragmented across dozens of apps that don't talk to each other. Users who want to understand:

- *"How many calories did I actually burn today, net of my BMR?"*
- *"Is my protein intake keeping up with my training volume?"*
- *"What's my projected weight in 6 weeks if I keep this up?"*

…have no single, queryable data source to answer these questions.

**NutriTrack solves this** with a unified relational database where every food scan, workout set, sip of water, and body measurement is linked — and answerable with SQL in seconds.

---

## 🏗️ Database Schema — 13 Tables

### 👤 User & Goals

| Table | Description |
|-------|-------------|
| `user` | Profile, height, starting weight, BMR formula preference, activity level |
| `user_goal` | Active goal (Lose Weight / Gain Muscle / Maintain / Recomposition) with macro targets |
| `bmr_log` | **BMR & TDEE calculation history** — recalculated on every weight update |

### 🍽️ Nutrition Tracking

| Table | Description |
|-------|-------------|
| `food_item` | OpenFoodFacts standard — per-100g macros + micros, barcode, category |
| `barcode_scan` | Log of every barcode scan (found / not found / manually added) |
| `ai_image_scan` | AI photo recognition log — estimated weight, calories, confidence score |
| `meal_log` | Meal header (Breakfast / Lunch / Dinner / Snack / Pre-Post Workout) |
| `meal_log_item` | Individual food entries per meal with calculated macros |

### 💪 Exercise Tracking

| Table | Description |
|-------|-------------|
| `exercise_type` | Exercise catalogue with MET values for calorie calculation |
| `workout_session` | Training session with duration, location, perceived effort |
| `workout_set` | Individual sets with reps, weight, duration, calories burned |

### 📊 Daily Wellness

| Table | Description |
|-------|-------------|
| `daily_tracker` | Water (ml), steps, sleep start/end, sleep quality, mood — one row per day |
| `body_measurement` | Weight, body fat %, BMI (auto-calculated), all circumference measurements, WHR |

---

## 🧮 BMR Calculation Logic

Every time a user logs a new weight, the system records a new `bmr_log` entry with:

```
Mifflin-St Jeor (default, most accurate):
  Male   → BMR = 10×kg + 6.25×cm − 5×age + 5
  Female → BMR = 10×kg + 6.25×cm − 5×age − 161

Harris-Benedict (classic):
  Male   → BMR = 13.397×kg + 4.799×cm − 5.677×age + 88.362
  Female → BMR = 9.247×kg  + 3.098×cm − 4.330×age + 447.593

Katch-McArdle (lean mass):
  BMR = 370 + 21.6 × (kg × (1 − body_fat% / 100))

TDEE = BMR × activity_multiplier
  Sedentary=1.2 | Lightly Active=1.375 | Moderately Active=1.55
  Very Active=1.725 | Extra Active=1.9

Suggested targets:
  Cut  = TDEE − 500 kcal   (−0.5 kg/week)
  Bulk = TDEE + 300 kcal   (+0.3 kg/week)
  Protein = 2g × body weight (kg)
```

---



## 📊 Views

| View | Purpose |
|------|---------|
| `v_latest_bmr` | Each user's most recent BMR & TDEE snapshot |
| `v_daily_nutrition_summary` | Daily totals: calories, protein, carbs, fat, fiber, sodium |
| `v_daily_calorie_balance` | Net calorie balance: consumed − TDEE − exercise burned |
| `v_weekly_progress` | Weekly averages for nutrition and workout volume |
| `v_goal_progress` | Today's progress vs active goal targets (% complete) |
| `v_body_progress` | Weight & composition trends with LAG-based change detection |

---

## ⚡ Key Features

**🔢 Automatic BMR/TDEE Recalculation**  
Every new weight entry triggers a new `bmr_log` record with updated BMR, TDEE, and macro suggestions — no manual calculation needed.

**📷 Barcode & AI Photo Scanning**  
`barcode_scan` and `ai_image_scan` tables track every scan attempt, AI confidence score, and whether the user corrected the AI's output — creating a rich audit trail.

**📅 Gap Analysis**  
Recursive CTE generates a full calendar, then LEFT JOINs with meal logs to instantly identify days with no tracking.

**📈 Weight Projection**  
Recursive CTE projects future weight based on the user's active weekly weight change target — showing estimated weeks to goal.

**🏋️ MET-Based Calorie Burn**  
Every exercise type has a MET value. Calories burned per set = `MET × user_weight_kg × (duration_min / 60)` — accurate and automatic.

---

## 🚀 Quick Start

```bash
# 1. Clone
git clone https://github.com/<your-username>/nutritrack-db.git
cd nutritrack-db

# 2. Build
sqlite3 nutritrack.db < schema.sql
sqlite3 nutritrack.db < seed.sql

# 3. Run queries
sqlite3 nutritrack.db < queries.sql

# 4. Interactive
sqlite3 nutritrack.db
```

### Verify

```sql
SELECT name, COUNT(*) AS rows
FROM sqlite_master s
JOIN (
    SELECT 'user'             AS t UNION ALL SELECT 'bmr_log'
    UNION ALL SELECT 'user_goal'   UNION ALL SELECT 'food_item'
    UNION ALL SELECT 'meal_log'    UNION ALL SELECT 'meal_log_item'
    UNION ALL SELECT 'workout_session' UNION ALL SELECT 'workout_set'
    UNION ALL SELECT 'daily_tracker'   UNION ALL SELECT 'body_measurement'
) tables ON tables.t = s.name
WHERE s.type = 'table';
```

---

## 📊 Sample Data Summary

| Table | Rows | Highlights |
|-------|------|-----------|
| `user` | 5 | Mixed goals: cut / bulk / maintain / recomp |
| `bmr_log` | 6 | Mifflin-St Jeor & Harris-Benedict, weight update trigger |
| `user_goal` | 5 | All goal types, linked to BMR records |
| `food_item` | 30 | Turkish + international foods, OpenFoodFacts standard |
| `barcode_scan` | 9 | Including 1 not-found scan |
| `ai_image_scan` | 6 | Confidence scores 0.72–0.95, 1 user correction |
| `meal_log` | 19 | Breakfast to post-workout, 5 users over multiple days |
| `meal_log_item` | 17 | Mixed entry sources: manual / barcode / AI |
| `exercise_type` | 25 | Strength, Cardio, HIIT, Flexibility with MET values |
| `workout_session` | 13 | Gym, outdoor, home sessions |
| `workout_set` | 31 | Full sets with reps, weight, duration, calories |
| `daily_tracker` | 17 | Water, steps, sleep, mood |
| `body_measurement` | 11 | 2–3 months of progress per user, BMI auto-calc |

---



---

