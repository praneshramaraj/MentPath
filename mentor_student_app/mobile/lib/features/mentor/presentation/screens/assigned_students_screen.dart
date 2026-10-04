import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class AssignedStudentsScreen extends ConsumerStatefulWidget {
  const AssignedStudentsScreen({super.key});

  @override
  ConsumerState<AssignedStudentsScreen> createState() => _AssignedStudentsScreenState();
}

class _AssignedStudentsScreenState extends ConsumerState<AssignedStudentsScreen> {
  List<dynamic> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignedStudents();
  }

  Future<void> _fetchAssignedStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final list = await apiClient.get('/mentor/students');
      setState(() {
        _students = list as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAssignStudentDialog() {
    final identifierController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Assign Real Student',
                style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Enter register number or email of a real student who has completed profile setup.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: identifierController,
                      decoration: const InputDecoration(
                        labelText: 'Register Number or Email *',
                        prefixIcon: Icon(Icons.person_search_outlined, color: AppColors.primaryBlue),
                        hintText: 'e.g. 710021104088 or realstudent@college.edu',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter register number or email' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
                AppButton(
                  text: 'Assign',
                  isLoading: isAssigning,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isAssigning = true);

                    try {
                      final apiClient = ref.read(apiClientProvider);
                      final res = await apiClient.post(
                        '/mentor/assign-student',
                        body: {
                          'student_identifier': identifierController.text.trim(),
                          'academic_year': '2025-2026',
                        },
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res['message'] ?? 'Student assigned successfully!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      _fetchAssignedStudents();
                    } catch (e) {
                      setDialogState(() => isAssigning = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Assigned Mentees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.primaryBlue),
            onPressed: _showAssignStudentDialog,
            tooltip: 'Assign Student',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _fetchAssignedStudents,
            tooltip: 'Refresh List',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Querying assigned students from MongoDB...')
            : _errorMessage != null
                ? AppErrorState(
                    title: 'Error Querying Students',
                    message: _errorMessage!,
                    onRetry: _fetchAssignedStudents,
                  )
                : _students.isEmpty
                    ? AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'No students assigned yet.',
                        description:
                            'No real students are currently linked to your mentorship. You can assign registered students using their register number or email.',
                        actionText: 'Assign Real Student',
                        onAction: _showAssignStudentDialog,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index] as Map<String, dynamic>;
                          return AppCard(
                            onTap: () {
                              final studentId = s['student_id'] ?? s['user_id'];
                              context.push('/mentor/students/$studentId');
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.lightBlue,
                                  child: Text(
                                    s['full_name'].substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.darkBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s['full_name'] ?? '',
                                        style: const TextStyle(
                                          color: AppColors.darkBlue,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Reg: ${s['register_number'] ?? "N/A"}',
                                        style: const TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s['department']} • Year ${s['year']} ${s['section'] != null ? "(${s['section']})" : ""}',
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.secondaryText,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.background,
        onPressed: _showAssignStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Assign Student'),
      ),
    );
  }
}
