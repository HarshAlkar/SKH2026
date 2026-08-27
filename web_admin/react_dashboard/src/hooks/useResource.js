import { useCallback, useEffect, useState } from 'react';

export function useResource(loader) {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const reload = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const data = await loader();
      setRows(Array.isArray(data) ? data : data?.results || []);
    } catch (e) {
      setError(e.message);
      setRows([]);
    } finally {
      setLoading(false);
    }
  }, [loader]);

  useEffect(() => {
    reload();
  }, [reload]);

  return { rows, setRows, loading, error, reload };
}
