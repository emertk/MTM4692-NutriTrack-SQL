-- =============================================================================
--  NutriTrack — Key Queries
--  File: queries.sql  |  Run AFTER schema.sql AND seed.sql
-- =============================================================================
PRAGMA foreign_keys = ON;

-- =============================================================================
-- QUERY 1 — BMR & TDEE Hesabı Gösterimi
--           Her kullanıcının son BMR hesabını formül detayıyla göster.
-- =============================================================================
SELECT
    u.username,
    u.first_name || ' ' || u.last_name     AS full_name,
    bl.weight_kg,
    bl.height_cm,
    bl.age_years,
    bl.gender,
    bl.activity_level,
    bl.formula_used,
    ROUND(bl.bmr_kcal, 1)                  AS bmr_kcal,
    bl.activity_multiplier,
    ROUND(bl.tdee_kcal, 1)                 AS tdee_kcal,
    ROUND(bl.suggested_cut_kcal, 0)        AS cut_kcal,
    ROUND(bl.suggested_maintain_kcal, 0)   AS maintain_kcal,
    ROUND(bl.suggested_bulk_kcal, 0)       AS bulk_kcal,
    bl.suggested_protein_g                 AS protein_g,
    bl.calculated_at
FROM v_latest_bmr bl
JOIN user u ON u.user_id = bl.user_id
ORDER BY u.user_id;

-- =============================================================================
-- QUERY 2 — BMR Geçmişi & Kilo Değişiminin BMR'ye Etkisi
--           Kullanıcının her tartı güncellemesinde BMR nasıl değişti?
-- =============================================================================
SELECT
    u.username,
    bl.calculated_at,
    bl.trigger_event,
    bl.weight_kg,
    bl.bmr_kcal,
    bl.tdee_kcal,
    bl.bmr_kcal - LAG(bl.bmr_kcal)
        OVER (PARTITION BY bl.user_id ORDER BY bl.calculated_at)   AS bmr_change,
    bl.tdee_kcal - LAG(bl.tdee_kcal)
        OVER (PARTITION BY bl.user_id ORDER BY bl.calculated_at)   AS tdee_change
FROM bmr_log bl
JOIN user u ON u.user_id = bl.user_id
ORDER BY u.user_id, bl.calculated_at;

-- =============================================================================
-- QUERY 3 — Günlük Kalori Dengesi (Hedef vs Gerçekleşen)
--           Alınan kalori − TDEE − egzersiz yakımı = net denge
-- =============================================================================
WITH daily_nutrition AS (
    SELECT user_id, meal_date,
           ROUND(SUM(total_calories), 1)    AS calories_in,
           ROUND(SUM(total_protein_g), 1)   AS protein_in,
           ROUND(SUM(total_carbs_g), 1)     AS carbs_in,
           ROUND(SUM(total_fat_g), 1)       AS fat_in
    FROM   meal_log
    GROUP  BY user_id, meal_date
),
daily_exercise AS (
    SELECT user_id, session_date,
           ROUND(SUM(total_calories_burned), 0) AS burned
    FROM   workout_session
    GROUP  BY user_id, session_date
),
latest_bmr AS (
    SELECT user_id, tdee_kcal FROM v_latest_bmr
)
SELECT
    u.username,
    dn.meal_date,
    dn.calories_in,
    dn.protein_in,
    dn.carbs_in,
    dn.fat_in,
    COALESCE(de.burned, 0)                              AS exercise_burned,
    lb.tdee_kcal                                        AS bmr_tdee,
    ROUND(dn.calories_in - lb.tdee_kcal - COALESCE(de.burned, 0), 1)
                                                        AS net_balance,
    g.daily_calorie_target,
    ROUND(dn.calories_in * 100.0 / g.daily_calorie_target, 1) AS calorie_goal_pct
FROM daily_nutrition dn
JOIN user            u  ON u.user_id  = dn.user_id
JOIN latest_bmr      lb ON lb.user_id = dn.user_id
JOIN user_goal       g  ON g.user_id  = dn.user_id AND g.is_active = 1
LEFT JOIN daily_exercise de ON de.user_id    = dn.user_id
                            AND de.session_date = dn.meal_date
