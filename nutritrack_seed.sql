-- =============================================================================
--  NutriTrack — Seed Data
--  File: seed.sql  |  Run AFTER schema.sql
-- =============================================================================
PRAGMA foreign_keys = ON;

-- =============================================================================
-- USERS (5 kullanıcı — farklı hedef ve profiller)
-- =============================================================================
INSERT INTO user (username, email, password_hash, first_name, last_name,
    date_of_birth, gender, height_cm, initial_weight_kg,
    activity_level, bmr_formula, timezone) VALUES
('ahmet_fit',   'ahmet@mail.com',  'hash_1', 'Ahmet',  'Yılmaz', '1990-05-14', 'Male',   178, 88.0, 'Moderately Active', 'Mifflin-St Jeor', 'Europe/Istanbul'),
('elif_wellness','elif@mail.com',  'hash_2', 'Elif',   'Kara',   '1995-08-22', 'Female', 163, 62.0, 'Lightly Active',    'Mifflin-St Jeor', 'Europe/Istanbul'),
('can_bulk',    'can@mail.com',    'hash_3', 'Can',    'Demir',  '1998-01-30', 'Male',   182, 75.0, 'Very Active',       'Mifflin-St Jeor', 'Europe/Istanbul'),
('selin_run',   'selin@mail.com',  'hash_4', 'Selin',  'Arslan', '1988-11-03', 'Female', 167, 58.0, 'Very Active',       'Harris-Benedict', 'Europe/Istanbul'),
('mert_recomp', 'mert@mail.com',   'hash_5', 'Mert',   'Çelik',  '1993-03-17', 'Male',   175, 82.0, 'Moderately Active', 'Mifflin-St Jeor', 'Europe/Istanbul');

-- =============================================================================
-- BMR_LOG
-- Mifflin-St Jeor:
--   Erkek : 10×kg + 6.25×cm − 5×yaş + 5
--   Kadın : 10×kg + 6.25×cm − 5×yaş − 161
-- TDEE  = BMR × multiplier (Moderately Active=1.55, Very Active=1.725, Lightly=1.375)
-- =============================================================================

-- Ahmet (Erkek, 34y, 88kg, 178cm, Moderately Active)
-- BMR = 10×88 + 6.25×178 − 5×34 + 5 = 880+1112.5−170+5 = 1827.5
-- TDEE = 1827.5 × 1.55 = 2832.6
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event) VALUES
(1, 88.0, 178, 34, 'Male', 'Moderately Active', 'Mifflin-St Jeor',
    1827.5, 2832.6, 1.55, 2332.6, 3132.6, 2832.6, 176.0, 284.0, 88.0, 'registration');

-- Elif (Kadın, 28y, 62kg, 163cm, Lightly Active)
-- BMR = 10×62 + 6.25×163 − 5×28 − 161 = 620+1018.75−140−161 = 1337.75
-- TDEE = 1337.75 × 1.375 = 1839.4
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event) VALUES
(2, 62.0, 163, 28, 'Female', 'Lightly Active', 'Mifflin-St Jeor',
    1337.75, 1839.4, 1.375, 1339.4, 2139.4, 1839.4, 124.0, 184.0, 55.0, 'registration');

-- Can (Erkek, 26y, 75kg, 182cm, Very Active)
-- BMR = 10×75 + 6.25×182 − 5×26 + 5 = 750+1137.5−130+5 = 1762.5
-- TDEE = 1762.5 × 1.725 = 3040.3
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event) VALUES
(3, 75.0, 182, 26, 'Male', 'Very Active', 'Mifflin-St Jeor',
    1762.5, 3040.3, 1.725, 2540.3, 3340.3, 3040.3, 150.0, 340.0, 75.0, 'registration');

-- Selin (Kadın, 35y, 58kg, 167cm, Very Active) — Harris-Benedict
-- BMR = 9.247×58 + 3.098×167 − 4.330×35 + 447.593 = 536.3+517.4−151.6+447.6 = 1349.7
-- TDEE = 1349.7 × 1.725 = 2328.2
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event) VALUES
(4, 58.0, 167, 35, 'Female', 'Very Active', 'Harris-Benedict',
    1349.7, 2328.2, 1.725, 1828.2, 2628.2, 2328.2, 116.0, 233.0, 58.0, 'registration');

-- Mert (Erkek, 31y, 82kg, 175cm, Moderately Active)
-- BMR = 10×82 + 6.25×175 − 5×31 + 5 = 820+1093.75−155+5 = 1763.75
-- TDEE = 1763.75 × 1.55 = 2733.8
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event) VALUES
(5, 82.0, 175, 31, 'Male', 'Moderately Active', 'Mifflin-St Jeor',
    1763.75, 2733.8, 1.55, 2233.8, 3033.8, 2733.8, 164.0, 274.0, 82.0, 'registration');

