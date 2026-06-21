import 'package:flutter/material.dart';
import 'package:monitored_app/core/network/p2p_manager.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

class P2PConnectionStatus extends StatefulWidget {
  const P2PConnectionStatus({super.key});

  @override
  State<P2PConnectionStatus> createState() => _P2PConnectionStatusState();
}

class _P2PConnectionStatusState extends State<P2PConnectionStatus> {
  late P2PManager _p2pManager;
  P2PManagerState _currentState = P2PManagerState.uninitialized;
  List<P2PConnectionInfo> _connections = [];

  @override
  void initState() {
    super.initState();
    _p2pManager = locator<P2PManager>();
    _currentState = _p2pManager.state;
    _connections = _p2pManager.activeConnections;
    
    _p2pManager.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
        });
      }
    });

    _p2pManager.connectionStream.listen((connection) {
      if (mounted) {
        setState(() {
          _connections = _p2pManager.activeConnections;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.p2pConnectionStatus,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getStatusText(l10n),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentState == P2PManagerState.ready && _connections.isEmpty)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showConnectionDialog(context),
                    tooltip: l10n.addConnection,
                  ),
              ],
            ),
            
            if (_connections.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                l10n.activeConnections,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ..._connections.map((connection) => _buildConnectionTile(context, connection)),
            ],
            
            if (_connections.isEmpty && _currentState == P2PManagerState.ready) ...[
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.devices_other,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.noActiveConnections,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showConnectionDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addConnection),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(BuildContext context, P2PConnectionInfo connection) {
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.devices,
          color: AppTheme.secondaryColor,
        ),
      ),
      title: Text(
        connection.deviceName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${connection.deviceId.substring(0, 8)}...'),
          Text(
            '${l10n.connectedAt}: ${_formatDateTime(connection.connectedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => _handleConnectionAction(context, connection, value),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'send_command',
            child: Row(
              children: [
                const Icon(Icons.send),
                const SizedBox(width: 8),
                Text(l10n.sendCommand),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'send_file',
            child: Row(
              children: [
                const Icon(Icons.file_upload),
                const SizedBox(width: 8),
                Text(l10n.sendFile),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'disconnect',
            child: Row(
              children: [
                const Icon(Icons.link_off, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  l10n.disconnect,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentState) {
      case P2PManagerState.uninitialized:
      case P2PManagerState.initializing:
        return Icons.hourglass_empty;
      case P2PManagerState.ready:
        return _connections.isNotEmpty ? Icons.devices : Icons.devices_other;
      case P2PManagerState.connecting:
        return Icons.sync;
      case P2PManagerState.connected:
        return Icons.devices;
      case P2PManagerState.disconnected:
        return Icons.device_unknown;
      case P2PManagerState.error:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (_currentState) {
      case P2PManagerState.uninitialized:
      case P2PManagerState.initializing:
        return Colors.orange;
      case P2PManagerState.ready:
        return _connections.isNotEmpty ? AppTheme.secondaryColor : Colors.grey;
      case P2PManagerState.connecting:
        return Colors.blue;
      case P2PManagerState.connected:
        return AppTheme.secondaryColor;
      case P2PManagerState.disconnected:
        return Colors.grey;
      case P2PManagerState.error:
        return AppTheme.alertColor;
    }
  }

  String _getStatusText(AppLocalizations l10n) {
    switch (_currentState) {
      case P2PManagerState.uninitialized:
        return l10n.p2pUninitialized;
      case P2PManagerState.initializing:
        return l10n.p2pInitializing;
      case P2PManagerState.ready:
        return _connections.isNotEmpty 
            ? l10n.p2pConnectedDevices(_connections.length.toString())
            : l10n.p2pReady;
      case P2PManagerState.connecting:
        return l10n.p2pConnecting;
      case P2PManagerState.connected:
        return l10n.p2pConnected;
      case P2PManagerState.disconnected:
        return l10n.p2pDisconnected;
      case P2PManagerState.error:
        return l10n.p2pError;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showConnectionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final deviceIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.connectToDevice),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: deviceIdController,
              decoration: InputDecoration(
                labelText: l10n.deviceId,
                hintText: l10n.enterDeviceId,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.p2pConnectionInfo,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final deviceId = deviceIdController.text.trim();
              if (deviceId.isNotEmpty) {
                Navigator.of(context).pop();
                _connectToDevice(deviceId);
              }
            },
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
  }

  void _connectToDevice(String deviceId) async {
    final l10n = AppLocalizations.of(context)!;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(l10n.connectingToDevice),
          ],
        ),
      ),
    );

    try {
      final success = await _p2pManager.connectToDevice(deviceId);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.connectionSuccessful : l10n.connectionFailed
            ),
            backgroundColor: success ? AppTheme.secondaryColor : AppTheme.alertColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.connectionError),
            backgroundColor: AppTheme.alertColor,
          ),
        );
      }
    }
  }

  void _handleConnectionAction(BuildContext context, P2PConnectionInfo connection, String action) {
    switch (action) {
      case 'send_command':
        _showCommandDialog(context, connection);
        break;
      case 'send_file':
        _showFilePicker(context, connection);
        break;
      case 'disconnect':
        _disconnectFromDevice(context, connection);
        break;
    }
  }

  void _showCommandDialog(BuildContext context, P2PConnectionInfo connection) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sendCommand),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock),
              title: Text(l10n.lockDevice),
              onTap: () {
                Navigator.of(context).pop();
                _sendCommand(connection, 'lock_device', {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: Text(l10n.unlockDevice),
              onTap: () {
                Navigator.of(context).pop();
                _sendCommand(connection, 'unlock_device', {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.restartDevice),
              onTap: () {
                Navigator.of(context).pop();
                _sendCommand(connection, 'restart_device', {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.capturePhoto),
              onTap: () {
                Navigator.of(context).pop();
                _sendCommand(connection, 'capture_media', {'media_type': 'photo'});
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  void _showFilePicker(BuildContext context, P2PConnectionInfo connection) {
    // This would integrate with a file picker
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File transfer feature coming soon'),
      ),
    );
  }

  void _sendCommand(P2PConnectionInfo connection, String command, Map<String, dynamic> parameters) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      final result = await _p2pManager.sendCommand(connection.deviceId, command, parameters);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null ? l10n.commandSent : l10n.commandFailed
            ),
            backgroundColor: result != null ? AppTheme.secondaryColor : AppTheme.alertColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commandError),
            backgroundColor: AppTheme.alertColor,
          ),
        );
      }
    }
  }

  void _disconnectFromDevice(BuildContext context, P2PConnectionInfo connection) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDisconnection),
        content: Text(l10n.disconnectDeviceConfirmation(connection.deviceName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertColor,
            ),
            child: Text(l10n.disconnect),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _p2pManager.disconnectFromDevice(connection.deviceId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.deviceDisconnected : l10n.disconnectionFailed
            ),
            backgroundColor: success ? AppTheme.secondaryColor : AppTheme.alertColor,
          ),
        );
      }
    }
  }
}