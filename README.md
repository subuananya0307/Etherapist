# eTherapist

> A Machine Learning and VR-Powered Solution for Social Anxiety Disorder

eTherapist is an AI-driven Android application that combines **Machine Learning diagnostics** and **Virtual Reality Exposure Therapy (VRET)** to provide accessible, personalized treatment for individuals with **Social Anxiety Disorder (SAD)**. Built with Flutter and a Python/Flask backend, it bridges the critical gap between objective diagnosis and adaptive therapy — all from a standard smartphone.

---

## The Problem

Social Anxiety Disorder affects millions globally, yet an **82% treatment gap** exists in India alone — driven by stigma, financial barriers, and limited access to mental health professionals. eTherapist offers a scalable, at-home alternative to traditional clinical care.

---

## Features

### ML-Powered Anxiety Assessment
- Digital questionnaire based on the **Hamilton Anxiety Rating Scale (HAM-A)**
- Classifies anxiety severity into **Mild**, **Moderate**, or **Severe**
- Powered by a **Random Forest classifier** achieving **97.5% accuracy**

### Virtual Reality Exposure Therapy (VRET)
- **Scenario 1 – Public Speaking:** Progressive levels from a small conference room (3–5 people) to a large auditorium (30–50 people)
- **Scenario 2 – Professional Interactions:** From informal office discussions to high-pressure panel interviews
- Dynamic audience behavior (attentive, distracted, neutral) to simulate real-world unpredictability
- 360° immersive experience using the device gyroscope — compatible with **Google Cardboard**

### Real-Time Speech Emotion Recognition (SER)
- Captures vocal responses during VR sessions via the smartphone microphone
- Detects emotional states: **Fear**, **Sadness**, **Anger**, **Neutral**
- Generates a Speech & Emotion Report sent directly to the doctor's dashboard

### Doctor-in-the-Loop Validation
- Healthcare professionals review ML-generated profiles before therapy begins
- Dual dashboards for **patients** and **doctors**
- Doctors can adjust therapy intensity, add clinical notes, and schedule appointments

### Personalized Therapy Recommendations
Based on predicted severity, the system recommends:
- VR Therapy sessions
- Mobile App Mind Exercises (meditation, yoga, breathing)
- In-Person Clinical Sessions

### Progress Monitoring
- Session history, anxiety trends, and therapy summaries
- Visual analytics dashboard accessible to both patient and doctor
- Continuous treatment adjustment based on progress

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Python, Flask |
| ML Model | Random Forest (Scikit-learn `.pkl`), Keras `.h5` |
| Assessment Scale | Hamilton Anxiety Rating Scale (HAM-A) |
| VR Rendering | Flutter-based lightweight 3D (no game engine needed) |
| VR Hardware | Google Cardboard-compatible |
| Database | Firebase |
| Platform | Android |

---

## ML Model Performance

| Model | Accuracy | Precision | Recall | F1 Score |
|---|---|---|---|---|
| K-Nearest Neighbors | 82.5% | 100% | 65% | 78.8% |
| **Random Forest** | **97.5%** | **100%** | **95%** | **97.4%** |

The Random Forest model was trained on data from **143 participants (aged 18–40)** using HAM-A questionnaire features. Severity labels were assigned using standard clinical scoring ranges:
- **0–17:** Mild
- **18–24:** Moderate
- **≥25:** Severe

---

## API Reference

### `POST /predict`

Predicts the user's anxiety severity from HAM-A questionnaire input.

**Request Body:**
```json
{
  "age": 24,
  "gender": 1,
  "hama_q1": 2,
  "hama_q2": 3,
  "...": "..."
}
```

**Response:**
```json
{
  "anxiety_level": "Mild" | "Moderate" | "Severe"
}
```

The Flask API runs on `http://localhost:6000` and serves real-time severity predictions and VR scenario configuration parameters to the Flutter app.

---

## Project Structure

```
Etherapist/
├── lib/              # Flutter app source code (UI, VR, dashboards)
├── android/          # Android platform configuration
├── test/             # Flutter unit tests
├── app.py            # Flask API server
├── mod.py            # ML model utilities
├── model.pkl         # Trained Random Forest model (Scikit-learn)
├── model.h5          # Trained Keras model
├── firebase.json     # Firebase configuration
└── pubspec.yaml      # Flutter dependencies
```

---

## System Workflow

```
User fills HAM-A Questionnaire
        ↓
ML Model predicts severity (Mild / Moderate / Severe)
        ↓
Doctor validates ML prediction
        ↓
Personalized therapy path is unlocked
  ├── VR Therapy (graded exposure scenarios)
  ├── Mobile Mind Exercises
  └── In-Person Sessions (if Severe)
        ↓
Progress tracked → Dashboard updated → Treatment adjusted
```

---

## Disclaimer

eTherapist is **not a substitute for professional mental health care**. The system includes a mandatory doctor validation step before therapy begins. If you or someone you know is in crisis, please contact a qualified mental health professional or a crisis helpline in your region.

---
