# LapakTani Database & Migration Directory
**User Story:** `[US-02]` Perancangan & Eksekusi Skema Basis Data Relasional MySQL 24+ Tabel & Migrasi  
**Architect:** Rafael Rizky (`Rafariz19`)  

Direktori ini memuat dokumentasi arsitektur basis data relasional MySQL, kamus data (*data dictionary*), dan referensi migrasi skema tabel aplikasi LapakTani.

## Isi Direktori
- `SCHEMA_DICTIONARY.md`: Dokumentasi lengkap 42 tabel relasional, diagram relasi entitas (ERD), dan pemetaan domain.
- `../lapaktani_backend/migrations/`: File migrasi SQL terurut (`001_*.sql` s/d `009_*.sql`).
- `../lapaktani_backend/src/config/migrate_*.js`: Script otomasi eksekusi migrasi tabel dan seeding data awal.
