import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_box.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import 'ai_mentor_assistant_screen.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _student;
  Map<String, dynamic>? _attendanceData;
  Map<String, dynamic>? _marksData;
  List<dynamic> _leaveRequests = [];
  List<dynamic> _odRequests = [];
  List<dynamic> _achievements = [];
  List<dynamic> _mentorNotes = [];
  List<dynamic> _meetings = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);

      final studentRes = await apiClient.get('/mentor/students/${widget.studentId}');
      _student = studentRes;

      try {
        _attendanceData = await apiClient.get('/attendance/student/${widget.studentId}');
      } catch (_) {}

      try {
        _marksData = await apiClient.get('/marks/student/${widget.studentId}');
      } catch (_) {}

      try {
        final leaves = await apiClient.get('/leave/mentor');
        if (leaves is List) {
          _leaveRequests = leaves.where((l) => l['student_id'] == widget.studentId).toList();
        }
      } catch (_) {}

      try {
        final ods = await apiClient.get('/od/mentor');
        if (ods is List) {
          _odRequests = ods.where((o) => o['student_id'] == widget.studentId).toList();
        }
      } catch (_) {}

      try {
        final achs = await apiClient.get('/achievements/student/${widget.studentId}');
        if (achs is List) _achievements = achs;
      } catch (_) {}

      try {
        final notes = await apiClient.get('/notes/student/${widget.studentId}');
        if (notes is List) _mentorNotes = notes;
      } catch (_) {}

      try {
        final meets = await apiClient.get('/meetings/student/${widget.studentId}');
        if (meets is List) _meetings = meets;
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

  void _showLogAttendanceDialog() {
    String statusStr = 'present';
    final dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
    );
    final subjectCodeController = TextEditingController();
    final periodSessionController = TextEditingController();
    final remarksController = TextEditingController();
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
              title: const Text('Log Attendance Entry', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter date' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: statusStr,
                        decoration: const InputDecoration(labelText: 'Status *'),
                        items: const [
                          DropdownMenuItem(value: 'present', child: Text('Present')),
                          DropdownMenuItem(value: 'absent', child: Text('Absent')),
                          DropdownMenuItem(value: 'late', child: Text('Late')),
                          DropdownMenuItem(value: 'on_duty', child: Text('On Duty (OD)')),
                          DropdownMenuItem(value: 'leave', child: Text('Leave')),
                        ],
                        onChanged: (v) => setDialogState(() => statusStr = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectCodeController,
                        decoration: const InputDecoration(labelText: 'Subject Code (Optional)', hintText: 'e.g. CS8591'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: periodSessionController,
                        decoration: const InputDecoration(labelText: 'Period / Session (Optional)', hintText: 'e.g. Period 1, FN, AN'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: remarksController,
                        decoration: const InputDecoration(labelText: 'Remarks (Optional)', hintText: 'e.g. Medical excuse'),
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
                  text: 'Save Entry',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/attendance', body: {
                        'student_id': widget.studentId,
                        'date': dateController.text.trim(),
                        'status': statusStr,
                        'subject_code': subjectCodeController.text.trim().isEmpty ? null : subjectCodeController.text.trim(),
                        'period_session': periodSessionController.text.trim().isEmpty ? null : periodSessionController.text.trim(),
                        'remarks': remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
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

  void _showLogMarksDialog() {
    int semester = 1;
    String examType = 'Internal';
    final examNameController = TextEditingController();
    final examDateController = TextEditingController();
    final academicYearController = TextEditingController(text: '2025-2026');
    final subjectCodeController = TextEditingController();
    final subjectNameController = TextEditingController();
    final marksObtainedController = TextEditingController();
    final maxMarksController = TextEditingController(text: '100');
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
              title: const Text('Log Subject Marks', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: semester,
                        decoration: const InputDecoration(labelText: 'Semester *'),
                        items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Semester ${i + 1}'))),
                        onChanged: (v) => setDialogState(() => semester = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: examType,
                        decoration: const InputDecoration(labelText: 'Exam Type *'),
                        items: const [
                          DropdownMenuItem(value: 'Internal', child: Text('Internal Exam')),
                          DropdownMenuItem(value: 'Model', child: Text('Model Exam')),
                          DropdownMenuItem(value: 'Semester', child: Text('Semester Exam')),
                          DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                          DropdownMenuItem(value: 'Practical', child: Text('Practical Lab')),
                        ],
                        onChanged: (v) => setDialogState(() => examType = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: examNameController,
                        decoration: const InputDecoration(labelText: 'Exam Title (Optional)', hintText: 'e.g. Internal Assessment 1'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectCodeController,
                        decoration: const InputDecoration(labelText: 'Subject Code *', hintText: 'e.g. CS8591'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject code' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: subjectNameController,
                        decoration: const InputDecoration(labelText: 'Subject Name *', hintText: 'e.g. Computer Networks'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter subject name' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marksObtainedController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Marks Obtained *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter marks' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: maxMarksController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Max Marks *'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Enter max' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: examDateController,
                        decoration: const InputDecoration(labelText: 'Exam Date (Optional)', hintText: 'YYYY-MM-DD'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: academicYearController,
                        decoration: const InputDecoration(labelText: 'Academic Year', hintText: 'e.g. 2025-2026'),
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
                  text: 'Log Marks',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/marks', body: {
                        'student_id': widget.studentId,
                        'semester': semester,
                        'exam_type': examType,
                        'exam_name': examNameController.text.trim().isEmpty ? null : examNameController.text.trim(),
                        'subject_code': subjectCodeController.text.trim(),
                        'subject_name': subjectNameController.text.trim(),
                        'marks_obtained': double.parse(marksObtainedController.text.trim()),
                        'max_marks': double.parse(maxMarksController.text.trim()),
                        'exam_date': examDateController.text.trim().isEmpty ? null : examDateController.text.trim(),
                        'academic_year': academicYearController.text.trim().isEmpty ? null : academicYearController.text.trim(),
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

  void _showAddNoteDialog() {
    String category = 'Academic discussion';
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
    );
    final followUpDateController = TextEditingController();
    bool isStudentVisible = false;
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
              title: const Text('Add Mentor Note', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category *'),
                        items: const [
                          DropdownMenuItem(value: 'Academic discussion', child: Text('Academic discussion')),
                          DropdownMenuItem(value: 'Career guidance', child: Text('Career guidance')),
                          DropdownMenuItem(value: 'Attendance discussion', child: Text('Attendance discussion')),
                          DropdownMenuItem(value: 'Personal follow-up', child: Text('Personal follow-up')),
                          DropdownMenuItem(value: 'Improvement plan', child: Text('Improvement plan')),
                        ],
                        onChanged: (v) => setDialogState(() => category = v!),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title *', hintText: 'e.g. Mid-Sem Academic Progress'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter title' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Note / Observations *', hintText: 'Detailed discussion points and recommendations...'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter note content' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *', suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: followUpDateController,
                        decoration: const InputDecoration(labelText: 'Follow-up Date (Optional, YYYY-MM-DD)', hintText: 'YYYY-MM-DD', suffixIcon: Icon(Icons.event_repeat, color: AppColors.primaryBlue)),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Visible to Student', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
                        subtitle: const Text('Uncheck to keep note strictly confidential (mentor-only)', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                        value: isStudentVisible,
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) => setDialogState(() => isStudentVisible = val ?? false),
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
                  text: 'Save Note',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/notes', body: {
                        'student_id': widget.studentId,
                        'category': category,
                        'title': titleController.text.trim(),
                        'note': noteController.text.trim(),
                        'date': dateController.text.trim(),
                        'follow_up_date': followUpDateController.text.trim().isEmpty ? null : followUpDateController.text.trim(),
                        'is_student_visible': isStudentVisible,
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

  void _showScheduleMeetingDialog() {
    final topicController = TextEditingController();
    final dateController = TextEditingController(
      text: "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}",
    );
    final summaryController = TextEditingController();
    final actionItemsController = TextEditingController();
    final followUpDateController = TextEditingController();
    bool isStudentVisible = true;
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
              title: const Text('Log Counseling Meeting Record', style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: topicController,
                        decoration: const InputDecoration(labelText: 'Topic *', hintText: 'e.g. Monthly Counseling & Career Guidance'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter topic' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: dateController,
                        decoration: const InputDecoration(labelText: 'Meeting Date (YYYY-MM-DD) *', suffixIcon: Icon(Icons.calendar_today, color: AppColors.primaryBlue)),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter date' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: summaryController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Discussion Summary *', hintText: 'Summarize key points discussed during meeting...'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter discussion summary' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: actionItemsController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Action Items (Optional)', hintText: 'e.g. 1. Submit assignment, 2. Attend remedial class'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: followUpDateController,
                        decoration: const InputDecoration(labelText: 'Follow-up Date (Optional, YYYY-MM-DD)', hintText: 'YYYY-MM-DD', suffixIcon: Icon(Icons.event_repeat, color: AppColors.primaryBlue)),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Visible to Student', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
                        subtitle: const Text('Allow student to view this meeting summary & action items', style: TextStyle(fontSize: 11, color: AppColors.secondaryText)),
                        value: isStudentVisible,
                        activeColor: AppColors.primaryBlue,
                        onChanged: (val) => setDialogState(() => isStudentVisible = val ?? true),
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
                  text: 'Log Meeting',
                  isLoading: isSaving,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setDialogState(() => isSaving = true);
                    try {
                      final apiClient = ref.read(apiClientProvider);
                      await apiClient.post('/meetings', body: {
                        'student_id': widget.studentId,
                        'topic': topicController.text.trim(),
                        'date': dateController.text.trim(),
                        'discussion_summary': summaryController.text.trim(),
                        'action_items': actionItemsController.text.trim().isEmpty ? null : actionItemsController.text.trim(),
                        'follow_up_date': followUpDateController.text.trim().isEmpty ? null : followUpDateController.text.trim(),
                        'is_student_visible': isStudentVisible,
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

  void _showReviewDialog(String type, String requestId, String targetStatus) {
    final remarksController = TextEditingController();
    final isApprove = targetStatus.contains('approved');
    final title = isApprove
        ? (type == 'leave' ? 'Approve Leave Request' : 'Approve OD Request')
        : (type == 'leave' ? 'Reject Leave Request' : 'Reject OD Request');
    final defaultRemarks = isApprove ? 'Approved by mentor.' : 'Rejected by mentor.';
    remarksController.text = defaultRemarks;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: TextStyle(color: isApprove ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? 'Confirm approval and add remarks for the student.'
                    : 'Provide rejection remarks so the student understands why.',
                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: remarksController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mentor Remarks',
                  hintText: 'e.g. Approved / Insufficient details',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              onPressed: () async {
                final remarks = remarksController.text.trim();
                Navigator.pop(context);
                await _updateRequestStatus(type, requestId, targetStatus, remarks);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isApprove ? AppColors.success : AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text(isApprove ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRequestStatus(String type, String requestId, String newStatus, String remarks) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final endpoint = type == 'leave' ? '/leave/$requestId/status' : '/od/$requestId/status';
      await apiClient.put(endpoint, body: {
        'status': newStatus,
        'remarks': remarks,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request marked as ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _toggleAchievementVerification(String achId, bool verifyTarget) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/achievements/$achId/verify', body: {
        'verified': verifyTarget,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifyTarget ? 'Achievement verified successfully' : 'Achievement marked as rejected'),
            backgroundColor: verifyTarget ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _fetchAllData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_student != null ? _student!['full_name'] : 'Student Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppColors.primaryBlue),
            tooltip: 'Ask AI Assistant about this student',
            onPressed: () {
              final studentName = _student != null ? _student!['full_name'] : 'Student';
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIMentorAssistantScreen(
                    initialStudentId: widget.studentId,
                    initialStudentName: studentName,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.secondaryText,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Attendance'),
            Tab(text: 'Marks'),
            Tab(text: 'Leave/OD'),
            Tab(text: 'Achievements'),
            Tab(text: 'Mentor Notes'),
            Tab(text: 'Meetings'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Verifying authorization and fetching student records...')
            : _errorMessage != null
                ? AppErrorState(
                    title: 'Authorization or Lookup Error',
                    message: _errorMessage!,
                    onRetry: _fetchAllData,
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileSection(),
                      _buildAttendanceSection(),
                      _buildMarksSection(),
                      _buildLeaveODSection(),
                      _buildAchievementsSection(),
                      _buildNotesSection(),
                      _buildMeetingsSection(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBox(
            title: 'Assigned Mentee Verified',
            message: 'Real student profile retrieved from MongoDB. Backend authorization confirmed.',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Full Name', _student?['full_name'] ?? ''),
                _buildRow('College Email', _student?['college_email'] ?? ''),
                _buildRow('Primary Phone', _student?['phone_number'] ?? ''),
                _buildRow('Date of Birth', _student?['date_of_birth'] ?? ''),
                _buildRow('Gender', _student?['gender'] ?? ''),
                if (_student?['personal_email'] != null) _buildRow('Personal Email', _student!['personal_email']),
                _buildRow('Address', '${_student?['address']}, ${_student?['city']}, ${_student?['state']} - ${_student?['pincode']}'),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('College & Academic Standing', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Register Number', _student?['register_number'] ?? ''),
                _buildRow('Department', _student?['department'] ?? ''),
                _buildRow('Course & Year', '${_student?['course']} - Year ${_student?['year']} (Sem ${_student?['semester']})'),
                if (_student?['section'] != null) _buildRow('Section', _student!['section']),
                _buildRow('Admission Year', '${_student?['admission_year']}'),
                _buildRow('CGPA', _student?['cgpa'] != null ? '${_student!['cgpa']}' : 'Not specified'),
                _buildRow('Backlog Count', '${_student?['backlog_count'] ?? 0}'),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Parent / Guardian Contacts', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                _buildRow('Parent Name', _student?['parent_name'] ?? ''),
                _buildRow('Relationship', _student?['relationship'] ?? ''),
                _buildRow('Parent Phone', _student?['parent_phone'] ?? ''),
                if (_student?['parent_email'] != null) _buildRow('Parent Email', _student!['parent_email']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    final records = (_attendanceData?['records'] as List<dynamic>?) ?? [];
    final subjectWise = (_attendanceData?['subject_wise'] as List<dynamic>?) ?? [];
    final num? pctNum = _attendanceData?['attendance_percentage'];
    final double? pct = pctNum?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Attendance Management', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Log Attendance',
                icon: Icons.add,
                onPressed: _showLogAttendanceDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const AppEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Attendance data is not available yet.',
              description: 'No attendance records logged for this student in MongoDB.',
            )
          else ...[
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricColumn('Overall Attendance', pct != null ? '$pct%' : 'N/A', color: (pct ?? 0) >= 75 ? AppColors.success : AppColors.error),
                      _buildMetricColumn('Total Records', '${_attendanceData?['total_days'] ?? 0}'),
                      _buildMetricColumn('Present', '${_attendanceData?['present_days'] ?? 0}'),
                      _buildMetricColumn('Late', '${_attendanceData?['late_days'] ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (subjectWise.isNotEmpty) ...[
              const Text('Subject-Wise Attendance Breakdown', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...subjectWise.map((s) {
                final double sPct = ((s['attendance_percentage'] as num?) ?? 0.0).toDouble();
                return AppCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s['subject_code']} ${s['subject_name'] != null ? "- ${s['subject_name']}" : ""}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('Classes Attended: ${s['attended_classes']} / ${s['total_classes']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sPct >= 75 ? AppColors.success.withAlpha(30) : AppColors.error.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$sPct%', style: TextStyle(color: sPct >= 75 ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            const Text('Date-Wise Attendance History', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...records.map((r) {
              final String st = r['status'] ?? 'present';
              return AppCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['date'] ?? '', style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                        if (r['subject_code'] != null)
                          Text('Subject: ${r['subject_code']} ${r['period_session'] != null ? "(${r['period_session']})" : ""}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        if (r['remarks'] != null)
                          Text('Remarks: ${r['remarks']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                      ],
                    ),
                    _buildStatusBadge(st),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMarksSection() {
    final records = (_marksData?['records'] as List<dynamic>?) ?? [];
    final semPerf = (_marksData?['semester_performance'] as List<dynamic>?) ?? [];
    final subPerf = (_marksData?['subject_performance'] as List<dynamic>?) ?? [];
    final examPerf = (_marksData?['exam_performance'] as List<dynamic>?) ?? [];
    final num? avgPctNum = _marksData?['average_percentage'];
    final double? avgPct = avgPctNum?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Academic Marks & Performance', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Log Subject Marks',
                icon: Icons.add,
                onPressed: _showLogMarksDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const AppEmptyState(
              icon: Icons.grade_outlined,
              title: 'No marks records available yet.',
              description: 'No academic exam marks logged for this student in MongoDB.',
            )
          else ...[
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricColumn('Overall Average', avgPct != null ? '$avgPct%' : 'N/A', color: AppColors.primaryBlue),
                  _buildMetricColumn('Total Exam Records', '${_marksData?['total_records'] ?? 0}'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (semPerf.isNotEmpty) ...[
              const Text('Semester Performance Summary', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...semPerf.map((sp) {
                final double sAvg = ((sp['average_percentage'] as num?) ?? 0.0).toDouble();
                return AppCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Semester ${sp['semester']} (${sp['total_exams']} Exams)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                      Text('$sAvg%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 15)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            if (subPerf.isNotEmpty) ...[
              const Text('Subject-Wise Performance Breakdown', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...subPerf.map((sb) {
                final double sbAvg = ((sb['average_percentage'] as num?) ?? 0.0).toDouble();
                return AppCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${sb['subject_code']} - ${sb['subject_name']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 14)),
                          Text('Exams Recorded: ${sb['total_exams']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        ],
                      ),
                      Text('$sbAvg%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 15)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            if (examPerf.isNotEmpty) ...[
              const Text('Exam-Wise Performance Breakdown', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...examPerf.map((ep) {
                final double epAvg = ((ep['average_percentage'] as num?) ?? 0.0).toDouble();
                return AppCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${ep['exam_type']} Exams (${ep['total_exams']} Total)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue)),
                      Text('$epAvg%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 15)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            const Text('Exam Records History', style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...records.map((m) {
              return AppCard(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${m['subject_code']} - ${m['subject_name']}', style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('Grade: ${m['grade'] ?? "N/A"}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${m['exam_type']} ${m['exam_name'] != null ? "(${m['exam_name']})" : ""} • Sem ${m['semester']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        Text('${m['marks_obtained']} / ${m['max_marks']} (${m['percentage']}%)', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaveODSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Applications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_leaveRequests.isEmpty)
            const AppEmptyState(icon: Icons.event_note, title: 'No leave requests submitted.', description: 'Leave applications submitted by this student will appear here.')
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
                        Text('Leave: ${l['start_date']} to ${l['end_date']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkBlue)),
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
                    if (l['mentor_remarks'] != null && (l['mentor_remarks'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Mentor Remarks: ${l['mentor_remarks']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    if (st == 'pending') ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showReviewDialog('leave', reqId, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showReviewDialog('leave', reqId, 'approved_by_mentor'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),
          const Text('On-Duty (OD) Requests', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_odRequests.isEmpty)
            const AppEmptyState(icon: Icons.card_membership, title: 'No OD requests submitted.', description: 'On-Duty activity applications will appear here.')
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
                        Text('OD: ${o['event_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkBlue)),
                        _buildStatusBadge(st),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Org: ${o['organization']} (${o['start_date']} to ${o['end_date']})', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
                    Text('Reason: ${o['reason']}', style: const TextStyle(color: AppColors.primaryText)),
                    if (proofUrl != null && proofUrl.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Proof Document: $proofUrl', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ],
                    if (o['mentor_remarks'] != null && (o['mentor_remarks'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text('Mentor Remarks: ${o['mentor_remarks']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    if (st == 'pending') ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _showReviewDialog('od', reqId, 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _showReviewDialog('od', reqId, 'approved_by_mentor'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          ),
                        ],
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

  Widget _buildAchievementsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Student Achievements & Certifications', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_achievements.isEmpty)
            const AppEmptyState(icon: Icons.emoji_events_outlined, title: 'No achievements recorded.', description: 'Certificates and awards submitted by this student will appear here.')
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
                    Text('Date Awarded: ${a['date_awarded']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                    if (certUrl != null && certUrl.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Document Link: $certUrl', style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, decoration: TextDecoration.underline)),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status != 'rejected')
                          OutlinedButton(
                            onPressed: () => _toggleAchievementVerification(achId, false),
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Reject'),
                          ),
                        const SizedBox(width: 8),
                        if (!isVerified)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Verify Record'),
                            onPressed: () => _toggleAchievementVerification(achId, true),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mentor Notes & Observations', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Add Note',
                icon: Icons.add,
                onPressed: _showAddNoteDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mentorNotes.isEmpty)
            const AppEmptyState(icon: Icons.lock_outline, title: 'No mentor notes logged.', description: 'Private observations and counseling notes for this student will appear here.')
          else
            ..._mentorNotes.map((n) {
              final bool isVisible = n['is_student_visible'] == true;
              final String? followUp = n['follow_up_date'];
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
                              Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.lightBlue, borderRadius: BorderRadius.circular(8)),
                                child: Text(n['category'] ?? 'General Note', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? AppColors.success.withAlpha(30) : AppColors.darkBlue.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVisible ? 'SHARED WITH STUDENT' : 'PRIVATE MENTOR NOTE',
                            style: TextStyle(color: isVisible ? AppColors.success : AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  Widget _buildMeetingsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Counseling & Meeting Records', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
              AppButton(
                text: 'Log Meeting',
                icon: Icons.add,
                onPressed: _showScheduleMeetingDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_meetings.isEmpty)
            const AppEmptyState(icon: Icons.groups_outlined, title: 'No meeting records logged.', description: 'Counseling session logs and agreed action items will appear here.')
          else
            ..._meetings.map((m) {
              final bool isVisible = m['is_student_visible'] == true;
              final String? actions = m['action_items'];
              final String? followUp = m['follow_up_date'];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(m['topic'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkBlue)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVisible ? AppColors.success.withAlpha(30) : AppColors.darkBlue.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVisible ? 'STUDENT VISIBLE' : 'CONFIDENTIAL LOG',
                            style: TextStyle(color: isVisible ? AppColors.success : AppColors.darkBlue, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Date: ${m['date']}', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
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
    String label = status.replaceAll('_', ' ').toUpperCase();

    if (status == 'present' || status == 'approved_by_mentor' || status == 'approved_by_hod') {
      bg = AppColors.success.withAlpha(30);
      fg = AppColors.success;
    } else if (status == 'absent' || status == 'rejected') {
      bg = AppColors.error.withAlpha(30);
      fg = AppColors.error;
    } else {
      bg = AppColors.lightBlue;
      fg = AppColors.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
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
