 # SoulShelf Backend API 🚀

> Laravel REST API backend for the SoulShelf mobile application.

The SoulShelf Backend is a secure RESTful API developed using Laravel 12 and MySQL 8. It powers authentication, media management, journaling, collections, planner synchronization, file uploads, offline sync support, and secure PIN-based privacy features for the SoulShelf Flutter mobile application.

---

# ✨ Features

## 🔐 Authentication System

* User Registration
* Login & Logout
* Email Verification
* Forgot Password
* Password Reset
* Sanctum Token Authentication
* Persistent Sessions

## 📚 Media Management

* Books
* Songs
* Movies
* TV Shows
* Anime
* Ratings & Status Tracking
* Personal Reflections
* Cover Image Uploads

## 📝 Journal & Planner

* Daily Journal Entries
* Mood Tracking
* Todo Lists
* Water Intake Tracking
* Planner Scheduling
* Personal Notes

## 📁 Collections

* Create Collections
* Add/Remove Media
* Collection Management

## 🔒 Security

* Laravel Sanctum Protection
* SHA-256 PIN Hashing
* User-based Authorization Policies
* Secure File Upload Validation
* Protected API Routes

## ☁️ Offline Sync Support

* API designed for offline-first Flutter architecture
* Sync queue compatible
* Cache-friendly responses

---

# 🛠️ Technology Stack

| Technology      | Purpose              |
| --------------- | -------------------- |
| Laravel 12      | Backend Framework    |
| PHP 8.2+        | Server Language      |
| MySQL 8         | Database             |
| Laravel Sanctum | API Authentication   |
| Eloquent ORM    | Database ORM         |
| REST API        | Communication Layer  |
| Laravel Storage | File Upload Handling |

---

# 📂 Backend Architecture

```text id="5i9bfz"
Flutter App
     ↓
REST API Requests
     ↓
Laravel Controllers
     ↓
Services & Policies
     ↓
Eloquent Models
     ↓
MySQL Database
```

---

# 📁 Project Structure

```text id="7i3e0m"
backend/
├── app/
│   ├── Http/
│   │   ├── Controllers/Api/
│   │   ├── Requests/
│   │   └── Middleware/
│   ├── Models/
│   ├── Policies/
│   └── Providers/
├── database/
│   ├── migrations/
│   └── seeders/
├── routes/
│   └── api.php
├── storage/
├── public/
└── .env
```

---

# 🔗 Main API Endpoints

## Authentication

| Method | Endpoint                    | Description         |
| ------ | --------------------------- | ------------------- |
| POST   | `/api/auth/register`        | Register user       |
| POST   | `/api/auth/login`           | Login user          |
| POST   | `/api/auth/logout`          | Logout user         |
| GET    | `/api/auth/me`              | Get current user    |
| POST   | `/api/auth/forgot-password` | Send reset link     |
| POST   | `/api/auth/reset-password`  | Reset password      |
| POST   | `/api/auth/email/resend`    | Resend verification |

---

## Media

| Method | Endpoint          |
| ------ | ----------------- |
| GET    | `/api/media`      |
| POST   | `/api/media`      |
| GET    | `/api/media/{id}` |
| PUT    | `/api/media/{id}` |
| DELETE | `/api/media/{id}` |

---

## Journal

| Method | Endpoint               |
| ------ | ---------------------- |
| GET    | `/api/journals`        |
| PUT    | `/api/journals/{date}` |

---

## Planner

| Method | Endpoint               |
| ------ | ---------------------- |
| GET    | `/api/planners`        |
| PUT    | `/api/planners/{date}` |

---

## Collections

| Method | Endpoint                |
| ------ | ----------------------- |
| GET    | `/api/collections`      |
| POST   | `/api/collections`      |
| PUT    | `/api/collections/{id}` |
| DELETE | `/api/collections/{id}` |

---

## File Uploads

| Method | Endpoint                |
| ------ | ----------------------- |
| POST   | `/api/media/{id}/cover` |
| POST   | `/api/user/avatar`      |
| POST   | `/api/user/header`      |

---

# 🗄️ Database Tables

* users
* media
* journals
* planners
* collections
* collection_media
* chat_history
* personal_access_tokens

---

# 🔐 Security Features

* Sanctum Bearer Token Authentication
* Route Protection Middleware
* User Ownership Policies
* SHA-256 PIN Hashing
* Secure Password Hashing
* File Validation & Restrictions
* Cross-user Access Protection

---

# 📦 Installation

## 1. Clone Repository

```bash id="pb77c2"
git clone https://github.com/your-username/soulshelf.git
cd soulshelf/backend
```

---

## 2. Install Dependencies

```bash id="k5cwdy"
composer install
```

---

## 3. Configure Environment

Create `.env` file:

```env id="6z0g7t"
APP_NAME=SoulShelf
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=soulshelf
DB_USERNAME=root
DB_PASSWORD=your_password
```

---

## 4. Generate App Key

```bash id="kv2i4u"
php artisan key:generate
```

---

## 5. Run Migrations

```bash id="9h2ncl"
php artisan migrate
```

---

## 6. Create Storage Link

```bash id="0p2n7x"
php artisan storage:link
```

---

## 7. Start Server

```bash id="i7w7z9"
php artisan serve
```

Server runs at:

```text id="r8v7sy"
http://localhost:8000
```

---

# 📤 File Storage Structure

```text id="0f6g4n"
storage/app/public/users/
    ├── {user_id}/
    │   ├── covers/
    │   └── profile/
```

---

# 🔄 Offline Sync Design

The backend supports:

* Optimistic updates
* Queue replay support
* Cache synchronization
* Retry-safe API design
* Conflict-safe updates

---

# 📊 Current Development Status

✅ Laravel Authentication
✅ Sanctum Integration
✅ REST API Completed
✅ File Upload System
✅ Authorization Policies
✅ Offline Sync Support
✅ PIN Hashing
🔄 Statistics Dashboard In Progress
🔄 AI Chatbot Enhancements In Progress

---

# 👨‍💻 Developer

**P.S Gunathilake**
 
