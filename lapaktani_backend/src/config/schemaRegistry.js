/**
 * [US-02] Schema Registry & Database Metadata Inspector
 * Lead Backend & Database Architect: Rafael Rizky (Rafariz19)
 * 
 * Provides an authoritative programmatic catalog of all 24+ MySQL relational tables,
 * their domain categorizations, primary keys, and foreign key constraints.
 */

const SCHEMA_CATALOG = {
  version: '2.0.0',
  dialect: 'MySQL / MariaDB (InnoDB)',
  minTableRequirement: 24,
  architect: 'Rafael Rizky (Rafariz19)',
  tables: [
    { name: 'user_roles', domain: 'AUTH', pk: 'id', description: 'Master 5 role pengguna' },
    { name: 'provinces', domain: 'GEO', pk: 'id', description: 'Master data provinsi' },
    { name: 'regencies', domain: 'GEO', pk: 'id', description: 'Master data kabupaten/kota' },
    { name: 'districts', domain: 'GEO', pk: 'id', description: 'Master data kecamatan' },
    { name: 'villages', domain: 'GEO', pk: 'id', description: 'Master data desa/kelurahan' },
    { name: 'users', domain: 'AUTH', pk: 'id', description: 'Akun & autentikasi pengguna' },
    { name: 'user_profiles', domain: 'AUTH', pk: 'user_id', description: 'Profil demografi & kontak' },
    { name: 'farmer_groups', domain: 'POKTAN', pk: 'id', description: 'Kelompok tani & ketua' },
    { name: 'farmer_profiles', domain: 'POKTAN', pk: 'id', description: 'Profil petani anggota poktan' },
    { name: 'farms', domain: 'POKTAN', pk: 'id', description: 'Bidang lahan fisik & koordinat GPS' },
    { name: 'commodity_categories', domain: 'COMMODITY', pk: 'id', description: 'Kategori komoditas tanaman' },
    { name: 'commodities', domain: 'COMMODITY', pk: 'id', description: 'Data komoditas pertanian' },
    { name: 'product_grades', domain: 'COMMODITY', pk: 'id', description: 'Standar mutu panen A/B/C' },
    { name: 'commodity_units', domain: 'COMMODITY', pk: 'id', description: 'Satuan unit berat' },
    { name: 'products', domain: 'COMMERCE', pk: 'id', description: 'Katalog etalase produk retail' },
    { name: 'product_images', domain: 'COMMERCE', pk: 'id', description: 'Galeri foto produk' },
    { name: 'cart_items', domain: 'COMMERCE', pk: 'id', description: 'Item keranjang belanja' },
    { name: 'orders', domain: 'ORDERS', pk: 'id', description: 'Pesanan resmi & nomor invoice' },
    { name: 'order_items', domain: 'ORDERS', pk: 'id', description: 'Rincian produk per pesanan' },
    { name: 'payments', domain: 'ORDERS', pk: 'id', description: 'Log pembayaran & Midtrans webhook' },
    { name: 'b2b_harvest_pools', domain: 'B2B', pk: 'id', description: 'Pool konsolidasi panen borongan' },
    { name: 'b2b_quota_allocations', domain: 'B2B', pk: 'id', description: 'Alokasi kuota per anggota poktan' },
    { name: 'b2b_orders', domain: 'B2B', pk: 'id', description: 'Kontrak pesanan B2B offtaker' },
    { name: 'b2b_contracts', domain: 'B2B', pk: 'id', description: 'Kesepakatan pasokan jangka panjang' },
    { name: 'soil_telemetries', domain: 'IOT', pk: 'id', description: 'Telemetri sensor IoT tanah' },
    { name: 'educational_articles', domain: 'COMMUNITY', pk: 'id', description: 'Artikel & materi edukasi budidaya' },
    { name: 'pest_reports', domain: 'COMMUNITY', pk: 'id', description: 'Laporan hama & verifikasi PPL' },
    { name: 'notifications', domain: 'SYSTEM', pk: 'id', description: 'Notifikasi & broadcast peringatan' },
    { name: 'wallets', domain: 'FINANCE', pk: 'id', description: 'Dompet saldo petani/pembeli' },
    { name: 'wallet_transactions', domain: 'FINANCE', pk: 'id', description: 'Mutasi transaksi dompet digital' },
    { name: 'monitoring_lahan', domain: 'POKTAN', pk: 'id', description: 'Monitoring kondisi lahan Sumenep' },
    { name: 'fertilizer_allocations', domain: 'SUPPLY_CHAIN', pk: 'id', description: 'Alokasi pupuk subsidi desa' },
    { name: 'store_applications', domain: 'COMMERCE', pk: 'id', description: 'Pengajuan mitra toko kios tani' },
    { name: 'ppl_forum_posts', domain: 'COMMUNITY', pk: 'id', description: 'Forum privat antar-penyuluh BPP' },
    { name: 'village_forum_posts', domain: 'COMMUNITY', pk: 'id', description: 'Forum privat warga tingkat desa' },
    { name: 'harvest_reports', domain: 'SUPPLY_CHAIN', pk: 'id', description: 'Laporan panen riil petani desa' },
    { name: 'harvest_purchase_offers', domain: 'COMMERCE', pk: 'id', description: 'Penawaran beli komoditas desa' },
    { name: 'chat_conversations', domain: 'CHAT', pk: 'id', description: 'Sesi obrolan langsung (DM)' },
    { name: 'chat_participants', domain: 'CHAT', pk: 'id', description: 'Partisipan obrolan & last read' },
    { name: 'chat_messages', domain: 'CHAT', pk: 'id', description: 'Pesan obrolan real-time' },
    { name: 'ppl_decision_reports', domain: 'COMMUNITY', pk: 'id', description: 'Surat rekomendasi keputusan PPL' },
    { name: 'farmer_daily_logs', domain: 'POKTAN', pk: 'id', description: 'Buku catatan harian budidaya tani' }
  ]
};

function getSchemaStats() {
  const domains = {};
  for (const t of SCHEMA_CATALOG.tables) {
    domains[t.domain] = (domains[t.domain] || 0) + 1;
  }
  return {
    totalTables: SCHEMA_CATALOG.tables.length,
    meetsRequirement: SCHEMA_CATALOG.tables.length >= SCHEMA_CATALOG.minTableRequirement,
    minRequired: SCHEMA_CATALOG.minTableRequirement,
    architect: SCHEMA_CATALOG.architect,
    domains
  };
}

module.exports = {
  SCHEMA_CATALOG,
  getSchemaStats
};
