import { useCallback } from 'react';
import { adminApi } from '../services/apiService';
import { usePolling } from './usePolling';

export function useMapMarkers(enabled = true) {
  const fetchFn = useCallback(() => adminApi.mapMarkers(), []);
  return usePolling(fetchFn, 15000, enabled);
}
