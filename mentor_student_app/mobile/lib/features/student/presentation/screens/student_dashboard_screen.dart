import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends ConsumerState<StudentDashboardScreen> {
  int _currentIndex = 0;

  Map<String, dynamic>? _studentProfile;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _marksData;
  List<dynamic> _leaveRequests = [];
  List<dynamic> _odRequests = [];
  List<dynamic> _achievements = [];
  List<dynamic> _notifications = [];
  List<dynamic> _mentorNotes = [];
  List<dynamic> _meetings = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      _studentProfile = await apiClient.get('/student/profile');

      try {
        final user = ref.read(authProvider).user;
        if (user != null) {
          _attendanceData = await apiClient.get('/attendance/student/${user.id}');
          _marksData = await apiClient.get('/marks/student/${user.id}');
        }
      } catch (_) {}

      try {
        final leaves = await apiClient.get('/leave/student');
        if (leaves is List) _leaveRequests = leaves;
      } catch (_) {}

      try {
        final ods = await apiClient.get('/od/student');
        if (ods is List) _odRequests = ods;
      } catch (_) {}

      try {
        final user = ref.read(authProvider).user;
        if (user != null) {
          final achs = await apiClient.get('/achievements/student/${user.id}');
          if (achs is List) _achievements = achs;
        }
      } catch (_) {}

      try {
        final user = ref.read(authProvider).user;
        if (user != null) {
          final notes = await apiClient.get('/notes/student/${user.id}');
          if (notes is List) _mentorNotes = notes;
          final meets = await apiClient.get('/meetings/student/${user.id}');
          if (meets is List) _meetings = meets;
        }
      } catch (_) {}

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

  void _showEditProfileDialog() {
    final phoneController = TextEditingController(text: _studentProfile?['phone_number'] ?? '');
    final personalEmailController = TextEditingController(text: _studentProfile?['personal_email'] ?? '');
    final addressController = TextEditingController(text: _studentProfile?['address'] ?? '');
    final cityController = TextEditingController(text: _studentProfile?['city'] ?? '');
    final stateController = TextEditingController(text: _studentProfile?['state'] ?? '');
    final pincodeController = TextEditingController(text: _studentProfile?['pincode'] ?? '');
    final parentNameController = TextEditingController(text: _studentProfile?['parent_name'] ?? '');
    final relationshipController = TextEditingController(text: _studentProfile?['relationship'] ?? '');
    final parentPhoneController = TextEditingController(text: _studentProfile?['parent_phone'] ?? '');
    final parentEmailController = TextEditingController(text: _studentProfile?['parent_email'] ?? '');

    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Edit Permitted Profile Fields', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Contact Info', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Primary Phone Number *'),
                        validator: (v) => v == null || v.trim().length != 10 ? 'Enter 10-digit phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: personalEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Personal Email'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cityController,
                              decoration: const InputDecoration(labelText: 'City *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: stateController,
                              decoration: const InputDecoration(labelText: 'State *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: pincodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pincode *'),
                        validator: (v) => v == null || v.trim().length != 6 ? 'Enter 6-digit pincode' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Parent / Guardian Details', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: parentNameController,
                        decoration: const InputDecoration(labelText: 'Parent Name *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter parent name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: relationshipController,
                        decoration: const InputDecoration(labelText: 'Relationship *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter relationship' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: parentPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Parent Phone *'),
                        validator: (v) => v == null || v.trim().length != 6 && v.trim().length != 10 ? 'Enter phone' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: parentEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Parent Email'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
                AppButton(
                  text: 'Save Changes',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.put('/student/profile', body: {
                        'phone_number': phoneController.text.trim(),
                        'personal_email': personalEmailController.text.trim().isEmpty ? null : personalEmailController.text.trim(),
                        'address': addressController.text.trim(),
                        'city': cityController.text.trim(),
                        'state': stateController.text.trim(),
                        'pincode': pincodeController.text.trim(),
                        'parent_name': parentNameController.text.trim(),
                        'relationship': relationshipController.text.trim(),
                        'parent_phone': parentPhoneController.text.trim(),
                        'parent_email': parentEmailController.text.trim().isEmpty ? null : parentEmailController.text.trim(),
                      });
                      if (context.mounted) Navigator.pop(context);
                      _fetchAllData();
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      controller.text = '${picked.year}-$month-$day';
    }
  }

  void _showSubmitLeaveDialog() {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final reasonController = TextEditingController();
    final docUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Apply for Leave', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: startDateController,
                        readOnly: true,
                        onTap: () => _pickDate(context, startDateController),
                        decoration: const InputDecoration(
                          labelText: 'Start Date (YYYY-MM-DD) *',
                          hintText: 'Select start date',
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Select start date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        onTap: () => _pickDate(context, endDateController),
                        decoration: const InputDecoration(
                          labelText: 'End Date (YYYY-MM-DD) *',
                          hintText: 'Select end date',
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Select end date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Reason *', hintText: 'Personal / Medical leave reason'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter reason' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: docUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Supporting Document Link / Reference (Optional)',
                          hintText: 'e.g. Medical certificate URL or file reference',
                          prefixIcon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
                AppButton(
                  text: 'Submit Application',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/leave', body: {
                        'start_date': startDateController.text.trim(),
                        'end_date': endDateController.text.trim(),
                        'reason': reasonController.text.trim(),
                        'document_url': docUrlController.text.trim().isEmpty ? null : docUrlController.text.trim(),
                      });
                      if (context.mounted) Navigator.pop(context);
                      _fetchAllData();
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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

  void _showSubmitODDialog() {
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final eventNameController = TextEditingController();
    final orgController = TextEditingController();
    final reasonController = TextEditingController();
    final docUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Submit On-Duty (OD) Request', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: eventNameController,
                        decoration: const InputDecoration(labelText: 'Event / Symposium Title *', hintText: 'Hackathon 2026'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter event title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: orgController,
                        decoration: const InputDecoration(labelText: 'Hosting Organization *', hintText: 'IIT Madras'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter host organization' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: startDateController,
                        readOnly: true,
                        onTap: () => _pickDate(context, startDateController),
                        decoration: const InputDecoration(
                          labelText: 'Start Date (YYYY-MM-DD) *',
                          hintText: 'Select start date',
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Select start date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        onTap: () => _pickDate(context, endDateController),
                        decoration: const InputDecoration(
                          labelText: 'End Date (YYYY-MM-DD) *',
                          hintText: 'Select end date',
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Select end date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(labelText: 'Reason *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter reason' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: docUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Invitation / Proof Link (Optional)',
                          hintText: 'e.g. Event registration or paper acceptance URL',
                          prefixIcon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
                AppButton(
                  text: 'Submit OD Request',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/od', body: {
                        'event_name': eventNameController.text.trim(),
                        'organization': orgController.text.trim(),
                        'start_date': startDateController.text.trim(),
                        'end_date': endDateController.text.trim(),
                        'reason': reasonController.text.trim(),
                        'proof_document_url': docUrlController.text.trim().isEmpty ? null : docUrlController.text.trim(),
                      });
                      if (context.mounted) Navigator.pop(context);
                      _fetchAllData();
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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

  void _showSubmitAchievementDialog() {
    final titleController = TextEditingController();
    String category = 'Hackathons';
    final orgController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController(text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}");
    final certUrlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Achievement / Certification', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. 1st Place Smart India Hackathon'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: const [
                          DropdownMenuItem(value: 'Hackathons', child: Text('Hackathons')),
                          DropdownMenuItem(value: 'Certifications', child: Text('Certifications')),
                          DropdownMenuItem(value: 'Internships', child: Text('Internships')),
                          DropdownMenuItem(value: 'Projects', child: Text('Projects')),
                          DropdownMenuItem(value: 'Competitions', child: Text('Competitions')),
                          DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                          DropdownMenuItem(value: 'Cultural Achievements', child: Text('Cultural Achievements')),
                          DropdownMenuItem(value: 'Other Approved Achievements', child: Text('Other Approved Achievements')),
                        ],
                        onChanged: (v) => setDialogState(() => category = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: orgController,
                        decoration: const InputDecoration(labelText: 'Organization / Issuer / Host', hintText: 'e.g. AWS, Coursera, IIT Madras'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        readOnly: true,
                        onTap: () => _pickDate(context, dateController),
                        decoration: const InputDecoration(
                          labelText: 'Date Awarded / Completed (YYYY-MM-DD) *',
                          suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Select date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description *', hintText: 'Key details, project scope, or award level'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: certUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Certificate / Document Reference URL (Optional)',
                          hintText: 'e.g. Verification URL or uploaded proof link',
                          prefixIcon: Icon(Icons.attach_file, color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
                ),
                AppButton(
                  text: 'Save Record',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/achievements', body: {
                        'title': titleController.text.trim(),
                        'category': category,
                        'organization': orgController.text.trim().isEmpty ? null : orgController.text.trim(),
                        'description': descController.text.trim(),
                        'date_awarded': dateController.text.trim(),
                        'certificate_url': certUrlController.text.trim().isEmpty ? null : certUrlController.text.trim(),
                      });
                      if (context.mounted) Navigator.pop(context);
                      _fetchAllData();
                    } catch (e) {
                      setDialogState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
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
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _fetchAllData,
            tooltip: 'Refresh Portal',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'My Profile'),
          const BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Leave & OD'),
          const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Achievements'),
          const BottomNavigationBarItem(icon: Icon(Icons.assignment_ind_outlined), label: 'Mentor Notes'),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Notifications',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Querying authenticated student records from MongoDB...')
            : _errorMessage != null
                ? AppErrorState(
                    title: 'Unable to Load Student Data',
                    message: _errorMessage!,
                    onRetry: _fetchAllData,
                  )
                : IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildDashboardOverview(user),
                      _buildProfileView(user),
                      _buildLeaveODView(),
                      _buildAchievementsView(),
                      _buildMentorNotesView(),
                      _buildNotificationsView(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDashboardOverview(dynamic user) {
    final String studentName = _studentProfile?['full_name'] ?? user?.fullName ?? 'Student';
    final String dept = _studentProfile?['department'] ?? 'Department N/A';
    final int year = _studentProfile?['year'] ?? 1;
    final int sem = _studentProfile?['semester'] ?? 1;
    final String sec = _studentProfile?['section'] ?? 'N/A';

    final attendanceRecords = (_attendanceData?['records'] as List<dynamic>?) ?? [];
    final marksRecords = (_marksData?['records'] as List<dynamic>?) ?? [];

    final String? mentorName = _studentProfile?['mentor_name'];
    final String? mentorEmail = _studentProfile?['mentor_email'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card: Real Profile Details
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        studentName,
                        style: const TextStyle(color: AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Profile Complete', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Department: $dept', style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Year $year • Semester $sem • Section $sec', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Module 1: Mentor Assignment
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.supervisor_account, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text('Assigned Mentor', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                if (mentorName != null) ...[
                  _buildRow('Mentor Name', mentorName),
                  if (mentorEmail != null) _buildRow('Email', mentorEmail),
                  if (_studentProfile?['mentor_department'] != null) _buildRow('Department', _studentProfile!['mentor_department']),
                ] else ...[
                  const Text('No mentor assigned yet.', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Module 2: Attendance Summary (NO fabricated statistics)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text('Attendance Summary', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                if (attendanceRecords.isEmpty) ...[
                  const Text('Attendance data is not available yet.', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn('Attendance', '${((_attendanceData?['attendance_percentage'] as num?) ?? 0.0).toDouble()}%', color: AppColors.primaryBlue),
                      _buildMetricColumn('Total Days', '${_attendanceData?['total_days'] ?? 0}'),
                      _buildMetricColumn('Present', '${_attendanceData?['present_days'] ?? 0}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Module 3: Marks & Academic Performance
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.grade, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text('Marks & Grades', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 16),
                if (marksRecords.isEmpty) ...[
                  const Text('No marks records available yet.', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn('Avg Performance', '${((_marksData?['average_percentage'] as num?) ?? 0.0).toDouble()}%', color: AppColors.primaryBlue),
                      _buildMetricColumn('Total Exams', '${_marksData?['total_records'] ?? 0}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Module 4: Achievements Summary
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.emoji_events, color: AppColors.primaryBlue),
                        SizedBox(width: 8),
                        Text('Achievements', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue),
                      onPressed: _showSubmitAchievementDialog,
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (_achievements.isEmpty) ...[
                  const Text('No achievements recorded yet.', style: TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic)),
                ] else ...[
                  ..._achievements.take(2).map((a) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('• ${a['title']} (${a['category']})', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600)),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Profile', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Edit Profile',
                icon: Icons.edit_outlined,
                onPressed: _showEditProfileDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Personal Info Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Details', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Full Name', _studentProfile?['full_name'] ?? user?.fullName ?? ''),
                _buildRow('College Email', _studentProfile?['college_email'] ?? user?.email ?? ''),
                _buildRow('Primary Phone', _studentProfile?['phone_number'] ?? ''),
                _buildRow('Date of Birth', _studentProfile?['date_of_birth'] ?? ''),
                _buildRow('Gender', _studentProfile?['gender'] ?? ''),
                if (_studentProfile?['personal_email'] != null) _buildRow('Personal Email', _studentProfile!['personal_email']),
                _buildRow('Address', '${_studentProfile?['address']}, ${_studentProfile?['city']}, ${_studentProfile?['state']} - ${_studentProfile?['pincode']}'),
              ],
            ),
          ),

          // College Standing Card (Non-editable system fields)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('College Information (System Managed)', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Register Number', _studentProfile?['register_number'] ?? ''),
                _buildRow('Department', _studentProfile?['department'] ?? ''),
                _buildRow('Course & Year', '${_studentProfile?['course']} - Year ${_studentProfile?['year']} (Sem ${_studentProfile?['semester']})'),
                if (_studentProfile?['section'] != null) _buildRow('Section', _studentProfile!['section']),
                _buildRow('Admission Year', '${_studentProfile?['admission_year']}'),
              ],
            ),
          ),

          // Parent Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parent / Guardian Contact', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Parent Name', _studentProfile?['parent_name'] ?? ''),
                _buildRow('Relationship', _studentProfile?['relationship'] ?? ''),
                _buildRow('Parent Phone', _studentProfile?['parent_phone'] ?? ''),
                if (_studentProfile?['parent_email'] != null) _buildRow('Parent Email', _studentProfile!['parent_email']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest(String type, String requestId) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final endpoint = type == 'leave' ? '/leave/$requestId/cancel' : '/od/$requestId/cancel';
      await apiClient.put(endpoint);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: AppColors.secondaryText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLeaveODView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Leave Applications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(text: 'Apply Leave', icon: Icons.add, onPressed: _showSubmitLeaveDialog),
            ],
          ),
          const SizedBox(height: 12),
          if (_leaveRequests.isEmpty)
            const AppEmptyState(icon: Icons.event_note_outlined, title: 'No leave applications submitted.', description: 'Submit a new leave request for mentor approval.')
          else
            ..._leaveRequests.map((l) {
              final String reqId = l['id'];
              final String st = (l['status'] ?? 'pending').toString().toLowerCase();
              final String? docUrl = l['document_url'];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Leave: ${l['start_date']} to ${l['end_date']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                        _buildStatusBadge(st),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Reason: ${l['reason']}', style: const TextStyle(color: AppColors.primaryText)),
                    if (docUrl != null && docUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Document: $docUrl', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ],
                    if (l['reviewer_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Reviewer: ${l['reviewer_name']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    ],
                    if (l['mentor_remarks'] != null && (l['mentor_remarks'] as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Remarks: ${l['mentor_remarks']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                    if (st == 'pending') ...[
                      const Divider(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _cancelRequest('leave', reqId),
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                          label: const Text('Cancel Application', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('On-Duty (OD) Requests', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(text: 'Apply OD', icon: Icons.add, onPressed: _showSubmitODDialog),
            ],
          ),
          const SizedBox(height: 12),
          if (_odRequests.isEmpty)
            const AppEmptyState(icon: Icons.card_membership_outlined, title: 'No OD requests submitted.', description: 'Apply for On-Duty leave for symposiums and workshops.')
          else
            ..._odRequests.map((o) {
              final String reqId = o['id'];
              final String st = (o['status'] ?? 'pending').toString().toLowerCase();
              final String? proofUrl = o['proof_document_url'];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('OD: ${o['event_name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                        _buildStatusBadge(st),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Host: ${o['organization']} (${o['start_date']} to ${o['end_date']})', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    Text('Reason: ${o['reason']}', style: const TextStyle(color: AppColors.primaryText)),
                    if (proofUrl != null && proofUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Proof Link: $proofUrl', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ],
                    if (o['reviewer_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Reviewer: ${o['reviewer_name']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    ],
                    if (o['mentor_remarks'] != null && (o['mentor_remarks'] as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Remarks: ${o['mentor_remarks']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                    if (st == 'pending') ...[
                      const Divider(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _cancelRequest('od', reqId),
                          icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                          label: const Text('Cancel Application', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _deleteAchievement(String id) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.delete('/achievements/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievement record deleted'),
            backgroundColor: AppColors.secondaryText,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildAchievementsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Achievements & Certifications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(text: 'Add Record', icon: Icons.add, onPressed: _showSubmitAchievementDialog),
            ],
          ),
          const SizedBox(height: 16),
          if (_achievements.isEmpty)
            const AppEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No achievements recorded yet.',
              description: 'Submit hackathons, certifications, internships, projects, sports, and cultural achievements for mentor review.',
            )
          else
            ..._achievements.map((a) {
              final String achId = a['id'];
              final bool isVerified = a['verified_by_mentor'] == true || a['verification_status'] == 'verified';
              final String status = a['verification_status'] ?? (isVerified ? 'verified' : 'pending');
              final String? certUrl = a['certificate_url'];
              final String? org = a['organization'];

              Color statusBg = AppColors.lightBlue;
              Color statusFg = AppColors.primaryBlue;
              String statusLabel = 'PENDING VERIFICATION';

              if (status == 'verified' || isVerified) {
                statusBg = AppColors.success.withAlpha(30);
                statusFg = AppColors.success;
                statusLabel = 'VERIFIED';
              } else if (status == 'rejected') {
                statusBg = AppColors.error.withAlpha(30);
                statusFg = AppColors.error;
                statusLabel = 'REJECTED';
              }

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
                              const SizedBox(height: 4),
                              Text('${a['category']}${org != null && org.isNotEmpty ? ' • $org' : ''}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(14)),
                          child: Text(statusLabel, style: TextStyle(color: statusFg, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(a['description'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Awarded: ${a['date_awarded']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    if (certUrl != null && certUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Document: $certUrl', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ],
                    if (a['verifier_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text('Reviewed by: ${a['verifier_name']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                    const Divider(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _deleteAchievement(achId),
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('Delete Record', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _markNotificationRead(String id) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/notifications/$id/read');
      _fetchAllData();
    } catch (_) {}
  }

  Future<void> _markAllNotificationsRead() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/notifications/read-all');
      _fetchAllData();
    } catch (_) {}
  }

  Widget _buildNotificationsView() {
    final unreadList = _notifications.where((n) => n['is_read'] == false).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('In-App Notifications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              if (unreadList.isNotEmpty)
                TextButton.icon(
                  onPressed: _markAllNotificationsRead,
                  icon: const Icon(Icons.done_all, size: 16, color: AppColors.primaryBlue),
                  label: const Text('Mark All Read', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_notifications.isEmpty)
            const AppEmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications available.',
              description: 'Official notifications for leave updates, OD status, mentor notes, meetings, and announcements will appear here.',
            )
          else
            ..._notifications.map((n) {
              final String notifId = n['id'];
              final bool isRead = n['is_read'] == true;
              final String typeStr = (n['notification_type'] ?? 'GENERAL').toString();
              final String createdAtRaw = n['created_at'] ?? '';
              
              String dateStr = '';
              if (createdAtRaw.isNotEmpty) {
                try {
                  final dt = DateTime.parse(createdAtRaw).toLocal();
                  dateStr = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } catch (_) {
                  dateStr = createdAtRaw;
                }
              }

              Color badgeBg = AppColors.lightBlue;
              Color badgeFg = AppColors.primaryBlue;
              String badgeLabel = typeStr.replaceAll('_', ' ');

              if (typeStr.contains('LEAVE')) {
                badgeBg = Colors.purple.shade50;
                badgeFg = Colors.purple.shade700;
              } else if (typeStr.contains('OD')) {
                badgeBg = Colors.indigo.shade50;
                badgeFg = Colors.indigo.shade700;
              } else if (typeStr.contains('NOTE') || typeStr.contains('MESSAGE')) {
                badgeBg = Colors.teal.shade50;
                badgeFg = Colors.teal.shade700;
              } else if (typeStr.contains('MEETING')) {
                badgeBg = Colors.amber.shade50;
                badgeFg = Colors.amber.shade900;
              } else if (typeStr.contains('ACADEMIC')) {
                badgeBg = Colors.blue.shade50;
                badgeFg = Colors.blue.shade800;
              } else if (typeStr.contains('ANNOUNCEMENT')) {
                badgeBg = Colors.orange.shade50;
                badgeFg = Colors.orange.shade800;
              }

              return AppCard(
                child: InkWell(
                  onTap: isRead ? null : () => _markNotificationRead(notifId),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.grey.shade100 : AppColors.lightBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: isRead ? AppColors.secondaryText : AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      color: isRead ? AppColors.primaryText : AppColors.darkBlue,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                                  child: Text(badgeLabel, style: TextStyle(color: badgeFg, fontWeight: FontWeight.bold, fontSize: 9)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(n['message'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (dateStr.isNotEmpty)
                                  Text(dateStr, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                                if (!isRead)
                                  const Text('Unread • Tap to mark read', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMentorNotesView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shared Mentor Notes & Counseling Records', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Only notes & meeting logs explicitly configured by your mentor as student-visible are shown here.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          if (_mentorNotes.isEmpty && _meetings.isEmpty)
            const AppEmptyState(
              icon: Icons.assignment_turned_in_outlined,
              title: 'No shared notes or meeting records available yet.',
              description: 'When your mentor shares feedback, notes, or counseling meeting logs, they will appear here.',
            )
          else ...[
            if (_mentorNotes.isNotEmpty) ...[
              const Text('Shared Mentor Notes', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._mentorNotes.map((n) {
                final String? followUp = n['follow_up_date'];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkBlue)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(8)),
                            child: Text(n['category'] ?? 'General Note', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(n['note'] ?? n['content'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Logged: ${n['date']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                          if (followUp != null && followUp.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.event_repeat, size: 14, color: AppColors.error),
                                const SizedBox(width: 4),
                                Text('Follow-up: $followUp', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            if (_meetings.isNotEmpty) ...[
              const Text('Counseling & Meeting Logs', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._meetings.map((m) {
                final String? actions = m['action_items'];
                final String? followUp = m['follow_up_date'];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
                      const SizedBox(height: 2),
                      Text('Meeting Date: ${m['date']}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                      const Divider(height: 16),
                      const Text('Discussion Summary:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(m['discussion_summary'] ?? '', style: const TextStyle(color: AppColors.primaryText, fontSize: 14)),
                      if (actions != null && actions.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 14, color: AppColors.primaryBlue),
                                  SizedBox(width: 4),
                                  Text('Agreed Action Items:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(actions, style: const TextStyle(color: AppColors.darkBlue, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      if (followUp != null && followUp.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event_repeat, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('Follow-up Scheduled: $followUp', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color ?? AppColors.darkBlue, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    final String s = status.toLowerCase();
    String label = status.replaceAll('_', ' ').toUpperCase();

    if (s.contains('approved')) {
      bg = AppColors.success.withAlpha(30);
      fg = AppColors.success;
      label = 'APPROVED';
    } else if (s == 'rejected') {
      bg = AppColors.error.withAlpha(30);
      fg = AppColors.error;
      label = 'REJECTED';
    } else if (s == 'cancelled') {
      bg = Colors.grey.withAlpha(40);
      fg = Colors.grey.shade700;
      label = 'CANCELLED';
    } else {
      bg = AppColors.lightBlue;
      fg = AppColors.primaryBlue;
      label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
