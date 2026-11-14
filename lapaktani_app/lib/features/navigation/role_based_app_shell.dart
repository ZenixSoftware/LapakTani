import 'package:flutter/material.dart';
import 'package:lapaktani_app/core/services/user_session.dart';
import 'package:lapaktani_app/features/auth/auth_repository.dart';
import 'package:lapaktani_app/features/home/home_dashboard_screen.dart';
import 'package:lapaktani_app/features/penyuluh/screens/penyuluh_hub_screen.dart';
import 'package:lapaktani_app/features/petani/screens/petani_simple_screen.dart';
import 'package:lapaktani_app/features/poktan/screens/poktan_main_shell.dart';

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

        // 1. GUEST / UNREGISTERED: Default to HomeDashboardScreen (Buyer Shell)
        if (activeUser == null) {
          return const HomeDashboardScreen();
        }

        final roleId = activeUser.roleId;
        final roleStr = (activeUser.role ?? '').toLowerCase();
        final isChairman = activeUser.isChairman;

        // 2. PENYULUH (role_id == 2 or role == 'penyuluh')
        if (roleId == 2 || roleStr == 'penyuluh') {
          return const PenyuluhHubScreen();
        }

        // 2B. KETUA POKTAN / ADMIN KOPERASI (role_id == 3 or role == 'admin')
        if (roleId == 3 || roleStr == 'admin') {
          return const PoktanMainShell();
        }

        // 3. PETANI (role_id == 1 or role == 'petani')
        if (roleId == 1 || roleStr == 'petani') {
          if (isChairman) {
            // POKTAN CHAIRMAN: Unified Poktan Management Shell (Retail + B2B + Members + Profile)
            return const PoktanMainShell();
          } else {
            // PETANI ANGGOTA: Simplified Field Farmer Screen
            return const PetaniSimpleScreen();
          }
        }

        // 4. BUYER (role_id == 4 or role == 'pembeli') & Fallback
        return const HomeDashboardScreen();
      },
    );
  }
}
