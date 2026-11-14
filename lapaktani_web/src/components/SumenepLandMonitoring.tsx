import React, { useEffect, useMemo, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet.markercluster';
import type { LandPlotRecord } from '../services/api';
import {
  escapeHtml,
  getPlotFertilityStatus,
  isPlotCritical,
  matchesPlotCategory,
} from '../utils/monitoringHelpers';

interface SumenepLandMonitoringProps {
  plots: LandPlotRecord[];
  isLoading: boolean;
  onRefresh: () => void;
  onInspectPlot: (plot: LandPlotRecord) => void;
}

type TileLayerKey = 'google_roadmap' | 'google_hybrid' | 'esri_street' | 'osm_street';

const FILTER_CHIPS: { key: string; label: string; icon: string; dotColor: string }[] = [
  { key: 'all', label: 'Semua Titik', icon: 'layers', dotColor: '#166534' },
  { key: 'padi', label: 'Padi', icon: 'grass', dotColor: '#16a34a' },
  { key: 'jagung', label: 'Jagung', icon: 'agriculture', dotColor: '#d97706' },
  { key: 'cabai', label: 'Cabai', icon: 'local_fire_department', dotColor: '#dc2626' },
  { key: 'tembakau', label: 'Tembakau', icon: 'eco', dotColor: '#0d9488' },
  { key: 'traktor', label: 'Traktor', icon: 'precision_manufacturing', dotColor: '#ea580c' },
  { key: 'sapi', label: 'Sapi', icon: 'pets', dotColor: '#854d0e' },
  { key: 'poktan', label: 'Poktan', icon: 'groups', dotColor: '#7c3aed' },
  { key: 'irigasi', label: 'Irigasi', icon: 'water', dotColor: '#0284c7' },
  { key: 'pompa', label: 'Pompa Air', icon: 'cyclone', dotColor: '#0891b2' },
  { key: 'listrik', label: 'Listrik', icon: 'bolt', dotColor: '#f59e0b' },
  { key: 'kritis', label: 'Titik Kritis', icon: 'warning', dotColor: '#e11d48' },
];

const PIN_SVGS: Record<string, string> = {
  padi: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2"><path d="M2 22 12 12"/><path d="M11.3 7.8a4 4 0 0 1 5.6-5.6 4 4 0 0 1-5.6 5.6Z"/><path d="M6.3 12.8a4 4 0 0 1 5.6-5.6 4 4 0 0 1-5.6 5.6Z"/></svg>',
  jagung: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2"><path d="M12 2a4 4 0 0 0-4 4v10a4 4 0 0 0 8 0V6a4 4 0 0 0-4-4Z"/><path d="M8 10h8"/></svg>',
  cabai: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2"><path d="M12 2c1.5 2 2 3.5 2 5 0 5-4 11-7 13-1-3 0-8 2-13 1-2.5 2-4 3-5Z"/></svg>',
  tembakau: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.2"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"/></svg>',
  irigasi: '<svg width="16" height="16" viewBox="0 0 24 24" fill="#fff"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>',
  listrik: '<svg width="16" height="16" viewBox="0 0 24 24" fill="#fff"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>',
  kritis: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.4"><path d="M12 9v4"/><path d="M12 17h.01"/><path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0Z"/></svg>',
};

const getEffectivePinType = (plot: LandPlotRecord, activeFilter: string): string => {
  if (activeFilter !== 'all') return activeFilter;
  if (isPlotCritical(plot)) return 'kritis';
  const kom = (plot.komoditas || '').toLowerCase();
  if (kom.includes('padi')) return 'padi';
  if (kom.includes('jagung')) return 'jagung';
  if (kom.includes('cabai') || kom.includes('cabe')) return 'cabai';
  if (kom.includes('tembakau')) return 'tembakau';
  return 'all';
};

const buildMarkerIcon = (pinType: string): L.DivIcon => {
  if (pinType === 'all') {
    return L.divIcon({
      className: 'custom-div-icon',
      html: '<div class="custom-marker-pin pin-default-green"><div class="dot-center"></div></div>',
      iconSize: [30, 30],
      iconAnchor: [15, 30],
      popupAnchor: [0, -26],
    });
  }
  const inner = PIN_SVGS[pinType] || '<div class="dot-center"></div>';
  return L.divIcon({
    className: 'custom-div-icon',
    html: `<div class="custom-marker-pin pin-${escapeHtml(pinType)}"><div class="pin-inner-icon">${inner}</div></div>`,
    iconSize: [34, 34],
    iconAnchor: [17, 34],
    popupAnchor: [0, -30],
  });
};

const buildPopupHtml = (plot: LandPlotRecord): string => {
  const status = getPlotFertilityStatus(plot);
  const statusBadge =
    status === 'kritis'
      ? '<span style="background:#ffe4e6;color:#be123c;padding:2px 7px;border-radius:999px;font-size:10px;font-weight:800;">KRITIS</span>'
      : status === 'optimal'
        ? '<span style="background:#dcfce7;color:#166534;padding:2px 7px;border-radius:999px;font-size:10px;font-weight:800;">OPTIMAL</span>'
        : '<span style="background:#fef3c7;color:#b45309;padding:2px 7px;border-radius:999px;font-size:10px;font-weight:800;">SEDANG</span>';

  const gmapsUrl =
    plot.latitude && plot.longitude
      ? `https://www.google.com/maps?q=${encodeURIComponent(`${plot.latitude},${plot.longitude}`)}`
      : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(`Desa ${plot.nama_desa || ''} Sumenep`)}`;

  return `
    <div style="min-width:270px;max-width:310px;font-family:'Plus Jakarta Sans',Inter,sans-serif;background:#fff;">
      <div style="background:#0D5136;color:#fff;padding:12px 15px;">
        <div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">
          <span style="font-size:10px;text-transform:uppercase;color:#a7f3d0;font-weight:700;letter-spacing:0.06em;">Precision Plot #${plot.id}</span>
          ${statusBadge}
        </div>
        <div style="font-size:15px;font-weight:800;margin-top:3px;">Desa ${escapeHtml(plot.nama_desa)}</div>
        <div style="font-size:11px;color:#d1fae5;">Poktan: ${escapeHtml(plot.kelompok_tani || 'Mandiri')}</div>
      </div>
      <div style="padding:12px 15px;">
        <table style="width:100%;font-size:11.5px;border-collapse:collapse;color:#131f18;">
          <tr style="border-bottom:1px solid #f1f5f9;">
            <td style="padding:4px 0;color:#64748b;">Komoditas / Luas</td>
            <td style="padding:4px 0;text-align:right;font-weight:700;text-transform:capitalize;">${escapeHtml(plot.komoditas)} · ${escapeHtml(plot.luas_lahan)}</td>
          </tr>
          <tr style="border-bottom:1px solid #f1f5f9;">
            <td style="padding:4px 0;color:#64748b;">pH / Kelembapan</td>
            <td style="padding:4px 0;text-align:right;font-weight:700;font-family:monospace;">pH ${escapeHtml(plot.ph)} · ${escapeHtml(plot.moisture)}%</td>
          </tr>
          <tr style="border-bottom:1px solid #f1f5f9;">
            <td style="padding:4px 0;color:#64748b;">NPK (mg/kg)</td>
            <td style="padding:4px 0;text-align:right;font-weight:700;font-family:monospace;">N:${escapeHtml(plot.nitrogen)} P:${escapeHtml(plot.phosphorus)} K:${escapeHtml(plot.potassium)}</td>
          </tr>
          <tr>
            <td style="padding:4px 0;color:#64748b;">Irigasi &amp; Pompa</td>
            <td style="padding:4px 0;text-align:right;font-weight:700;">Irigasi ${escapeHtml(plot.irigasi)} · Pompa ${escapeHtml(plot.pompa_air)}</td>
          </tr>
        </table>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-top:11px;padding-top:10px;border-top:1px solid #e2e8f0;">
          <button type="button" data-inspect-plot-id="${plot.id}" style="padding:7px 10px;background:#166534;color:#fff;border:none;border-radius:8px;font-size:11.5px;font-weight:700;cursor:pointer;">
            Inspeksi 8-in-1
          </button>
          <a href="${gmapsUrl}" target="_blank" rel="noreferrer" style="padding:7px 10px;background:#F8FAF9;color:#0D5136;border:1px solid #E2E8F0;border-radius:8px;font-size:11.5px;font-weight:700;text-decoration:none;text-align:center;">
            Google Maps ↗
          </a>
        </div>
      </div>
    </div>
  `;
};

export const SumenepLandMonitoring: React.FC<SumenepLandMonitoringProps> = ({
  plots,
  isLoading,
  onRefresh,
  onInspectPlot,
}) => {
  const [activeFilter, setActiveFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [layerType, setLayerType] = useState<TileLayerKey>('google_roadmap');

  const mapContainerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<L.Map | null>(null);
  const clusterGroupRef = useRef<L.MarkerClusterGroup | null>(null);
  const tileLayersRef = useRef<Record<TileLayerKey, L.TileLayer> | null>(null);
  const inspectCallbackRef = useRef(onInspectPlot);
  const plotsRef = useRef(plots);

  useEffect(() => {
    inspectCallbackRef.current = onInspectPlot;
  }, [onInspectPlot]);

  useEffect(() => {
    plotsRef.current = plots;
  }, [plots]);

  const filteredPlots = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    return plots.filter((plot) => {
      if (!matchesPlotCategory(plot, activeFilter)) return false;
      if (!q) return true;
      return [
        plot.nama_desa,
        plot.kecamatan,
        plot.komoditas,
        plot.varietas,
        plot.kelompok_tani,
        plot.sumber_air,
      ]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase().includes(q));
    });
  }, [plots, activeFilter, searchQuery]);

  // Initialize Leaflet Map + MarkerClusterGroup once (StrictMode safe)
  useEffect(() => {
    const container = mapContainerRef.current;
    if (!container) return;

    const map = L.map(container, {
      center: [-7.0105855, 113.8347767],
      zoom: 11,
      preferCanvas: true,
    });

    const layerGoogleRoadmap = L.tileLayer('https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', {
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; Google Maps',
      maxZoom: 20,
    });
    const layerGoogleHybrid = L.tileLayer('https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', {
      subdomains: ['mt0', 'mt1', 'mt2', 'mt3'],
      attribution: '&copy; Google Satellite',
      maxZoom: 20,
    });
    const layerEsriStreet = L.tileLayer(
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
      {
        attribution: '&copy; Esri',
        maxZoom: 19,
      }
    );
    const layerOsmStreet = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap',
      maxZoom: 19,
    });

    layerGoogleRoadmap.addTo(map);
    tileLayersRef.current = {
      google_roadmap: layerGoogleRoadmap,
      google_hybrid: layerGoogleHybrid,
      esri_street: layerEsriStreet,
      osm_street: layerOsmStreet,
    };

    const clusterGroup = L.markerClusterGroup({
      showCoverageOnHover: false,
      zoomToBoundsOnClick: true,
      spiderfyOnMaxZoom: true,
      removeOutsideVisibleBounds: true,
      maxClusterRadius: 45,
      disableClusteringAtZoom: 16,
      animate: true,
      animateAddingMarkers: false,
      iconCreateFunction: (cluster) => {
        const count = cluster.getChildCount();
        let sizeClass = 'cluster-small';
        let iconSize: [number, number] = [34, 34];
        if (count >= 50) {
          sizeClass = 'cluster-large';
          iconSize = [46, 46];
        } else if (count >= 10) {
          sizeClass = 'cluster-medium';
          iconSize = [40, 40];
        }
        return L.divIcon({
          html: `<div class="cluster-bubble ${sizeClass}"><span>${count}</span></div>`,
          className: 'custom-cluster-icon',
          iconSize,
          iconAnchor: [iconSize[0] / 2, iconSize[1] / 2],
        });
      },
    });

    map.addLayer(clusterGroup);

    map.on('popupopen', (e) => {
      const popupEl = e.popup.getElement();
      if (!popupEl) return;
      const btn = popupEl.querySelector<HTMLButtonElement>('[data-inspect-plot-id]');
      if (!btn) return;
      btn.onclick = () => {
        const id = Number(btn.getAttribute('data-inspect-plot-id'));
        const target = plotsRef.current.find((p) => p.id === id);
        if (target) inspectCallbackRef.current(target);
      };
    });

    mapRef.current = map;
    clusterGroupRef.current = clusterGroup;

    const timer = window.setTimeout(() => {
      map.invalidateSize();
    }, 150);

    return () => {
      window.clearTimeout(timer);
      clusterGroup.clearLayers();
      map.remove();
      mapRef.current = null;
      clusterGroupRef.current = null;
      tileLayersRef.current = null;
    };
  }, []);

  // Switch tile layers when layerType changes
  useEffect(() => {
    const map = mapRef.current;
    const layers = tileLayersRef.current;
    if (!map || !layers) return;
    (Object.keys(layers) as TileLayerKey[]).forEach((key) => {
      if (map.hasLayer(layers[key])) {
        map.removeLayer(layers[key]);
      }
    });
    layers[layerType].addTo(map);
  }, [layerType]);

  // Synchronize filtered markers onto MarkerClusterGroup
  useEffect(() => {
    const map = mapRef.current;
    const clusterGroup = clusterGroupRef.current;
    if (!map || !clusterGroup) return;

    clusterGroup.clearLayers();
    const markers: L.Marker[] = [];
    const boundsCoords: [number, number][] = [];

    filteredPlots.forEach((plot) => {
      const lat = Number(plot.latitude);
      const lng = Number(plot.longitude);
      if (!Number.isFinite(lat) || !Number.isFinite(lng) || (lat === 0 && lng === 0)) return;

      const pinType = getEffectivePinType(plot, activeFilter);
      const marker = L.marker([lat, lng], { icon: buildMarkerIcon(pinType) });
      marker.bindPopup(buildPopupHtml(plot));
      markers.push(marker);
      boundsCoords.push([lat, lng]);
    });

    if (markers.length > 0) {
      clusterGroup.addLayers(markers);
      map.fitBounds(boundsCoords, { padding: [45, 45], maxZoom: 14, animate: true });
    }
  }, [filteredPlots, activeFilter]);

  return (
    <div className="space-y-5">
      {/* Header & Breadcrumb Mirroring SmartAgri "Peta Lahan & Infrastruktur" */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="inline-flex items-center gap-2 text-[11.5px] font-bold uppercase tracking-wider text-[#166534]">
            <span className="w-2 h-2 rounded-full bg-[#22C55E] animate-pulse" />
            Kabupaten Sumenep &bull; Sensor 8-in-1 &amp; Precision Farming
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900 mt-0.5">
            Peta Lahan &amp; Infrastruktur
          </h1>
          <p className="text-[13px] text-gray-500">
            Filter cepat komoditas pertanian, alat pembajak lahan (traktor &amp; sapi), kelompok tani, irigasi, pompa air, listrik, dan titik kritis PPL.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <span className="px-3.5 py-2 rounded-xl bg-white border border-[#E2E8F0] text-[12.5px] font-extrabold text-[#0D5136] shadow-sm font-mono">
            Total: {filteredPlots.length} Titik
          </span>
          <button
            type="button"
            onClick={onRefresh}
            disabled={isLoading}
            className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#166534] hover:bg-[#0D5136] text-white text-[12.5px] font-bold shadow-sm transition-colors disabled:opacity-50"
          >
            <span className={`material-symbols-outlined text-[17px] ${isLoading ? 'animate-spin' : ''}`}>
              refresh
            </span>
            Sinkronkan
          </button>
        </div>
      </div>

      {/* Filter & Map Controls Toolbar */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] p-4 shadow-sm space-y-3.5">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-md">
            <span className="material-symbols-outlined text-gray-400 text-[18px] absolute left-3 top-1/2 -translate-y-1/2">
              search
            </span>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Cari desa (Mandala, Pakondang...), Poktan, atau komoditas..."
              className="w-full pl-9 pr-4 py-2 text-[13px] bg-[#F8FAF9] border border-[#E2E8F0] rounded-xl focus:outline-none focus:ring-2 focus:ring-[#22C55E]/30 focus:border-[#166534]"
            />
          </div>

          {/* Basemap Tile Switcher & Reset */}
          <div className="flex flex-wrap items-center gap-2">
            <label htmlFor="sumenepLayerSelect" className="text-[12px] font-bold text-gray-600">
              Peta Dasar:
            </label>
            <select
              id="sumenepLayerSelect"
              value={layerType}
              onChange={(e) => setLayerType(e.target.value as TileLayerKey)}
              className="px-3 py-2 rounded-xl bg-[#F8FAF9] border border-[#E2E8F0] text-[12.5px] font-bold text-gray-800 focus:outline-none focus:border-[#166534]"
            >
              <option value="google_roadmap">Google Maps</option>
              <option value="google_hybrid">Satellite Hybrid</option>
              <option value="osm_street">Street (OpenStreetMap)</option>
              <option value="esri_street">Esri World Street</option>
            </select>
            <button
              type="button"
              onClick={() => {
                setActiveFilter('all');
                setSearchQuery('');
              }}
              className="px-3 py-2 rounded-xl bg-[#F8FAF9] hover:bg-gray-100 border border-[#E2E8F0] text-[12px] font-bold text-gray-700 flex items-center gap-1"
              title="Reset ke Semua Titik"
            >
              <span className="material-symbols-outlined text-[16px]">restart_alt</span>
              Reset
            </button>
          </div>
        </div>

        {/* Multi-Chip Filter Bar */}
        <div className="flex flex-wrap gap-2 pt-1 border-t border-[#E2E8F0]">
          {FILTER_CHIPS.map((chip) => {
            const active = activeFilter === chip.key;
            return (
              <button
                key={chip.key}
                type="button"
                onClick={() => setActiveFilter(chip.key)}
                className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-[12px] font-bold transition-all ${
                  active
                    ? 'bg-[#0D5136] text-white shadow-sm'
                    : 'bg-[#F8FAF9] text-gray-700 border border-[#E2E8F0] hover:bg-emerald-50 hover:text-[#166534]'
                }`}
              >
                <span
                  className="w-2 h-2 rounded-full shrink-0"
                  style={{ backgroundColor: active ? '#22C55E' : chip.dotColor }}
                />
                <span className="material-symbols-outlined text-[15px]">{chip.icon}</span>
                {chip.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Clustered Leaflet Map Card */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] p-3 shadow-sm">
        <div className="relative lapaktani-leaflet-map">
          <div
            ref={mapContainerRef}
            className="w-full h-[520px] lg:h-[600px] rounded-xl border border-[#E2E8F0] z-10 bg-[#F8FAF9]"
          />
          {filteredPlots.length === 0 && (
            <div className="absolute inset-0 z-20 flex items-center justify-center pointer-events-none">
              <div className="bg-white/95 backdrop-blur-sm border border-[#E2E8F0] rounded-2xl px-6 py-4 shadow-lg text-center">
                <p className="text-[13.5px] font-bold text-gray-800">
                  Tidak ada titik koordinat yang sesuai dengan filter saat ini.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Interactive Plot Directory Strip for Fast Inspection */}
      <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-sm overflow-hidden">
        <div className="px-5 py-3.5 border-b border-[#E2E8F0] flex flex-wrap items-center justify-between gap-2 bg-[#F8FAF9]">
          <div>
            <h2 className="text-[14px] font-extrabold text-gray-900">
              Direktori Titik Terfilter ({filteredPlots.length})
            </h2>
            <p className="text-[11.5px] text-gray-500">
              Klik baris lahan untuk membuka drawer inspektor sensor 8-in-1 &amp; form rekomendasi PPL
            </p>
          </div>
          <div className="flex items-center gap-3 text-[11px] font-bold">
            <span className="inline-flex items-center gap-1 text-[#166534]">
              <span className="w-2.5 h-2.5 rounded-full bg-[#22C55E]" /> Optimal
            </span>
            <span className="inline-flex items-center gap-1 text-amber-700">
              <span className="w-2.5 h-2.5 rounded-full bg-[#F59E0B]" /> Sedang
            </span>
            <span className="inline-flex items-center gap-1 text-rose-700">
              <span className="w-2.5 h-2.5 rounded-full bg-rose-500" /> Kritis
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3 p-4">
          {filteredPlots.map((plot) => {
            const status = getPlotFertilityStatus(plot);
            return (
              <button
                key={plot.id}
                type="button"
                onClick={() => onInspectPlot(plot)}
                className="text-left p-4 rounded-xl bg-[#F8FAF9] hover:bg-emerald-50/60 border border-[#E2E8F0] hover:border-[#22C55E] transition-all space-y-2"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <div className="font-extrabold text-[14px] text-gray-900">
                      Desa {plot.nama_desa}
                      {plot.kecamatan ? `, ${plot.kecamatan}` : ''}
                    </div>
                    <div className="text-[11.5px] text-gray-500">
                      {plot.kelompok_tani || 'Mandiri'} ·{' '}
                      <span className="capitalize font-semibold text-[#166534]">
                        {plot.komoditas}
                      </span>
                    </div>
                  </div>
                  <span
                    className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase ${
                      status === 'kritis'
                        ? 'bg-rose-100 text-rose-700'
                        : status === 'optimal'
                          ? 'bg-emerald-100 text-[#166534]'
                          : 'bg-amber-100 text-amber-800'
                    }`}
                  >
                    {status}
                  </span>
                </div>
                <div className="flex items-center justify-between text-[11.5px] font-mono font-bold text-gray-700 pt-2 border-t border-[#E2E8F0]">
                  <span>pH {plot.ph}</span>
                  <span>Lembab {plot.moisture}%</span>
                  <span>Subur {plot.fertility}/100</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};
