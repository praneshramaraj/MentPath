import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_box.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import 'ai_mentor_assistant_screen.dart';

class MentorDashboardScreen extends ConsumerStatefulWidget {
  const MentorDashboardScreen({super.key});

  @override
  ConsumerState<MentorDashboardScreen> createState() => _MentorDashboardScreenState();
}

class _MentorDashboardScreenState extends ConsumerState<MentorDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchMentorDashboard();
  }

  Future<void> _fetchMentorDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/mentor/dashboard');
      _dashboardData = res['data'] ?? res;

      try {
        final notifs = await apiClient.get('/notifications');
        if (notifs is List) _notifications = notifs;
      } catch (_) {}

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final unread = _notifications.where((n) => n['is_read'] == false).toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mentor Notifications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                          if (unread.isNotEmpty)
                            TextButton.icon(
                              onPressed: () async {
                                final apiClient = ref.read(apiClientProvider);
                                await apiClient.put('/notifications/read-all');
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _fetchMentorDashboard();
                              },
                              icon: const Icon(Icons.done_all, size: 16, color: AppColors.primaryBlue),
                              label: const Text('Mark All Read', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                        ],
                      ),
                      const Divider(height: 20),
                      if (_notifications.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text('No mentor notifications available.', style: TextStyle(color: AppColors.secondaryText)),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _notifications.length,
                            itemBuilder: (context, idx) {
                              final n = _notifications[idx];
                              final bool isRead = n['is_read'] == true;
                              return AppCard(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: isRead ? AppColors.secondaryText : AppColors.primaryBlue,
                                  ),
                                  title: Text(
                                    n['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      color: isRead ? AppColors.primaryText : AppColors.darkBlue,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(n['message'] ?? '', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                                  ),
                                  trailing: !isRead
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle_outline, color: AppColors.primaryBlue),
                                          onPressed: () async {
                                            final apiClient = ref.read(apiClientProvider);
                                            await apiClient.put('/notifications/${n['id']}/read');
                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                            _fetchMentorDashboard();
                                          },
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
                      _fetchMentorDashboard();
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
    final user = ref.watch(authProvider).user;
    final int assignedCount = _dashboardData?['assigned_student_count'] ?? 0;

    final int unreadNotifCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mentor Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.primaryBlue),
            tooltip: 'AI Mentor Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIMentorAssistantScreen()),
              );
            },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: unreadNotifCount > 0,
              label: Text('$unreadNotifCount'),
              child: const Icon(Icons.notifications_outlined, color: AppColors.primaryBlue),
            ),
            onPressed: _showNotificationsModal,
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _fetchMentorDashboard,
            tooltip: 'Refresh Dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Querying mentor records from MongoDB...')
            : _errorMessage != null
                ? AppErrorState(
                    title: 'Dashboard Error',
                    message: _errorMessage!,
                    onRetry: _fetchMentorDashboard,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoBox(
                          title: 'Welcome, ${_dashboardData?['full_name'] ?? user?.fullName}!',
                          message: 'Department: ${_dashboardData?['department'] ?? "General Academics"}. Authenticated live MongoDB query active.',
                          icon: Icons.supervisor_account_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Mentor Profile Summary Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mentor Profile Details',
                                style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const Divider(height: 20),
                              _buildRow('Full Name', _dashboardData?['full_name'] ?? user?.fullName ?? ''),
                              _buildRow('Email', _dashboardData?['email'] ?? user?.email ?? ''),
                              _buildRow('Employee ID', _dashboardData?['employee_id'] ?? 'M-001'),
                              _buildRow('Department', _dashboardData?['department'] ?? 'General Academics'),
                              _buildRow('Designation', _dashboardData?['designation'] ?? 'Faculty Mentor'),
                              _buildRow('Mentee Quota', '${_dashboardData?['max_mentees'] ?? 30} Students Max'),
                            ],
                          ),
                        ),

                        // Real Assigned Student Count Metric Card
                        // AI Assistant Card
                        AppCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 24),
                            ),
                            title: const Text('AI Mentor Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 16)),
                            subtitle: const Text('Zero-hallucination analysis of attendance, marks & follow-up status.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryBlue),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AIMentorAssistantScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Assigned Mentees',
                                        style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Real count from MongoDB mentor_student_assignments',
                                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightBlue,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.primaryBlue.withAlpha(60)),
                                    ),
                                    child: Text(
                                      '$assignedCount Students',
                                      style: const TextStyle(
                                        color: AppColors.darkBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              if (assignedCount == 0) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue.withAlpha(60),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: AppColors.secondaryText),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No students assigned yet.',
                                          style: TextStyle(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: AppButton(
                                      text: 'View Assigned List',
                                      icon: Icons.people_outline,
                                      onPressed: () => context.push('/mentor/students'),
                                      variant: AppButtonVariant.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppButton(
                                      text: 'Assign Student',
                                      icon: Icons.person_add_outlined,
                                      onPressed: _showAssignStudentDialog,
                                      variant: AppButtonVariant.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Sign Out Session',
                          icon: Icons.logout,
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          variant: AppButtonVariant.secondary,
                          width: double.infinity,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