ORDER BY u.username, dn.meal_date;

-- =============================================================================
-- QUERY 4 — Barkod / AI Taramasıyla Eklenen Besinlerin Oranı
--           Hangi kullanıcı ne kadar teknoloji kullanıyor?
-- =============================================================================
SELECT
    u.username,
    COUNT(*)                                            AS total_items,
    SUM(CASE WHEN mli.entry_source = 'manual'       THEN 1 ELSE 0 END) AS manual_count,
    SUM(CASE WHEN mli.entry_source = 'barcode_scan' THEN 1 ELSE 0 END) AS barcode_count,
    SUM(CASE WHEN mli.entry_source = 'ai_image_scan'THEN 1 ELSE 0 END) AS ai_scan_count,
    ROUND(SUM(CASE WHEN mli.entry_source = 'barcode_scan'
                   OR mli.entry_source = 'ai_image_scan'
              THEN 1.0 ELSE 0 END) * 100 / COUNT(*), 1) AS tech_usage_pct
FROM meal_log_item mli
JOIN meal_log ml ON ml.meal_id  = mli.meal_id
JOIN user     u  ON u.user_id   = ml.user_id
GROUP BY u.user_id
ORDER BY tech_usage_pct DESC;

-- =============================================================================
-- QUERY 5 — AI Kalori Tahmin Doğruluğu
--           AI'ın tahmin ettiği kalori ile gerçek değer arasındaki fark.
-- =============================================================================
SELECT
    u.username,
    ais.detected_food_name,
    ais.estimated_weight_g,
    ais.estimated_calories                              AS ai_estimated_kcal,
    ROUND(fi.calories_per_100g * ais.estimated_weight_g / 100, 1) AS actual_kcal,
    ROUND(ABS(ais.estimated_calories
              - fi.calories_per_100g * ais.estimated_weight_g / 100), 1) AS abs_error_kcal,
    ROUND(ais.confidence_score * 100, 1)               AS confidence_pct,
    ais.user_corrected,
    ais.scanned_at
FROM ai_image_scan ais
JOIN user      u  ON u.user_id  = ais.user_id
JOIN food_item fi ON fi.food_id = ais.detected_food_id
ORDER BY abs_error_kcal DESC;

-- =============================================================================
-- QUERY 6 — Haftalık Makro Ortalama vs Hedef (CTE)
-- =============================================================================
WITH weekly_avg AS (
    SELECT
        ml.user_id,
        strftime('%Y-W%W', ml.meal_date)               AS week,
        COUNT(DISTINCT ml.meal_date)                    AS tracked_days,
        ROUND(AVG(day_sum.cal), 0)                      AS avg_cal,
        ROUND(AVG(day_sum.prot), 1)                     AS avg_prot_g,
        ROUND(AVG(day_sum.carb), 1)                     AS avg_carb_g,
        ROUND(AVG(day_sum.fat), 1)                      AS avg_fat_g
    FROM meal_log ml
    JOIN (
        SELECT user_id, meal_date,
               SUM(total_calories)  AS cal,
               SUM(total_protein_g) AS prot,
               SUM(total_carbs_g)   AS carb,
               SUM(total_fat_g)     AS fat
        FROM   meal_log
        GROUP  BY user_id, meal_date
    ) day_sum ON day_sum.user_id = ml.user_id AND day_sum.meal_date = ml.meal_date
    GROUP BY ml.user_id, week
),
goal_targets AS (
    SELECT user_id, daily_calorie_target, daily_protein_g,
           daily_carb_g, daily_fat_g
    FROM   user_goal WHERE is_active = 1
)
SELECT
    u.username,
    wa.week,
    wa.tracked_days,
    wa.avg_cal,   gt.daily_calorie_target,
    ROUND((wa.avg_cal - gt.daily_calorie_target), 0)    AS cal_diff,
    wa.avg_prot_g, gt.daily_protein_g,
    ROUND((wa.avg_prot_g - gt.daily_protein_g), 1)      AS prot_diff_g,
    wa.avg_carb_g, wa.avg_fat_g
