import 'dart:async';
import 'package:flutter/material.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/security_service.dart';
import 'package:monitored_app/core/services/anti_tamper_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  late SecurityService _securityService;
  late AntiTamperService _antiTamperService;
  
  Map<String, dynamic> _securityStatus = {};
  Map<String, dynamic> _protectionStatus = {};
  List<Map<String, dynamic>> _recentEvents = [];
  bool _isLoading = false;
  
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _securityService = locator<SecurityService>();
    _antiTamperService = locator<AntiTamperService>();
    _loadSecurityData();
    
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadSecurityData();
    });
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadSecurityData() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final securityStatus = await _securityService.getProtectionStatus();
      final protectionStatus = _antiTamperService.getProtectionStatus();
      final recentEvents = _antiTamperService.getRecentEvents(limit: 10);
      
      if (mounted) {
        setState(() {
          _securityStatus = securityStatus;
          _protectionStatus = protectionStatus;
          _recentEvents = recentEvents;
        });
      }
    } catch (e) {
      debugPrint('Error loading security data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Anti-Tampering'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSecurityData,
          ),
        ],
      ),
      body: _isLoading && _securityStatus.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityOverview(),
                  const SizedBox(height: 24),
                  _buildProtectionControls(),
                  const SizedBox(height: 24),
                  _buildThreatDetection(),
                  const SizedBox(height: 24),
                  _buildSecurityActions(),
                  const SizedBox(height: 24),
                  _buildRecentEvents(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSecurityOverview() {
    final isDeviceAdmin = _securityStatus['device_admin_active'] as bool? ?? false;
    final threatLevel = _securityStatus['threat_level'] as String? ?? 'none';
    final protectionEnabled = _protectionStatus['enabled'] as bool? ?? false;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    if (threatLevel == 'critical') {
      statusColor = Colors.red;
      statusText = 'CRITICAL THREATS DETECTED';
      statusIcon = Icons.warning;
    } else if (threatLevel == 'high') {
      statusColor = Colors.orange;
      statusText = 'HIGH SECURITY RISK';
      statusIcon = Icons.error;
    } else if (protectionEnabled && isDeviceAdmin) {
      statusColor = Colors.green;
      statusText = 'SECURE';
      statusIcon = Icons.security;
    } else {
      statusColor = Colors.amber;
      statusText = 'PARTIALLY PROTECTED';
      statusIcon = Icons.shield;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Device Admin',
                    isDeviceAdmin ? 'Active' : 'Inactive',
                    isDeviceAdmin ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Anti-Tamper',
                    protectionEnabled ? 'Enabled' : 'Disabled',
                    protectionEnabled ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Threats',
                    '${_securityStatus['threats_detected'] ?? 0}',
                    (_securityStatus['threats_detected'] as int? ?? 0) > 0 ? Colors.red : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Protection Level',
                    threatLevel.toUpperCase(),
                    statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildProtectionControls() {
    final protectionEnabled = _protectionStatus['enabled'] as bool? ?? false;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protection Controls',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Anti-Tamper Protection'),
              subtitle: const Text('Enable advanced anti-tampering measures'),
              value: protectionEnabled,
              onChanged: (value) async {
                if (value) {
                  await _antiTamperService.enableProtection();
                } else {
                  await _antiTamperService.disableProtection();
                }
                _loadSecurityData();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Device Administrator'),
              subtitle: Text(_securityStatus['device_admin_active'] == true 
                  ? 'Device admin privileges active'
                  : 'Click to enable device admin'),
              trailing: _securityStatus['device_admin_active'] == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.error, color: Colors.red),
              onTap: () async {
                final success = await _securityService.requestDeviceAdmin();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success 
                        ? 'Device admin enabled successfully'
                        : 'Failed to enable device admin'),
                      backgroundColor: success 
                        ? AppTheme.secondaryColor 
                        : AppTheme.alertColor,
                    ),
                  );
                }
                _loadSecurityData();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThreatDetection() {
    final checksumFailures = _protectionStatus['checksum_failures'] as int? ?? 0;
    final debuggerDetections = _protectionStatus['debugger_detections'] as int? ?? 0;
    final hookingAttempts = _protectionStatus['hooking_attempts'] as int? ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Threat Detection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThreatCounter(
                    'Checksum Failures',
                    checksumFailures,
                    Icons.fingerprint,
                  ),
                ),
                Expanded(
                  child: _buildThreatCounter(
                    'Debugger Attempts',
                    debuggerDetections,
                    Icons.bug_report,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildThreatCounter(
                    'Hooking Attempts',
                    hookingAttempts,
                    Icons.gavel,
                  ),
                ),
                Expanded(
                  child: _buildThreatCounter(
                    'Total Events',
                    _protectionStatus['total_tamper_events'] as int? ?? 0,
                    Icons.event_note,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThreatCounter(String label, int count, IconData icon) {
    final color = count > 0 ? Colors.red : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _securityService.performSecurityScan();
                      _loadSecurityData();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Security Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _antiTamperService.performManualIntegrityCheck();
                      _loadSecurityData();
                    },
                    icon: const Icon(Icons.verified),
                    label: const Text('Integrity Check'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _securityService.enableAntiTampering();
                      _loadSecurityData();
                    },
                    icon: const Icon(Icons.security),
                    label: const Text('Enable Anti-Tamper'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _securityService.startPeriodicMonitoring();
                      _loadSecurityData();
                    },
                    icon: const Icon(Icons.monitor),
                    label: const Text('Start Monitoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecentEvents() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Security Events',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${_recentEvents.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentEvents.isEmpty)
              const Center(
                child: Text(
                  'No security events detected',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentEvents.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final event = _recentEvents[index];
                  return _buildEventItem(event);
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventItem(Map<String, dynamic> event) {
    final type = event['type'] as String;
    final description = event['description'] as String;
    final level = event['level'] as String;
    final detectedAt = DateTime.parse(event['detected_at'] as String);
    
    Color levelColor;
    IconData levelIcon;
    
    switch (level) {
      case 'critical':
        levelColor = Colors.red;
        levelIcon = Icons.dangerous;
        break;
      case 'high':
        levelColor = Colors.orange;
        levelIcon = Icons.warning;
        break;
      case 'medium':
        levelColor = Colors.amber;
        levelIcon = Icons.info;
        break;
      default:
        levelColor = Colors.grey;
        levelIcon = Icons.circle;
    }
    
    return ListTile(
      leading: Icon(levelIcon, color: levelColor),
      title: Text(
        type.replaceAll('_', ' ').toLowerCase().split(' ').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' '),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description),
          const SizedBox(height: 4),
          Text(
            '${detectedAt.day}/${detectedAt.month} ${detectedAt.hour}:${detectedAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: levelColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          level.toUpperCase(),
          style: TextStyle(
            color: levelColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}