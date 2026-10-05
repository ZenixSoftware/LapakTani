# LapakTani Local REST API Backend

Backend REST API lokal mandiri untuk platform LapakTani berbasis **Node.js, Express.js, MySQL, dan Redis**, dirancang sebagai arsitektur mandiri (on-premise / self-hosted) berkinerja tinggi untuk menggantikan BaaS Supabase.

---

## Arsitektur & Teknologi

- **Runtime & Web Framework:** Node.js v24+, Express.js v5+
- **Database Relasional:** MySQL / MariaDB via `mysql2/promise` (connection pooling)
- **Caching Layer:** Redis Server v6+ via `redis` (Node Redis client v4+)
- **Autentikasi & Keamanan:** JSON Web Token (`jsonwebtoken`), Password Hashing (`bcryptjs`), CORS
- **File Upload Support:** `multer`

```
lapaktani_backend/
├── schema.sql                     # Skema inisialisasi tabel MySQL (users & products)
├── server.js                      # Entry point Express, CORS, routing & lifecycle
├── package.json                   # Dependensi & skrip dev/start
├── .env                           # Konfigurasi variabel lingkungan
├── .env.example                   # Template konfigurasi variabel lingkungan
├── .gitignore                     # Git ignore untuk node_modules & kredensial
└── src/
    ├── config/
    │   ├── db.js                  # Pool koneksi MySQL (mysql2/promise)
    │   └── redis.js               # Client Redis terhubung (reconnect & timeout)
    ├── middlewares/
    │   └── authMiddleware.js      # Verifikasi token JWT Bearer
    ├── controllers/
    │   ├── authController.js      # Logika register & login dengan bcrypt
    │   └── productController.js   # Logika katalog & strategi caching Redis
    └── routes/
        ├── auth.js                # Router rute autentikasi
        └── products.js            # Router rute katalog produk
```

---

## Persiapan & Instalasi

### 1. Inisialisasi Database MySQL
Pastikan servis MySQL lokal telah berjalan di port `3306`. Eksekusi file skema untuk membuat database dan tabel:
```bash
mysql -u root -p < schema.sql
```
Skema akan membuat:
- Database: `lapaktani_db`
- Tabel `users`: `id`, `full_name`, `email`, `password_hash`, `role` (`petani`, `pembeli`), `is_verified`, `created_at`
- Tabel `products`: `id`, `farmer_id` (FK ke `users.id`), `title`, `description`, `price`, `stock`, `image_url`, `created_at`

### 2. Jalankan Redis Server
Pastikan servis Redis telah berjalan di port default `6379`:
```bash
# Melalui Windows Service, Docker, atau WSL
redis-server
```

### 3. Konfigurasi Variabel Lingkungan (`.env`)
Sesuaikan file `.env` di root direktori `lapaktani_backend`:
```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=lapaktani_db
REDIS_URL=redis://localhost:6379
JWT_SECRET=lapaktani_secret_jwt_key_2026
JWT_EXPIRES_IN=7d
```

### 4. Menjalankan Server
```bash
# Mode pengembangan (auto-reload saat file berubah)
npm run dev

# Mode produksi
npm start
```
Server akan aktif di `http://localhost:3000`.

---

## Dokumentasi Endpoint API

### 1. Autentikasi (`/api/auth`)

#### `POST /api/auth/register`
Mendaftarkan pengguna baru (petani atau pembeli).
- **Request Body (JSON):**
  ```json
  {
    "full_name": "Pak Ahmad Subagio",
    "email": "ahmad.tani@example.com",
    "password": "PasswordAman123!",
    "role": "petani" // "petani" atau "pembeli" (default: "pembeli")
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Registrasi berhasil.",
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": 1,
      "full_name": "Pak Ahmad Subagio",
      "email": "ahmad.tani@example.com",
      "role": "petani",
      "is_verified": true
    }
  }
  ```

#### `POST /api/auth/login`
Verifikasi kredensial pengguna dan dapatkan token JWT.
- **Request Body (JSON):**
  ```json
  {
    "email": "ahmad.tani@example.com",
    "password": "PasswordAman123!"
  }
  ```
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "message": "Login berhasil.",
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": 1,
      "full_name": "Pak Ahmad Subagio",
      "email": "ahmad.tani@example.com",
      "role": "petani",
      "is_verified": true
    }
  }
  ```

---

### 2. Katalog Produk & Caching Redis (`/api/products`)

#### Strategi Caching Redis:
1. **Cache-Aside Pattern pada Read:**
   - Klien meminta `GET /api/products`.
   - Controller memeriksa key Redis `catalog_products`.
   - **Cache Hit:** Data langsung diparsing dari Redis dan dikembalikan (`"source": "redis_cache"`).
   - **Cache Miss:** Query dieksekusi ke MySQL, disimpan ke Redis dengan TTL 1 jam (`setEx('catalog_products', 3600, ...)`), kemudian dikembalikan (`"source": "database"`).
2. **Invalidasi Cache pada Write:**
   - Petani menambahkan produk via `POST /api/products`.
   - Produk disimpan ke MySQL.
   - Cache key `catalog_products` langsung dihapus via `redisClient.del('catalog_products')` agar pembeli selalu mendapatkan data katalog paling aktual pada pembacaan berikutnya.

#### `GET /api/products`
Mengambil semua katalog produk (didukung oleh Redis caching).
- **Headers:** Tidak memerlukan autentikasi (publik).
- **Response (200 OK):**
  ```json
  {
    "success": true,
    "source": "redis_cache", // atau "database" pada cache miss pertama
    "count": 2,
    "data": [
      {
        "id": 1,
        "farmer_id": 1,
        "title": "Beras Organik Sumenep 5kg",
        "description": "Beras pandan wangi pulen langsung dari sawah petani Bluto.",
        "price": 65000.00,
        "stock": 40,
        "image_url": "https://example.com/beras.jpg",
        "created_at": "2026-10-05T06:00:00.000Z",
        "farmer_name": "Pak Ahmad Subagio",
        "farmer_email": "ahmad.tani@example.com"
      }
    ]
  }
  ```

#### `POST /api/products`
Menambahkan produk baru ke katalog (khusus pengguna terautentikasi / petani).
- **Headers:** `Authorization: Bearer <TOKEN_JWT>`
- **Request Body (JSON):**
  ```json
  {
    "title": "Bawang Merah Varietas Super 1kg",
    "description": "Bawang merah panen segar kualitas grade A dari Rubaru Sumenep.",
    "price": 32000,
    "stock": 100,
    "image_url": "https://example.com/bawang.jpg"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "success": true,
    "message": "Produk berhasil ditambahkan ke katalog.",
    "data": {
      "id": 2,
      "farmer_id": 1,
      "title": "Bawang Merah Varietas Super 1kg",
      "description": "Bawang merah panen segar kualitas grade A dari Rubaru Sumenep.",
      "price": 32000,
      "stock": 100,
      "image_url": "https://example.com/bawang.jpg"
    }
  }
  ```
*(Catatan: Setelah eksekusi endpoint ini, key Redis `catalog_products` otomatis diinvalidasi).*

---

### 3. Health Check (`/api/health`)

#### `GET /api/health`
Memeriksa status konektivitas servis MySQL dan Redis.
- **Response (200 OK):**
  ```json
  {
    "uptime": 128.45,
    "database": "connected",
    "redis": "connected",
    "timestamp": "2026-10-05T06:30:00.000Z"
  }
  ```
