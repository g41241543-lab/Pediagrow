"""
PediaGrow - Machine Learning Pipeline: Deteksi Risiko Stunting
Algoritma: Random Forest Classifier dengan Hyperparameter Tuning GridSearchCV

Pipeline ini mencakup:
1. Pemuatan dataset anthropometri anak dari Stunting.csv (data riil, bukan sintetis)
2. Preprocessing data & feature encoding (Gender, Breastfeeding) dengan LabelEncoder
3. Pemisahan Data Training (70%) dan Testing (30%) secara stratifikasi
4. Hyperparameter Tuning menggunakan GridSearchCV (n_estimators, max_depth,
   min_samples_split, min_samples_leaf, max_features, class_weight)
5. Evaluasi performa model (Accuracy, Precision, Recall, F1-Score, Confusion Matrix)
6. Ekspor model terbaik ke format Joblib
7. REST API Server (FastAPI) untuk melayani inference ke aplikasi Flutter PediaGrow

Catatan: pipeline ini adalah versi produksi dari CekStunting.ipynb -- param grid,
urutan fitur, dan encoding label DIPERTAHANKAN SAMA PERSIS dengan notebook supaya
hasil training konsisten dan bisa direproduksi.
"""

import os
import json
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score, f1_score
import joblib

# ==============================================================================
# 1. PEMUATAN DATASET ANTHROPOMETRI ASLI (Stunting.csv)
# ==============================================================================

# Urutan fitur & encoding di bawah ini HARUS SAMA dengan yang dipakai saat training
# di CekStunting.ipynb, karena endpoint /predict_stunting menerima input dengan
# urutan dan encoding yang sama.
FEATURE_ORDER = [
    "Gender", "Age", "Birth Weight", "Birth Length",
    "Body Weight", "Body Length", "Breastfeeding",
]

# le_gender.classes_ hasil training: ['female', 'male'] -> female=0, male=1
GENDER_MAP = {"female": 0, "male": 1}
# le_breastfeeding.classes_ hasil training: ['No', 'Yes'] -> No=0, Yes=1
BREASTFEEDING_MAP = {"No": 0, "Yes": 1}
# le_stunting.classes_ hasil training: ['No', 'Yes'] -> No=0, Yes=1
STUNTING_LABELS = {0: "No", 1: "Yes"}


def load_dataset(filepath: str = "Stunting.csv") -> pd.DataFrame:
    """Memuat Stunting.csv apa adanya (data riil, tidak ada generate sintetis)."""
    if not os.path.exists(filepath):
        raise FileNotFoundError(
            f"'{filepath}' tidak ditemukan. Taruh Stunting.csv sejajar dengan "
            "train_serve.py ini (folder ml_backend/)."
        )
    print(f"Memuat dataset dari {filepath}...")
    df = pd.read_csv(filepath, sep=";", decimal=",")
    print(f"Jumlah data: {len(df)} baris")
    return df


def preprocess(df: pd.DataFrame):
    """Encode Gender, Breastfeeding, Stunting persis seperti di notebook."""
    df = df.copy()

    le_gender = LabelEncoder()
    le_breastfeeding = LabelEncoder()
    le_stunting = LabelEncoder()

    df["Gender"] = le_gender.fit_transform(df["Gender"])
    df["Breastfeeding"] = le_breastfeeding.fit_transform(df["Breastfeeding"])
    df["Stunting"] = le_stunting.fit_transform(df["Stunting"])

    print("Gender classes:", list(le_gender.classes_))
    print("Breastfeeding classes:", list(le_breastfeeding.classes_))
    print("Stunting classes:", list(le_stunting.classes_))

    X = df[FEATURE_ORDER]
    y = df["Stunting"]
    return X, y


# ==============================================================================
# 2. TRAINING & TUNING RANDOM FOREST MENGGUNAKAN GRIDSEARCHCV
# ==============================================================================

def train_and_tune_model(X: pd.DataFrame, y: pd.Series):
    print("\n" + "=" * 60)
    print("MEMULAI TRAINING DENGAN RANDOM FOREST & GRIDSEARCHCV")
    print("=" * 60)

    # Train-Test Split (70% Training, 30% Testing dengan Stratifikasi)
    # -- sama seperti di CekStunting.ipynb
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.30, random_state=42, stratify=y
    )

    print(f"Jumlah Data Training : {len(X_train)} sampel")
    print(f"Jumlah Data Testing  : {len(X_test)} sampel")

    # Param grid sama persis dengan CekStunting.ipynb
    param_grid = {
        "n_estimators": [50, 100, 150, 200],
        "max_depth": [None, 5, 10, 15],
        "min_samples_split": [2, 5, 10],
        "min_samples_leaf": [1, 2, 4],
        "max_features": ["sqrt", "log2"],
        "class_weight": ["balanced", "balanced_subsample", None],
    }

    rf_base = RandomForestClassifier(random_state=42)
    grid_search = GridSearchCV(
        estimator=rf_base,
        param_grid=param_grid,
        cv=5,
        scoring="f1",
        n_jobs=-1,
        verbose=1,
    )

    print("\nMenjalankan 5-Fold Cross Validation GridSearchCV...")
    grid_search.fit(X_train, y_train)

    best_model = grid_search.best_estimator_
    print("\nParameter Terbaik Hasil GridSearchCV:")
    print(json.dumps(grid_search.best_params_, indent=2))

    # Evaluasi pada Data Testing
    y_pred = best_model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    print("\n" + "-" * 40)
    print("HASIL EVALUASI MODEL (DATA TESTING):")
    print(f"Accuracy : {acc * 100:.2f}%")
    print(f"F1-Score : {f1 * 100:.2f}%")
    print("\nConfusion Matrix:")
    print(confusion_matrix(y_test, y_pred))
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=["No", "Yes"]))

    importances = pd.Series(best_model.feature_importances_, index=X.columns)
    print("\nFeature Importance:")
    print(importances.sort_values(ascending=False))

    # Simpan model
    os.makedirs("models", exist_ok=True)
    model_path = os.path.join("models", "stunting_random_forest_best.joblib")
    joblib.dump(best_model, model_path)
    print(f"\nModel berhasil disimpan ke: {model_path}")
    return best_model