-- Ahmet kilo verdi: 85kg → yeni BMR hesabı tetiklendi
INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level,
    formula_used, bmr_kcal, tdee_kcal, activity_multiplier,
    suggested_cut_kcal, suggested_bulk_kcal, suggested_maintain_kcal,
    suggested_protein_g, suggested_carb_g, suggested_fat_g,
    trigger_event, calculated_at) VALUES
(1, 85.0, 178, 34, 'Male', 'Moderately Active', 'Mifflin-St Jeor',
    1797.5, 2786.1, 1.55, 2286.1, 3086.1, 2786.1, 170.0, 279.0, 85.0,
    'weight_update', '2026-03-15 08:00:00');

-- =============================================================================
-- USER_GOALS
-- =============================================================================
INSERT INTO user_goal (user_id, goal_type, target_weight_kg, daily_calorie_target,
    daily_protein_g, daily_carb_g, daily_fat_g,
    daily_water_ml, daily_steps_target, daily_sleep_min_target,
    weekly_workout_days, weekly_weight_change_kg, based_on_bmr_id, notes) VALUES
(1, 'Lose Weight',         80.0, 2330, 176, 235, 78,  2500, 10000, 480, 4, -0.5, 1, 'Kilo vermek, karın bölgesini sıkılaştırmak'),
(2, 'Maintain',            62.0, 1840, 124, 184, 55,  2000,  8000, 480, 3,  0.0, 2, 'Kiloyu korumak, fit kalmak'),
(3, 'Gain Muscle',         82.0, 3340, 150, 390, 90,  3000,  6000, 510, 5,  0.3, 3, 'Bulk dönemi, kas kütlesi artırmak'),
(4, 'Lose Weight',         54.0, 1830, 116, 183, 50,  2500, 12000, 480, 5, -0.4, 4, 'Maraton hazırlığı'),
(5, 'Body Recomposition',  80.0, 2734, 164, 274, 82,  2500,  9000, 480, 4,  0.0, 5, 'Yağ yakıp kas kazanmak');

-- =============================================================================
-- FOOD_ITEMS (30 besin — OpenFoodFacts standardı, per 100g)
-- =============================================================================
INSERT INTO food_item (barcode, name, brand, category, calories_per_100g,
    protein_per_100g, carbs_per_100g, sugar_per_100g, fiber_per_100g,
    fat_per_100g, saturated_fat_per_100g, sodium_mg_per_100g,
    serving_size_g, serving_unit, is_verified, source) VALUES
