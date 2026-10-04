import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class StudentProfileSetupScreen extends ConsumerStatefulWidget {
  const StudentProfileSetupScreen({super.key});

  @override
  ConsumerState<StudentProfileSetupScreen> createState() => _StudentProfileSetupScreenState();
}

class _StudentProfileSetupScreenState extends ConsumerState<StudentProfileSetupScreen> {
  int _currentStep = 0;
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  // Section 1: Personal
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String _gender = 'Male';
  final _phoneController = TextEditingController();
  final _collegeEmailController = TextEditingController();
  final _personalEmailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // Section 2: College
  final _regNumberController = TextEditingController();
  String _department = 'Computer Science & Engineering';
  String _course = 'B.E.';
  int _year = 1;
  int _semester = 1;
  final _sectionController = TextEditingController();
  int _admissionYear = DateTime.now().year;

  // Section 3: Parent
  final _parentNameController = TextEditingController();
  String _relationship = 'Father';
  final _parentPhoneController = TextEditingController();
  final _parentEmailController = TextEditingController();

  // Section 4: Academic
  final _cgpaController = TextEditingController();
  final _prevSemController = TextEditingController();
  final _backlogController = TextEditingController(text: '0');

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _collegeEmailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _collegeEmailController.dispose();
    _personalEmailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _regNumberController.dispose();
    _sectionController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _cgpaController.dispose();
    _prevSemController.dispose();
    _backlogController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2003, 1, 1),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _nextStep() {
    FormState? currentForm;
    if (_currentStep == 0) currentForm = _step1FormKey.currentState;
    if (_currentStep == 1) currentForm = _step2FormKey.currentState;
    if (_currentStep == 2) currentForm = _step3FormKey.currentState;

    if (currentForm != null && currentForm.validate()) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitProfile() async {
    if (!_step4FormKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      final payload = {
        'full_name': _nameController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'gender': _gender,
        'phone_number': _phoneController.text.trim(),
        'college_email': _collegeEmailController.text.trim(),
        'personal_email': _personalEmailController.text.trim().isNotEmpty ? _personalEmailController.text.trim() : null,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'register_number': _regNumberController.text.trim(),
        'department': _department,
        'course': _course,
        'year': _year,
        'semester': _semester,
        'section': _sectionController.text.trim().isNotEmpty ? _sectionController.text.trim() : null,
        'admission_year': _admissionYear,
        'parent_name': _parentNameController.text.trim(),
        'relationship': _relationship,
        'parent_phone': _parentPhoneController.text.trim(),
        'parent_email': _parentEmailController.text.trim().isNotEmpty ? _parentEmailController.text.trim() : null,
        'cgpa': _cgpaController.text.trim().isNotEmpty ? double.tryParse(_cgpaController.text.trim()) : null,
        'previous_semester_info': _prevSemController.text.trim().isNotEmpty ? _prevSemController.text.trim() : null,
        'backlog_count': int.tryParse(_backlogController.text.trim()) ?? 0,
      };

      await apiClient.post('/student/profile', body: payload);

      // Refresh auth status in Riverpod -> updates isProfileComplete -> auto-redirects to Dashboard
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup completed successfully! Welcome to Student Dashboard.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    final double progress = (_currentStep + 1) / 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Profile Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryBlue),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar Header
            Container(
              color: AppColors.lightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Section ${_currentStep + 1} of 4: ${_getStepTitle(_currentStep)}',
                        style: const TextStyle(
                          color: AppColors.darkBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.border,
                    color: AppColors.primaryBlue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: IndexedStack(
                    index: _currentStep,
                    children: [
                      _buildPersonalSection(),
                      _buildCollegeSection(),
                      _buildParentSection(),
                      _buildAcademicSection(),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: AppButton(
                        text: 'Previous',
                        onPressed: _prevStep,
                        variant: AppButtonVariant.secondary,
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _currentStep < 3
                        ? AppButton(
                            text: 'Next Section',
                            icon: Icons.arrow_forward,
                            onPressed: _nextStep,
                          )
                        : AppButton(
                            text: 'Save & Submit Profile',
                            icon: Icons.check_circle,
                            isLoading: _isSubmitting,
                            onPressed: _submitProfile,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Information';
      case 1:
        return 'College Details';
      case 2:
        return 'Parent / Guardian Details';
      case 3:
        return 'Academic History';
      default:
        return '';
    }
  }

  Widget _buildPersonalSection() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Details',
            style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('Fields marked with * are required.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, color: AppColors.primaryBlue)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dobController,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: 'Date of Birth (YYYY-MM-DD) *',
              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue),
              suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.secondaryText),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Select date of birth' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender *', prefixIcon: Icon(Icons.wc, color: AppColors.primaryBlue)),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
              DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
            ],
            onChanged: (v) => setState(() => _gender = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone Number (10 Digits) *', prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryBlue)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter phone number';
              final cleaned = v.replaceAll(RegExp(r'\D'), '');
              if (cleaned.length != 10) return 'Phone number must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _collegeEmailController,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'College Email * (Account Email)', prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondaryText)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _personalEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Personal Email (Optional)', prefixIcon: Icon(Icons.mark_email_read_outlined, color: AppColors.primaryBlue)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Residential Address *', prefixIcon: Icon(Icons.home_outlined, color: AppColors.primaryBlue)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter city' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter state' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode (6 Digits) *', prefixIcon: Icon(Icons.pin_drop_outlined, color: AppColors.primaryBlue)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter pincode';
              final cleaned = v.replaceAll(RegExp(r'\D'), '');
              if (cleaned.length != 6) return 'Pincode must be 6 digits';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCollegeSection() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('College Details', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Academic registration details.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _regNumberController,
            decoration: const InputDecoration(labelText: 'Register Number *', prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primaryBlue), hintText: 'e.g. 710021104001'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter college register number' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _department,
            decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.primaryBlue)),
            items: const [
              DropdownMenuItem(value: 'Computer Science & Engineering', child: Text('Computer Science & Engineering')),
              DropdownMenuItem(value: 'Information Technology', child: Text('Information Technology')),
              DropdownMenuItem(value: 'Electronics & Communication', child: Text('Electronics & Communication')),
              DropdownMenuItem(value: 'Electrical & Electronics', child: Text('Electrical & Electronics')),
              DropdownMenuItem(value: 'Mechanical Engineering', child: Text('Mechanical Engineering')),
              DropdownMenuItem(value: 'Civil Engineering', child: Text('Civil Engineering')),
            ],
            onChanged: (v) => setState(() => _department = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _course,
                  decoration: const InputDecoration(labelText: 'Course *'),
                  items: const [
                    DropdownMenuItem(value: 'B.E.', child: Text('B.E.')),
                    DropdownMenuItem(value: 'B.Tech.', child: Text('B.Tech.')),
                    DropdownMenuItem(value: 'M.E.', child: Text('M.E.')),
                    DropdownMenuItem(value: 'M.Tech.', child: Text('M.Tech.')),
                    DropdownMenuItem(value: 'M.C.A.', child: Text('M.C.A.')),
                  ],
                  onChanged: (v) => setState(() => _course = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(labelText: 'Year *'),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1st Year')),
                    DropdownMenuItem(value: 2, child: Text('2nd Year')),
                    DropdownMenuItem(value: 3, child: Text('3rd Year')),
                    DropdownMenuItem(value: 4, child: Text('4th Year')),
                  ],
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _semester,
                  decoration: const InputDecoration(labelText: 'Semester *'),
                  items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Semester ${i + 1}'))),
                  onChanged: (v) => setState(() => _semester = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _sectionController,
                  decoration: const InputDecoration(labelText: 'Section (Optional)', hintText: 'e.g. A'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _admissionYear,
            decoration: const InputDecoration(labelText: 'Admission Year *', prefixIcon: Icon(Icons.event_outlined, color: AppColors.primaryBlue)),
            items: List.generate(10, (i) {
              final y = DateTime.now().year - i;
              return DropdownMenuItem(value: y, child: Text('$y'));
            }),
            onChanged: (v) => setState(() => _admissionYear = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildParentSection() {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Parent / Guardian Details', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Emergency contact and guardian details.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _parentNameController,
            decoration: const InputDecoration(labelText: 'Parent / Guardian Name *', prefixIcon: Icon(Icons.escalator_warning_outlined, color: AppColors.primaryBlue)),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter parent/guardian name' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: const InputDecoration(labelText: 'Relationship *', prefixIcon: Icon(Icons.family_restroom_outlined, color: AppColors.primaryBlue)),
            items: const [
              DropdownMenuItem(value: 'Father', child: Text('Father')),
              DropdownMenuItem(value: 'Mother', child: Text('Mother')),
              DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
            ],
            onChanged: (v) => setState(() => _relationship = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _parentPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Parent Phone Number (10 Digits) *', prefixIcon: Icon(Icons.phone_in_talk_outlined, color: AppColors.primaryBlue)),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter parent phone number';
              final cleaned = v.replaceAll(RegExp(r'\D'), '');
              if (cleaned.length != 10) return 'Phone number must be 10 digits';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _parentEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Parent Email (Optional)', prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection() {
    return Form(
      key: _step4FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Academic History', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Current academic standing (Optional fields can be updated later).', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cgpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Current CGPA (Optional)', hintText: 'e.g. 8.5', prefixIcon: Icon(Icons.grade_outlined, color: AppColors.primaryBlue)),
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                final val = double.tryParse(v.trim());
                if (val == null || val < 0.0 || val > 10.0) return 'Enter valid CGPA (0.0 to 10.0)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _prevSemController,
            decoration: const InputDecoration(labelText: 'Previous Semester Summary (Optional)', hintText: 'e.g. Passed all subjects in Sem 1', prefixIcon: Icon(Icons.history_edu_outlined, color: AppColors.primaryBlue)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _backlogController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Active Backlog Count (Optional)', prefixIcon: Icon(Icons.format_list_numbered_outlined, color: AppColors.primaryBlue)),
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                final val = int.tryParse(v.trim());
                if (val == null || val < 0) return 'Enter valid backlog count';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
