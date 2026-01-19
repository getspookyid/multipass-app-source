import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service for admin dashboard API calls
class AdminDashboardService {
  final String baseUrl;

  AdminDashboardService({this.baseUrl = 'http://localhost:7777'});

  /// Fetches comprehensive system metrics
  Future<DashboardMetrics> getMetrics(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/metrics'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DashboardMetrics.fromJson(data);
    } else if (response.statusCode == 401) {
      throw Exception('Token expired or invalid');
    } else {
      throw Exception('Failed to load metrics: ${response.statusCode}');
    }
  }

  /// Fetches recent authentication events
  Future<List<AuthEvent>> getRecentAuth(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/recent_auth'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final eventsList = data['events'] as List;
      return eventsList.map((e) => AuthEvent.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Token expired or invalid');
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  }
}

/// Dashboard metrics data model
class DashboardMetrics {
  final AuthenticationMetrics authentication;
  final DeviceMetrics devices;
  final SecurityMetrics security;
  final SystemMetrics system;

  DashboardMetrics({
    required this.authentication,
    required this.devices,
    required this.security,
    required this.system,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      authentication: AuthenticationMetrics.fromJson(json['authentication']),
      devices: DeviceMetrics.fromJson(json['devices']),
      security: SecurityMetrics.fromJson(json['security']),
      system: SystemMetrics.fromJson(json['system']),
    );
  }
}

class AuthenticationMetrics {
  final int totalVerifications;
  final int recentVerifications24h;
  final int failedAttempts24h;

  AuthenticationMetrics({
    required this.totalVerifications,
    required this.recentVerifications24h,
    required this.failedAttempts24h,
  });

  factory AuthenticationMetrics.fromJson(Map<String, dynamic> json) {
    return AuthenticationMetrics(
      totalVerifications: json['total_verifications'] ?? 0,
      recentVerifications24h: json['recent_verifications_24h'] ?? 0,
      failedAttempts24h: json['failed_attempts_24h'] ?? 0,
    );
  }
}

class DeviceMetrics {
  final int totalRegistered;
  final int activeSessions;

  DeviceMetrics({
    required this.totalRegistered,
    required this.activeSessions,
  });

  factory DeviceMetrics.fromJson(Map<String, dynamic> json) {
    return DeviceMetrics(
      totalRegistered: json['total_registered'] ?? 0,
      activeSessions: json['active_sessions'] ?? 0,
    );
  }
}

class SecurityMetrics {
  final String rootAnchor;
  final int revokedTagsCount;

  SecurityMetrics({
    required this.rootAnchor,
    required this.revokedTagsCount,
  });

  factory SecurityMetrics.fromJson(Map<String, dynamic> json) {
    return SecurityMetrics(
      rootAnchor: json['root_anchor'] ?? 'Not established',
      revokedTagsCount: json['revoked_tags_count'] ?? 0,
    );
  }
}

class SystemMetrics {
  final int uptimeSeconds;
  final String version;

  SystemMetrics({
    required this.uptimeSeconds,
    required this.version,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      uptimeSeconds: json['uptime_seconds'] ?? 0,
      version: json['version'] ?? 'Unknown',
    );
  }
}

/// Authentication event model
class AuthEvent {
  final int timestamp;
  final String linkageTag;
  final String status;
  final int disclosedAttributes;

  AuthEvent({
    required this.timestamp,
    required this.linkageTag,
    required this.status,
    required this.disclosedAttributes,
  });

  factory AuthEvent.fromJson(Map<String, dynamic> json) {
    return AuthEvent(
      timestamp: json['timestamp'] ?? 0,
      linkageTag: json['linkage_tag'] ?? '',
      status: json['status'] ?? 'unknown',
      disclosedAttributes: json['disclosed_attributes'] ?? 0,
    );
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
}
