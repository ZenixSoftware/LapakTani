import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  String _activeFilter = 'ALL'; // ALL | DIRECT | ORDER
  List<ChatConversationModel> _conversations = [];
  List<ChatParticipant> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _chatService.fetchConversations(),
        _chatService.fetchContacts(),
      ]);
      if (!mounted) return;
      setState(() {
        _conversations = results[0] as List<ChatConversationModel>;
        _contacts = results[1] as List<ChatParticipant>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openChatWithParticipant(ChatParticipant participant) async {
    try {
      final conv = await _chatService.openDirectConversation(
        targetUserId: participant.id,
        title: 'DM — ${participant.fullName}',
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conv)),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka obrolan: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openQuickRoleChat(String targetRole, String title) async {
    try {
      final conv = await _chatService.openDirectConversation(
        targetRole: targetRole,
        title: title,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatRoomScreen(conversation: conv)),
      );
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kontak belum tersedia: $e'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  List<ChatConversationModel> get _filteredConversations {
    if (_activeFilter == 'DIRECT') {
      return _conversations.where((c) => !c.isOrderChat).toList();
    }
    if (_activeFilter == 'ORDER') {
      return _conversations.where((c) => c.isOrderChat).toList();
    }
    return _conversations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesan & Konsultasi Terpadu',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              'Direct Message Komunitas, PPL & Pesanan Poktan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(LucideIcons.refreshCw, size: 19),
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Akses Cepat Konsultasi & Koordinasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickRoleChip(
                          icon: LucideIcons.stethoscope,
                          label: 'Chat Penyuluh BPP',
                          color: AppColors.primaryDark,
                          onTap: () => _openQuickRoleChat(
                            'penyuluh',
                            'Konsultasi Penyuluh BPP Sumenep',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuickRoleChip(
                          icon: LucideIcons.store,
                          label: 'Chat Ketua Poktan',
                          color: AppColors.accent,
                          onTap: () => _openQuickRoleChat(
                            'admin',
                            'Koordinasi Ketua Poktan',
                          ),
                        ),
                        ..._contacts.take(6).map(
                              (c) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _QuickRoleChip(
                                  icon: LucideIcons.userCheck,
                                  label: '${c.fullName} (${c.roleLabel})',
                                  color: AppColors.info,
                                  onTap: () => _openChatWithParticipant(c),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildFilterChip('ALL', 'Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('DIRECT', 'DM Sosial / PPL'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ORDER', 'Pesanan'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_filteredConversations.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.messageSquare,
                            size: 36,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada percakapan di kategori ini',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pilih tombol Akses Cepat di atas atau chat langsung dari pesanan & forum edukasi.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._filteredConversations.map(_buildConversationTile),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String code, String label) {
    final selected = _activeFilter == code;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.outline,
      ),
      onSelected: (_) => setState(() => _activeFilter = code),
    );
  }

  Widget _buildConversationTile(ChatConversationModel conv) {
    final other = conv.otherParticipant;
    final last = conv.lastMessage;
    final timeStr = (last?.createdAt ?? conv.updatedAt) != null
        ? DateFormat('dd/MM HH:mm')
            .format((last?.createdAt ?? conv.updatedAt)!.toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
        boxShadow: AppColors.softShadow,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: conv.isOrderChat
              ? AppColors.warningSoft
              : AppColors.surfaceSoft,
          child: Icon(
            conv.isOrderChat
                ? LucideIcons.shoppingBag
                : LucideIcons.messageCircle,
            color: conv.isOrderChat ? AppColors.accent : AppColors.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conv.displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (timeStr.isNotEmpty)
              Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Row(
              children: [
                if (other != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      other.roleLabel,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                if (conv.isOrderChat)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ORDER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    last?.body ?? 'Ketuk untuk mulai menulis pesan...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (conv.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${conv.unreadCount}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(conversation: conv),
            ),
          );
          _loadData();
        },
      ),
    );
  }
}

class _QuickRoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickRoleChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
