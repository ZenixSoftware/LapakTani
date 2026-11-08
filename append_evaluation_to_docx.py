# -*- coding: utf-8 -*-
"""
Script untuk mengintegrasikan evaluasi McCall's Quality Model secara otomatis
ke dalam file dokumen: Moch Ilham Abdul Aziz_3125522014_METODOLOGI AGILE_Pertemuan 9.docx
"""

import docx
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml
from docx.oxml.ns import nsdecls

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    tcPr.append(shd)

def set_cell_margins(cell, top=120, bottom=120, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def set_table_borders(table, color="B0C4DE"):
    tblPr = table._tbl.tblPr
    borders = parse_xml(
        f'<w:tblBorders {nsdecls("w")}>'
        f'<w:top w:val="single" w:sz="8" w:space="0" w:color="{color}"/>'
        f'<w:bottom w:val="single" w:sz="8" w:space="0" w:color="{color}"/>'
        f'<w:left w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:insideH w:val="single" w:sz="4" w:space="0" w:color="{color}"/>'
        f'<w:insideV w:val="none"/>'
        f'</w:tblBorders>'
    )
    tblPr.append(borders)

def add_p(doc, text="", style='Normal', space_before=2, space_after=4, align=WD_ALIGN_PARAGRAPH.JUSTIFY, bold=False, italic=False, font_size=11.5, color=None):
    p = doc.add_paragraph(style=style)
    p.alignment = align
    p.paragraph_format.space_before = Pt(space_before)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    if text:
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(font_size)
        r.bold = bold
        r.italic = italic
        if color:
            r.font.color.rgb = color
    return p

def add_bullet(doc, text, bold_prefix="", level=0, space_after=3):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(1)
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.line_spacing = 1.15
    p.paragraph_format.left_indent = Inches(0.25 * (level + 1))
    
    r_bullet = p.add_run("• ")
    r_bullet.font.name = 'Times New Roman'
    r_bullet.font.size = Pt(11.5)
    r_bullet.bold = True
    
    if bold_prefix:
        r_pre = p.add_run(bold_prefix)
        r_pre.font.name = 'Times New Roman'
        r_pre.font.size = Pt(11.5)
        r_pre.bold = True
    
    r_body = p.add_run(text)
    r_body.font.name = 'Times New Roman'
    r_body.font.size = Pt(11.5)
    return p

def add_heading2(doc, text):
    p = doc.add_paragraph(style='Heading 2')
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(13)
    r.bold = True
    r.font.color.rgb = RGBColor(27, 54, 93) # Deep Navy PENS
    return p

def add_heading3(doc, text):
    p = doc.add_paragraph(style='Heading 3')
    p.paragraph_format.space_before = Pt(9)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.keep_with_next = True
    r = p.add_run(text)
    r.font.name = 'Times New Roman'
    r.font.size = Pt(12)
    r.bold = True
    r.font.color.rgb = RGBColor(44, 62, 80)
    return p

def add_callout_box(doc, text, title=""):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = table.cell(0, 0)
    cell.width = Inches(6.5)
    set_cell_background(cell, "F4F6F9")
    set_cell_margins(cell, top=120, bottom=120, left=160, right=160)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:top w:val="none"/>'
        f'<w:left w:val="single" w:sz="24" w:space="0" w:color="1B365D"/>'
        f'<w:bottom w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.15
    if title:
        rt = p.add_run(title + "\n")
        rt.font.name = 'Times New Roman'
        rt.font.size = Pt(11)
        rt.bold = True
        rt.font.color.rgb = RGBColor(27, 54, 93)
    rb = p.add_run(text)
    rb.font.name = 'Times New Roman'
    rb.font.size = Pt(10.5)
    rb.italic = True
    
    sp = doc.add_paragraph()
    sp.paragraph_format.space_before = Pt(0)
    sp.paragraph_format.space_after = Pt(2)

def build_evaluation():
    doc_path = "Moch Ilham Abdul Aziz_3125522014_METODOLOGI AGILE_Pertemuan 9.docx"
    doc = docx.Document(doc_path)
    
    # Verifikasi keberadaan bab JAWABAN
    print("Mempersiapkan penulisan ke dokumen Word...")
    
    # Paragraf Pengantar
    add_p(doc, 
        "Berdasarkan rencana arsitektur sistem informasi rantai pasok dan agribisnis LAPAKTANI yang mengintegrasikan frontend multiplatform Flutter (Dart) dan backend Supabase (PostgreSQL, Auth, Storage, Edge Functions), berikut disajikan laporan pengujian dan evaluasi kualitas perangkat lunak komprehensif berdasarkan McCall's Quality Model. Evaluasi ini berfokus pada dua pilar kualitas internal sistem, yaitu Product Revision (Revisi Produk) dan Product Transition (Transisi Produk) sebagai landasan penguatan kualitas menjelang Sprint 4.",
        space_before=6, space_after=6)
    
    add_callout_box(doc,
        "Konsep Pengujian Kualitas McCall: Model kualitas McCall membagi perspektif evaluasi perangkat lunak ke dalam tiga dimensi utama: Product Operation (Operasi Produk), Product Revision (Kemampuan Pemeliharaan dan Adaptasi Internal), dan Product Transition (Kemampuan Portabilitas dan Interoperabilitas). Evaluasi internal ini melengkapi kuesioner eksternal pengguna (Petani, Pengepul, Konsumen, Penyuluh) guna menjamin keandalan teknis sistem sebelum perilisan produksi.",
        "Ringkasan Tujuan Evaluasi Teknis:")

    # =========================================================================
    # 1. PRODUCT REVISION
    # =========================================================================
    add_heading2(doc, "1. Product Revision (Revisi Produk)")
    
    add_p(doc,
        "Dimensi Product Revision menilai kesiapan arsitektur internal perangkat lunak dalam menghadapi perubahan kode, proses perbaikan bug, dan penambahan fitur baru tanpa menurunkan performa maupun stabilitas sistem.",
        space_after=4)

    # 1.1 Maintainability
    add_heading3(doc, "1.1 Maintainability (Kemudahan Pemeliharaan)")
    add_p(doc, 
        "Maintainability mengukur seberapa mudah source code dan skema database dipelihara, didebug, serta diperluas oleh tim pengembang yang bekerja secara paralel dalam metodologi Agile.")
    
    add_p(doc, "a. Evaluasi Arsitektur Frontend Flutter (Clean Architecture & Feature-First):", bold=True, space_before=4)
    add_bullet(doc, 
        "Untuk mencegah anti-pattern 'God Class' atau penumpukan kode pada satu file UI, proyek LapakTani harus secara ketat menerapkan arsitektur Feature-First. Setiap modul fungsional (auth, buyer, seller, cart, order, logistics) dipecah ke dalam 3 layer utama: data (Remote Data Source, DTO, Repository Implementation), domain (Entities, Use Cases, Repository Interface), dan presentation (Controllers/Notifiers, Screens, Widgets).",
        "Pemisahan Layer Berbasis Fitur: ")
    add_bullet(doc, 
        "Presentation Layer (UI) dilarang berinteraksi langsung dengan Supabase Client atau HTTP Client. Seluruh interaksi wajib melalui abstraksi Use Case dan Repository Interface di Domain Layer. Dengan demikian, jika terjadi perubahan kontrak backend (misalnya migrasi dari Supabase BaaS ke local REST API Express/MySQL), perubahan hanya terlokalisasi pada layer Data tanpa menyentuh UI.",
        "Prinsip Dependency Inversion: ")
    add_bullet(doc, 
        "Manfaatkan Service Locator (get_it) atau dependency injection modern untuk mengelola instansiasi singleton (AuthService, ApiService, CartRepository). Hal ini memudahkan pelacakan alur ketergantungan dan mempercepat debugging.",
        "Dependency Injection Terpusat: ")

    add_p(doc, "b. Evaluasi Basis Data (24 Tabel PostgreSQL di Supabase):", bold=True, space_before=4)
    add_bullet(doc, 
        "Menaruh seluruh 24 tabel ke dalam skema default 'public' akan menimbulkan kompleksitas tinggi dalam tata kelola hak akses dan dokumentasi relasi. Disarankan membagi 24 tabel ke dalam namespace skema logis PostgreSQL, seperti: auth_ext (profil, verifikasi NIK/KTP), catalog (produk, varietas, grade, unit satuan 3NF), trade (keranjang, pesanan, status history), logistics (cold-chain tracking, koordinat GPS armada), dan billing (transaksi, escrow kelompok tani).",
        "Modularisasi Skema Logis (Namespaces): ")
    add_bullet(doc, 
        "Terapkan B-Tree Index pada seluruh Foreign Key (farmer_id, order_id, product_id) untuk mengoptimalkan kecepatan query JOIN. Selain itu, pasang Composite Index pada query pencarian tinggi, seperti (category_id, is_active, price) pada tabel produk dan (buyer_id, order_status, created_at DESC) pada tabel riwayat transaksi.",
        "Strategi Pengindeksan Terukur: ")
    add_bullet(doc, 
        "Seluruh modifikasi DDL harus dikelola via Supabase CLI Migrations berbasis file SQL terurut waktu (YYYYMMDD_migration_name.sql) yang di-commit ke Git. Hal ini mencegah terjadinya schema drift antara environment local developer dan production instance.",
        "Automated Migration Versioning: ")

    # 1.2 Flexibility
    add_heading3(doc, "1.2 Flexibility (Fleksibilitas Arsitektur)")
    add_p(doc, 
        "Flexibility mengevaluasi kemampuan sistem beradaptasi terhadap perubahan kebutuhan bisnis, khususnya saat penambahan role pengguna baru di luar 5 role yang telah ditetapkan (Petani, Pengepul, Penyuluh, Konsumen/Pembeli, dan Admin/Logistik). Di masa mendatang, sangat mungkin muncul role baru seperti: Investor Agribisnis, Driver Armada Cold-chain, atau Auditor Sertifikasi Organik.")
    
    add_p(doc, "a. Kelemahan Pendekatan ENUM Hardcoded vs Solusi Dynamic RBAC:", bold=True, space_before=4)
    add_bullet(doc, 
        "Menyimpan role sebagai tipe ENUM('petani', 'pembeli', ...) pada tabel users merupakan anti-pattern fleksibilitas. Penambahan role baru membutuhkan perintah DDL ALTER TYPE yang berisiko mengunci tabel (table lock) dan menuntut refactoring logika kondisional di banyak screen.",
        "Kelemahan ENUM Hardcoded: ")
    add_bullet(doc, 
        "Terapkan relasi Role-Based Access Control (RBAC) dinamis menggunakan 3 tabel relasional: public.roles (id, code, name, description), public.permissions (id, module, action), dan pivot table public.user_roles (user_id, role_id). Dengan pola ini, penambahan role baru cukup dilakukan melalui satu baris INSERT data tanpa mengubah skema tabel maupun downtime sistem.",
        "Arsitektur Dynamic RBAC: ")

    add_p(doc, "b. Pola Ekstensi Profil Polimorfik (Open-Closed Principle):", bold=True, space_before=4)
    add_bullet(doc, 
        "Gunakan tabel ekstensi profil terpisah dengan relasi 1:1 terhadap tabel users (misal farmer_profiles, buyer_profiles, logistics_profiles, investor_profiles). Saat role baru ditambahkan, entitas data spesifik role tersebut dibuat di tabel baru tanpa memodifikasi tabel users inti.",
        "Ekstensi Profil Terisolasi: ")
    add_bullet(doc, 
        "Kaitkan role pengguna ke dalam Custom Claims JWT di Supabase (auth.jwt() -> 'app_metadata' -> 'roles'). Kebijakan RLS (Row Level Security) di PostgreSQL dapat secara otomatis mengevaluasi izin akses role baru secara deklaratif menggunakan operator JSONB tanpa perlu menulis ulang fungsi keamanan database.",
        "Dynamic Row Level Security (RLS): ")

    add_p(doc, "c. Fleksibilitas Navigasi dan UI Flutter:", bold=True, space_before=4)
    add_bullet(doc, 
        "Gunakan Factory Pattern atau Navigation Registry untuk memetakan role pengguna ke susunan Bottom Navigation Bar dan Dashboard. Hindari pernyataan switch-case statis pada file main navigation. Dengan registry terpusat, penambahan dashboard role baru cukup dengan mendaftarkan kelas handler baru tanpa mengotak-atik routing role lainnya.",
        "Registry Resolver Antarmuka: ")

    # 1.3 Testability
    add_heading3(doc, "1.3 Testability (Kemudahan Pengujian pada Sprint 4)")
    add_p(doc, 
        "Testability mengukur sejauh mana sistem memfasilitasi otomasi pengujian untuk menemukan defek secara dini. Pada pelaksanaan Sprint 4, tim disarankan mengadopsi Piramida Pengujian (Test Pyramid) terstruktur:")

    add_bullet(doc, 
        "Fokus pada pengujian logika bisnis murni tanpa dependensi UI. Modul yang wajib diuji mencakup: formula kalkulasi total biaya pesanan (harga produk × kuantitas + margin logistik dingin), validasi NIK KTP (16 digit), sanitasi payload, dan state reducers (Initial, Loading, Loaded, Error). Manfaatkan package mocktail untuk melakukan mock terhadap HTTP/Supabase Client sehingga unit test dapat dieksekusi secara cepat, terisolasi, dan offline di pipeline CI/CD.",
        "Unit Testing (Target Coverage ~70%): ")
    add_bullet(doc, 
        "Fokus pada verifikasi komponen antarmuka mandiri. Pengujian mencakup: ProductCard (memastikan badge 'Grade A' memiliki warna hijau dan format mata uang Rupiah akurat), CartQuantityStepper (memastikan nilai kuantitas bertambah saat tombol '+' ditekan), dan Form Validasi Input Produk. Manfaatkan WidgetTester.pumpAndSettle() dengan injeksi mocked providers/controllers.",
        "Widget Testing (Target Coverage ~20%): ")
    add_bullet(doc, 
        "Menguji skenario alur transaksi kritis dari awal hingga akhir (End-to-End). Contoh skenario kritis Sprint 4: Petani membuat listing komoditas -> Pembeli mencari komoditas via search bar -> Memasukkan ke keranjang -> Checkout pesanan -> Callback simulasi pembayaran sukses -> Verifikasi otomatisasi pemotongan stok pada database. Pengujian dijalankan menggunakan package integration_test.",
        "Integration & E2E Testing (Target Coverage ~10%): ")
    add_bullet(doc, 
        "Gunakan tool pgTAP di PostgreSQL untuk menguji aturan keamanan Row Level Security (RLS) dan trigger database secara terprogram (misalnya memastikan user dengan role 'Pembeli' gagal melakukan modifikasi harga pada tabel catalog.products).",
        "Database Integration Testing (RLS pgTAP): ")

    # =========================================================================
    # 2. PRODUCT TRANSITION
    # =========================================================================
    add_heading2(doc, "2. Product Transition (Transisi Produk)")
    
    add_p(doc, 
        "Dimensi Product Transition mengevaluasi kemampuan perangkat lunak ketika dipindahkan ke lingkungan komputasi yang berbeda, digunakan kembali pada modul lain, serta dihubungkan secara aman dengan ekosistem API pihak ketiga.",
        space_after=4)

    # 2.1 Portability
    add_heading3(doc, "2.1 Portability (Portabilitas Aplikasi Multiplatform)")
    add_p(doc, 
        "Portability menganalisis adaptabilitas kode Flutter ketika dikompilasi menjadi APK Android, iOS bundle, maupun Web Dashboard, serta kesiapan integrasi backend Supabase lintas platform.")

    add_bullet(doc, 
        "Modul pelacakan logistik cold-chain bergantung pada GPS background tracking dan pemindai barcode/kamera. Pada Android, sistem membutuhkan deklarasi izin ACCESS_FINE_LOCATION dan ACCESS_BACKGROUND_LOCATION di AndroidManifest.xml. Sementara pada iOS, diperlukan deskripsi jelas pada NSLocationAlwaysAndWhenInUseUsageDescription di Info.plist. Pada platform Web, background tracking tidak dapat berjalan saat browser diminimalkan. Oleh karena itu, modul logistik wajib membungkus akses hardware dalam Service Interface (ILocationService) yang memiliki strategi fallback ketika fitur native tidak tersedia.",
        "Platform Channels & Akses Hardware Native: ")
    add_bullet(doc, 
        "Pada mobile (Android/iOS), sesi autentikasi Supabase diamankan menggunakan flutter_secure_storage (Android Keystore dan iOS Keychain). Namun pada Flutter Web, penyimpanan beralih ke IndexedDB/LocalStorage yang memiliki vektor risiko XSS. Diperlukan pengaturan Content Security Policy (CSP) dan CORS yang ketat pada Supabase project.",
        "Keamanan Token Sesi Supabase Lintas Platform: ")
    add_bullet(doc, 
        "Koneksi WebSocket Supabase Realtime di perangkat mobile akan diputus oleh sistem operasi ketika aplikasi masuk ke kondisi latar belakang (Background / Doze Mode). Sistem tidak boleh hanya mengandalkan WebSocket stateful untuk event kritis (seperti notifikasi pesanan masuk pada petani). Sistem harus mengintegrasikan push notifications melalui Firebase Cloud Messaging (FCM) sebagai mekanisme pengiriman sinyal di background.",
        "Manajemen Koneksi Realtime WebSocket: ")

    # 2.2 Reusability
    add_heading3(doc, "2.2 Reusability (Kemampuan Penggunaan Ulang Komponen)")
    add_p(doc, 
        "Reusability menilai apakah komponen antarmuka dan fungsi backend dirancang secara modular sehingga dapat dipakai kembali di berbagai modul tanpa duplikasi kode (*Don't Repeat Yourself*).")

    add_p(doc, "a. Komponen Antarmuka (UI) Modular di Flutter:", bold=True, space_before=4)
    add_bullet(doc, 
        "Didesain agnostic context; menerima entitas ProductData, callback onTap, dan flag opsi showAddToCart. Widget ini dapat dipakai ulang pada Beranda Pembeli, Hasil Pencarian, Halaman Rekomendasi Petani, dan Mode Pratinjau Produk Saya oleh Penjual.",
        "ProductCardWidget: ")
    add_bullet(doc, 
        "Menerima daftar status pengiriman (termasuk temperatur cold-chain dan titik transit). Digunakan bersama pada Halaman Lacak Pesanan Pembeli, Dasbor Kurir, dan Panel Monitoring Petani.",
        "OrderStatusTimelineWidget: ")
    add_bullet(doc, 
        "Komponen chip visual yang memetakan status transaksi ke kode warna dan ikon baku (Menunggu Pembayaran, Diproses, Dalam Pengiriman Dingin, Selesai, Dibatalkan).",
        "StatusBadge: ")
    add_bullet(doc, 
        "Widget upload foto terintegrasi kompresi otomatis (image_picker + image_cropper) dan validasi magic bytes. Dipakai ulang pada registrasi Petani (KTP), verifikasi keahlian Penyuluh, dan bukti tanda terima barang (Proof of Delivery).",
        "DocumentUploadPicker: ")

    add_p(doc, "b. Modul Logika Backend Reusable:", bold=True, space_before=4)
    add_bullet(doc, 
        "Terapkan Adapter Pattern dengan interface seragam (IPaymentGateway). Implementasi spesifik (Midtrans, Xendit, QRIS) dienkapsulasi. Jika di masa mendatang LapakTani berganti vendor pembayaran, alur transaksi inti sama sekali tidak berubah.",
        "Payment Gateway Adapter Interface: ")
    add_bullet(doc, 
        "Fungsi kalkulasi independen berbasis Formula Haversine (menghitung jarak koordinat gudang ke pembeli) dikombinasikan dengan koefisien armada pendingin. Fungsi ini dapat dipanggil oleh modul Checkout, modul Estimasi Biaya Pengepul, maupun modul Simulasi Ekspedisi.",
        "Shipping & Cold-Chain Tariff Engine: ")
    add_bullet(doc, 
        "Modul transaksi ACID di database untuk mengunci stok sementara saat checkout (reservasi 15 menit) dan auto-rollback stok jika pembayaran kadaluarsa.",
        "Stock Reservation & Rollback Service: ")

    # 2.3 Interoperability
    add_heading3(doc, "2.3 Interoperability (Interoperabilitas Antar-Sistem)")
    add_p(doc, 
        "Interoperability mengukur kelancaran dan keamanan integrasi antara frontend Flutter, backend Supabase/Edge Functions, dan layanan pihak ketiga (Payment Gateway, Webhook Ekspedisi Logistik, API Cuaca BMKG, SMS/WhatsApp Gateway).")

    add_bullet(doc, 
        "Aplikasi Flutter yang dikompilasi ke APK rentan terhadap teknik reverse-engineering yang dapat membocorkan API Secret Key. Oleh karena itu, Flutter dilarang keras memanggil API pihak ketiga secara langsung. Seluruh pemanggilan wajib melalui Supabase Edge Functions / Backend API yang bertindak sebagai API Gateway / BFF. Edge Function memverifikasi JWT user, membaca credentials rahasia dari environment variables terenkripsi, lalu memanggil pihak ketiga secara Server-to-Server.",
        "Pola Backend-For-Frontend (BFF) via Edge Functions: ")
    add_bullet(doc, 
        "Setiap callback webhook dari payment gateway atau vendor kurir wajib memverifikasi cryptographic HMAC signature (misalnya SHA-512 signature dari Midtrans). Selain itu, terapkan tabel webhook_events dengan constraint UNIQUE pada event_id untuk menjamin idempotensi (mencegah double-crediting atau double-updating status akibat network retry dari vendor eksternal).",
        "Webhook Security & Idempotency: ")
    add_bullet(doc, 
        "Saat menghubungi API eksternal yang rentan gangguan (misalnya API data cuaca/harga pasar agribisnis), terapkan konfigurasi HTTP Timeout (maksimal 5 detik) dan pola Retry dengan Exponential Backoff. Data non-kritis wajib disimpan ke dalam Redis / Table Cache dengan TTL 1–6 jam untuk menghindari throttling API eksternal dan menjaga aplikasi tetap responsif.",
        "Resilience & Caching Layer: ")

    # =========================================================================
    # 3. MATRIKS REKAPITULASI EVALUASI
    # =========================================================================
    add_heading2(doc, "3. Matriks Rekapitulasi Evaluasi McCall (Rencana Aksi Sprint 4)")
    
    add_p(doc, 
        "Tabel berikut merangkum hasil evaluasi kualitas perangkat lunak LAPAKTANI berdasarkan faktor internal McCall, status implementasi terkini, dan rencana tindakan perbaikan konkret yang harus dieksekusi pada Sprint 4:",
        space_after=6)

    # Tabel Rekapitulasi
    table = doc.add_table(rows=7, cols=4)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    set_table_borders(table, color="1B365D")

    col_widths = [Inches(1.3), Inches(1.8), Inches(1.2), Inches(2.2)]
    headers = ["Faktor Kualitas", "Kriteria Evaluasi", "Status Saat Ini", "Rencana Tindakan Sprint 4"]

    # Format Header Row
    hdr_cells = table.rows[0].cells
    for i, title in enumerate(headers):
        hdr_cells[i].width = col_widths[i]
        set_cell_background(hdr_cells[i], "1B365D")
        set_cell_margins(hdr_cells[i], top=140, bottom=140, left=120, right=120)
        p = hdr_cells[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        r = p.add_run(title)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(11)
        r.bold = True
        r.font.color.rgb = RGBColor(255, 255, 255)

    data = [
        ("Maintainability\n(Product Revision)",
         "Modularitas 24 tabel PostgreSQL dan struktur Clean Architecture Flutter",
         "Perlu Peningkatan",
         "Pemisahan 24 tabel ke skema logis (catalog, trade, logistics). Penegasan Feature-First arsitektur dan Dependency Inversion di Flutter."),
        
        ("Flexibility\n(Product Revision)",
         "Kemampuan adaptasi penambahan role baru di luar 5 role awal",
         "Rentan jika ENUM",
         "Migrasi dari role ENUM ke arsitektur Dynamic RBAC (roles, user_roles). Manfaatkan Custom Claims JWT pada RLS Supabase."),
        
        ("Testability\n(Product Revision)",
         "Kesiapan infrastruktur pengujian otomasi (Unit, Widget, E2E)",
         "Belum Maksimal",
         "Penerapan Piramida Pengujian: Unit test (mocktail) 70%, Widget test komponen kunci 20%, Integration test alur transaksi 10%, dan pgTAP."),
        
        ("Portability\n(Product Transition)",
         "Portabilitas APK Android, iOS, Web & akses hardware native",
         "Cukup Baik",
         "Enkapsulasi GPS dan kamera ke dalam Service Interface. Integrasi FCM push notifications sebagai fallback WebSocket Realtime di background."),
        
        ("Reusability\n(Product Transition)",
         "Modularitas widget UI dan modul fungsi backend lintas fitur",
         "Perlu Standarisasi",
         "Ekstraksi ProductCard, OrderStatusTimeline, dan modul Payment Gateway Adapter Pattern ke direktori shared/core."),
        
        ("Interoperability\n(Product Transition)",
         "Keamanan dan keandalan komunikasi API eksternal (Payment & Kurir)",
         "Perlu Pengamanan",
         "Wajibkan BFF via Supabase Edge Functions, verifikasi cryptographic webhook signature (HMAC), dan catat tabel Idempotency.")
    ]

    for row_idx, row_data in enumerate(data, start=1):
        row_cells = table.rows[row_idx].cells
        bg_color = "F9FBFC" if row_idx % 2 == 1 else "FFFFFF"
        for col_idx, text in enumerate(row_data):
            row_cells[col_idx].width = col_widths[col_idx]
            set_cell_background(row_cells[col_idx], bg_color)
            set_cell_margins(row_cells[col_idx], top=100, bottom=100, left=120, right=120)
            p = row_cells[col_idx].paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = 1.15
            
            if col_idx == 0:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                r = p.add_run(text)
                r.font.name = 'Times New Roman'
                r.font.size = Pt(10.5)
                r.bold = True
            elif col_idx == 2:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                r = p.add_run(text)
                r.font.name = 'Times New Roman'
                r.font.size = Pt(10.5)
                r.italic = True
                if "Perlu" in text or "Rentan" in text:
                    r.font.color.rgb = RGBColor(180, 40, 40) # Red warning
                else:
                    r.font.color.rgb = RGBColor(30, 130, 60) # Green OK
            else:
                p.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY
                r = p.add_run(text)
                r.font.name = 'Times New Roman'
                r.font.size = Pt(10.5)

    # Paragraf Penutup
    sp_end = doc.add_paragraph()
    sp_end.paragraph_format.space_before = Pt(10)
    sp_end.paragraph_format.space_after = Pt(4)
    add_p(doc,
        "Kesimpulan: Evaluasi kualitas berbasis McCall's Quality Model pada proyek LAPAKTANI membuktikan bahwa sistem memiliki fondasi arsitektur yang solid, namun memerlukan langkah penguatan spesifik pada Sprint 4. Dengan mengimplementasikan pemisahan layer Clean Architecture, skema basis data RBAC dinamis, piramida otomasi pengujian, abstraksi hardware multiplatform, dan pola API Gateway BFF yang aman, aplikasi LAPAKTANI akan memiliki daya tahan tinggi, skalabel, serta siap dioperasikan dalam skala produksi agribisnis nasional.",
        bold=False, italic=False, space_before=4, space_after=12)

    doc.save(doc_path)
    print(f"Berhasil! Seluruh isi evaluasi telah dimasukkan ke file: {doc_path}")

if __name__ == "__main__":
    build_evaluation()
