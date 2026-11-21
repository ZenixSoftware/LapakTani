import React, { useCallback, useEffect, useMemo, useState } from 'react';
import {
  fetchWebChatContacts,
  fetchWebChatConversations,
  fetchWebChatMessages,
  openWebDirectConversation,
  sendWebChatMessage,
  type AuthUser,
  type WebChatConversation,
  type WebChatMessage,
  type WebChatParticipant,
} from '../services/api';

interface WebDirectMessageDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  currentUser?: AuthUser | null;
  onShowToast?: (message: string, type?: 'success' | 'error' | 'info') => void;
}

const ROLE_LABELS: Record<string, string> = {
  superadmin: 'Super Admin',
  dinas: 'Dinas Pertanian',
  penyuluh: 'Penyuluh BPP',
  admin: 'Admin Toko / Koperasi',
  petani: 'Petani Desa',
  pembeli: 'Pembeli',
};

export const WebDirectMessageDrawer: React.FC<WebDirectMessageDrawerProps> = ({
  isOpen,
  onClose,
  currentUser,
  onShowToast,
}) => {
  const isDinas =
    currentUser?.role?.toLowerCase() === 'dinas' || currentUser?.role_id === 5;
  const isSuperAdmin =
    currentUser?.role?.toLowerCase() === 'superadmin' || currentUser?.role_id === 6;

  const [conversations, setConversations] = useState<WebChatConversation[]>([]);
  const [contacts, setContacts] = useState<WebChatParticipant[]>([]);
  const [activeConv, setActiveConv] = useState<WebChatConversation | null>(null);
  const [messages, setMessages] = useState<WebChatMessage[]>([]);
  const [draft, setDraft] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [isLoadingMessages, setIsLoadingMessages] = useState<boolean>(false);
  const [isSending, setIsSending] = useState<boolean>(false);

  const loadInbox = useCallback(async () => {
    if (!currentUser) return;
    setIsLoading(true);
    try {
      const [convs, ctcs] = await Promise.all([
        fetchWebChatConversations(),
        fetchWebChatContacts(),
      ]);
      const directOnly = convs.filter((c) => c.type !== 'ORDER');
      setConversations(directOnly);
      setContacts(ctcs);
      setActiveConv((prev) => {
        if (prev && directOnly.some((c) => c.id === prev.id)) {
          return directOnly.find((c) => c.id === prev.id) || prev;
        }
        return directOnly[0] || null;
      });
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal memuat kotak masuk DM.',
        'error'
      );
    } finally {
      setIsLoading(false);
    }
  }, [currentUser, onShowToast]);

  const loadMessages = useCallback(
    async (convId: string) => {
      setIsLoadingMessages(true);
      try {
        const list = await fetchWebChatMessages(convId);
        setMessages(list);
      } catch (err) {
        onShowToast?.(
          err instanceof Error ? err.message : 'Gagal memuat riwayat pesan.',
          'error'
        );
      } finally {
        setIsLoadingMessages(false);
      }
    },
    [onShowToast]
  );

  useEffect(() => {
    if (isOpen && currentUser) {
      void loadInbox();
    }
  }, [isOpen, currentUser, loadInbox]);

  useEffect(() => {
    if (isOpen && activeConv) {
      void loadMessages(activeConv.id);
    } else {
      setMessages([]);
    }
  }, [isOpen, activeConv, loadMessages]);

  const roleFilteredContacts = useMemo(() => {
    if (isSuperAdmin) {
      return contacts;
    }
    if (isDinas) {
      return contacts.filter((c) => ['penyuluh', 'superadmin'].includes(c.role) || c.role_id === 2 || c.role_id === 6);
    }
    return contacts.filter((c) => ['dinas', 'penyuluh', 'petani', 'admin', 'superadmin'].includes(c.role));
  }, [contacts, isDinas, isSuperAdmin]);

  const handleOpenContact = async (payload: {
    target_user_id?: string;
    target_role?: string;
    title: string;
  }) => {
    try {
      const conv = await openWebDirectConversation(payload);
      await loadInbox();
      setActiveConv(conv);
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal membuka ruang obrolan DM.',
        'error'
      );
    }
  };

  const handleSend = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!activeConv || !draft.trim() || isSending) return;
    setIsSending(true);
    try {
      const created = await sendWebChatMessage(activeConv.id, draft.trim());
      setMessages((prev) => [...prev, created]);
      setDraft('');
      await loadInbox();
    } catch (err) {
      onShowToast?.(
        err instanceof Error ? err.message : 'Gagal mengirim pesan DM.',
        'error'
      );
    } finally {
      setIsSending(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40 backdrop-blur-[1px]">
      <div className="w-full max-w-3xl bg-white h-full shadow-2xl border-l border-lt-border flex flex-col">
        {/* Header */}
        <div className="px-5 py-4 bg-lt-surface-card border-b border-lt-border border-l-4 border-l-lt-primary flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-lt-primary-tint text-lt-primary flex items-center justify-center">
              <span className="material-symbols-outlined text-[20px]">forum</span>
            </div>
            <div>
              <h2 className="text-[15px] font-extrabold text-lt-neutral leading-tight">
                Pesan Langsung (DM) 6-Role Terpadu
              </h2>
              <p className="text-[11px] text-lt-neutral-muted">
                {isSuperAdmin
                  ? 'Komando langsung Super Admin ↔ Dinas Pertanian, Penyuluh BPP, & Admin Toko'
                  : isDinas
                    ? 'Koordinasi langsung Dinas Pertanian ↔ Penyuluh BPP Kab. Sumenep & Super Admin'
                    : 'Koordinasi langsung Penyuluh ↔ Dinas Pertanian, Petani Desa, & Admin Toko'}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => void loadInbox()}
              className="p-2 rounded-lg bg-lt-surface-canvas hover:bg-lt-primary-tint text-lt-neutral border border-lt-border transition-colors"
              title="Muat Ulang"
            >
              <span className="material-symbols-outlined text-[18px]">refresh</span>
            </button>
            <button
              type="button"
              onClick={onClose}
              className="p-2 rounded-lg bg-lt-surface-canvas hover:bg-lt-error-tint text-lt-neutral-muted hover:text-lt-error border border-lt-border transition-colors"
              title="Tutup"
            >
              <span className="material-symbols-outlined text-[18px]">close</span>
            </button>
          </div>
        </div>

        {/* Quick Contacts Strip */}
        <div className="px-5 py-3 bg-lt-surface-canvas border-b border-lt-border space-y-2">
          <div className="text-[10.5px] font-extrabold uppercase tracking-wider text-lt-primary">
            Akses Cepat Kontak Koordinasi
          </div>
          <div className="flex flex-wrap gap-2">
            {isSuperAdmin ? (
              <>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'dinas',
                      title: 'Tata Kelola Super Admin ↔ Dinas Pertanian',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-lt-tertiary text-lt-neutral text-[11.5px] font-bold flex items-center gap-1.5 hover:bg-lt-tertiary-tint border border-lt-tertiary-border transition-colors"
                >
                  <span className="material-symbols-outlined text-[15px]">account_balance</span>
                  DM Dinas Pertanian
                </button>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'penyuluh',
                      title: 'Koordinasi Super Admin ↔ Penyuluh BPP',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-lt-primary text-white text-[11.5px] font-bold flex items-center gap-1.5 hover:bg-lt-primary-dark"
                >
                  <span className="material-symbols-outlined text-[15px]">agriculture</span>
                  DM Penyuluh BPP
                </button>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'admin',
                      title: 'Audit Super Admin ↔ Admin Toko',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-white border border-lt-border text-lt-neutral text-[11.5px] font-bold flex items-center gap-1.5 hover:border-lt-primary"
                >
                  <span className="material-symbols-outlined text-[15px]">storefront</span>
                  DM Admin Toko
                </button>
              </>
            ) : isDinas ? (
              <button
                type="button"
                onClick={() =>
                  void handleOpenContact({
                    target_role: 'penyuluh',
                    title: 'Koordinasi Dinas ↔ Penyuluh BPP',
                  })
                }
                className="px-3 py-1.5 rounded-xl bg-lt-primary text-white text-[11.5px] font-bold flex items-center gap-1.5 hover:bg-lt-primary-dark"
              >
                <span className="material-symbols-outlined text-[15px]">agriculture</span>
                DM Penyuluh BPP
              </button>
            ) : (
              <>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'dinas',
                      title: 'Eskalasi Penyuluh ↔ Dinas Pertanian',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-lt-tertiary text-lt-neutral text-[11.5px] font-bold flex items-center gap-1.5 hover:bg-lt-tertiary-tint border border-lt-tertiary-border transition-colors"
                >
                  <span className="material-symbols-outlined text-[15px]">account_balance</span>
                  DM Dinas Pertanian
                </button>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'petani',
                      title: 'Pendampingan Penyuluh ↔ Petani Desa',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-lt-primary text-white text-[11.5px] font-bold flex items-center gap-1.5 hover:bg-lt-primary-dark"
                >
                  <span className="material-symbols-outlined text-[15px]">person</span>
                  DM Petani Desa
                </button>
                <button
                  type="button"
                  onClick={() =>
                    void handleOpenContact({
                      target_role: 'admin',
                      title: 'Koordinasi Penyuluh ↔ Admin Toko',
                    })
                  }
                  className="px-3 py-1.5 rounded-xl bg-white border border-lt-border text-lt-neutral text-[11.5px] font-bold flex items-center gap-1.5 hover:border-lt-primary"
                >
                  <span className="material-symbols-outlined text-[15px]">storefront</span>
                  DM Admin Toko
                </button>
              </>
            )}

            {roleFilteredContacts.slice(0, 6).map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() =>
                  void handleOpenContact({
                    target_user_id: c.id,
                    title: `DM — ${c.full_name}`,
                  })
                }
                className="px-2.5 py-1.5 rounded-xl bg-white border border-lt-border hover:border-lt-primary text-[11px] font-semibold text-lt-neutral flex items-center gap-1.5"
              >
                <span className="w-2 h-2 rounded-full bg-lt-primary"></span>
                <span>{c.full_name}</span>
                <span className="text-[10px] text-lt-neutral-subtle">
                  ({ROLE_LABELS[c.role] || c.role}
                  {c.village_name ? ` · ${c.village_name}` : ''})
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Body Split: Conversation List + Thread */}
        <div className="flex-1 grid grid-cols-1 md:grid-cols-12 min-h-0">
          {/* Conversations sidebar */}
          <div className="md:col-span-5 border-r border-lt-border overflow-y-auto divide-y divide-lt-surface-canvas">
            {isLoading ? (
              <div className="p-6 text-center text-[12px] text-lt-neutral-muted">Memuat daftar DM...</div>
            ) : conversations.length === 0 ? (
              <div className="p-6 text-center text-[12px] text-lt-neutral-muted">
                Belum ada riwayat DM. Pilih salah satu kontak di atas untuk memulai obrolan.
              </div>
            ) : (
              conversations.map((conv) => {
                const selected = activeConv?.id === conv.id;
                const other = conv.other_participant;
                return (
                  <button
                    key={conv.id}
                    type="button"
                    onClick={() => setActiveConv(conv)}
                    className={`w-full text-left p-3.5 transition-colors ${
                      selected ? 'bg-lt-primary-tint border-l-4 border-l-lt-primary' : 'hover:bg-lt-surface-canvas'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-[12.5px] font-extrabold text-lt-neutral truncate">
                        {other?.full_name || conv.title || 'Obrolan Langsung'}
                      </span>
                      {conv.unread_count > 0 && (
                        <span className="px-1.5 py-0.5 rounded-full bg-lt-primary text-white text-[10px] font-extrabold">
                          {conv.unread_count}
                        </span>
                      )}
                    </div>
                    {other && (
                      <div className="text-[10.5px] font-bold text-lt-primary mt-0.5">
                        {ROLE_LABELS[other.role] || other.role}
                      </div>
                    )}
                    <p className="text-[11.5px] text-lt-neutral-muted truncate mt-1">
                      {conv.last_message?.body || 'Ketuk untuk membaca pesan...'}
                    </p>
                  </button>
                );
              })
            )}
          </div>

          {/* Active Thread */}
          <div className="md:col-span-7 flex flex-col min-h-0 bg-lt-surface-canvas">
            {!activeConv ? (
              <div className="flex-1 flex items-center justify-center p-6 text-center text-[12.5px] text-lt-neutral-muted">
                Pilih percakapan atau tombol kontak cepat di atas.
              </div>
            ) : (
              <>
                <div className="px-4 py-3 bg-white border-b border-lt-border">
                  <div className="text-[13px] font-extrabold text-lt-neutral">
                    {activeConv.other_participant?.full_name || activeConv.title}
                  </div>
                  <div className="text-[11px] text-lt-neutral-muted">
                    {activeConv.other_participant
                      ? `${ROLE_LABELS[activeConv.other_participant.role] || activeConv.other_participant.role} · ${activeConv.other_participant.email}`
                      : 'Ruang Koordinasi LapakTani'}
                  </div>
                </div>

                <div className="flex-1 overflow-y-auto p-4 space-y-2.5">
                  {isLoadingMessages ? (
                    <div className="text-center text-[12px] text-lt-neutral-muted py-8">
                      Memuat pesan...
                    </div>
                  ) : messages.length === 0 ? (
                    <div className="text-center text-[12px] text-lt-neutral-muted py-8">
                      Belum ada pesan. Mulai diskusi di bawah ini.
                    </div>
                  ) : (
                    messages.map((m) => {
                      const isMe = m.sender_id === currentUser?.id;
                      const isAdvisory = m.message_type === 'ADVISORY_CARD';
                      return (
                        <div
                          key={m.id}
                          className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}
                        >
                          <div
                            className={`max-w-[85%] rounded-2xl px-3.5 py-2.5 text-[12.5px] shadow-sm ${
                              isAdvisory
                                ? 'bg-lt-tertiary-tint border border-lt-tertiary-border text-lt-tertiary-text'
                                : isMe
                                  ? 'bg-lt-primary text-white'
                                  : 'bg-white border border-lt-border text-lt-neutral'
                            }`}
                          >
                            {!isMe && (
                              <div className="text-[10.5px] font-extrabold text-lt-primary mb-0.5">
                                {m.sender_name}
                              </div>
                            )}
                            <div className="whitespace-pre-wrap leading-relaxed">{m.body}</div>
                            <div
                              className={`text-[9.5px] mt-1 ${
                                isMe && !isAdvisory ? 'text-lt-primary-tint text-right' : 'text-lt-neutral-subtle'
                              }`}
                            >
                              {new Date(m.created_at).toLocaleTimeString('id-ID', {
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </div>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>

                <form
                  onSubmit={handleSend}
                  className="p-3 bg-white border-t border-lt-border flex items-center gap-2"
                >
                  <input
                    type="text"
                    value={draft}
                    onChange={(e) => setDraft(e.target.value)}
                    placeholder="Tulis pesan DM koordinasi..."
                    className="flex-1 px-3.5 py-2 rounded-xl bg-lt-surface-canvas border border-lt-border text-[12.5px] focus:bg-white focus:border-lt-primary outline-none"
                  />
                  <button
                    type="submit"
                    disabled={isSending || !draft.trim()}
                    className="px-4 py-2 rounded-xl bg-lt-primary hover:bg-lt-primary-dark text-white text-[12.5px] font-bold disabled:opacity-50"
                  >
                    {isSending ? 'Kirim...' : 'Kirim'}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
