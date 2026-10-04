import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';

class MentorEmptyScreen extends StatelessWidget {
  const MentorEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mentor Portal'),
      ),
      body: const AppEmptyState(
        icon: Icons.supervisor_account_outlined,
        title: 'Mentor Dashboard Pending Real Users',
        description:
            'Mentor profile, mentee assignments, meeting scheduler, and note management will populate dynamically once real mentors are registered. No fake mentor data is created.',
      ),
    );
  }
}
