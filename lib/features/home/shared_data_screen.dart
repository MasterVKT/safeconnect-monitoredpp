import 'package:flutter/material.dart';
import 'package:monitored_app/app/theme.dart';
import 'package:monitored_app/generated/l10n/app_localizations.dart';

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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
                onPressed: () => _showPrivacyPolicy(context),
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
                        ? AppTheme.primaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
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
                        ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
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

  void _showPrivacyPolicy(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.privacyPolicy,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // Privacy policy content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrivacySection(
                        context,
                        'Collecte de Données',
                        'Cette application collecte les données suivantes pour assurer la sécurité et le contrôle parental :\n\n'
                        '• Position géographique (GPS et réseau)\n'
                        '• Messages SMS et historique d\'appels\n'
                        '• Utilisation des applications\n'
                        '• Photos et enregistrements audio (en cas d\'urgence)\n'
                        '• Informations sur l\'appareil',
                      ),
                      _buildPrivacySection(
                        context,
                        'Utilisation des Données',
                        'Les données collectées sont utilisées pour :\n\n'
                        '• Surveiller la sécurité de l\'utilisateur\n'
                        '• Répondre aux situations d\'urgence\n'
                        '• Fournir un contrôle parental approprié\n'
                        '• Améliorer les fonctionnalités de l\'application',
                      ),
                      _buildPrivacySection(
                        context,
                        'Partage des Données',
                        'Les données ne sont partagées qu\'avec :\n\n'
                        '• Les parents ou tuteurs légaux autorisés\n'
                        '• Les services d\'urgence en cas de situation critique\n'
                        '• Les fournisseurs de services techniques (chiffrées)',
                      ),
                      _buildPrivacySection(
                        context,
                        'Sécurité',
                        'Toutes les données sont :\n\n'
                        '• Chiffrées pendant le transport et le stockage\n'
                        '• Stockées sur des serveurs sécurisés\n'
                        '• Protégées par des mesures de sécurité avancées\n'
                        '• Accessibles uniquement aux utilisateurs autorisés',
                      ),
                      _buildPrivacySection(
                        context,
                        'Droits de l\'Utilisateur',
                        'L\'utilisateur a le droit de :\n\n'
                        '• Consulter les données collectées\n'
                        '• Demander la suppression des données\n'
                        '• Modifier les paramètres de collecte\n'
                        '• Révoquer le consentement à tout moment',
                      ),
                      _buildPrivacySection(
                        context,
                        'Conservation des Données',
                        'Les données sont conservées selon les politiques suivantes :\n\n'
                        '• Localisation: 90 jours\n'
                        '• Messages et appels: 180 jours\n'
                        '• Utilisation des apps: 365 jours\n'
                        '• Médias d\'urgence: 30 jours\n'
                        '• Informations de l\'appareil: 365 jours',
                      ),
                      _buildPrivacySection(
                        context,
                        'Contact',
                        'Pour toute question concernant cette politique de confidentialité, '
                        'veuillez contacter le support technique de XP SafeConnect.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dernière mise à jour: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}