import 'package:flutter/material.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SharedDataScreen extends StatelessWidget {
  const SharedDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Sample data for shared information categories
    final List<Map<String, dynamic>> sharedCategories = [
      {
        'title': l10n.location,
        'icon': Icons.location_on,
        'isActive': true,
        'lastSync': DateTime.now().subtract(const Duration(minutes: 15)),
        'description': l10n.locationSharingDescription,
      },
      {
        'title': l10n.messages,
        'icon': Icons.message,
        'isActive': true,
        'lastSync': DateTime.now().subtract(const Duration(minutes: 5)),
        'description': l10n.messagesSharingDescription,
      },
      {
        'title': l10n.calls,
        'icon': Icons.call,
        'isActive': true,
        'lastSync': DateTime.now().subtract(const Duration(hours: 1)),
        'description': l10n.callsSharingDescription,
      },
      {
        'title': l10n.apps,
        'icon': Icons.apps,
        'isActive': true,
        'lastSync': DateTime.now().subtract(const Duration(hours: 2)),
        'description': l10n.appsSharingDescription,
      },
      {
        'title': l10n.photos,
        'icon': Icons.photo_library,
        'isActive': false,
        'lastSync': null,
        'description': l10n.photosSharingDescription,
      },
    ];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedData),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Explanation text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        l10n.aboutSharedData,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.sharedDataExplanation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // List of shared data categories
            ...sharedCategories.map((category) => _buildCategoryCard(context, category)),
            
            const SizedBox(height: 24),
            
            // Privacy policy link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Open privacy policy
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.featureComingSoon)),
                  );
                },
                icon: const Icon(Icons.privacy_tip_outlined),
                label: Text(l10n.viewPrivacyPolicy),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    final l10n = AppLocalizations.of(context)!;
    final bool isActive = category['isActive'] as bool;
    final DateTime? lastSync = category['lastSync'] as DateTime?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: isActive ? AppTheme.primaryColor : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category['title'] as String,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      if (lastSync != null)
                        Text(
                          l10n.lastSyncTime(_formatTimeAgo(context, lastSync)),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppTheme.secondaryColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isActive ? l10n.active : l10n.inactive,
                    style: TextStyle(
                      color: isActive ? AppTheme.secondaryColor : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Category description
            Text(
              category['description'] as String,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return l10n.justNow;
    } else if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes.toString());
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours.toString());
    } else {
      return l10n.daysAgo(difference.inDays.toString());
    }
  }
}