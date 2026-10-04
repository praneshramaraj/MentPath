import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';

class AuthEmptyScreen extends StatelessWidget {
  const AuthEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Authentication Module'),
      ),
      body: const AppEmptyState(
        icon: Icons.lock_outline,
        title: 'Authentication Uninitialized',
        description:
            'JWT authentication, login/signup routes, and user credentials will be connected in Phase 2. No hardcoded or dummy users exist.',
      ),
    );
  }
}