FROM weekly_avg wa
JOIN goal_targets gt ON gt.user_id = wa.user_id
JOIN user         u  ON u.user_id  = wa.user_id
ORDER BY u.username, wa.week;

-- =============================================================================
-- QUERY 7 — Egzersiz Kategorisi Başına Kalori Yakımı (GROUP BY + HAVING)
-- =============================================================================
SELECT
    u.username,
    et.category,
    COUNT(DISTINCT ws.session_id)                   AS sessions,
    COUNT(wset.set_id)                              AS total_sets,
    ROUND(SUM(wset.calories_burned), 0)             AS total_burned_kcal,
    ROUND(AVG(wset.calories_burned), 1)             AS avg_kcal_per_set
FROM workout_set   wset
JOIN workout_session ws ON ws.session_id  = wset.session_id
JOIN exercise_type  et  ON et.exercise_id = wset.exercise_id
JOIN user           u   ON u.user_id      = ws.user_id
GROUP BY u.user_id, et.category
HAVING total_burned_kcal > 50
ORDER BY u.username, total_burned_kcal DESC;

-- =============================================================================
-- QUERY 8 — Kilo Değişim Trendi (Window Function + Correlated Subquery)
--           Her ölçümde bir önceki ölçüme göre değişim ve hedefe uzaklık.
-- =============================================================================
SELECT
    u.username,
    bm.measured_date,
    bm.weight_kg,
    bm.body_fat_pct,
    bm.bmi,
    bm.waist_hip_ratio,
    ROUND(bm.weight_kg - LAG(bm.weight_kg)
        OVER (PARTITION BY bm.user_id ORDER BY bm.measured_date), 2) AS weight_change_kg,
    -- Hedefe uzaklık (correlated subquery)
    ROUND(bm.weight_kg - (
        SELECT g.target_weight_kg
        FROM   user_goal g
        WHERE  g.user_id = bm.user_id AND g.is_active = 1
        LIMIT  1
    ), 2)                                           AS kg_to_goal,
    bm.triggered_bmr_id
FROM body_measurement bm
JOIN user u ON u.user_id = bm.user_id
ORDER BY u.username, bm.measured_date;

-- =============================================================================
-- QUERY 9 — Su & Uyku & Adım Uyum Analizi (Hedeflere Göre)
-- =============================================================================
SELECT
    u.username,
    dt.track_date,
    dt.water_ml,        g.daily_water_ml     AS water_goal,
    ROUND(dt.water_ml * 100.0 / g.daily_water_ml, 1) AS water_pct,
    dt.steps,           g.daily_steps_target AS step_goal,
    ROUND(dt.steps * 100.0 / g.daily_steps_target, 1) AS step_pct,
    dt.sleep_duration_min, g.daily_sleep_min_target AS sleep_goal,
    dt.sleep_quality,
    dt.mood,
    -- Günün genel skoru (3 hedefin ortalaması)
    ROUND((
        MIN(dt.water_ml * 100.0 / g.daily_water_ml, 100) +
        MIN(dt.steps * 100.0 / g.daily_steps_target, 100) +
        MIN(COALESCE(dt.sleep_duration_min,0) * 100.0 / g.daily_sleep_min_target, 100)
    ) / 3, 1)                                   AS daily_wellness_score
FROM daily_tracker dt
JOIN user      u ON u.user_id  = dt.user_id
JOIN user_goal g ON g.user_id  = dt.user_id AND g.is_active = 1
ORDER BY u.username, dt.track_date;

-- =============================================================================
-- QUERY 10 — CTE: En Çok Tüketilen 10 Besin (Frekans + Kalori Katkısı)
-- =============================================================================
WITH food_frequency AS (
    SELECT
        mli.food_id,
        COUNT(*)                            AS times_logged,
        ROUND(SUM(mli.quantity_g), 0)       AS total_grams,
        ROUND(SUM(mli.calories), 0)         AS total_calories_contributed,
        ROUND(AVG(mli.quantity_g), 0)       AS avg_portion_g
    FROM meal_log_item mli
    GROUP BY mli.food_id
),
ranked AS (
    SELECT
        fi.name,
        fi.brand,
        fi.category,
        fi.calories_per_100g,
        fi.protein_per_100g,
        ff.times_logged,
        ff.total_grams,
        ff.total_calories_contributed,
        ff.avg_portion_g
    FROM food_frequency ff
    JOIN food_item fi ON fi.food_id = ff.food_id
)
SELECT * FROM ranked
ORDER BY times_logged DESC, total_calories_contributed DESC
LIMIT 10;

