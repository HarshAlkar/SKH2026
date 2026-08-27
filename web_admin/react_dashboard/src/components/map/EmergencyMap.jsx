import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const defaultCenter = [20.5937, 78.9629];

const emergencyIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

const visitIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-blue.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

const ashaIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

const pharmacyIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-orange.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

function FitBounds({ markers }) {
  const map = useMap();
  useEffect(() => {
    if (!markers?.length) return;
    const bounds = L.latLngBounds(markers.map((m) => [m.lat, m.lng]));
    map.fitBounds(bounds, { padding: [24, 24], maxZoom: 14 });
  }, [markers, map]);
  return null;
}

function PanTo({ target }) {
  const map = useMap();
  useEffect(() => {
    if (target?.lat != null && target?.lng != null) {
      map.setView([target.lat, target.lng], 15, { animate: true });
    }
  }, [target, map]);
  return null;
}

export default function EmergencyMap({ data, height = 280, focusTarget = null, onMarkerClick }) {
  const emergencies = data?.emergencies || [];
  const visits = data?.visits || [];
  const asha = data?.asha_workers || [];
  const pharmacies = data?.pharmacies || [];
  const all = [...emergencies, ...visits, ...asha, ...pharmacies];
  const center = all.length ? [all[0].lat, all[0].lng] : defaultCenter;

  return (
    <div className="rounded-2xl overflow-hidden border border-slate-200 shadow-sm" style={{ height }}>
      <MapContainer center={center} zoom={6} scrollWheelZoom className="h-full w-full">
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {all.length ? <FitBounds markers={all} /> : null}
        {focusTarget ? <PanTo target={focusTarget} /> : null}
        {emergencies.map((m) => (
          <Marker
            key={`e-${m.id}`}
            position={[m.lat, m.lng]}
            icon={emergencyIcon}
            eventHandlers={{ click: () => onMarkerClick?.(m) }}
          >
            <Popup>
              <strong>{m.label}</strong>
              <br />
              {m.alert_type}
              <br />
              {m.village}
            </Popup>
          </Marker>
        ))}
        {visits.map((m) => (
          <Marker key={`v-${m.id}`} position={[m.lat, m.lng]} icon={visitIcon}>
            <Popup>
              <strong>{m.label}</strong>
              <br />
              Visit · {m.status}
            </Popup>
          </Marker>
        ))}
        {asha.map((m) => (
          <Marker key={`a-${m.id}`} position={[m.lat, m.lng]} icon={ashaIcon}>
            <Popup>
              <strong>{m.label}</strong>
              <br />
              ASHA · {m.village}
            </Popup>
          </Marker>
        ))}
        {pharmacies.map((m) => (
          <Marker
            key={`p-${m.id}`}
            position={[m.lat, m.lng]}
            icon={pharmacyIcon}
            eventHandlers={{ click: () => onMarkerClick?.(m) }}
          >
            <Popup>
              <strong>{m.label}</strong>
              <br />
              {m.facility_type} · {m.village}
              <br />
              Low: {m.low_stock ?? 0} · Out: {m.out_of_stock ?? 0} · Exp: {m.expiring_soon ?? 0}
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
