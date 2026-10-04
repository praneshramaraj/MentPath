import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';

class StudentEmptyScreen extends StatelessWidget {
  const StudentEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Portal'),
      ),
      body: const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'Student Dashboard Pending Real Users',
        description:
            'All future student information, attendance, marks, and requests will originate strictly from real authenticated student accounts. No fake student data is generated.',
      ),
    );
  }
}
