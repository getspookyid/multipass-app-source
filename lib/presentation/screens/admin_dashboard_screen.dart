import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../data/services/admin_dashboard_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String accessToken;

  const AdminDashboardScreen({
    super.key,
    required this.accessToken,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _service = AdminDashboardService();
  
  DashboardMetrics? _metrics;
  List<AuthEvent>? _events;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final metrics = await _service.getMetrics(widget.accessToken);
      final events = await _service.getRecentAuth(widget.accessToken);
      
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _events = events;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        
        // If token expired, navigate back
        if (e.toString().contains('expired') || e.toString().contains('401')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  String _formatUptime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading && _metrics == null
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.electricBlue,
                strokeWidth: 3,
              ),
            )
          : _error != null && _metrics == null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.electricBlue,
                  child: _buildDashboard(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.hotPink),
            const SizedBox(height: 16),
            Text(
              'Failed to load metrics',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('RETRY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    if (_metrics == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Authentication Metrics
        _MetricCard(
          icon: Icons.verified_user,
          title: 'Authentication',
          color: AppTheme.electricBlue,
          children: [
            _MetricRow('Total Verifications', '${_metrics!.authentication.totalVerifications}'),
            _MetricRow('Last 24h', '${_metrics!.authentication.recentVerifications24h}'),
            _MetricRow('Failed (24h)', '${_metrics!.authentication.failedAttempts24h}',
                valueColor: _metrics!.authentication.failedAttempts24h > 0 ? AppTheme.hotPink : Colors.white70),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Device Metrics
        _MetricCard(
          icon: Icons.devices,
          title: 'Devices',
          color: const Color(0xFF00D9AA),
          children: [
            _MetricRow('Total Registered', '${_metrics!.devices.totalRegistered}'),
            _MetricRow('Active Sessions', '${_metrics!.devices.activeSessions}'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Security Metrics
        _MetricCard(
          icon: Icons.shield,
          title: 'Security',
          color: AppTheme.hotPink,
          children: [
            _MetricRow('Root Anchor', _metrics!.security.rootAnchor, monospace: true),
            _MetricRow('Revoked Tags', '${_metrics!.security.revokedTagsCount}'),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // System Metrics
        _MetricCard(
          icon: Icons.dns,
          title: 'System',
          color: const Color(0xFFFFD700),
          children: [
            _MetricRow('Uptime', _formatUptime(_metrics!.system.uptimeSeconds)),
            _MetricRow('Version', _metrics!.system.version),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Recent Events
        Text(
          'Recent Authentication Events',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (_events == null || _events!.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Text(
                'No recent events',
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ),
          )
        else
          ..._events!.take(10).map((event) => _EventTile(event: event)),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool monospace;

  const _MetricRow(
    this.label,
    this.value, {
    this.valueColor,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white60,
            ),
          ),
          Text(
            value,
            style: monospace
                ? GoogleFonts.robotoMono(
                    fontSize: 13,
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.outfit(
                    fontSize: 16,
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final AuthEvent event;

  const _EventTile({required this.event});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = event.status == 'success';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? AppTheme.electricBlue.withOpacity(0.2)
              : AppTheme.hotPink.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.cancel,
            color: isSuccess ? AppTheme.electricBlue : AppTheme.hotPink,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.linkageTag,
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.disclosedAttributes} attributes disclosed',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(event.dateTime),
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
