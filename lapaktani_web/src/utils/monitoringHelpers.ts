import type { LandPlotRecord } from '../services/api';

export type FertilityStatus = 'optimal' | 'sedang' | 'kritis';

export const isPlotCritical = (plot: LandPlotRecord): boolean => {
  const ph = Number(plot.ph ?? 6.5);
  const moisture = Number(plot.moisture ?? 50);
  const fertility = Number(plot.fertility ?? 60);
  return ph < 5.5 || ph > 7.5 || moisture < 15 || fertility < 20;
};

export const getPlotFertilityStatus = (plot: LandPlotRecord): FertilityStatus => {
  if (isPlotCritical(plot)) return 'kritis';
  const fertility = Number(plot.fertility ?? 0);
  return fertility >= 60 ? 'optimal' : 'sedang';
};

export const matchesPlotCategory = (plot: LandPlotRecord, filterKey: string): boolean => {
  if (!filterKey || filterKey === 'all') return true;
  const kom = (plot.komoditas || '').toLowerCase().trim();
  const iri = (plot.irigasi || '').toLowerCase().trim();
  const pom = (plot.pompa_air || '').toLowerCase().trim();
  const lis = (plot.listrik || '').toLowerCase().trim();
  const bajak = (plot.pembajak || '').toLowerCase().trim();
  const pok = (plot.kelompok_tani || '').toLowerCase().trim();

  switch (filterKey) {
    case 'padi':
      return kom.includes('padi');
    case 'jagung':
      return kom.includes('jagung');
    case 'cabai':
      return kom.includes('cabai') || kom.includes('caba') || kom.includes('cabe');
    case 'tembakau':
      return kom.includes('tembakau');
    case 'traktor':
      return (
        bajak.includes('traktor') ||
        bajak.includes('trktor') ||
        bajak.includes('traktro') ||
        bajak.includes('tarktor')
      );
    case 'sapi':
      return bajak.includes('sapi');
    case 'poktan':
      return pok !== 'tidak' && pok !== 'mandiri' && pok !== '' && pok !== '-';
    case 'irigasi':
      return iri === 'ya';
    case 'pompa':
      return pom === 'ya';
    case 'listrik':
      return lis === 'ya';
    case 'kritis':
      return isPlotCritical(plot);
    default:
      return true;
  }
};

export const escapeHtml = (value: unknown): string => {
  const text = String(value ?? '');
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
};

export const computePlotAverages = (plots: LandPlotRecord[]) => {
  if (plots.length === 0) {
    return {
      count: 0,
      avgTemp: 0,
      avgMoisture: 0,
      avgPh: 0,
      avgEc: 0,
      avgN: 0,
      avgP: 0,
      avgK: 0,
      avgFertility: 0,
    };
  }
  const totals = plots.reduce(
    (acc, p) => {
      acc.temp += Number(p.temp) || 0;
      acc.moisture += Number(p.moisture) || 0;
      acc.ph += Number(p.ph) || 0;
      acc.ec += Number(p.conductivity) || 0;
      acc.n += Number(p.nitrogen) || 0;
      acc.p += Number(p.phosphorus) || 0;
      acc.k += Number(p.potassium) || 0;
      acc.fertility += Number(p.fertility) || 0;
      return acc;
    },
    { temp: 0, moisture: 0, ph: 0, ec: 0, n: 0, p: 0, k: 0, fertility: 0 }
  );
  const n = plots.length;
  return {
    count: n,
    avgTemp: totals.temp / n,
    avgMoisture: totals.moisture / n,
    avgPh: totals.ph / n,
    avgEc: totals.ec / n,
    avgN: totals.n / n,
    avgP: totals.p / n,
    avgK: totals.k / n,
    avgFertility: totals.fertility / n,
  };
};

export const downloadPlotsCsv = (plots: LandPlotRecord[], filename = 'lapaktani_sensor_sumenep.csv') => {
  const headers = [
    'ID',
    'Desa',
    'Kecamatan',
    'Poktan',
    'Komoditas',
    'Varietas',
    'Luas_Lahan',
    'Latitude',
    'Longitude',
    'Suhu_C',
    'Kelembaban_Pct',
    'pH',
    'EC_uS_cm',
    'Nitrogen_mg_kg',
    'Fosfor_mg_kg',
    'Kalium_mg_kg',
    'Fertilitas',
    'Status_Kesuburan',
    'Irigasi',
    'Pompa_Air',
    'Energi_Pompa',
    'Listrik',
    'Pembajak',
    'Status_PPL',
    'Rekomendasi_PPL',
  ];

  const escapeCsvCell = (val: unknown) => {
    const str = String(val ?? '').replace(/"/g, '""');
    return `"${str}"`;
  };

  const rows = plots.map((p) =>
    [
      p.id,
      p.nama_desa,
      p.kecamatan || '',
      p.kelompok_tani,
      p.komoditas,
      p.varietas || '',
      p.luas_lahan,
      p.latitude,
      p.longitude,
      p.temp,
      p.moisture,
      p.ph,
      p.conductivity,
      p.nitrogen,
      p.phosphorus,
      p.potassium,
      p.fertility,
      getPlotFertilityStatus(p),
      p.irigasi,
      p.pompa_air,
      p.sumber_energi_pompa,
      p.listrik,
      p.pembajak,
      p.status_verifikasi_ppl || 'pending',
      p.rekomendasi_ppl || '',
    ]
      .map(escapeCsvCell)
      .join(',')
  );

  const csvContent = [headers.join(','), ...rows].join('\n');
  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.setAttribute('download', filename);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