-- Protein kaynakları
('8690504050056', 'Chicken Breast (Grilled)',    NULL,          'Poultry',   165, 31.0,  0.0,  0.0, 0.0,  3.6, 1.0,  74,  150, 'g',     1, 'manual'),
('0070038640257', 'Canned Tuna in Water',        'Chicken of the Sea','Seafood', 116, 25.5, 0.0, 0.0, 0.0, 1.0, 0.3, 290, 130, 'g',     1, 'openfoodfacts'),
('8691904010036', 'Whole Eggs',                  NULL,          'Dairy & Eggs',155,12.6,  1.1,  1.1, 0.0, 10.6, 3.3, 124,   50, 'piece', 1, 'manual'),
('8690632030036', 'Greek Yogurt (0% fat)',       'Chobani',     'Dairy & Eggs',59, 10.2,  3.6,  3.6, 0.0,  0.4, 0.1,  36,  200, 'g',     1, 'openfoodfacts'),
('0737628064502', 'Whey Protein Isolate',        'Optimum Nutrition','Supplements',370,80.0,7.0,3.5,0.0,2.0,1.0,130, 30,'g',  1, 'barcode_api'),
('8690546712689', 'Cottage Cheese (low fat)',    'Pınar',       'Dairy & Eggs',84,  11.1,  3.4,  2.5, 0.0,  2.2, 1.4, 390,  100, 'g',     1, 'barcode_api'),
-- Karbonhidrat kaynakları
('8690504010687', 'Oats (Rolled)',               NULL,          'Grains',    389,  16.9, 66.3,  0.9,10.6,  6.9, 1.3,   2,   80, 'g',     1, 'manual'),
('8690632010045', 'Brown Rice (cooked)',         NULL,          'Grains',    123,   2.7, 25.6,  0.3, 1.8,  0.9, 0.2,   5,  150, 'g',     1, 'manual'),
('8690547010019', 'Whole Wheat Bread',           'Uno',         'Bakery',    247,   9.0, 41.0,  4.2, 7.0,  3.8, 0.8, 420,   35, 'slice', 1, 'barcode_api'),
('8690632010083', 'Sweet Potato (boiled)',       NULL,          'Vegetables', 86,   1.6, 20.1,  4.2, 2.8,  0.1, 0.0,  27,  200, 'g',     1, 'manual'),
('8690632018010', 'Banana',                      NULL,          'Fruits',     89,   1.1, 22.8, 12.2, 2.6,  0.3, 0.1,   1,  120, 'piece', 1, 'manual'),
('8690547020018', 'Quinoa (cooked)',             NULL,          'Grains',    120,   4.4, 21.3,  0.9, 2.8,  1.9, 0.2,   7,  185, 'g',     1, 'manual'),
-- Yağ kaynakları
('0033674100134', 'Almond Butter',               'Justin''s',   'Nuts & Seeds',614,21.4,18.8, 5.5, 10.2, 55.5, 4.4,  0,   32, 'tbsp',  1, 'openfoodfacts'),
('8690504060026', 'Avocado',                     NULL,          'Fruits',    160,   2.0,  8.5,  0.7, 6.7, 14.7, 2.1,   7,  150, 'g',     1, 'manual'),
('8690632060011', 'Olive Oil (Extra Virgin)',    'Komili',      'Oils',      884,   0.0,  0.0,  0.0, 0.0,100.0,14.0,   0,   14, 'tbsp',  1, 'barcode_api'),
('0070038340020', 'Walnuts',                     NULL,          'Nuts & Seeds',654,15.2,13.7,  2.6, 6.7, 65.2, 6.1,   2,   30, 'g',     1, 'manual'),
-- Sebze
('8690504030006', 'Broccoli (raw)',              NULL,          'Vegetables', 34,   2.8,  6.6,  1.7, 2.6,  0.4, 0.0,  33,  100, 'g',     1, 'manual'),
('8690504030007', 'Spinach (raw)',               NULL,          'Vegetables', 23,   2.9,  3.6,  0.4, 2.2,  0.4, 0.1,  79,  100, 'g',     1, 'manual'),
('8690632080019', 'Cherry Tomatoes',             NULL,          'Vegetables', 18,   0.9,  3.9,  2.6, 1.2,  0.2, 0.0,   5,  100, 'g',     1, 'manual'),
('8690632080020', 'Cucumber',                    NULL,          'Vegetables', 15,   0.7,  3.6,  1.7, 0.5,  0.1, 0.0,   2,  100, 'g',     1, 'manual'),
-- Hazır / işlenmiş ürünler
('8690504050091', 'Greek Yogurt Parfait',        'Danone',      'Dairy & Eggs',120, 5.0, 18.0, 14.0, 0.5,  3.0, 1.5,  60, 150, 'g',     1, 'barcode_api'),
('8690632030099', 'Protein Bar (Chocolate)',     'Quest',       'Supplements',384, 26.9, 43.6, 26.9, 17.0, 11.6, 3.1,420, 60, 'piece', 1, 'barcode_api'),
('8690632010099', 'Milk (Semi-skimmed)',         'Sütaş',       'Dairy & Eggs',46,  3.4,  5.0,  5.0, 0.0,  1.5, 0.9,  44, 250, 'ml',    1, 'barcode_api'),
('8690632020011', 'Orange Juice (fresh)',        NULL,          'Beverages',  45,   0.7, 10.4,  8.4, 0.2,  0.2, 0.0,   1, 200, 'ml',    1, 'manual'),
-- Türk mutfağı
(NULL,            'Simit',                        NULL,          'Bakery',    284,   9.2, 56.4,  3.0, 2.8,  2.2, 0.5, 450, 180, 'piece', 1, 'manual'),
(NULL,            'Ayran (Homemade)',             NULL,          'Beverages',  44,   3.0,  2.9,  2.9, 0.0,  2.0, 1.3, 240, 200, 'ml',    1, 'manual'),
(NULL,            'Mercimek Corbasi (Lentil Soup)',NULL,         'Legumes',    87,   5.5, 12.0,  1.2, 4.1,  1.5, 0.3, 380, 300, 'ml',    1, 'manual'),
(NULL,            'Yumurtali Menemen',            NULL,          'Eggs',      145,   8.5,  6.2,  3.1, 1.2,  9.0, 2.5, 290, 250, 'g',     1, 'manual'),
(NULL,            'Tavuk Sote',                   NULL,          'Poultry',   180,  24.0,  4.5,  1.5, 1.2,  7.0, 1.5, 320, 200, 'g',     1, 'manual'),
(NULL,            'Baklava (pistachio)',          NULL,          'Sweets',    478,   6.0, 56.0, 30.0, 1.5, 25.0, 8.0, 120,  60, 'piece', 1, 'manual');

