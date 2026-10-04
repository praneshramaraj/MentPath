import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';

class AIMessage {
  final String text;
  final bool isUser;
  final bool isDataSufficient;
  final int? assignedCount;
  final String timestamp;

  AIMessage({
    required this.text,
    required this.isUser,
    this.isDataSufficient = true,
    this.assignedCount,
    required this.timestamp,
  });
}

class AIMentorAssistantScreen extends ConsumerStatefulWidget {
  final String? initialStudentId;
  final String? initialStudentName;

  const AIMentorAssistantScreen({
    super.key,
    this.initialStudentId,
    this.initialStudentName,
  });

  @override
  ConsumerState<AIMentorAssistantScreen> createState() => _AIMentorAssistantScreenState();
}

class _AIMentorAssistantScreenState extends ConsumerState<AIMentorAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessage> _messages = [];
  bool _isLoading = false;
  double _attendanceThreshold = 75.0;

  @override
  void initState() {
    super.initState();
    // Add welcome message from AI Assistant
    _messages.add(
      AIMessage(
        text: widget.initialStudentName != null
            ? "Hello! I am your AI Mentor Assistant. How can I help you analyze real database records for **${widget.initialStudentName}**?"
            : "Hello! I am your AI Mentor Assistant. Ask me anything about your assigned students based strictly on real database records.",
        isUser: false,
        timestamp: _getCurrentTimeStr(),
      ),
    );
  }

  String _getCurrentTimeStr() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _sendQuery([String? customQuery]) async {
    final queryText = (customQuery ?? _queryController.text).trim();
    if (queryText.isEmpty || _isLoading) return;

    if (customQuery == null) {
      _queryController.clear();
    }

    setState(() {
      _messages.add(AIMessage(
        text: queryText,
        isUser: true,
        timestamp: _getCurrentTimeStr(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post('/ai-mentor/query', body: {
        'query': queryText,
        'student_id': widget.initialStudentId,
        'attendance_threshold': _attendanceThreshold,
      });

      final String aiResponse = response.data['response'] ?? "I don't have enough recorded data to answer that.";
      final bool isSufficient = response.data['is_data_sufficient'] ?? true;
      final int count = response.data['assigned_students_count'] ?? 0;

      if (mounted) {
        setState(() {
          _messages.add(AIMessage(
            text: aiResponse,
            isUser: false,
            isDataSufficient: isSufficient,
            assignedCount: count,
            timestamp: _getCurrentTimeStr(),
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(AIMessage(
            text: "I don't have enough recorded data to answer that.",
            isUser: false,
            isDataSufficient: false,
            timestamp: _getCurrentTimeStr(),
          ));
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showThresholdDialog() {
    double tempVal = _attendanceThreshold;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Configure Attendance Threshold', style: TextStyle(color: AppColors.darkBlue, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Alert threshold for low attendance analysis: ${tempVal.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
              const SizedBox(height: 10),
              Slider(
                value: tempVal,
                min: 50.0,
                max: 95.0,
                divisions: 45,
                activeColor: AppColors.primaryBlue,
                label: '${tempVal.toStringAsFixed(1)}%',
                onChanged: (val) {
                  setDialogState(() {
                    tempVal = val;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            AppButton(
              text: 'Save',
              onPressed: () {
                setState(() {
                  _attendanceThreshold = tempVal;
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Mentor Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text(
              widget.initialStudentName != null
                  ? 'Analyzing ${widget.initialStudentName}'
                  : 'Zero-Hallucination Database Intelligence',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: AppColors.darkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Attendance Threshold (${_attendanceThreshold.toInt()}%)',
            onPressed: _showThresholdDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Action Suggestion Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip(
                    label: 'Low Attendance (<${_attendanceThreshold.toInt()}%)',
                    icon: Icons.warning_amber_rounded,
                    onTap: () => _sendQuery('Show students with attendance below ${_attendanceThreshold.toInt()}%'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    label: 'Missing Marks',
                    icon: Icons.grade_outlined,
                    onTap: () => _sendQuery('Which students have missing marks?'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    label: 'Academic Summary',
                    icon: Icons.auto_graph,
                    onTap: () => _sendQuery("Summarize this student's academic progress."),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickChip(
                    label: 'Follow-ups Needed',
                    icon: Icons.event_repeat,
                    onTap: () => _sendQuery('Which assigned students need follow-up based on available records?'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                  ),
                  SizedBox(width: 10),
                  Text('Querying database & generating response...', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                ],
              ),
            ),

          // Bottom Input Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendQuery(),
                    decoration: InputDecoration(
                      hintText: 'Ask AI Assistant about assigned students...',
                      hintStyle: const TextStyle(fontSize: 14, color: AppColors.secondaryText),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: () => _sendQuery(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primaryBlue),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage msg) {
    final bool isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: AppCard(
          backgroundColor: isUser ? AppColors.darkBlue : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isUser ? Icons.person : Icons.smart_toy_outlined,
                        size: 16,
                        color: isUser ? Colors.white70 : AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUser ? 'You (Mentor)' : 'AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isUser ? Colors.white : AppColors.darkBlue,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    msg.timestamp,
                    style: TextStyle(fontSize: 10, color: isUser ? Colors.white60 : AppColors.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.primaryText,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (!isUser && msg.assignedCount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: msg.isDataSufficient ? AppColors.lightBlue : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        msg.isDataSufficient
                            ? 'Ground-truth DB Verified (${msg.assignedCount} students analyzed)'
                            : 'Insufficient Database Information',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: msg.isDataSufficient ? AppColors.primaryBlue : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
