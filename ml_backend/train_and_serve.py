"""
PediaGrow - Machine Learning Pipeline: Deteksi Risiko Stunting
Algoritma: Random Forest Classifier dengan Hyperparameter Tuning GridSearchCV

Pipeline ini mencakup:
1. Pemuatan / pembuatan dataset anthropometri anak Indonesia berdasarkan standar WHO
2. Preprocessing data & feature encoding (Gender, ASI Eksklusif, Usia, dsb)
3. Pemisahan Data Training (80%) dan Testing (20%) secara stratifikasi
4. Hyperparameter Tuning menggunakan GridSearchCV (n_estimators, max_depth, min_samples_split, criterion)
5. Evaluasi performa model (Accuracy, Precision, Recall, F1-Score, dan Confusion Matrix)
6. Ekspor model terbaik ke format Joblib
7. REST API Server (FastAPI / Flask) untuk melayani inference ke aplikasi Flutter PediaGrow
"""

import os
import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
from sklearn.preprocessing import StandardScaler
import joblib

# ==============================================================================
# 1. GENERASI DATASET ANTHROPOMETRI BERBASIS WHO & RISET STUNTING INDONESIA
# ==============================================================================

def generate_or_load_dataset(filepath: str = "stunting_dataset.csv") -> pd.DataFrame:
    if os.path.exists(filepath):
        print(f"Memuat dataset dari {filepath}...")
        return pd.read_csv(filepath)
    
    print("Dataset lokal belum ditemukan. Menghasilkan dataset antropometri terkalibrasi...")
    np.random.seed(42)
    n_samples = 2500

    # Fitur Dasar
    genders = np.random.choice([0, 1], size=n_samples) # 0: Laki-laki, 1: Perempuan
    age_months = np.random.randint(0, 60, size=n_samples)
    birth_weight = np.round(np.random.normal(3.1, 0.45, size=n_samples), 2)
    birth_height = np.round(np.random.normal(49.5, 2.0, size=n_samples), 1)
    asi_eksklusif = np.random.choice([0, 1], size=n_samples, p=[0.35, 0.65]) # 0: Tidak, 1: Ya

    # WHO Standard Height & Weight Calculation
    base_height = np.where(genders == 1, 49.1, 49.9) + (age_months * 1.05)
    base_weight = np.where(genders == 1, 3.2, 3.3) + (age_months * 0.28)

    # Introduksi Variasi Gizi & Faktor Risiko
    height_noise = np.random.normal(0, 3.5, size=n_samples)
    weight_noise = np.random.normal(0, 1.2, size=n_samples)
    
    current_height = np.round(base_height + height_noise, 1)
    current_weight = np.round(base_weight + weight_noise, 1)

    # Perhitungan Z-score HAZ & WAZ
    sd_height = 2.4 + (age_months * 0.038)
    haz = (current_height - base_height) / sd_height

    # Label Stunting:
    # 0: Normal (HAZ >= -2.0)
    # 1: Stunted / Berisiko ( -3.0 <= HAZ < -2.0 )
    # 2: Severely Stunted ( HAZ < -3.0 )
    labels = np.zeros(n_samples, dtype=int)
    labels[haz < -2.0] = 1
    labels[haz < -3.0] = 2

    df = pd.DataFrame({
        'gender': genders,
        'age_months': age_months,
        'birth_weight_kg': birth_weight,
        'birth_height_cm': birth_height,
        'current_weight_kg': current_weight,
        'current_height_cm': current_height,
        'asi_eksklusif': asi_eksklusif,
        'stunting_status': labels # Target
    })

    df.to_csv(filepath, index=False)
    print(f"Dataset berhasil disimpan ke {filepath} (Total: {n_samples} baris).")
    return df

# ==============================================================================
# 2. TRAINING & TUNING RANDOM FOREST MENGGUNAKAN GRIDSEARCHCV
# ==============================================================================