-- =============================================================================
-- BARCODE SCANS
-- =============================================================================
INSERT INTO barcode_scan (user_id, barcode, food_id, scan_result, scanned_at) VALUES
(1, '8690504050056', 1,  'found',       '2026-03-01 07:55:00'),
(1, '8690504010687', 7,  'found',       '2026-03-01 07:56:00'),
(1, '0070038640257', 2,  'found',       '2026-03-01 12:50:00'),
(3, '0737628064502', 5,  'found',       '2026-03-01 18:00:00'),
(3, '8690632010083', 10, 'found',       '2026-03-02 12:45:00'),
(2, '8690504030006', 17, 'found',       '2026-03-02 13:10:00'),
(4, '9999999999999', NULL,'not_found',  '2026-03-03 08:00:00'),
(1, '8690632030036', 4,  'found',       '2026-03-05 07:50:00'),
(5, '8690632030099', 22, 'found',       '2026-03-07 10:30:00');

-- =============================================================================
-- AI IMAGE SCANS
-- =============================================================================
INSERT INTO ai_image_scan (user_id, image_path, detected_food_name, detected_food_id,
    estimated_weight_g, estimated_calories, confidence_score, ai_model_used,
    user_corrected, scanned_at) VALUES
(1, '/photos/ahmet_lunch_0301.jpg', 'Grilled Chicken Breast', 1, 150, 247.5, 0.91, 'claude-vision', 0, '2026-03-01 12:58:00'),
(2, '/photos/elif_dinner_0302.jpg', 'Greek Yogurt Parfait',  21, 200, 240.0, 0.83, 'claude-vision', 1, '2026-03-02 19:10:00'),
(3, '/photos/can_preworkout.jpg',   'Banana',                11, 130, 115.7, 0.95, 'claude-vision', 0, '2026-03-03 17:45:00'),
(4, '/photos/selin_snack.jpg',      'Walnuts',               16,  30, 196.2, 0.78, 'claude-vision', 0, '2026-03-04 15:20:00'),
(5, '/photos/mert_breakfast.jpg',   'Yumurtali Menemen',     28, 300, 435.0, 0.88, 'claude-vision', 0, '2026-03-05 08:05:00'),
(1, '/photos/ahmet_baklava.jpg',    'Baklava (pistachio)',   30,  60, 286.8, 0.72, 'claude-vision', 0, '2026-03-08 21:00:00');

-- =============================================================================
-- MEAL LOGS (öğün başlıkları)
-- =============================================================================
INSERT INTO meal_log (user_id, meal_type, meal_date, meal_time,
    total_calories, total_protein_g, total_carbs_g, total_fat_g, total_fiber_g, total_sodium_mg) VALUES
-- Ahmet — 2026-03-01
(1, 'Breakfast',    '2026-03-01', '07:30', 467, 25.3, 71.3, 9.3,  11.4, 265),
(1, 'Lunch',        '2026-03-01', '12:30', 520, 53.9,  9.2, 9.4,   4.9, 701),
(1, 'Dinner',       '2026-03-01', '19:00', 610, 42.0, 52.0, 18.0,  6.5, 520),
(1, 'Snack',        '2026-03-01', '16:00', 196,  5.0, 13.5, 14.7,  6.7,   7),
-- Elif — 2026-03-02
(2, 'Breakfast',    '2026-03-02', '08:00', 311, 22.9, 22.8,  9.6,  2.6,  97),
(2, 'Lunch',        '2026-03-02', '13:00', 345, 14.7, 53.0,  7.5,  8.9, 215),
(2, 'Dinner',       '2026-03-02', '19:30', 420, 31.0, 38.0, 12.0,  4.5, 380),
-- Can — 2026-03-03
(3, 'Breakfast',    '2026-03-03', '07:00', 711, 38.6, 85.6, 20.4, 13.4, 194),
(3, 'Pre-Workout',  '2026-03-03', '17:30', 200,  1.1, 22.8,  0.3,  2.6,   1),
(3, 'Post-Workout', '2026-03-03', '19:30', 481, 86.1,  8.6,  3.4,  0.0, 196),
(3, 'Dinner',       '2026-03-03', '21:00', 820, 52.0, 80.0, 28.0,  8.2, 560),
-- Selin — 2026-03-04
(4, 'Breakfast',    '2026-03-04', '06:30', 275, 15.0, 35.0,  7.5,  3.5, 220),
(4, 'Snack',        '2026-03-04', '10:00', 196,  4.6, 13.7, 14.7,  6.7,   2),
(4, 'Lunch',        '2026-03-04', '13:30', 510, 42.0, 35.0, 16.0,  5.0, 480),
(4, 'Dinner',       '2026-03-04', '19:00', 440, 30.0, 40.0, 14.0,  6.0, 390),
-- Mert — 2026-03-05
(5, 'Breakfast',    '2026-03-05', '08:00', 435, 18.0, 20.0, 28.5,  4.2, 710),
(5, 'Lunch',        '2026-03-05', '13:00', 640, 50.0, 55.0, 20.0,  6.0, 540),
(5, 'Dinner',       '2026-03-05', '19:30', 720, 55.0, 60.0, 22.0,  7.5, 620),
(5, 'Snack',        '2026-03-05', '16:00', 230,  8.0, 25.0,  9.0,  2.0, 190);