-- =============================================================================
-- QUERY 11 — Recursive CTE: 90 Günlük Takvim + Kalori Takip Durumu
--            Hangi günler loglama yapılmış, hangi günler boş kalmış?
-- =============================================================================
WITH RECURSIVE calendar AS (
    SELECT date('2026-01-01') AS cal_date
    UNION ALL
    SELECT date(cal_date, '+1 day')
    FROM   calendar
    WHERE  cal_date < '2026-03-31'
),
user_days AS (
    SELECT DISTINCT user_id, meal_date AS logged_date
    FROM   meal_log
)
SELECT
    c.cal_date,
    strftime('%A', c.cal_date)                          AS day_name,
    u.username,
    CASE WHEN ud.logged_date IS NOT NULL THEN 1 ELSE 0 END AS is_logged,
    COALESCE(SUM(ml.total_calories), 0)                 AS calories_logged
FROM calendar c
CROSS JOIN user u
LEFT JOIN user_days ud ON ud.user_id = u.user_id AND ud.logged_date = c.cal_date
LEFT JOIN meal_log  ml ON ml.user_id = u.user_id AND ml.meal_date   = c.cal_date
WHERE u.user_id = 1   -- Ahmet için göster
GROUP BY c.cal_date, u.user_id
ORDER BY c.cal_date;

-- =============================================================================
-- QUERY 12 — Recursive CTE: 6 Haftalık Kilo Projeksiyonu
--            Kullanıcının hedef kilo değişimine göre ileriye dönük tahmin.
-- =============================================================================
WITH RECURSIVE projection AS (
    SELECT
        1                                               AS week_num,
        date('now')                                     AS projection_date,
        bm.weight_kg                                    AS projected_weight,
        g.target_weight_kg
    FROM body_measurement bm
    JOIN user_goal g ON g.user_id = bm.user_id AND g.is_active = 1
    WHERE bm.user_id = 1
      AND bm.measured_date = (SELECT MAX(measured_date) FROM body_measurement WHERE user_id = 1)

    UNION ALL

    SELECT
        week_num + 1,
        date(projection_date, '+7 days'),
        ROUND(projected_weight + (
            SELECT g2.weekly_weight_change_kg
            FROM   user_goal g2
            WHERE  g2.user_id = 1 AND g2.is_active = 1
        ), 2),
        target_weight_kg
    FROM projection
    WHERE week_num < 12
      AND ABS(projected_weight - target_weight_kg) > 0.2
)
SELECT
    week_num,
    projection_date,
    projected_weight,
    target_weight_kg,
    ROUND(projected_weight - target_weight_kg, 2)       AS kg_remaining,
    CASE
        WHEN projected_weight <= target_weight_kg THEN '✓ Hedefe Ulaşıldı!'
        WHEN projected_weight - target_weight_kg < 2    THEN 'Hedefe Çok Yakın'
        WHEN projected_weight - target_weight_kg < 5    THEN 'İyi Gidiyor'
        ELSE 'Devam Et'
    END                                                  AS status
FROM projection;

-- =============================================================================
-- QUERY 13 — En Verimli Egzersizler (Kcal/Dakika Oranı)
-- =============================================================================
SELECT
    et.name,
    et.category,
    et.met_value,
    et.muscle_groups,
    -- 80kg kullanıcı için referans kalori/dakika
    ROUND(et.met_value * 80 / 60.0, 2)                  AS kcal_per_min_80kg,
    ROUND(et.met_value * 70 / 60.0, 2)                  AS kcal_per_min_70kg,
    ROUND(et.met_value * 60 / 60.0, 2)                  AS kcal_per_min_60kg,
    COUNT(wset.set_id)                                   AS times_performed
FROM exercise_type et
LEFT JOIN workout_set    wset ON wset.exercise_id = et.exercise_id
GROUP BY et.exercise_id
ORDER BY et.met_value DESC;

