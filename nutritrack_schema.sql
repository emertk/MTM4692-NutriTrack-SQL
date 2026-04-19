-- =============================================================================
--  NutriTrack — Fitness & Nutrition Tracking System
--  Schema Definition
--  File   : schema.sql  |  DB: SQLite 3.x
-- =============================================================================
--  TABLE OF CONTENTS
--    §1  Pragmas
--    §2  Core Tables (13 tables)
--         2.1  user
--         2.2  bmr_log            ← BMR/TDEE hesap geçmişi
--         2.3  user_goal
--         2.4  food_item          ← OpenFoodFacts standardı
--         2.5  barcode_scan       ← barkod okuma logu
--         2.6  ai_image_scan      ← fotoğraftan AI kalori tahmini
--         2.7  meal_log           ← öğün kaydı
--         2.8  meal_log_item      ← öğün içindeki besinler
--         2.9  exercise_type      ← egzersiz kataloğu
--         2.10 workout_session    ← antrenman seansı
--         2.11 workout_set        ← set/rep/süre detayı
--         2.12 daily_tracker      ← su, adım, uyku günlük özet
--         2.13 body_measurement   ← vücut ölçüleri + BF%
--    §3  Indexes
--    §4  Views
-- =============================================================================

PRAGMA foreign_keys = ON;
PRAGMA journal_mode  = WAL;

