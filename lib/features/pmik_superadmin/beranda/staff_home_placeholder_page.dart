import 'package:flutter/material.dart';

import '../../../core/services/staff_auth_service.dart';
import '../../../models/staff_account_model.dart';
import '../../auth/auth_choice_page.dart';

/// Halaman sementara setelah staf berhasil login.
///
/// Ganti isi [build] (atau ganti pemanggilan di login_page.dart) dengan
/// dashboard asli tiap role:
///   - StaffRole.superadmin -> kelola dokter & PMIK
///   - StaffRole.admin      -> dashboard PMIK
///   - StaffRole.dokter     -> dashboard dokter
class StaffHomePlaceholderPage extends StatelessWidget {
  final StaffAccount account;
  const StaffHomePlaceholderPage({super.key, required this.account});

  void _logout(BuildContext context) {
    StaffAuthService().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthChoicePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(account.role.label)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halo, ${account.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Masuk sebagai ${account.role.label}'),
              const SizedBox(height: 4),
              Text(account.email),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
