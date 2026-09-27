# Heathify Cloud Deployment Guide (Render)

This guide walks you through deploying the Heathify FastAPI backend and PostgreSQL database to **Render**, giving you a live HTTPS URL so you can run the mobile app **anywhere** without keeping your computer on.

---

## Step 1: Push Project to GitHub

1. If you haven't initialized Git in your project folder, run:
   ```bash
   cd /home/rohitdoshi/Downloads/heathify-backend
   git init
   git add .
   git commit -m "feat: prepare cloud deployment with render blueprint"
   ```

2. Create a new repository on [GitHub](https://github.com/new) (can be Public or Private).

3. Push your code to GitHub:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/heathify.git
   git branch -M main
   git push -u origin main
   ```

---

## Step 2: Deploy to Render via Blueprint

1. Go to [Render.com](https://render.com) and log in (or sign up with GitHub).
2. On your Render Dashboard, click **New +** and select **Blueprint**.
3. Connect your GitHub repository (`heathify`).
4. Render will read the `render.yaml` file automatically and propose creating:
   * **Database**: `heathify-db` (Free PostgreSQL instance)
   * **Web Service**: `heathify-api` (Docker web service running FastAPI)
5. Fill in the required environment variables prompted by Render:
   * `GEMINI_API_KEY`: Your Gemini API key from AI Studio
   * `USDA_API_KEY`: Your USDA FoodData Central key
   * `GOOGLE_CLIENT_ID`: Your Google OAuth web client ID
6. Click **Apply**.
7. Render will automatically:
   * Provision the PostgreSQL database
   * Build the Docker image
   * Run database migrations (`alembic upgrade head`)
   * Seed the base nutrition data and import USDA foods
   * Start your FastAPI server on a public HTTPS URL (e.g. `https://heathify-api.onrender.com`)

---

## Step 3: Connect Your Flutter Mobile App

Once your service is deployed and live on Render:

1. Copy your live Render URL (e.g. `https://heathify-api.onrender.com`).
2. Open `frontend/lib/core/config/api_constants.dart` and update the default URL:
   ```dart
   static String get baseUrl {
     const customUrl = String.fromEnvironment('API_URL');
     if (customUrl.isNotEmpty) {
       return customUrl;
     }
     return 'https://heathify-api.onrender.com'; // <--- Your Render URL here
   }
   ```
3. Rebuild and install the APK on your phone one last time:
   ```bash
   cd frontend
   flutter build apk --debug
   adb install -r build/app/outputs/flutter-apk/app-debug.apk
   ```

4. **Disconnect your phone!**
   You can now open Heathify anywhere in the world on 4G, 5G, or any Wi-Fi network without your computer running.

