import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/info_box.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String? _apiTestResult;
  bool _isTestingApi = false;

  Future<void> _testAdminApi() async {
    setState(() {
      _isTestingApi = true;
      _apiTestResult = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/admin/dashboard');
      setState(() {
        _apiTestResult = res['message'] ?? 'API access granted!';
        _isTestingApi = false;
      });
    } catch (e) {
      setState(() {
        _apiTestResult = 'Access Error: ${e.toString()}';
        _isTestingApi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoBox(
                title: 'Admin Console Active',
                message: 'Authenticated as ${user?.fullName} (${user?.email}). Full administrative RBAC authorization enabled.',
                icon: Icons.admin_panel_settings_outlined,
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Authenticated Admin Profile',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildRow('User ID', user?.id ?? ''),
                    _buildRow('Email', user?.email ?? ''),
                    _buildRow('Full Name', user?.fullName ?? ''),
                    _buildRow('Role', user?.role.toUpperCase() ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Admin Authorization Check',
                      style: TextStyle(
                        color: AppColors.darkBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verify that /api/v1/admin/dashboard requires ADMIN role and rejects unauthorized student/mentor tokens.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Test Admin API Access',
                      icon: Icons.security,
                      onPressed: _testAdminApi,
                      isLoading: _isTestingApi,
                      variant: AppButtonVariant.primary,
                      width: double.infinity,
                    ),
                    if (_apiTestResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryBlue.withAlpha(50)),
                        ),
                        child: Text(
                          _apiTestResult!,
                          style: const TextStyle(
                            color: AppColors.darkBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Log Out Session',
                icon: Icons.logout,
                onPressed: () => ref.read(authProvider.notifier).logout(),
                variant: AppButtonVariant.secondary,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
