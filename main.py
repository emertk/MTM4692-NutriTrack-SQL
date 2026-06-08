from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from datetime import date
import sqlite3
import random


app = FastAPI(title="NutriTrack API")

# Veritabanı bağlantı fonksiyonu
def get_db_connection():
    conn = sqlite3.connect('nutritrack.db')
    conn.row_factory = sqlite3.Row # Verileri JSON formatında kolayca döndürmek için
    return conn

# 1. Ana sayfaya girildiğinde HTML dosyamızı göster
@app.get("/")
async def serve_frontend():
    return FileResponse("static/nutritrack_app.html")

# 2. Test amaçlı API Uç Noktası: Veritabanındaki kullanıcıları getir
@app.get("/api/users")
async def get_users():
    conn = get_db_connection()
    users = conn.execute("SELECT user_id, username, email FROM user").fetchall()
    conn.close()
    return {"users": [dict(user) for user in users]}

# 3. Ana sayfa (Dashboard) için kullanıcının temel verilerini ve hedeflerini getir
# 3. Ana sayfa (Dashboard) için kullanıcının temel verilerini ve hedeflerini getir
@app.get("/api/dashboard/{user_id}")
async def get_dashboard(user_id: int):
    conn = get_db_connection()
    today_str = date.today().isoformat() # Bugünün tarihi: YYYY-MM-DD
    
    query = """
        SELECT 
            u.first_name, 
            u.last_name,
            b.bmr_kcal, 
            b.tdee_kcal, 
            g.daily_calorie_target,
            g.daily_protein_g,
            g.daily_carb_g,
            g.daily_fat_g,
            COALESCE(t.water_ml, 0) as water_ml,
            COALESCE(t.steps, 0) as steps,
            COALESCE(t.sleep_duration_min, 0) as sleep_duration_min
        FROM user u
        LEFT JOIN v_latest_bmr b ON u.user_id = b.user_id
        LEFT JOIN user_goal g ON u.user_id = g.user_id AND g.is_active = 1
        LEFT JOIN daily_tracker t ON u.user_id = t.user_id AND t.track_date = ?
        WHERE u.user_id = ?
    """
    user_data = conn.execute(query, (today_str, user_id)).fetchone()
    conn.close()
    
    if user_data is None:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")
        
    return dict(user_data)
class UserRegister(BaseModel):
    fname: str
    lname: str
    dob: str
    gender: str
    height: float
    weight: float
    goal: str
    activity: str
    formula: str
    age: int
    bmr: float
    tdee: float
    target: float
    prot: float
    carb: float
    fat: float

