import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { stockApi } from '../services/apiService';
import { PageHeader, ErrorBanner } from '../components/ui/PageHeader';

const defaultCenter = [19.9975, 73.7898];

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
    map.fitBounds(bounds, { padding: [32, 32], maxZoom: 13 });
  }, [markers, map]);
  return null;
}

export default function MapPage() {
  const [markers, setMarkers] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        setMarkers(await stockApi.map());
      } catch (e) {
        setError(e.message);
      }
    })();
  }, []);

  const center = markers.length ? [markers[0].lat, markers[0].lng] : defaultCenter;

  return (
    <div>
      <PageHeader title="Facility Map" subtitle="Pharmacies and PHCs colored by stock health" />
      <ErrorBanner error={error} />
      <div className="rounded-2xl overflow-hidden border border-slate-200 shadow-sm" style={{ height: 480 }}>
        <MapContainer center={center} zoom={10} scrollWheelZoom className="h-full w-full">
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          {markers.length ? <FitBounds markers={markers} /> : null}
          {markers.map((m) => (
            <Marker key={m.id} position={[m.lat, m.lng]} icon={pharmacyIcon}>
              <Popup>
                <strong>{m.label}</strong>
                <br />
                {m.village} · {m.facility_type}
                <br />
                Low: {m.low_stock} · Out: {m.out_of_stock} · Expiring: {m.expiring_soon}
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>
    </div>
  );
}
