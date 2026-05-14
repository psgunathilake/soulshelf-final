# SoulShelf 📚🎵🎬📝

> **Read · Watch · Listen · Journal**

SoulShelf is a cross-platform personal media tracker and digital journaling mobile application developed using Flutter. The application combines books, music, movies, TV shows, anime tracking, journaling, planning, recommendations, and personal reflections into one secure and organized platform.

The project was developed for the **PUSL3190 Computing Project** module of the **BSc (Hons) Software Engineering** degree program.

---

## ✨ Features

### 📖 Multi-Category Media Tracking

* Track Books
* Track Songs & Albums
* Track Movies & TV Shows
* Anime Support
* Ratings & Status Management
* Personal Reflections

### 📝 My Space

* Personal Journal
* Daily Planner
* Mood Tracking
* Weather & Water Intake Logging
* Birthday & Todo Tracking
* PIN Protected Privacy Area

### 🎨 User Experience

* Light / Dark Theme
* Smooth Animations
* Glassmorphism UI
* Responsive Flutter Design
* Custom Panda Branding

### 🤖 Smart Features

* Personalized Recommendation System
* AI Chatbot Prototype
* Search & Filtering
* Collections / Albums

### 🔐 Security

* Laravel Sanctum Authentication
* Email Verification
* Password Reset
* SHA-256 PIN Hashing
* Secure API Communication

---

## 🛠️ Technology Stack

### Frontend

* Flutter
* Dart
* Riverpod
* Hive Local Storage

### Backend

* Laravel 12
* Sanctum Authentication
* REST API
* MySQL 8

### Other Tools

* Dio HTTP Client
* Figma
* Git & GitHub
* Android Studio

---

## 📂 Project Architecture

```text
Presentation Layer
        ↓
Riverpod State Management
        ↓
Repository Layer
        ↓
API Services + Hive Cache
        ↓
Laravel REST API
        ↓
MySQL Database
```

---

## 📱 Main Modules

| Module               | Description                             |
| -------------------- | --------------------------------------- |
| Authentication       | Register, Login, Logout, Password Reset |
| Home Dashboard       | Main navigation & recommendations       |
| Books                | Add, edit, delete, rate books           |
| Songs                | Music tracking & recommendations        |
| Shows & Movies       | TV, Movie & Anime management            |
| My Space             | Journal + Planner + Privacy             |
| Collections          | Group media into collections            |
| Statistics Dashboard | User activity analytics                 |
| Chatbot              | AI assistant prototype                  |

---

## 🔄 Offline Support

SoulShelf supports:

* Local Hive caching
* Offline media access
* Offline journal writing
* Pending write synchronization
* Automatic sync when reconnected

---

## 🔐 Authentication Flow

* User Registration
* Email Verification
* Login with Sanctum Token
* Persistent Sessions
* Secure Logout
* Password Reset via Email

---

## 📸 File Upload Support

Users can upload:

* Media Cover Images
* Profile Pictures
* Header Images

Stored securely using Laravel storage.

---

## 📊 Statistics Dashboard

The dashboard provides:

* Total media count
* Average ratings
* Journal activity
* Mood trends
* Category distributions
* Reading / Watching progress

---

## 🚀 Future Improvements

* Advanced AI recommendations
* Gemini AI chatbot integration
* Push notifications
* Mood analytics visualization
* Biometric authentication
* Cloud backups
* External media APIs integration

---

## 🧪 Development Methodology

The project follows an **Agile iterative development approach** with phased implementation:

1. Foundation Refactor
2. Laravel Authentication Integration
3. API Integration & Offline Sync
4. Dashboard & Collections
5. Recommendation Engine
6. AI Chatbot Enhancements

---

## 📦 Installation

### Frontend (Flutter)

```bash
git clone https://github.com/your-username/soulshelf.git
cd soulshelf/project/soulshelf

flutter pub get
flutter run
```

### Backend (Laravel)

```bash
cd backend

composer install
php artisan key:generate
php artisan migrate
php artisan serve
```

---

## ⚙️ Environment Setup

Example `.env` configuration:

```env
APP_NAME=SoulShelf
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_DATABASE=soulshelf
DB_USERNAME=root
DB_PASSWORD=your_password
```

---

## 📌 Current Status

✅ Flutter Frontend Completed
✅ Laravel Authentication Completed
✅ REST API Integration Completed
✅ Offline Sync System Completed
✅ File Upload System Completed
✅ PIN Hashing Security Completed
🔄 Dashboard & Advanced Features In Progress

---

## 👨‍💻 Author

**P.S Gunathilake**
---

## 📄 License

This project was developed for academic purposes.

---

## 📚 Documentation

Project analysis and implementation phases are documented in the project files. 
https://liveplymouthac-my.sharepoint.com/:f:/g/personal/10952618_students_plymouth_ac_uk/IgAECH1WzIPbS4lmQ9jz5COZAdRGqBLyvkSVbTn1ev1HY2M?e=fv7mOs

 

 ⭐ Support

If you like this project, give it a ⭐ on GitHub!

 