-- =============================================================================
-- MEAL LOG ITEMS
-- =============================================================================
INSERT INTO meal_log_item (meal_id, food_id, quantity_g,
    calories, protein_g, carbs_g, fat_g, fiber_g, sodium_mg, sugar_g, entry_source, barcode_scan_id) VALUES
-- Ahmet Breakfast (meal_id=1): Oats 80g + Banana 120g + Greek Yogurt 150g
(1, 7,  80,  311, 13.5, 53.1, 5.5,  8.5,   2, 0.7, 'barcode_scan', 1),
(1, 11, 120,  107,  1.3, 27.4, 0.4,  3.1,   1, 14.7,'manual', NULL),
(1, 4,  150,   89, 15.3,  5.4, 0.6,  0.0,  54,  5.4,'manual', NULL),
-- Ahmet Lunch (meal_id=2): Chicken 150g + Brown Rice 150g + Broccoli 100g
(2, 1,  150,  248, 46.5,  0.0, 5.4,  0.0, 111, 0.0, 'ai_image_scan', NULL),
(2, 8,  150,  185,  4.1, 38.4, 1.4,  2.7,   8, 0.5, 'barcode_scan', 3),
(2, 17, 100,   34,  2.8,  6.6, 0.4,  2.6,  33, 1.7, 'manual', NULL),
-- Ahmet Dinner (meal_id=3): Tuna 130g + Sweet Potato 200g + Olive Oil 14g + Spinach 100g
(3, 2,  130,  151, 33.2,  0.0, 1.3,  0.0, 377, 0.0, 'manual', NULL),
(3, 10, 200,  172,  3.2, 40.2, 0.2,  5.6,  54, 8.4, 'manual', NULL),
(3, 15,  14,  124,  0.0,  0.0,14.0,  0.0,   0, 0.0, 'manual', NULL),
(3, 18, 100,   23,  2.9,  3.6, 0.4,  2.2,  79, 0.4, 'manual', NULL),
-- Elif Breakfast (meal_id=5): Eggs 2pcs + Whole Wheat Toast 35g + Orange Juice 200ml
(5, 3,  100,  155, 12.6,  1.1,10.6,  0.0, 124, 1.1, 'manual', NULL),
(5, 9,   35,   86,  3.2, 14.4, 1.3,  2.5, 147, 1.5, 'manual', NULL),
(5, 24, 200,   90,  1.4, 20.8, 0.4,  0.4,   2,16.8, 'manual', NULL),
-- Can Pre-Workout (meal_id=9): Banana
(9, 11, 130,  116,  1.4, 29.6, 0.4,  3.4,   1,15.9, 'ai_image_scan', NULL),
-- Can Post-Workout (meal_id=10): Whey Protein 30g + Milk 250ml
(10, 5,  30,  111, 24.0,  2.1, 0.6,  0.0,  39, 1.1, 'barcode_scan', 4),
(10, 23,250,  115,  8.5, 12.5, 3.8,  0.0, 110,12.5, 'manual', NULL),
-- Mert Breakfast (meal_id=16): Yumurtali Menemen 300g
(16, 28,300,  435, 25.5, 18.6,27.0,  3.6, 870, 9.3, 'ai_image_scan', NULL);

