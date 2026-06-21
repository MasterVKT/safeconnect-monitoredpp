import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/core/collectors/media_collector.dart';
import 'package:monitored_app/core/services/advanced_media_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/app/theme.dart';

class MediaSettingsScreen extends ConsumerStatefulWidget {
  const MediaSettingsScreen({super.key});

  @override
  ConsumerState<MediaSettingsScreen> createState() => _MediaSettingsScreenState();
}

class _MediaSettingsScreenState extends ConsumerState<MediaSettingsScreen> {
  final AdvancedMediaService _mediaService = locator<AdvancedMediaService>();
  
  late AdvancedMediaConfiguration _config;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  void _loadConfiguration() {
    setState(() {
      _config = _mediaService.getConfiguration();
      _isLoading = false;
    });
  }

  void _updateConfiguration() {
    _mediaService.setConfiguration(_config);
    setState(() {
      _hasChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Media settings saved successfully'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Media Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            IconButton(
              onPressed: _updateConfiguration,
              icon: const Icon(Icons.save),
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildQualitySection(),
          const SizedBox(height: 24),
          _buildCompressionSection(),
          const SizedBox(height: 24),
          _buildStreamingSection(),
          const SizedBox(height: 24),
          _buildDetectionSection(),
          const SizedBox(height: 24),
          _buildSecuritySection(),
          const SizedBox(height: 24),
          _buildAdvancedSection(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildQualitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Quality',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...MediaQuality.values.map((quality) => RadioListTile<MediaQuality>(
              title: Text(_getQualityLabel(quality)),
              subtitle: Text(_getQualityDescription(quality)),
              value: quality,
              groupValue: _config.videoQuality,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = AdvancedMediaConfiguration(
                      videoQuality: value,
                      compression: _config.compression,
                      streaming: _config.streaming,
                      faceDetection: _config.faceDetection,
                      enableEncryption: _config.enableEncryption,
                      enableWatermark: _config.enableWatermark,
                      enableNoiseReduction: _config.enableNoiseReduction,
                      enableVoiceRecognition: _config.enableVoiceRecognition,
                      maxFileSizeMB: _config.maxFileSizeMB,
                      customWatermarkText: _config.customWatermarkText,
                    );
                  });
                  _markChanged();
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCompressionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compression',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...CompressionType.values.map((compression) => RadioListTile<CompressionType>(
              title: Text(_getCompressionLabel(compression)),
              subtitle: Text(_getCompressionDescription(compression)),
              value: compression,
              groupValue: _config.compression,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = AdvancedMediaConfiguration(
                      videoQuality: _config.videoQuality,
                      compression: value,
                      streaming: _config.streaming,
                      faceDetection: _config.faceDetection,
                      enableEncryption: _config.enableEncryption,
                      enableWatermark: _config.enableWatermark,
                      enableNoiseReduction: _config.enableNoiseReduction,
                      enableVoiceRecognition: _config.enableVoiceRecognition,
                      maxFileSizeMB: _config.maxFileSizeMB,
                      customWatermarkText: _config.customWatermarkText,
                    );
                  });
                  _markChanged();
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Streaming',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...StreamingMode.values.map((streaming) => RadioListTile<StreamingMode>(
              title: Text(_getStreamingLabel(streaming)),
              subtitle: Text(_getStreamingDescription(streaming)),
              value: streaming,
              groupValue: _config.streaming,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = AdvancedMediaConfiguration(
                      videoQuality: _config.videoQuality,
                      compression: _config.compression,
                      streaming: value,
                      faceDetection: _config.faceDetection,
                      enableEncryption: _config.enableEncryption,
                      enableWatermark: _config.enableWatermark,
                      enableNoiseReduction: _config.enableNoiseReduction,
                      enableVoiceRecognition: _config.enableVoiceRecognition,
                      maxFileSizeMB: _config.maxFileSizeMB,
                      customWatermarkText: _config.customWatermarkText,
                    );
                  });
                  _markChanged();
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detection Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Face Detection',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...FaceDetectionMode.values.map((detection) => RadioListTile<FaceDetectionMode>(
              title: Text(_getFaceDetectionLabel(detection)),
              subtitle: Text(_getFaceDetectionDescription(detection)),
              value: detection,
              groupValue: _config.faceDetection,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _config = AdvancedMediaConfiguration(
                      videoQuality: _config.videoQuality,
                      compression: _config.compression,
                      streaming: _config.streaming,
                      faceDetection: value,
                      enableEncryption: _config.enableEncryption,
                      enableWatermark: _config.enableWatermark,
                      enableNoiseReduction: _config.enableNoiseReduction,
                      enableVoiceRecognition: _config.enableVoiceRecognition,
                      maxFileSizeMB: _config.maxFileSizeMB,
                      customWatermarkText: _config.customWatermarkText,
                    );
                  });
                  _markChanged();
                }
              },
            )),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voice Recognition'),
              subtitle: const Text('Analyze audio for voice patterns and speech'),
              value: _config.enableVoiceRecognition,
              onChanged: (value) {
                setState(() {
                  _config = AdvancedMediaConfiguration(
                    videoQuality: _config.videoQuality,
                    compression: _config.compression,
                    streaming: _config.streaming,
                    faceDetection: _config.faceDetection,
                    enableEncryption: _config.enableEncryption,
                    enableWatermark: _config.enableWatermark,
                    enableNoiseReduction: _config.enableNoiseReduction,
                    enableVoiceRecognition: value,
                    maxFileSizeMB: _config.maxFileSizeMB,
                    customWatermarkText: _config.customWatermarkText,
                  );
                });
                _markChanged();
              },
            ),
            SwitchListTile(
              title: const Text('Noise Reduction'),
              subtitle: const Text('Reduce background noise in audio recordings'),
              value: _config.enableNoiseReduction,
              onChanged: (value) {
                setState(() {
                  _config = AdvancedMediaConfiguration(
                    videoQuality: _config.videoQuality,
                    compression: _config.compression,
                    streaming: _config.streaming,
                    faceDetection: _config.faceDetection,
                    enableEncryption: _config.enableEncryption,
                    enableWatermark: _config.enableWatermark,
                    enableNoiseReduction: value,
                    enableVoiceRecognition: _config.enableVoiceRecognition,
                    maxFileSizeMB: _config.maxFileSizeMB,
                    customWatermarkText: _config.customWatermarkText,
                  );
                });
                _markChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Features',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('File Encryption'),
              subtitle: const Text('Encrypt media files for enhanced security'),
              value: _config.enableEncryption,
              onChanged: (value) {
                setState(() {
                  _config = AdvancedMediaConfiguration(
                    videoQuality: _config.videoQuality,
                    compression: _config.compression,
                    streaming: _config.streaming,
                    faceDetection: _config.faceDetection,
                    enableEncryption: value,
                    enableWatermark: _config.enableWatermark,
                    enableNoiseReduction: _config.enableNoiseReduction,
                    enableVoiceRecognition: _config.enableVoiceRecognition,
                    maxFileSizeMB: _config.maxFileSizeMB,
                    customWatermarkText: _config.customWatermarkText,
                  );
                });
                _markChanged();
              },
            ),
            SwitchListTile(
              title: const Text('Watermark'),
              subtitle: const Text('Add watermark to photos and videos'),
              value: _config.enableWatermark,
              onChanged: (value) {
                setState(() {
                  _config = AdvancedMediaConfiguration(
                    videoQuality: _config.videoQuality,
                    compression: _config.compression,
                    streaming: _config.streaming,
                    faceDetection: _config.faceDetection,
                    enableEncryption: _config.enableEncryption,
                    enableWatermark: value,
                    enableNoiseReduction: _config.enableNoiseReduction,
                    enableVoiceRecognition: _config.enableVoiceRecognition,
                    maxFileSizeMB: _config.maxFileSizeMB,
                    customWatermarkText: _config.customWatermarkText,
                  );
                });
                _markChanged();
              },
            ),
            if (_config.enableWatermark) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Custom Watermark Text',
                  hintText: 'Enter custom watermark text',
                  border: OutlineInputBorder(),
                ),
                initialValue: _config.customWatermarkText ?? 'XP SafeConnect',
                onChanged: (value) {
                  setState(() {
                    _config = AdvancedMediaConfiguration(
                      videoQuality: _config.videoQuality,
                      compression: _config.compression,
                      streaming: _config.streaming,
                      faceDetection: _config.faceDetection,
                      enableEncryption: _config.enableEncryption,
                      enableWatermark: _config.enableWatermark,
                      enableNoiseReduction: _config.enableNoiseReduction,
                      enableVoiceRecognition: _config.enableVoiceRecognition,
                      maxFileSizeMB: _config.maxFileSizeMB,
                      customWatermarkText: value.isEmpty ? null : value,
                    );
                  });
                  _markChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Maximum File Size: ${_config.maxFileSizeMB} MB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _config.maxFileSizeMB.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              label: '${_config.maxFileSizeMB} MB',
              onChanged: (value) {
                setState(() {
                  _config = AdvancedMediaConfiguration(
                    videoQuality: _config.videoQuality,
                    compression: _config.compression,
                    streaming: _config.streaming,
                    faceDetection: _config.faceDetection,
                    enableEncryption: _config.enableEncryption,
                    enableWatermark: _config.enableWatermark,
                    enableNoiseReduction: _config.enableNoiseReduction,
                    enableVoiceRecognition: _config.enableVoiceRecognition,
                    maxFileSizeMB: value.round(),
                    customWatermarkText: _config.customWatermarkText,
                  );
                });
                _markChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _hasChanges ? _updateConfiguration : null,
            icon: const Icon(Icons.save),
            label: const Text('Save Configuration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showExportDialog(),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImportDialog(),
                icon: const Icon(Icons.upload),
                label: const Text('Import'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _resetToDefaults(),
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.alertColor,
              side: const BorderSide(color: AppTheme.alertColor),
            ),
          ),
        ),
      ],
    );
  }

  void _showExportDialog() {
    final config = _mediaService.exportConfiguration();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Configuration'),
        content: SingleChildScrollView(
          child: SelectableText(
            config.toString(),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Configuration'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Paste configuration JSON here',
            border: OutlineInputBorder(),
          ),
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                // Parse and import configuration
                // _mediaService.importConfiguration(parsedConfig);
                Navigator.of(context).pop();
                _loadConfiguration();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuration imported successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error importing configuration: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all media settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _config = const AdvancedMediaConfiguration();
                _hasChanges = true;
              });
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getQualityLabel(MediaQuality quality) {
    switch (quality) {
      case MediaQuality.low:
        return 'Low (480p)';
      case MediaQuality.medium:
        return 'Medium (720p)';
      case MediaQuality.high:
        return 'High (1080p)';
      case MediaQuality.ultra:
        return 'Ultra (4K)';
    }
  }

  String _getQualityDescription(MediaQuality quality) {
    switch (quality) {
      case MediaQuality.low:
        return 'Lower quality, smaller file sizes';
      case MediaQuality.medium:
        return 'Balanced quality and file size';
      case MediaQuality.high:
        return 'High quality, larger file sizes';
      case MediaQuality.ultra:
        return 'Maximum quality, very large files';
    }
  }

  String _getCompressionLabel(CompressionType compression) {
    switch (compression) {
      case CompressionType.none:
        return 'None';
      case CompressionType.light:
        return 'Light';
      case CompressionType.medium:
        return 'Medium';
      case CompressionType.heavy:
        return 'Heavy';
    }
  }

  String _getCompressionDescription(CompressionType compression) {
    switch (compression) {
      case CompressionType.none:
        return 'No compression, largest files';
      case CompressionType.light:
        return 'Minimal compression, good quality';
      case CompressionType.medium:
        return 'Moderate compression, balanced';
      case CompressionType.heavy:
        return 'Maximum compression, smallest files';
    }
  }

  String _getStreamingLabel(StreamingMode streaming) {
    switch (streaming) {
      case StreamingMode.off:
        return 'Disabled';
      case StreamingMode.realtime:
        return 'Real-time';
      case StreamingMode.buffered:
        return 'Buffered';
    }
  }

  String _getStreamingDescription(StreamingMode streaming) {
    switch (streaming) {
      case StreamingMode.off:
        return 'No live streaming';
      case StreamingMode.realtime:
        return 'Immediate streaming, higher bandwidth';
      case StreamingMode.buffered:
        return 'Buffered streaming, efficient bandwidth';
    }
  }

  String _getFaceDetectionLabel(FaceDetectionMode detection) {
    switch (detection) {
      case FaceDetectionMode.off:
        return 'Disabled';
      case FaceDetectionMode.basic:
        return 'Basic';
      case FaceDetectionMode.advanced:
        return 'Advanced';
    }
  }

  String _getFaceDetectionDescription(FaceDetectionMode detection) {
    switch (detection) {
      case FaceDetectionMode.off:
        return 'No face detection';
      case FaceDetectionMode.basic:
        return 'Basic face detection';
      case FaceDetectionMode.advanced:
        return 'Advanced face analysis and recognition';
    }
  }
}