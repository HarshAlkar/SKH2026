import { openDB } from 'idb';

const DB_NAME = 'vr-pharmacy-offline';
const STORE = 'outbox';

async function db() {
  return openDB(DB_NAME, 1, {
    upgrade(database) {
      if (!database.objectStoreNames.contains(STORE)) {
        database.createObjectStore(STORE, { keyPath: 'client_id' });
      }
    },
  });
}

export async function enqueueAdjustment(item) {
  const database = await db();
  await database.put(STORE, {
    ...item,
    queued_at: new Date().toISOString(),
    retries: item.retries || 0,
  });
}

export async function listPending() {
  const database = await db();
  return database.getAll(STORE);
}

export async function removePending(clientId) {
  const database = await db();
  await database.delete(STORE, clientId);
}

export async function bumpRetry(clientId) {
  const database = await db();
  const row = await database.get(STORE, clientId);
  if (!row) return;
  row.retries = (row.retries || 0) + 1;
  await database.put(STORE, row);
}

export async function pendingCount() {
  const rows = await listPending();
  return rows.length;
}