-- =============================================================================
-- EXERCISE TYPES (25 egzersiz — MET değerleri ile)
-- =============================================================================
INSERT INTO exercise_type (name, category, muscle_groups, met_value, is_strength, equipment_needed, description) VALUES
-- Kuvvet
('Barbell Back Squat',       'Strength', 'quads,hamstrings,glutes,core', 5.0, 1, 'barbell,squat rack', 'Temel alt vücut egzersizi'),
('Barbell Bench Press',      'Strength', 'chest,triceps,front delts',    5.0, 1, 'barbell,bench',      'Temel göğüs egzersizi'),
('Deadlift',                 'Strength', 'back,hamstrings,glutes,core',  6.0, 1, 'barbell',            'Temel bileşik kaldırış'),
('Pull-up',                  'Strength', 'lats,biceps,rear delts',       4.0, 1, 'pull-up bar',        'Üst sırt ve biceps'),
('Overhead Press',           'Strength', 'shoulders,triceps,upper chest',4.0, 1, 'barbell',            'Omuz ve triceps'),
('Dumbbell Row',             'Strength', 'lats,rhomboids,biceps',        3.5, 1, 'dumbbell',           'Sırt ve biceps'),
('Leg Press',                'Strength', 'quads,hamstrings,glutes',      3.5, 1, 'leg press machine',  'Alt vücut makinesi'),
('Dumbbell Lateral Raise',   'Strength', 'lateral delts',                2.5, 1, 'dumbbells',          'Omuz yan başı'),
('Tricep Pushdown',          'Strength', 'triceps',                      3.0, 1, 'cable machine',      'Tricep izolasyon'),
('Barbell Curl',             'Strength', 'biceps',                       3.0, 1, 'barbell',            'Bicep izolasyon'),
('Romanian Deadlift',        'Strength', 'hamstrings,glutes,lower back', 5.0, 1, 'barbell',            'Hamstring odaklı'),
('Plank',                    'Strength', 'core,shoulders',               3.0, 1, 'none',               'Core stabilizasyon'),
-- Kardiyo
('Running (8 km/h)',         'Cardio',   'legs,core',                    8.3, 0, 'none',               'Orta tempo koşu'),
('Running (10 km/h)',        'Cardio',   'legs,core',                   10.0, 0, 'none',               'Hızlı tempo koşu'),
('Running (12 km/h)',        'Cardio',   'legs,core',                   11.5, 0, 'none',               'Yarı maraton temposu'),
('Cycling (outdoor, 20km/h)','Cardio',   'legs,glutes',                  8.0, 0, 'bicycle',            'Orta hızda bisiklet'),
('Rowing Machine',           'Cardio',   'back,arms,legs,core',          7.0, 0, 'rowing machine',     'Tam vücut kardiyo'),
('Jump Rope',                'Cardio',   'legs,shoulders,core',         12.3, 0, 'jump rope',          'Yüksek yoğunluklu kardiyo'),
('Swimming (freestyle)',     'Water Sports','full body',                  8.3, 0, 'pool',               'Tam vücut'),
('Walking (brisk)',          'Cardio',   'legs',                         4.3, 0, 'none',               'Hızlı yürüyüş'),
-- HIIT & Diğer
('Burpees',                  'HIIT',     'full body',                   10.0, 0, 'none',               'Tam vücut HIIT'),
('Box Jumps',                'HIIT',     'quads,glutes,calves',          8.0, 0, 'plyo box',           'Patlayıcı kuvvet'),
('Battle Ropes',             'HIIT',     'shoulders,arms,core',          8.5, 0, 'battle ropes',       'Üst vücut HIIT'),
('Yoga (power)',             'Flexibility','full body',                   4.0, 0, 'yoga mat',           'Esneklik ve güç'),
('Stretching',               'Flexibility','full body',                   2.5, 0, 'none',              'Soğuma ve esneme');

-- =============================================================================
-- WORKOUT SESSIONS
-- =============================================================================
INSERT INTO workout_session (user_id, session_date, start_time, end_time, duration_min,
    total_calories_burned, user_weight_kg, location, notes, perceived_effort) VALUES
(1, '2026-03-01', '06:00', '07:00',  60,  380, 88.0, 'Gym',     'Push Day A', 8),
(1, '2026-03-03', '06:00', '07:15',  75,  410, 88.0, 'Gym',     'Pull Day A', 7),
(1, '2026-03-05', '06:00', '07:00',  60,  360, 88.0, 'Gym',     'Leg Day A',  9),
(1, '2026-03-08', '07:00', '07:30',  30,  210, 88.0, 'Outdoor', 'Koşu — düşük yoğunluk', 5),
(2, '2026-03-02', '18:00', '18:45',  45,  215, 62.0, 'Home',    'Full Body Yoga', 5),
(2, '2026-03-05', '18:00', '18:50',  50,  185, 62.0, 'Home',    'Stretching & Core', 4),
(3, '2026-03-01', '18:00', '19:30',  90,  620, 75.0, 'Gym',     'Chest + Triceps (Bulk)', 9),
(3, '2026-03-03', '18:00', '19:30',  90,  580, 75.0, 'Gym',     'Back + Biceps (Bulk)', 8),
(3, '2026-03-05', '17:00', '18:30',  90,  650, 75.0, 'Gym',     'Legs (Bulk)',          10),
(4, '2026-03-04', '06:00', '07:00',  60,  510, 58.0, 'Outdoor', '10km koşu — maraton hazırlık', 8),
(4, '2026-03-06', '06:00', '07:10',  70,  595, 58.0, 'Outdoor', '12km tempo koşu',     9),
(5, '2026-03-05', '07:00', '08:00',  60,  420, 82.0, 'Gym',     'Upper Body Recomp',   7),
(5, '2026-03-07', '07:00', '08:15',  75,  490, 82.0, 'Gym',     'Lower Body Recomp',   8);