-- =============================================================================
-- QUERY 14 — Mikro Besin Eksikliği Analizi
--            Günlük sodyum ve fiber alımını kontrol et.
-- =============================================================================
WITH daily_micros AS (
    SELECT
        ml.user_id,
        ml.meal_date,
        ROUND(SUM(ml.total_fiber_g), 1)     AS fiber_g,
        ROUND(SUM(ml.total_sodium_mg), 0)   AS sodium_mg
    FROM meal_log ml
    GROUP BY ml.user_id, ml.meal_date
)
SELECT
    u.username,
    dm.meal_date,
    dm.fiber_g,
    CASE WHEN dm.fiber_g < 25 THEN 'DÜŞÜK ⚠️' ELSE 'YETERLİ ✓' END AS fiber_status,
    dm.sodium_mg,
    CASE WHEN dm.sodium_mg > 2300 THEN 'YÜKSEK ⚠️' ELSE 'NORMAL ✓' END AS sodium_status
FROM daily_micros dm
JOIN user u ON u.user_id = dm.user_id
ORDER BY u.username, dm.meal_date;

-- =============================================================================
-- QUERY 15 — Kapsamlı Kullanıcı Sağlık Özeti (Multi-CTE)
-- =============================================================================
WITH current_weight AS (
    SELECT user_id, weight_kg, body_fat_pct, bmi
    FROM   body_measurement
    WHERE  (user_id, measured_date) IN (
        SELECT user_id, MAX(measured_date)
        FROM   body_measurement GROUP BY user_id
    )
),
nutrition_avg AS (
    SELECT user_id,
           ROUND(AVG(total_calories), 0)    AS avg_cal,
           ROUND(AVG(total_protein_g), 1)   AS avg_prot,
           COUNT(DISTINCT meal_date)        AS logged_days
    FROM   meal_log GROUP BY user_id
),
workout_summary AS (
    SELECT user_id,
           COUNT(*)                         AS total_sessions,
           ROUND(SUM(total_calories_burned),0) AS total_burned,
           ROUND(AVG(perceived_effort), 1)  AS avg_effort
    FROM   workout_session GROUP BY user_id
),
hydration_avg AS (
    SELECT user_id,
           ROUND(AVG(water_ml), 0)          AS avg_water_ml,
           ROUND(AVG(steps), 0)             AS avg_steps,
           ROUND(AVG(sleep_duration_min),0) AS avg_sleep_min
    FROM   daily_tracker GROUP BY user_id
)
SELECT
    u.username,
    u.first_name || ' ' || u.last_name     AS full_name,
    cw.weight_kg,
    cw.body_fat_pct,
    cw.bmi,
    lb.bmr_kcal,
    lb.tdee_kcal,
    g.goal_type,
    g.daily_calorie_target,
    na.avg_cal,
    ROUND(na.avg_cal - g.daily_calorie_target, 0) AS calorie_gap,
    na.avg_prot,
    g.daily_protein_g                       AS protein_target,
    na.logged_days,
    ws.total_sessions,
    ws.total_burned,
    ws.avg_effort,
    ha.avg_water_ml,
    g.daily_water_ml                        AS water_target,
    ha.avg_steps,
    g.daily_steps_target                    AS steps_target,
    ha.avg_sleep_min
FROM user u
LEFT JOIN current_weight cw ON cw.user_id = u.user_id
LEFT JOIN v_latest_bmr   lb ON lb.user_id = u.user_id
LEFT JOIN user_goal      g  ON g.user_id  = u.user_id AND g.is_active = 1
LEFT JOIN nutrition_avg  na ON na.user_id = u.user_id
LEFT JOIN workout_summary ws ON ws.user_id = u.user_id
LEFT JOIN hydration_avg  ha ON ha.user_id = u.user_id
ORDER BY u.user_id;

-- =============================================================================
-- QUERY 16 — EXPLAIN: Barkod arama sorgusu için index kontrolü
-- =============================================================================
EXPLAIN QUERY PLAN
SELECT f.* FROM food_item f WHERE f.barcode = '8690504050056';

-- =============================================================================
--  END OF QUERIES
-- =============================================================================
