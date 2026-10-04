class DatabaseHealthInfo {
  final String status;
  final String details;
  final String? dbName;

  const DatabaseHealthInfo({
    required this.status,
    required this.details,
    this.dbName,
  });

  factory DatabaseHealthInfo.fromJson(Map<String, dynamic> json) {
    return DatabaseHealthInfo(
      status: json['status'] ?? 'unknown',
      details: json['details'] ?? '',
      dbName: json['db_name'],
    );
  }
}

class SystemHealthStatus {
  final String status;
  final String appName;
  final String version;
  final String environment;
  final DateTime timestamp;
  final DatabaseHealthInfo database;

  const SystemHealthStatus({
    required this.status,
    required this.appName,
    required this.version,
    required this.environment,
    required this.timestamp,
    required this.database,
  });

  factory SystemHealthStatus.fromJson(Map<String, dynamic> json) {
    return SystemHealthStatus(
      status: json['status'] ?? 'unknown',
      appName: json['app_name'] ?? 'System',
      version: json['version'] ?? '1.0.0',
      environment: json['environment'] ?? 'development',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      database: DatabaseHealthInfo.fromJson(json['database'] ?? {}),
    );
  }
}
