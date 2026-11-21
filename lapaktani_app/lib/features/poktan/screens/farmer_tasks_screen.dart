import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_soft_card.dart';
import '../models/production_task_model.dart';
import '../services/poktan_service.dart';

class FarmerTasksScreen extends StatefulWidget {
  final bool showBackButton;

  const FarmerTasksScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<FarmerTasksScreen> createState() => _FarmerTasksScreenState();
}

class _FarmerTasksScreenState extends State<FarmerTasksScreen> {
  final PoktanService _poktanService = PoktanService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'id_ID');

  bool _isLoading = true;
  List<ProductionTaskModel> _tasks = [];
  List<PoktanNotificationModel> _notifications = [];
  bool _showNotifBanner = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final data = await _poktanService.fetchMyTasks();
    if (!mounted) return;
    setState(() {
      _tasks = data['tasks'] as List<ProductionTaskModel>;
      _notifications = data['notifications'] as List<PoktanNotificationModel>;
      _isLoading = false;
    });
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'planting':
        bg = AppColors.secondaryTint;
        fg = AppColors.secondary;
        label = 'Masa Tanam';
        break;
      case 'harvesting':
        bg = AppColors.tertiaryTint;
        fg = AppColors.tertiaryText;
        label = 'Masa Panen';
        break;
      case 'delivered':
        bg = AppColors.primaryTint;
        fg = AppColors.primary;
        label = 'Terkirim';
        break;
      case 'cancelled':
        bg = AppColors.errorTint;
        fg = AppColors.error;
        label = 'Dibatalkan';
        break;
      case 'pending':
      default:
        bg = AppColors.surfaceCanvas;
        fg = AppColors.neutralMuted;
        label = 'Persiapan Lahan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.neutral, size: 22),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Tugas Produksi Panen',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.neutral,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: AppColors.neutralMuted, size: 20),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadTasks,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notification Alert Banner
                  if (_showNotifBanner && _notifications.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(LucideIcons.bellRing, color: AppColors.primaryDark, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _notifications.first.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => setState(() => _showNotifBanner = false),
                                      child: const Icon(LucideIcons.x, size: 16, color: AppColors.primaryDark),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _notifications.first.message,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Header intro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Alokasi Kuota Tanam',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutral,
                        ),
                      ),
                      Text(
                        '${_tasks.length} Tugas',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutralMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tasks List
                  if (_tasks.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceCanvas,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.clipboardCheck, color: AppColors.neutralSubtle, size: 32),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada tugas alokasi panen',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutralMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tugas akan muncul saat pengurus Poktan membagikan kuota kontrak B2B.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.neutralSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    ..._tasks.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomSoftCard(
                          padding: const EdgeInsets.all(16),
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTint,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(LucideIcons.sprout, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.commodityName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.neutral,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Kontrak: ${task.buyerName}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.neutralMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(task.taskStatus),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Kuota target & deadline box
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCanvas,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Target Kuota Anda',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AppColors.neutralMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_currencyFormat.format(task.allocatedKg)} kg',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 32,
                                      width: 1,
                                      color: AppColors.border,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tenggat Panen',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: AppColors.neutralMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            task.harvestDeadline ?? task.contractDeadline ?? 'Sesuai Kontrak',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.neutral,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Details row
                              Row(
                                children: [
                                  const Icon(LucideIcons.calendarDays, size: 14, color: AppColors.neutralSubtle),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tanam: ${task.plantingDeadline ?? 'Segera'}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.neutralMuted,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(LucideIcons.users, size: 14, color: AppColors.neutralSubtle),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.poktanName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.neutralMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
    );
  }
}