-- =============================================================================
-- WORKOUT SETS
-- Kalori: MET × kg × (duration_min/60) → kuvvet egzersizleri için süre ≈ set başına 2dk
-- =============================================================================
INSERT INTO workout_set (session_id, exercise_id, set_number, reps, weight_kg, duration_min, calories_burned, notes) VALUES
-- Ahmet Push Day (session 1)
(1, 2, 1, 8,  80, 2, 24.0, 'Warm-up seti'),
(1, 2, 2, 6,  90, 2, 24.0, 'Çalışma seti'),
(1, 2, 3, 5,  95, 2, 24.0, 'Çalışma seti'),
(1, 5, 1, 8,  50, 2, 19.0, NULL),
(1, 5, 2, 6,  55, 2, 19.0, NULL),
(1, 8, 1,15,  10, 2, 14.7, NULL),
(1, 8, 2,15,  10, 2, 14.7, NULL),
(1, 9, 1,12, NULL,2, 17.6, 'Cable machine'),
(1, 9, 2,12, NULL,2, 17.6, NULL),
-- Ahmet Pull Day (session 2)
(2, 4, 1, 8, NULL,2, 19.0, 'Ağırlıksız'),
(2, 4, 2, 6, NULL,2, 19.0, NULL),
(2, 6, 1,10,  30, 2, 18.7, NULL),
(2, 6, 2,10,  32, 2, 18.7, NULL),
(2,10, 1,12,  30, 2, 17.6, NULL),
-- Ahmet Leg Day (session 3)
(3, 1, 1, 8,  80, 2, 23.0, NULL),
(3, 1, 2, 6, 100, 2, 23.0, 'PR denemesi'),
(3, 1, 3, 5, 100, 2, 23.0, NULL),
(3,11, 1, 8,  60, 2, 23.0, 'Romanian DL'),
(3,11, 2, 8,  70, 2, 23.0, NULL),
-- Ahmet Koşu (session 4) — kardiyo, set yerine süre
(4,13, 1,NULL,NULL,30,219.0,'8 km/h'),
-- Selin Koşu 10km (session 10)
(10,14,1,NULL,NULL,60,348.0,'10km, 10km/h ortalama'),
-- Selin Koşu 12km (session 11)
(11,15,1,NULL,NULL,70,469.0,'12km, 12km/h ortalama'),
-- Can Chest+Tri (session 7)
(7, 2, 1,10, 100, 2, 25.0, 'Bulk — ağır'),
(7, 2, 2, 8, 110, 2, 25.0, NULL),
(7, 2, 3, 6, 120, 2, 25.0, 'PR!'),
(7, 9, 1,15,NULL, 2, 15.0, NULL),
(7, 9, 2,15,NULL, 2, 15.0, NULL),
-- Can Back+Bi (session 8)
(8, 3, 1, 5, 140, 2, 29.3, 'Deadlift PR hazırlık'),
(8, 3, 2, 4, 150, 2, 29.3, 'Kişisel rekor!'),
(8, 4, 1, 8,NULL, 2, 19.0, NULL),
(8,10, 1,12,  35, 2, 14.6, NULL);

-- =============================================================================
-- DAILY TRACKER
-- =============================================================================
INSERT INTO daily_tracker (user_id, track_date, water_ml, steps,
    sleep_start, sleep_end, sleep_duration_min, sleep_quality, mood, notes) VALUES