def train_and_tune_model(df: pd.DataFrame):
    print("\n" + "="*60)
    print("MEMULAI TRAINING DENGAN RANDOM FOREST & GRIDSEARCHCV")
    print("="*60)

    X = df[['gender', 'age_months', 'birth_weight_kg', 'birth_height_cm', 
            'current_weight_kg', 'current_height_cm', 'asi_eksklusif']]
    y = df['stunting_status']

    # Train-Test Split (80% Training, 20% Testing dengan Stratifikasi)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )

    print(f"Jumlah Data Training : {len(X_train)} sampel")
    print(f"Jumlah Data Testing  : {len(X_test)} sampel")

    # Definisi Parameter Grid untuk GridSearchCV
    param_grid = {
        'n_estimators': [50, 100, 150],
        'max_depth': [6, 8, 12, None],
        'min_samples_split': [2, 4, 6],
        'criterion': ['gini', 'entropy']
    }

    rf_base = RandomForestClassifier(random_state=42)
    grid_search = GridSearchCV(
        estimator=rf_base,
        param_grid=param_grid,
        cv=5,
        scoring='f1_macro',
        n_jobs=-1,
        verbose=1
    )

    print("\nMenjalankan 5-Fold Cross Validation GridSearchCV...")
    grid_search.fit(X_train, y_train)

    best_model = grid_search.best_estimator_
    print(f"\nParameter Terbaik Hasil GridSearchCV:")
    print(json.dumps(grid_search.best_params_, indent=2))

    # Evaluasi pada Data Testing
    y_pred = best_model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average='macro')

    print("\n" + "-"*40)
    print(f"HASIL EVALUASI MODEL (DATA TESTING):")
    print(f"Accuracy  : {acc * 100:.2f}%")
    print(f"F1-Score  : {f1 * 100:.2f}%")
    print("\nConfusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    print("\nClassification Report:")
    target_names = ['Normal', 'Berisiko Stunting', 'Severely Stunted']
    print(classification_report(y_test, y_pred, target_names=target_names))

    # Simpan model
    os.makedirs("models", exist_ok=True)
    model_path = os.path.join("models", "stunting_random_forest_best.joblib")
    joblib.dump(best_model, model_path)
    print(f"Model berhasil disimpan ke: {model_path}")
    return best_model

# ==============================================================================
# 3. FASTAPI / FLASK REST API SERVER UNTUK INFERENCE
# ==============================================================================

def run_rest_api_server():
    """
    Menjalankan REST API server lokal untuk melayani permintaan dari aplikasi Flutter PediaGrow.
    Endpoint: POST /predict_stunting
    """
    try:
        from fastapi import FastAPI, HTTPException
        import uvicorn
        from pydantic import BaseModel

        app = FastAPI(title="PediaGrow Stunting AI Service", version="1.0.0")

        model_path = os.path.join("models", "stunting_random_forest_best.joblib")
        if not os.path.exists(model_path):
            df = generate_or_load_dataset()
            train_and_tune_model(df)
        
        model = joblib.load(model_path)

        class ChildPredictionInput(BaseModel):
            nama_anak: str
            gender: int # 0: Laki-laki, 1: Perempuan
            gender_label: str
            age_months: int
            birth_weight_kg: float
            birth_height_cm: float
            current_weight_kg: float
            current_height_cm: float
            asi_eksklusif: int # 0: Tidak, 1: Ya
            tanggal_periksa: str

        @app.post("/predict_stunting")
        def predict(data: ChildPredictionInput):
            features = np.array([[
                data.gender,
                data.age_months,
                data.birth_weight_kg,
                data.birth_height_cm,
                data.current_weight_kg,
                data.current_height_cm,
                data.asi_eksklusif
            ]])

            pred_class = int(model.predict(features)[0])
            pred_proba = model.predict_proba(features)[0]
            confidence = float(np.max(pred_proba))

            # Hitung Z-score WHO sederhana untuk respon medis
            base_height = (49.1 if data.gender == 1 else 49.9) + (data.age_months * 1.05)
            sd_h = 2.4 + (data.age_months * 0.038)
            haz = float(np.round((data.current_height_cm - base_height) / sd_h, 2))

            base_weight = (3.2 if data.gender == 1 else 3.3) + (data.age_months * 0.28)
            sd_w = 0.8 + (data.age_months * 0.045)
            waz = float(np.round((data.current_weight_kg - base_weight) / sd_w, 2))

            status_map = {
                0: ("normal", "Normal (Pertumbuhan Optimal)", [
                    "Pertahankan asupan gizi seimbang kaya protein hewani dan sayur buah.",
                    "Lakukan stimulasi motorik dan pemantauan bulanan di Posyandu.",
                    "Pastikan imunisasi lengkap dan kebersihan lingkungan si Kecil."
                ]),
                1: ("berisiko_stunting", "Berisiko Stunting (Pendek)", [
                    "Tingkatkan konsumsi protein hewani harian (telur, ikan, daging, ayam).",
                    "Konsultasikan perkembangan dengan Dokter Spesialis Anak melalui PediaGrow.",
                    "Pantau kenaikan berat dan tinggi badan secara ketat setiap bulan."
                ]),
                2: ("severely_stunted", "Sangat Pendek (Severely Stunted)", [
                    "Segera kunjungi Fasyankes / Dokter Spesialis Anak untuk tata laksana klinis.",
                    "Evaluasi kemungkinan infeksi berulang dan sanitasi air minum rumah tangga.",
                    "Dapatkan pendampingan intervensi gizi intensif dari tenaga kesehatan."
                ])
            }

            code, label, recs = status_map.get(pred_class, status_map[0])

            return {
                "status_code": code,
                "status_label": label,
                "z_score_haz": haz,
                "z_score_waz": waz,
                "confidence_probability": round(confidence, 3),
                "description": f"Diagnosis berdasarkan Random Forest model (GridSearchCV tuned). Status: {label}",
                "recommendations": recs,
                "model_name": "Random Forest (Best GridSearchCV Model)"
            }

        print("\nMenjalankan FastAPI server pada http://0.0.0.0:5000 ...")
        uvicorn.run(app, host="0.0.0.0", port=5000)

    except ImportError:
        print("FastAPI atau Uvicorn belum terpasang. Menjalankan mode training mandiri.")

if __name__ == "__main__":
    dataset = generate_or_load_dataset()
    best_rf = train_and_tune_model(dataset)
    print("\nTraining selesai! Untuk menjalankan REST API backend, panggil: run_rest_api_server()")
