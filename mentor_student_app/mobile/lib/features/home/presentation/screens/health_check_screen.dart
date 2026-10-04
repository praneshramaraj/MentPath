import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/health_status.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_box.dart';
import '../../../../shared/widgets/loading_indicator.dart';

class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  SystemHealthStatus? _healthStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHealthStatus();
  }

  Future<void> _fetchHealthStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonResponse = await _apiClient.get('/health');
      final health = SystemHealthStatus.fromJson(jsonResponse);
      setState(() {
        _healthStatus = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Foundation & Health'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _fetchHealthStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator(message: 'Verifying FastAPI & MongoDB status...')
            : _errorMessage != null
                ? AppErrorState(
                    title: 'Backend Connection Error',
                    message: _errorMessage!,
                    onRetry: _fetchHealthStatus,
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const InfoBox(
                          title: 'Phase 1 Architecture Active',
                          message:
                              'Backend, MongoDB connection, CORS, JWT security architecture, and Material 3 design system are configured. No sample database records created.',
                          icon: Icons.check_circle_outline,
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Real-Time Health Status',
                            style: TextStyle(
                              color: AppColors.darkBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusRow(
                                label: 'API System Status',
                                value: _healthStatus!.status.toUpperCase(),
                                isSuccess: _healthStatus!.status == 'healthy',
                              ),
                              const Divider(height: 24),
                              _buildDetailRow('Application Name', _healthStatus!.appName),
                              _buildDetailRow('API Version', _healthStatus!.version),
                              _buildDetailRow('Environment', _healthStatus!.environment),
                              _buildDetailRow('Last Ping Time', _healthStatus!.timestamp.toIso8601String()),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Database Connectivity',
                            style: TextStyle(
                              color: AppColors.darkBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusRow(
                                label: 'MongoDB Connection',
                                value: _healthStatus!.database.status.toUpperCase(),
                                isSuccess: _healthStatus!.database.status == 'connected',
                              ),
                              const Divider(height: 24),
                              _buildDetailRow('Target Database', _healthStatus!.database.dbName ?? 'N/A'),
                              _buildDetailRow('Connection Details', _healthStatus!.database.details),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AppButton(
                            text: 'Re-verify API Health',
                            icon: Icons.sync,
                            onPressed: _fetchHealthStatus,
                            width: double.infinity,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required String value,
    required bool isSuccess,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSuccess
                ? AppColors.success.withAlpha(30)
                : AppColors.error.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSuccess ? AppColors.success : AppColors.error,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                size: 14,
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isSuccess ? AppColors.success : AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
