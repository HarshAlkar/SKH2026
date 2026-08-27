import { useCallback, useEffect, useState } from 'react';
import { adminApi } from '../../services/apiService';
import { useResource } from '../../hooks/useResource';
import { PageHeader, ErrorBanner } from '../../components/ui/PageHeader';
import LiveBadge from '../../components/ui/LiveBadge';
import AvatarInitials from '../../components/ui/AvatarInitials';
import { DataTable } from '../../components/ui/DataTable';
import { Badge } from '../../components/ui/Badge';
import { toast } from '../../components/ui/Toast';

export default function ChatPage() {
  const fetchList = useCallback(() => adminApi.chats(), []);
  const { rows, loading, error, reload } = useResource(fetchList);
  const [thread, setThread] = useState(null);
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    const id = setInterval(reload, 15000);
    return () => clearInterval(id);
  }, [reload]);

  useEffect(() => {
    if (!thread) return undefined;
    const refresh = async () => {
      try {
        const msgs = await adminApi.chatMessages(thread.id);
        setMessages(msgs);
      } catch {
        /* ignore polling errors */
      }
    };
    const id = setInterval(refresh, 15000);
    return () => clearInterval(id);
  }, [thread]);

  const open = async (row) => {
    try {
      const msgs = await adminApi.chatMessages(row.id);
      setThread(row);
      setMessages(msgs);
    } catch (e) {
      toast(e.message, 'error');
    }
  };

  return (
    <div>
      <PageHeader title="Chat Moderation" subtitle="Read-only thread oversight for care teams." actions={<LiveBadge />} />
      <ErrorBanner error={error} onRetry={reload} />
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div className="bg-white rounded-2xl border shadow-sm overflow-hidden">
          <div className="px-4 py-3 border-b font-semibold text-sm">Threads</div>
          <DataTable
            loading={loading}
            rows={rows}
            empty="No chat threads."
            columns={[
              {
                key: 'users',
                header: 'Participants',
                render: (r) => (
                  <div className="flex items-center gap-2">
                    <AvatarInitials name={r.user_a_name} size="sm" />
                    <span className="text-muted text-xs">↔</span>
                    <AvatarInitials name={r.user_b_name} size="sm" />
                  </div>
                ),
              },
              {
                key: 'roles',
                header: 'Roles',
                render: (r) => (
                  <div className="flex gap-1">
                    <Badge>{r.user_a_role}</Badge>
                    <Badge>{r.user_b_role}</Badge>
                  </div>
                ),
              },
              {
                key: 'last_message',
                header: 'Last message',
                render: (r) => (
                  <span className="text-sm line-clamp-1 max-w-[200px]">{r.last_message?.text || '—'}</span>
                ),
              },
              {
                key: 'a',
                header: '',
                render: (r) => (
                  <button type="button" className="text-xs font-semibold text-primary" onClick={() => open(r)}>
                    Open
                  </button>
                ),
              },
            ]}
          />
        </div>
        <div className="bg-white rounded-2xl border shadow-sm min-h-[400px] flex flex-col">
          <div className="px-4 py-3 border-b font-semibold text-sm">
            {thread ? `${thread.user_a_name} ↔ ${thread.user_b_name}` : 'Select a thread'}
          </div>
          <div className="flex-1 p-4 space-y-3 overflow-y-auto max-h-[60vh]">
            {!thread ? (
              <p className="text-sm text-muted text-center py-12">Choose a thread to view messages.</p>
            ) : messages.length === 0 ? (
              <p className="text-sm text-muted text-center py-12">No messages.</p>
            ) : (
              messages.map((m) => (
                <div key={m.id} className="rounded-xl bg-slate-50 px-3 py-2">
                  <div className="flex items-center gap-2 mb-1">
                    <AvatarInitials name={m.sender_name} size="sm" />
                    <p className="text-xs font-semibold text-primary">{m.sender_name}</p>
                  </div>
                  <p className="text-sm">{m.text}</p>
                  <p className="text-[11px] text-muted mt-1">{new Date(m.created_at).toLocaleString()}</p>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