-- =============================================================================
-- §2 ── CORE TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1  USER
--      Temel kullanıcı profili. BMR hesabı için gerekli tüm alanlar burada.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user (
    user_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    username            TEXT    NOT NULL UNIQUE,
    email               TEXT    NOT NULL UNIQUE,
    password_hash       TEXT    NOT NULL,
    first_name          TEXT    NOT NULL,
    last_name           TEXT    NOT NULL,
    date_of_birth       TEXT    NOT NULL,          -- YYYY-MM-DD
    gender              TEXT    NOT NULL
                                CHECK (gender IN ('Male','Female','Other')),
    height_cm           REAL    NOT NULL CHECK (height_cm > 0),
    initial_weight_kg   REAL    NOT NULL CHECK (initial_weight_kg > 0),
    activity_level      TEXT    NOT NULL DEFAULT 'Moderately Active'
                                CHECK (activity_level IN (
                                    'Sedentary',        -- 1.2  — masa başı, egzersiz yok
                                    'Lightly Active',   -- 1.375 — haftada 1-3 gün
                                    'Moderately Active',-- 1.55  — haftada 3-5 gün
                                    'Very Active',      -- 1.725 — haftada 6-7 gün
                                    'Extra Active'      -- 1.9   — fiziksel iş + antrenman
                                )),
    -- BMR formül tercihi
    bmr_formula         TEXT    NOT NULL DEFAULT 'Mifflin-St Jeor'
                                CHECK (bmr_formula IN (
                                    'Mifflin-St Jeor',  -- en güncel, önerilen
                                    'Harris-Benedict',  -- klasik formül
                                    'Katch-McArdle'     -- vücut yağı % gerektirir
                                )),
    unit_system         TEXT    NOT NULL DEFAULT 'metric'
                                CHECK (unit_system IN ('metric','imperial')),
    timezone            TEXT    NOT NULL DEFAULT 'Europe/Istanbul',
    profile_photo       TEXT,
    is_active           INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    created_at          TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.2  BMR_LOG
--      Her kilo değişimi veya aktivite düzeyi güncellemesinde BMR & TDEE
--      otomatik hesaplanarak buraya kaydedilir. Geçmiş korunur.
--
--      Formüller:
--        Mifflin-St Jeor:
--          Erkek : BMR = 10×kg + 6.25×cm − 5×yaş + 5
--          Kadın : BMR = 10×kg + 6.25×cm − 5×yaş − 161
--        Harris-Benedict (revised):
--          Erkek : BMR = 13.397×kg + 4.799×cm − 5.677×yaş + 88.362
--          Kadın : BMR = 9.247×kg  + 3.098×cm − 4.330×yaş + 447.593
--        Katch-McArdle (lean mass gerektirir):
--          BMR = 370 + 21.6 × (kg × (1 − bodyfat%/100))
--
--      TDEE = BMR × activity_multiplier
--        Sedentary=1.2 | Lightly Active=1.375 | Moderately Active=1.55
--        Very Active=1.725 | Extra Active=1.9
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bmr_log (
    bmr_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    -- Hesap girdi değerleri (snapshot — kullanıcı değişirse eski kayıt bozulmaz)
    weight_kg           REAL    NOT NULL,
    height_cm           REAL    NOT NULL,
    age_years           INTEGER NOT NULL,
    gender              TEXT    NOT NULL,
    activity_level      TEXT    NOT NULL,
    body_fat_pct        REAL,                      -- Katch-McArdle için gerekli
    formula_used        TEXT    NOT NULL,
    -- Hesap çıktıları
    bmr_kcal            REAL    NOT NULL,          -- Bazal Metabolik Hız
    tdee_kcal           REAL    NOT NULL,          -- Toplam Günlük Enerji Harcaması
    activity_multiplier REAL    NOT NULL,
    -- Hedef kalori önerileri (hedefe göre otomatik)
    suggested_cut_kcal  REAL,                      -- TDEE − 500  (kilo verme)
    suggested_bulk_kcal REAL,                      -- TDEE + 300  (kilo alma)
    suggested_maintain_kcal REAL,                  -- TDEE        (koruma)
    -- Makro önerileri (protein: 2g/kg, karbonhidrat & yağ dengeli)
    suggested_protein_g REAL,
    suggested_carb_g    REAL,
    suggested_fat_g     REAL,
    -- Meta
    trigger_event       TEXT    DEFAULT 'manual'
                                CHECK (trigger_event IN (
                                    'manual',           -- kullanıcı el ile istedi
                                    'weight_update',    -- yeni tartı girişi
                                    'goal_change',      -- hedef değişti
                                    'activity_change',  -- aktivite seviyesi değişti
                                    'registration'      -- ilk kayıt
                                )),
    notes               TEXT,
    calculated_at       TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.3  USER_GOAL
--      Kullanıcının aktif hedefi. Geçmiş hedefler is_active=0 ile arşivlenir.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_goal (
    goal_id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id                 INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    goal_type               TEXT    NOT NULL
                                    CHECK (goal_type IN (
                                        'Lose Weight',
                                        'Gain Muscle',
                                        'Maintain',
                                        'Body Recomposition'
                                    )),
    target_weight_kg        REAL    CHECK (target_weight_kg > 0),
    target_body_fat_pct     REAL    CHECK (target_body_fat_pct BETWEEN 3 AND 60),
    -- Günlük hedefler (bmr_log'dan otomatik doldurulabilir)
    daily_calorie_target    INTEGER NOT NULL CHECK (daily_calorie_target > 0),
    daily_protein_g         REAL    NOT NULL DEFAULT 0,
    daily_carb_g            REAL    NOT NULL DEFAULT 0,
    daily_fat_g             REAL    NOT NULL DEFAULT 0,
    daily_water_ml          INTEGER NOT NULL DEFAULT 2500,
    daily_steps_target      INTEGER NOT NULL DEFAULT 8000,
    daily_sleep_min_target  INTEGER NOT NULL DEFAULT 480,  -- 480 dk = 8 saat
    weekly_workout_days     INTEGER NOT NULL DEFAULT 4
                                    CHECK (weekly_workout_days BETWEEN 0 AND 7),
    -- Haftalık kilo değişim hedefi
    weekly_weight_change_kg REAL,                  -- negatif=verme, pozitif=alma
    start_date              TEXT    NOT NULL DEFAULT (date('now')),
    end_date                TEXT,
    is_active               INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    notes                   TEXT,
    -- Hangi BMR hesabına dayandığı
    based_on_bmr_id         INTEGER REFERENCES bmr_log(bmr_id),
    created_at              TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.4  FOOD_ITEM
--      OpenFoodFacts standardı. Per 100g değerleri saklanır.
--      Barkod, AI taraması veya manuel giriş ile eklenir.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS food_item (
    food_id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    barcode                 TEXT    UNIQUE,         -- EAN-13 / UPC-A
    name                    TEXT    NOT NULL,
    brand                   TEXT,
    category                TEXT,                  -- Dairy, Grains, Protein…
    -- Makro (per 100g)
    calories_per_100g       REAL    NOT NULL CHECK (calories_per_100g >= 0),
    protein_per_100g        REAL    NOT NULL DEFAULT 0,
    carbs_per_100g          REAL    NOT NULL DEFAULT 0,
    sugar_per_100g          REAL    DEFAULT 0,
    fiber_per_100g          REAL    DEFAULT 0,
    fat_per_100g            REAL    NOT NULL DEFAULT 0,
    saturated_fat_per_100g  REAL    DEFAULT 0,
    trans_fat_per_100g      REAL    DEFAULT 0,
    -- Mikro (per 100g)
    sodium_mg_per_100g      REAL    DEFAULT 0,
    potassium_mg_per_100g   REAL    DEFAULT 0,
    calcium_mg_per_100g     REAL    DEFAULT 0,
    iron_mg_per_100g        REAL    DEFAULT 0,
    vitamin_c_mg_per_100g   REAL    DEFAULT 0,
    vitamin_d_mcg_per_100g  REAL    DEFAULT 0,
    -- Porsiyon bilgisi
    serving_size_g          REAL    NOT NULL DEFAULT 100,
    serving_unit            TEXT    NOT NULL DEFAULT 'g'
                                    CHECK (serving_unit IN ('g','ml','piece','slice','cup','tbsp','tsp')),
    allergens               TEXT,                  -- 'gluten,dairy,nuts' gibi
    is_verified             INTEGER NOT NULL DEFAULT 0 CHECK (is_verified IN (0,1)),
    source                  TEXT    NOT NULL DEFAULT 'manual'
                                    CHECK (source IN ('manual','barcode_api','ai_scan','openfoodfacts')),
    created_at              TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.5  BARCODE_SCAN
--      Kullanıcının kamera ile barkod okutma logu.
--      Barkod API'den veri gelirse food_item'a bağlanır.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS barcode_scan (
    scan_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    barcode             TEXT    NOT NULL,
    food_id             INTEGER REFERENCES food_item(food_id),  -- NULL = bulunamadı
    scan_result         TEXT    NOT NULL DEFAULT 'found'
                                CHECK (scan_result IN ('found','not_found','manual_added')),
    api_response_json   TEXT,                      -- ham API yanıtı (debug için)
    scanned_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.6  AI_IMAGE_SCAN
--      Kullanıcı yemek fotoğrafı çektiğinde AI tahmini kaydedilir.
--      Güven skoru düşükse kullanıcı manuel düzeltebilir.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ai_image_scan (
    scan_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    image_path          TEXT    NOT NULL,           -- yerel dosya yolu
    -- AI çıktısı
    detected_food_name  TEXT,                       -- 'Grilled Chicken Breast'
    detected_food_id    INTEGER REFERENCES food_item(food_id),
    estimated_weight_g  REAL,                       -- tahmini gram
    estimated_calories  REAL,                       -- tahmini kalori
    confidence_score    REAL CHECK (confidence_score BETWEEN 0 AND 1),
    ai_model_used       TEXT    DEFAULT 'claude-vision',
    raw_ai_response     TEXT,                       -- tam AI yanıtı
    -- Kullanıcı düzeltmesi
    user_corrected      INTEGER NOT NULL DEFAULT 0 CHECK (user_corrected IN (0,1)),
    corrected_food_id   INTEGER REFERENCES food_item(food_id),
    corrected_weight_g  REAL,
    -- Bu tarama bir öğüne eklendi mi?
    added_to_meal_log_item_id INTEGER,
    scanned_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.7  MEAL_LOG
--      Öğün kaydı başlığı (kahvaltı, öğle, akşam, atıştırma).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meal_log (
    meal_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    meal_type           TEXT    NOT NULL
                                CHECK (meal_type IN ('Breakfast','Lunch','Dinner','Snack','Pre-Workout','Post-Workout')),
    meal_date           TEXT    NOT NULL,           -- YYYY-MM-DD
    meal_time           TEXT,                       -- HH:MM
    notes               TEXT,
    -- Toplam makrolar (meal_log_item'lardan hesaplanır, denormalizasyon)
    total_calories      REAL    NOT NULL DEFAULT 0,
    total_protein_g     REAL    NOT NULL DEFAULT 0,
    total_carbs_g       REAL    NOT NULL DEFAULT 0,
    total_fat_g         REAL    NOT NULL DEFAULT 0,
    total_fiber_g       REAL    NOT NULL DEFAULT 0,
    total_sodium_mg     REAL    NOT NULL DEFAULT 0,
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.8  MEAL_LOG_ITEM
--      Öğündeki her bir besin kalemi. Gram cinsinden miktar girilir,
--      kalori ve makrolar otomatik hesaplanır.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS meal_log_item (
    item_id             INTEGER PRIMARY KEY AUTOINCREMENT,
    meal_id             INTEGER NOT NULL REFERENCES meal_log(meal_id) ON DELETE CASCADE,
    food_id             INTEGER NOT NULL REFERENCES food_item(food_id),
    quantity_g          REAL    NOT NULL CHECK (quantity_g > 0),
    -- Hesaplanan değerler (quantity_g / 100 × per_100g)
    calories            REAL    NOT NULL,
    protein_g           REAL    NOT NULL DEFAULT 0,
    carbs_g             REAL    NOT NULL DEFAULT 0,
    fat_g               REAL    NOT NULL DEFAULT 0,
    fiber_g             REAL    NOT NULL DEFAULT 0,
    sodium_mg           REAL    NOT NULL DEFAULT 0,
    sugar_g             REAL    NOT NULL DEFAULT 0,
    -- Kaynak (barkod/AI/manuel)
    entry_source        TEXT    NOT NULL DEFAULT 'manual'
                                CHECK (entry_source IN ('manual','barcode_scan','ai_image_scan')),
    barcode_scan_id     INTEGER REFERENCES barcode_scan(scan_id),
    ai_scan_id          INTEGER REFERENCES ai_image_scan(scan_id),
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.9  EXERCISE_TYPE
--      Egzersiz kataloğu. MET değeri ile kalori yakımı hesaplanır.
--      MET (Metabolic Equivalent of Task): 1 MET = 1 kcal/kg/saat
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS exercise_type (
    exercise_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name                TEXT    NOT NULL UNIQUE,
    category            TEXT    NOT NULL
                                CHECK (category IN (
                                    'Strength',         -- ağırlık, direnç
                                    'Cardio',           -- koşu, bisiklet
                                    'HIIT',             -- yüksek yoğunluk
                                    'Flexibility',      -- yoga, esneme
                                    'Sports',           -- futbol, basketbol
                                    'Water Sports',     -- yüzme, kürek
                                    'Other'
                                )),
    muscle_groups       TEXT,                      -- 'chest,triceps,shoulders'
    met_value           REAL    NOT NULL CHECK (met_value > 0),
    -- Kuvvet egzersizleri için (Strength)
    is_strength         INTEGER NOT NULL DEFAULT 0 CHECK (is_strength IN (0,1)),
    equipment_needed    TEXT,                      -- 'barbell,bench' veya 'none'
    description         TEXT,
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.10 WORKOUT_SESSION
--      Bir antrenman seansı. Toplam kalori workout_set'lerden hesaplanır.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_session (
    session_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    session_date        TEXT    NOT NULL,           -- YYYY-MM-DD
    start_time          TEXT,                       -- HH:MM
    end_time            TEXT,                       -- HH:MM
    duration_min        INTEGER CHECK (duration_min > 0),
    -- Toplam yakılan kalori (workout_set'lerden hesaplanır)
    total_calories_burned REAL  NOT NULL DEFAULT 0,
    -- Kullanıcının o anki ağırlığı (kalori hesabı için)
    user_weight_kg      REAL    NOT NULL,
    location            TEXT    CHECK (location IN ('Gym','Home','Outdoor','Pool','Other')),
    notes               TEXT,
    perceived_effort    INTEGER CHECK (perceived_effort BETWEEN 1 AND 10),  -- RPE
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.11 WORKOUT_SET
--      Bir seansın her bir egzersiz seti.
--      Kalori = MET × user_weight_kg × (duration_min / 60)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workout_set (
    set_id              INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id          INTEGER NOT NULL REFERENCES workout_session(session_id) ON DELETE CASCADE,
    exercise_id         INTEGER NOT NULL REFERENCES exercise_type(exercise_id),
    set_number          INTEGER NOT NULL CHECK (set_number > 0),
    -- Kuvvet egzersizleri
    reps                INTEGER CHECK (reps > 0),
    weight_kg           REAL    CHECK (weight_kg >= 0),
    -- Kardiyo / süreli egzersizler
    duration_min        REAL    CHECK (duration_min > 0),
    distance_km         REAL    CHECK (distance_km > 0),
    -- Hesaplanan kalori (bu set için)
    calories_burned     REAL    NOT NULL DEFAULT 0,
    notes               TEXT,
    is_warmup           INTEGER NOT NULL DEFAULT 0 CHECK (is_warmup IN (0,1)),
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- -----------------------------------------------------------------------------
-- 2.12 DAILY_TRACKER
--      Günlük su, adım ve uyku takibi. Günde bir kayıt (UNIQUE constraint).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daily_tracker (
    tracker_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    track_date          TEXT    NOT NULL,           -- YYYY-MM-DD
    -- Su
    water_ml            INTEGER NOT NULL DEFAULT 0 CHECK (water_ml >= 0),
    water_glasses       INTEGER GENERATED ALWAYS AS (water_ml / 250) VIRTUAL,
    -- Adım
    steps               INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
    steps_distance_km   REAL    GENERATED ALWAYS AS (ROUND(steps * 0.000762, 2)) VIRTUAL,
    -- Uyku (bir önceki gece)
    sleep_start         TEXT,                       -- HH:MM
    sleep_end           TEXT,                       -- HH:MM
    sleep_duration_min  INTEGER CHECK (sleep_duration_min >= 0),
    sleep_quality       INTEGER CHECK (sleep_quality BETWEEN 1 AND 5),  -- 1=kötü 5=mükemmel
    -- Genel
    mood                INTEGER CHECK (mood BETWEEN 1 AND 5),
    notes               TEXT,
    created_at          TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (user_id, track_date)
);

-- -----------------------------------------------------------------------------
-- 2.13 BODY_MEASUREMENT
--      Vücut ölçümleri ve tartı geçmişi. Her yeni tartı girildiğinde
--      bmr_log'a yeni hesaplama tetiklenir.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS body_measurement (
    measurement_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id             INTEGER NOT NULL REFERENCES user(user_id) ON DELETE CASCADE,
    measured_date       TEXT    NOT NULL,           -- YYYY-MM-DD
    -- Ağırlık & boy
    weight_kg           REAL    CHECK (weight_kg > 0),
    height_cm           REAL    CHECK (height_cm > 0),
    -- Vücut kompozisyonu
    body_fat_pct        REAL    CHECK (body_fat_pct BETWEEN 3 AND 60),
    muscle_mass_kg      REAL    CHECK (muscle_mass_kg > 0),
    bone_mass_kg        REAL    CHECK (bone_mass_kg > 0),
    water_pct           REAL    CHECK (water_pct BETWEEN 0 AND 80),
    -- BMI (hesaplanmış, weight_kg / (height_m)^2)
    bmi                 REAL    GENERATED ALWAYS AS (
                                    CASE WHEN height_cm > 0 AND weight_kg > 0
                                    THEN ROUND(weight_kg / ((height_cm/100.0)*(height_cm/100.0)), 1)
                                    ELSE NULL END
                                ) VIRTUAL,
    -- Çevre ölçüleri (cm)
    waist_cm            REAL    CHECK (waist_cm > 0),
    hip_cm              REAL    CHECK (hip_cm > 0),
    chest_cm            REAL    CHECK (chest_cm > 0),
    neck_cm             REAL    CHECK (neck_cm > 0),
    left_arm_cm         REAL    CHECK (left_arm_cm > 0),
    right_arm_cm        REAL    CHECK (right_arm_cm > 0),
    left_thigh_cm       REAL    CHECK (left_thigh_cm > 0),
    right_thigh_cm      REAL    CHECK (right_thigh_cm > 0),
    left_calf_cm        REAL    CHECK (left_calf_cm > 0),
    right_calf_cm       REAL    CHECK (right_calf_cm > 0),
    -- Bel/kalça oranı (kardiyovasküler risk göstergesi)
    waist_hip_ratio     REAL    GENERATED ALWAYS AS (
                                    CASE WHEN hip_cm > 0 AND waist_cm > 0
                                    THEN ROUND(waist_cm / hip_cm, 3)
                                    ELSE NULL END
                                ) VIRTUAL,
    -- Bu ölçümle tetiklenen BMR hesabı
    triggered_bmr_id    INTEGER REFERENCES bmr_log(bmr_id),
    measurement_method  TEXT    DEFAULT 'manual'
                                CHECK (measurement_method IN ('manual','smart_scale','dexa','caliper')),
    notes               TEXT,
    created_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- =============================================================================
-- §3 ── INDEXES
-- =============================================================================

-- user
CREATE INDEX IF NOT EXISTS idx_user_email         ON user(email);

-- bmr_log (en sık: user bazlı son hesap)
CREATE INDEX IF NOT EXISTS idx_bmr_user           ON bmr_log(user_id);
CREATE INDEX IF NOT EXISTS idx_bmr_calculated_at  ON bmr_log(calculated_at);

-- user_goal
CREATE INDEX IF NOT EXISTS idx_goal_user_active   ON user_goal(user_id, is_active);

-- food_item (barkod araması çok sık)
CREATE INDEX IF NOT EXISTS idx_food_barcode       ON food_item(barcode);
CREATE INDEX IF NOT EXISTS idx_food_name          ON food_item(name);
CREATE INDEX IF NOT EXISTS idx_food_category      ON food_item(category);

-- barcode_scan
CREATE INDEX IF NOT EXISTS idx_bscan_user         ON barcode_scan(user_id);
CREATE INDEX IF NOT EXISTS idx_bscan_barcode      ON barcode_scan(barcode);

-- ai_image_scan
CREATE INDEX IF NOT EXISTS idx_aiscan_user        ON ai_image_scan(user_id);

-- meal_log (tarih bazlı sorgular çok sık)
CREATE INDEX IF NOT EXISTS idx_meal_user_date     ON meal_log(user_id, meal_date);
CREATE INDEX IF NOT EXISTS idx_meal_type          ON meal_log(meal_type);

-- meal_log_item
CREATE INDEX IF NOT EXISTS idx_mitem_meal         ON meal_log_item(meal_id);
CREATE INDEX IF NOT EXISTS idx_mitem_food         ON meal_log_item(food_id);

-- workout_session
CREATE INDEX IF NOT EXISTS idx_wsess_user_date    ON workout_session(user_id, session_date);

-- workout_set
CREATE INDEX IF NOT EXISTS idx_wset_session       ON workout_set(session_id);
CREATE INDEX IF NOT EXISTS idx_wset_exercise      ON workout_set(exercise_id);

-- daily_tracker (tarih sorguları)
CREATE INDEX IF NOT EXISTS idx_tracker_user_date  ON daily_tracker(user_id, track_date);

-- body_measurement
CREATE INDEX IF NOT EXISTS idx_bmeas_user_date    ON body_measurement(user_id, measured_date);

-- =============================================================================
-- §4 ── VIEWS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1  v_latest_bmr
--      Her kullanıcının en güncel BMR / TDEE değeri.
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_latest_bmr AS
SELECT
    bl.*,
    u.username,
    u.first_name || ' ' || u.last_name AS full_name,
    u.bmr_formula,
    u.activity_level
FROM bmr_log bl
JOIN user u ON u.user_id = bl.user_id
WHERE bl.bmr_id = (
    SELECT MAX(b2.bmr_id)
    FROM   bmr_log b2
    WHERE  b2.user_id = bl.user_id
);

-- -----------------------------------------------------------------------------
-- 4.2  v_daily_nutrition_summary
--      Bir kullanıcının her günü için toplam kalori ve makro özeti.
--      Günlük hedefle karşılaştırılabilir.
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_daily_nutrition_summary AS
SELECT
    ml.user_id,
    ml.meal_date,
    COUNT(DISTINCT ml.meal_id)              AS meal_count,
    ROUND(SUM(ml.total_calories), 1)        AS total_calories,
    ROUND(SUM(ml.total_protein_g), 1)       AS total_protein_g,
    ROUND(SUM(ml.total_carbs_g), 1)         AS total_carbs_g,
    ROUND(SUM(ml.total_fat_g), 1)           AS total_fat_g,
    ROUND(SUM(ml.total_fiber_g), 1)         AS total_fiber_g,
    ROUND(SUM(ml.total_sodium_mg), 0)       AS total_sodium_mg
FROM meal_log ml
GROUP BY ml.user_id, ml.meal_date;

-- -----------------------------------------------------------------------------
-- 4.3  v_daily_calorie_balance
--      Kalori dengesi: alınan − yakılan − BMR bazalı harcama.
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_daily_calorie_balance AS
WITH nutrition AS (
    SELECT user_id, meal_date,
           ROUND(SUM(total_calories), 1) AS calories_in
    FROM   meal_log
    GROUP  BY user_id, meal_date
),
exercise AS (
    SELECT user_id, session_date AS ex_date,
           ROUND(SUM(total_calories_burned), 1) AS calories_burned
    FROM   workout_session
    GROUP  BY user_id, session_date
),
tracker AS (
    SELECT user_id, track_date,
           steps, water_ml, sleep_duration_min, sleep_quality
    FROM   daily_tracker
),
latest_bmr AS (
    SELECT user_id, bmr_kcal, tdee_kcal
    FROM   v_latest_bmr
)
SELECT
    COALESCE(n.user_id, e.user_id, t.user_id)   AS user_id,
    COALESCE(n.meal_date, e.ex_date, t.track_date) AS log_date,
    COALESCE(n.calories_in, 0)                  AS calories_consumed,
    COALESCE(e.calories_burned, 0)              AS calories_burned_exercise,
    COALESCE(lb.bmr_kcal, 0)                    AS bmr_kcal,
    COALESCE(lb.tdee_kcal, 0)                   AS tdee_kcal,
    ROUND(
        COALESCE(n.calories_in, 0)
        - COALESCE(lb.tdee_kcal, 0)
        - COALESCE(e.calories_burned, 0),
    1)                                          AS net_calorie_balance,
    COALESCE(t.steps, 0)                        AS steps,
    COALESCE(t.water_ml, 0)                     AS water_ml,
    t.sleep_duration_min,
    t.sleep_quality
FROM       nutrition n
FULL OUTER JOIN exercise e  ON e.user_id  = n.user_id  AND e.ex_date    = n.meal_date
FULL OUTER JOIN tracker  t  ON t.user_id  = COALESCE(n.user_id, e.user_id)
                            AND t.track_date = COALESCE(n.meal_date, e.ex_date)
LEFT JOIN  latest_bmr    lb ON lb.user_id = COALESCE(n.user_id, e.user_id, t.user_id);

-- -----------------------------------------------------------------------------
-- 4.4  v_weekly_progress
--      Haftalık ortalama kalori, protein, adım, uyku ve kilo değişimi.
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_weekly_progress AS
SELECT
    ml.user_id,
    strftime('%Y-W%W', ml.meal_date)           AS iso_week,
    MIN(ml.meal_date)                           AS week_start,
    MAX(ml.meal_date)                           AS week_end,
    COUNT(DISTINCT ml.meal_date)                AS active_days,
    ROUND(AVG(day_totals.daily_cal), 0)         AS avg_daily_calories,
    ROUND(AVG(day_totals.daily_prot), 1)        AS avg_daily_protein_g,
    ROUND(AVG(day_totals.daily_carb), 1)        AS avg_daily_carbs_g,
    ROUND(AVG(day_totals.daily_fat), 1)         AS avg_daily_fat_g,
    COUNT(DISTINCT ws.session_id)               AS workout_sessions,
    ROUND(SUM(ws.total_calories_burned), 0)     AS total_burned_kcal
FROM meal_log ml
JOIN (
    SELECT user_id, meal_date,
           SUM(total_calories) AS daily_cal,
           SUM(total_protein_g) AS daily_prot,
           SUM(total_carbs_g) AS daily_carb,
           SUM(total_fat_g) AS daily_fat
    FROM   meal_log
    GROUP  BY user_id, meal_date
) day_totals ON day_totals.user_id = ml.user_id AND day_totals.meal_date = ml.meal_date
LEFT JOIN workout_session ws ON ws.user_id = ml.user_id
                             AND strftime('%Y-W%W', ws.session_date) = strftime('%Y-W%W', ml.meal_date)
GROUP BY ml.user_id, iso_week;

-- -----------------------------------------------------------------------------
-- 4.5  v_goal_progress
--      Aktif hedefe göre bugünkü ilerleme durumu (% olarak).
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_goal_progress AS
SELECT
    g.user_id,
    g.goal_type,
    g.daily_calorie_target,
    g.daily_protein_g   AS protein_target,
    g.daily_carb_g      AS carb_target,
    g.daily_fat_g       AS fat_target,
    g.daily_water_ml    AS water_target,
    g.daily_steps_target AS steps_target,
    -- Bugünkü gerçekleşen
    COALESCE(dns.total_calories, 0)     AS calories_today,
    COALESCE(dns.total_protein_g, 0)    AS protein_today,
    COALESCE(dns.total_carbs_g, 0)      AS carbs_today,
    COALESCE(dns.total_fat_g, 0)        AS fat_today,
    COALESCE(dt.water_ml, 0)            AS water_today,
    COALESCE(dt.steps, 0)               AS steps_today,
    -- Yüzde tamamlanma
    ROUND(COALESCE(dns.total_calories,0) * 100.0 / g.daily_calorie_target, 1) AS calorie_pct,
    ROUND(COALESCE(dt.water_ml,0) * 100.0 / g.daily_water_ml, 1)             AS water_pct,
    ROUND(COALESCE(dt.steps,0) * 100.0 / g.daily_steps_target, 1)            AS steps_pct,
    -- Kalan
    ROUND(g.daily_calorie_target - COALESCE(dns.total_calories, 0), 0)  AS calories_remaining,
    g.daily_water_ml - COALESCE(dt.water_ml, 0)                         AS water_remaining_ml
FROM user_goal g
LEFT JOIN v_daily_nutrition_summary dns
       ON dns.user_id   = g.user_id
      AND dns.meal_date = date('now')
LEFT JOIN daily_tracker dt
       ON dt.user_id    = g.user_id
      AND dt.track_date = date('now')
WHERE g.is_active = 1;

-- -----------------------------------------------------------------------------
-- 4.6  v_body_progress
--      Vücut ölçümü geçmişi: kilo değişimi ve trend.
-- -----------------------------------------------------------------------------
CREATE VIEW IF NOT EXISTS v_body_progress AS
SELECT
    bm.user_id,
    bm.measured_date,
    bm.weight_kg,
    bm.body_fat_pct,
    bm.bmi,
    bm.waist_cm,
    bm.waist_hip_ratio,
    -- Bir önceki ölçüme göre değişim
    bm.weight_kg - LAG(bm.weight_kg)
        OVER (PARTITION BY bm.user_id ORDER BY bm.measured_date) AS weight_change_kg,
    -- İlk ölçümden toplam değişim
    bm.weight_kg - FIRST_VALUE(bm.weight_kg)
        OVER (PARTITION BY bm.user_id ORDER BY bm.measured_date) AS total_weight_change_kg,
    bl.bmr_kcal,
    bl.tdee_kcal
FROM body_measurement bm
LEFT JOIN bmr_log bl ON bl.bmr_id = bm.triggered_bmr_id;

-- =============================================================================
--  END OF SCHEMA
-- =============================================================================
