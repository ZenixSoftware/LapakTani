import 'package:flutter/material.dart';
import '../../core/services/user_session.dart';
import '../auth/auth_repository.dart';
import '../home/home_dashboard_screen.dart';
import '../penyuluh/screens/penyuluh_hub_screen.dart';
import '../petani/screens/petani_simple_screen.dart';
import '../poktan/screens/poktan_dashboard_screen.dart';

typedef BuyerMainShell = HomeDashboardScreen;

class RoleBasedAppShell extends StatefulWidget {
  const RoleBasedAppShell({super.key});

  @override
  State<RoleBasedAppShell> createState() => _RoleBasedAppShellState();
}

class _RoleBasedAppShellState extends State<RoleBasedAppShell> {
  final UserSession _session = UserSession();

  @override
  void initState() {
    super.initState();
    _session.init();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: _session.userNotifier,
      builder: (context, user, _) {
        final activeUser = user ?? AuthRepository().currentUser;

        // 1. GUEST / UNREGISTERED: Default to Buyer Shell
        if (activeUser == null) {
          return const BuyerMainShell();
        }

        final roleId = activeUser.roleId;
        final roleStr = (activeUser.role ?? '').toLowerCase();
        final isChairman = activeUser.isChairman;

        // 2. PENYULUH (role_id == 2 or role == 'penyuluh')
        if (roleId == 2 || roleStr == 'penyuluh') {
          return const PenyuluhHubScreen();
        }

        // 3. PETANI (role_id == 1 or role == 'petani')
        if (roleId == 1 || roleStr == 'petani') {
          if (isChairman) {
            // POKTAN CHAIRMAN: Poktan Management Dashboard
            return const PoktanDashboardScreen();
          } else {
            // PETANI ANGGOTA: Simplified Field Farmer Screen
            return const PetaniSimpleScreen();
          }
        }

        // 4. BUYER (role_id == 4 or role == 'pembeli') & Fallback
        return const BuyerMainShell();
      },
    );
  }
}