def get_or_train_model():
    model_path = os.path.join("models", "stunting_random_forest_best.joblib")
    if os.path.exists(model_path):
        print(f"Memuat model yang sudah ada dari {model_path}...")
        return joblib.load(model_path)

    df = load_dataset()
    X, y = preprocess(df)
    return train_and_tune_model(X, y)


# ==============================================================================
# 3. FASTAPI REST API SERVER UNTUK INFERENCE
# ==============================================================================

def run_rest_api_server():
    """
    Menjalankan REST API server lokal untuk melayani permintaan dari aplikasi
    Flutter PediaGrow (fitur cek_stunting: form_cek_stunting_page.dart memanggil
    endpoint ini saat user submit, hasilnya ditampilkan di hasil_cek_stunting_page.dart).

    Endpoint: POST /predict_stunting
    """
    try:
        # pyrefly: ignore [missing-import]
        from fastapi import FastAPI, HTTPException
        # pyrefly: ignore [missing-import]
        import uvicorn
        # pyrefly: ignore [missing-import]
        from pydantic import BaseModel

        app = FastAPI(title="PediaGrow Stunting AI Service", version="1.0.0")

        model = get_or_train_model()

        class ChildPredictionInput(BaseModel):
            nama_anak: str
            gender_label: str          # "male" atau "female"
            age: int                   # usia dalam bulan
            birth_weight: float        # kg
            birth_length: float        # cm
            body_weight: float         # kg (berat badan saat ini)
            body_length: float         # cm (panjang/tinggi badan saat ini)
            breastfeeding_label: str   # "Yes" atau "No" (ASI eksklusif)
            tanggal_periksa: str

        @app.post("/predict_stunting")
        def predict(data: ChildPredictionInput):
            if data.gender_label not in GENDER_MAP:
                raise HTTPException(400, "gender_label harus 'male' atau 'female'")
            if data.breastfeeding_label not in BREASTFEEDING_MAP:
                raise HTTPException(400, "breastfeeding_label harus 'Yes' atau 'No'")

            # Urutan fitur HARUS sama dengan FEATURE_ORDER
            features = np.array([[
                GENDER_MAP[data.gender_label],
                data.age,
                data.birth_weight,
                data.birth_length,
                data.body_weight,
                data.body_length,
                BREASTFEEDING_MAP[data.breastfeeding_label],
            ]])

            pred_class = int(model.predict(features)[0])
            pred_proba = model.predict_proba(features)[0]
            confidence = float(np.max(pred_proba))
            status_label = STUNTING_LABELS[pred_class]

            recommendations_map = {
                "No": [
                    "Pertahankan asupan gizi seimbang kaya protein hewani dan sayur buah.",
                    "Lakukan stimulasi motorik dan pemantauan rutin setiap bulan.",
                    "Pastikan imunisasi lengkap dan kebersihan lingkungan si Kecil.",
                ],
                "Yes": [
                    "Tingkatkan konsumsi protein hewani harian (telur, ikan, daging, ayam).",
                    "Konsultasikan perkembangan dengan Dokter Spesialis Anak melalui PediaGrow.",
                    "Kunjungi Fasyankes terdekat untuk evaluasi dan tata laksana lebih lanjut.",
                ],
            }

            return {
                "status_code": "stunting" if status_label == "Yes" else "normal",
                "status_label": "Berisiko Stunting" if status_label == "Yes" else "Normal (Pertumbuhan Sesuai)",
                "confidence_probability": round(confidence, 3),
                "description": f"Diagnosis berdasarkan Random Forest model (GridSearchCV tuned, F1 CV ~0.97).",
                "recommendations": recommendations_map[status_label],
                "model_name": "Random Forest (Best GridSearchCV Model)",
            }

        print("\nMenjalankan FastAPI server pada http://0.0.0.0:5000 ...")
        uvicorn.run(app, host="0.0.0.0", port=5000)

    except ImportError:
        print("FastAPI atau Uvicorn belum terpasang (pip install fastapi uvicorn).")
        print("Menjalankan mode training mandiri saja.")


if __name__ == "__main__":
    df = load_dataset()
    X, y = preprocess(df)
    best_rf = train_and_tune_model(X, y)
    print("\nTraining selesai! Untuk menjalankan REST API backend, panggil: run_rest_api_server()")