-- Ahmet
(1, '2026-03-01', 2800, 11200, '23:00', '06:30', 450, 4, 4, 'Antrenman günü, iyi hissettim'),
(1, '2026-03-02', 2200,  8500, '23:30', '07:00', 450, 3, 3, 'Dinlenme günü'),
(1, '2026-03-03', 3000, 12500, '22:30', '06:00', 450, 5, 5, 'Harika antrenman'),
(1, '2026-03-04', 2500,  9200, '00:00', '07:30', 450, 3, 3, 'Geç yattım'),
(1, '2026-03-05', 2800, 13500, '22:00', '06:00', 480, 5, 5, 'Leg day — yorucu ama iyi'),
-- Elif
(2, '2026-03-01', 1800,  6200, '23:00', '07:00', 480, 4, 4, NULL),
(2, '2026-03-02', 2100,  7800, '22:30', '07:00', 510, 5, 5, 'Yoga günü, muhteşem'),
(2, '2026-03-03', 2000,  8900, '23:00', '07:30', 510, 4, 4, NULL),
-- Can
(3, '2026-03-01', 3500, 14200, '22:00', '07:00', 540, 5, 5, 'Bulk günü, çok yedim'),
(3, '2026-03-02', 3200, 11000, '22:30', '07:00', 510, 4, 4, 'Hafif dinlenme'),
(3, '2026-03-03', 4000, 15000, '21:30', '06:30', 540, 5, 5, 'Back day — harika'),
-- Selin
(4, '2026-03-04', 2800, 18500, '22:00', '06:00', 480, 5, 5, '10km koşu, PR!'),
(4, '2026-03-05', 2500, 12000, '22:30', '06:30', 480, 4, 4, 'Aktif dinlenme'),
(4, '2026-03-06', 3000, 20000, '21:30', '06:00', 510, 5, 5, '12km tempo — çok iyi'),
-- Mert
(5, '2026-03-05', 2600, 10500, '23:00', '07:00', 480, 4, 4, 'Upper body recomp günü'),
(5, '2026-03-06', 2400,  9800, '23:30', '07:30', 480, 3, 3, 'Dinlenme'),
(5, '2026-03-07', 2800, 11200, '22:30', '06:30', 480, 4, 4, 'Lower body iyi geçti');

-- =============================================================================
-- BODY MEASUREMENTS
-- =============================================================================
INSERT INTO body_measurement (user_id, measured_date, weight_kg, height_cm,
    body_fat_pct, muscle_mass_kg, water_pct,
    waist_cm, hip_cm, chest_cm, neck_cm,
    left_arm_cm, right_arm_cm, left_thigh_cm, right_thigh_cm,
    measurement_method, triggered_bmr_id, notes) VALUES
-- Ahmet (başlangıç)
(1, '2026-01-01', 88.0, 178, 22.5, 58.0, 56.0, 93.0, 102.0, 105.0, 38.5, 36.0, 36.5, 60.0, 60.5, 'smart_scale', 1, 'Başlangıç ölçümü'),
(1, '2026-02-01', 86.5, 178, 21.8, 58.2, 56.5, 91.5, 101.0, 104.5, 38.0, 36.2, 36.8, 59.5, 60.0, 'smart_scale', 1, 'İlk ay sonu'),
(1, '2026-03-01', 85.0, 178, 20.9, 58.5, 57.0, 90.0, 100.0, 104.0, 37.5, 36.5, 37.0, 59.0, 59.5, 'smart_scale', 6, '2. ay sonu — 3kg verildi'),
-- Elif
(2, '2026-01-15', 62.0, 163, 24.0, 40.0, 52.0, 72.0,  90.0,  88.0, 32.0, 27.0, 27.5, 54.0, 54.5, 'smart_scale', 2, 'Başlangıç'),
(2, '2026-03-15', 61.5, 163, 23.5, 40.2, 52.5, 71.0,  89.5,  87.5, 31.8, 27.2, 27.8, 53.5, 54.0, 'smart_scale', 2, '2 ay sonra kilo korundu'),
-- Can
(3, '2026-01-01', 75.0, 182, 12.0, 60.0, 62.0, 82.0,  96.0, 100.0, 37.0, 38.0, 38.5, 60.0, 60.5, 'caliper',     3, 'Bulk başlangıcı'),
(3, '2026-03-01', 77.5, 182, 12.8, 61.5, 61.5, 83.5,  97.0, 102.0, 37.5, 39.0, 39.5, 61.0, 61.5, 'caliper',     3, '2 ay bulk — +2.5kg'),
-- Selin
(4, '2026-01-01', 58.0, 167, 20.0, 42.0, 55.0, 68.0,  91.0,  86.0, 32.5, 26.5, 27.0, 55.0, 55.5, 'smart_scale', 4, 'Maraton hazırlığı başlangıç'),
(4, '2026-03-01', 57.0, 167, 19.2, 42.3, 55.5, 67.0,  90.0,  85.0, 32.0, 26.8, 27.2, 55.5, 56.0, 'smart_scale', 4, '2 ay — −1kg yağ kaybı'),
-- Mert
(5, '2026-01-01', 82.0, 175, 20.0, 56.0, 56.0, 88.0, 100.0, 102.0, 38.0, 36.0, 36.5, 59.0, 59.5, 'smart_scale', 5, 'Recomp başlangıcı'),
(5, '2026-03-01', 81.5, 175, 18.5, 57.5, 57.0, 86.0,  99.0, 102.5, 37.5, 36.5, 37.0, 59.5, 60.0, 'smart_scale', 5, '2 ay — yağ -1.5%, kas +1.5kg');

-- =============================================================================
--  END OF SEED DATA
-- =============================================================================