# 4. Yeni Kullanıcı Kaydı (POST)
@app.post("/api/register")
async def register_user(data: UserRegister):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # 1. user tablosuna ekle (Benzersiz sahte email/username üretiyoruz)
        username = f"{data.fname.lower()}_{data.lname.lower()}_{random.randint(1000,9999)}"
        email = f"{username}@mail.com"
        
        cursor.execute("""
            INSERT INTO user (username, email, password_hash, first_name, last_name, date_of_birth, gender, height_cm, initial_weight_kg, activity_level, bmr_formula)
            VALUES (?, ?, 'hashed_pw', ?, ?, ?, ?, ?, ?, ?, ?)
        """, (username, email, data.fname, data.lname, data.dob, data.gender, data.height, data.weight, data.activity, data.formula))
        
        user_id = cursor.lastrowid
        
        # 2. bmr_log tablosuna ekle
        cursor.execute("""
            INSERT INTO bmr_log (user_id, weight_kg, height_cm, age_years, gender, activity_level, formula_used, bmr_kcal, tdee_kcal, activity_multiplier, trigger_event)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1.55, 'registration')
        """, (user_id, data.weight, data.height, data.age, data.gender, data.activity, data.formula, data.bmr, data.tdee))
        
        bmr_id = cursor.lastrowid
        
        # 3. user_goal tablosuna ekle
        cursor.execute("""
            INSERT INTO user_goal (user_id, goal_type, target_weight_kg, daily_calorie_target, daily_protein_g, daily_carb_g, daily_fat_g, based_on_bmr_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (user_id, data.goal, data.weight, data.target, data.prot, data.carb, data.fat, bmr_id))
        
        conn.commit()
        return {"success": True, "user_id": user_id}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# Günlük takip veri modeli
class TrackerUpdate(BaseModel):
    track_date: str
    action_type: str  # 'water', 'steps' veya 'sleep'
    value: int = 0
    sleep_start: str = None
    sleep_end: str = None
    sleep_quality: int = None

# 5. Günlük Takip Kaydı (Su, Adım, Uyku)
@app.post("/api/tracker/{user_id}")
async def update_tracker(user_id: int, data: TrackerUpdate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # Bugünün kaydı var mı kontrol et
        existing = cursor.execute("SELECT * FROM daily_tracker WHERE user_id = ? AND track_date = ?", (user_id, data.track_date)).fetchone()
        
        # Yoksa boş bir kayıt oluştur
        if not existing:
            cursor.execute("INSERT INTO daily_tracker (user_id, track_date) VALUES (?, ?)", (user_id, data.track_date))
            
        # Gelen verinin tipine göre ilgili sütunu güncelle
        if data.action_type == 'water':
            cursor.execute("UPDATE daily_tracker SET water_ml = water_ml + ? WHERE user_id = ? AND track_date = ?", (data.value, user_id, data.track_date))
        elif data.action_type == 'steps':
            cursor.execute("UPDATE daily_tracker SET steps = ? WHERE user_id = ? AND track_date = ?", (data.value, user_id, data.track_date))
        elif data.action_type == 'sleep':
            cursor.execute("UPDATE daily_tracker SET sleep_start = ?, sleep_end = ?, sleep_duration_min = ?, sleep_quality = ? WHERE user_id = ? AND track_date = ?", 
                           (data.sleep_start, data.sleep_end, data.value, data.sleep_quality, user_id, data.track_date))
            
        conn.commit()
        return {"success": True}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# --- ÖĞÜN VE BESİN EKLEME API'Sİ ---
class FoodEntry(BaseModel):
    food_id: str 
    name: str
    qty: float
    cal: float
    prot: float
    carb: float
    fat: float

class MealRequest(BaseModel):
    meal_date: str
    meal_type: str
    food: FoodEntry

@app.post("/api/meals/{user_id}")
async def add_food_to_meal(user_id: int, data: MealRequest):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 1. Bu kullanıcının bugünkü bu öğünü (örn: Breakfast) veritabanında var mı?
        meal = cursor.execute("SELECT meal_id FROM meal_log WHERE user_id = ? AND meal_date = ? AND meal_type = ?", 
                              (user_id, data.meal_date, data.meal_type)).fetchone()
        
        if meal:
            meal_id = meal['meal_id']
        else:
            # Yoksa yeni öğün başlığı oluştur
            cursor.execute("INSERT INTO meal_log (user_id, meal_type, meal_date) VALUES (?, ?, ?)", 
                           (user_id, data.meal_type, data.meal_date))
            meal_id = cursor.lastrowid

        # 2. Besini bu öğüne ekle (HTML'den 'f001' gibi gelen ID'nin sadece sayısal kısmını alıyoruz)
        clean_food_id = int(''.join(filter(str.isdigit, str(data.food.food_id)))) if str(data.food.food_id) else 1
        
        cursor.execute("""
            INSERT INTO meal_log_item (meal_id, food_id, quantity_g, calories, protein_g, carbs_g, fat_g)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (meal_id, clean_food_id, data.food.qty, data.food.cal, data.food.prot, data.food.carb, data.food.fat))
        
        # 3. Öğün başlığındaki toplam makroları güncelle
        cursor.execute("""
            UPDATE meal_log 
            SET total_calories = total_calories + ?,
                total_protein_g = total_protein_g + ?,
                total_carbs_g = total_carbs_g + ?,
                total_fat_g = total_fat_g + ?
            WHERE meal_id = ?
        """, (data.food.cal, data.food.prot, data.food.carb, data.food.fat, meal_id))
        
        conn.commit()
        return {"success": True}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

# --- GÜNLÜK ÖĞÜNLERİ GETİRME API'Sİ (GET) ---
@app.get("/api/meals/{user_id}/{meal_date}")
async def get_meals(user_id: int, meal_date: str):
    conn = get_db_connection()
    try:
        # 1. O günkü öğün başlıklarını al (Örn: Breakfast, Lunch)
        meals = conn.execute("SELECT * FROM meal_log WHERE user_id = ? AND meal_date = ?", (user_id, meal_date)).fetchall()
        
        result = []
        for m in meals:
            meal_dict = dict(m)
            
            # 2. O öğünün içindeki detaylı besinleri (Yumurta, Yulaf vb.) al
            items = conn.execute("""
                SELECT mli.*, f.name, f.barcode 
                FROM meal_log_item mli 
                JOIN food_item f ON mli.food_id = f.food_id 
                WHERE mli.meal_id = ?
            """, (meal_dict['meal_id'],)).fetchall()
            
            foods = []
            for item in items:
                foods.append({
                    "foodId": str(item['food_id']),
                    "name": item['name'],
                    "qty": item['quantity_g'],
                    "cal": item['calories'],
                    "prot": item['protein_g'],
                    "carb": item['carbs_g'],
                    "fat": item['fat_g']
                })
            
            result.append({
                "id": str(meal_dict['meal_id']),
                "date": meal_dict['meal_date'],
                "type": meal_dict['meal_type'],
                "foods": foods
            })
            
        return {"meals": result}
    finally:
        conn.close()