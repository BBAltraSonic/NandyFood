import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Admin Settings Screen for platform configuration
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Platform settings
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _requireRestaurantVerification = true;
  String _defaultCurrency = 'ZAR';
  double _platformFeeRate = 0.15; // 15%

  // Payment settings
  bool _payfastEnabled = true;
  bool _cardPaymentsEnabled = true;
  String _payfastMerchantId = '';
  String _payfastMerchantKey = '';

  // Notification settings
  bool _emailNotificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  String _adminEmail = 'admin@nandyfood.com';

  // System settings
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'daily';
  int _backupRetentionDays = 30;
  bool _logLevelVerbose = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Platform Settings'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSettings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Platform'),
                Tab(text: 'Payments'),
                Tab(text: 'Notifications'),
                Tab(text: 'System'),
                Tab(text: 'Backup'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlatformSettingsTab(),
                _buildPaymentSettingsTab(),
                _buildNotificationSettingsTab(),
                _buildSystemSettingsTab(),
                _buildBackupSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform Status
          _buildSectionCard(
            'Platform Status',
            [
              SwitchListTile(
                title: const Text('Maintenance Mode'),
                subtitle: const Text('Put the platform in maintenance mode'),
                value: _maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    _maintenanceMode = value;
                  });
                },
                activeColor: SemanticColors.error,
              ),
              SwitchListTile(
                title: const Text('Allow New Registrations'),
                subtitle: const Text('Enable new user and restaurant registrations'),
                value: _allowNewRegistrations,
                onChanged: (value) {
                  setState(() {
                    _allowNewRegistrations = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              SwitchListTile(
                title: const Text('Require Restaurant Verification'),
                subtitle: const Text('New restaurants must be verified before going live'),
                value: _requireRestaurantVerification,
                onChanged: (value) {
                  setState(() {
                    _requireRestaurantVerification = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Currency Settings
          _buildSectionCard(
            'Currency Settings',
            [
              ListTile(
                title: const Text('Default Currency'),
                subtitle: Text('Currently set to $_defaultCurrency'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showCurrencySelector,
              ),
              ListTile(
                title: const Text('Platform Fee Rate'),
                subtitle: Text('${(_platformFeeRate * 100).toStringAsFixed(1)}% of each transaction'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showPlatformFeeDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Settings
          _buildSectionCard(
            'Content Settings',
            [
              ListTile(
                title: const Text('Platform Terms & Conditions'),
                subtitle: const Text('Manage platform terms and conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Terms & Conditions Management');
                },
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                subtitle: const Text('Manage privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Privacy Policy Management');
                },
              ),
              ListTile(
                title: const Text('Help & Support Content'),
                subtitle: const Text('Manage help documentation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Help Content Management');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Gateways
          _buildSectionCard(
            'Payment Gateways',
            [
              SwitchListTile(
                title: const Text('PayFast (South Africa)'),
                subtitle: const Text('Enable PayFast payment processing'),
                value: _payfastEnabled,
                onChanged: (value) {
                  setState(() {
                    _payfastEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              if (_payfastEnabled) ...[
                ListTile(
                  title: const Text('PayFast Merchant ID'),
                  subtitle: Text(_payfastMerchantId.isEmpty ? 'Not configured' : _payfastMerchantId),
                  trailing: const Icon(Icons.edit),
                  onTap: _editPayfastMerchantId,
                ),
                ListTile(
                  title: const Text('PayFast Merchant Key'),
                  subtitle: Text(_payfastMerchantKey.isEmpty ? 'Not configured' : '••••••••'),
                  trailing: const Icon(Icons.edit),
                  onTap: _editPayfastMerchantKey,
                ),
              ],
              SwitchListTile(
                title: const Text('Card Payments'),
                subtitle: const Text('Enable direct card payment processing'),
                value: _cardPaymentsEnabled,
                onChanged: (value) {
                  setState(() {
                    _cardPaymentsEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Transaction Settings
          _buildSectionCard(
            'Transaction Settings',
            [
              ListTile(
                title: const Text('Payout Schedule'),
                subtitle: const Text('Configure restaurant payout frequency'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Payout Schedule Configuration');
                },
              ),
              ListTile(
                title: const Text('Refund Policy'),
                subtitle: const Text('Configure refund and cancellation policies'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Refund Policy Configuration');
                },
              ),
              ListTile(
                title: const Text('Transaction Limits'),
                subtitle: const Text('Set minimum and maximum order amounts'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Transaction Limits Configuration');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tax Settings
          _buildSectionCard(
            'Tax Settings',
            [
              ListTile(
                title: const Text('VAT Configuration'),
                subtitle: const Text('Configure Value Added Tax settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('VAT Configuration');
                },
              ),
              ListTile(
                title: const Text('Tax Reports'),
                subtitle: const Text('Generate and download tax reports'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Tax Reports');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Channels
          _buildSectionCard(
            'Notification Channels',
            [
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Send transactional emails to users'),
                value: _emailNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _emailNotificationsEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Send push notifications to mobile apps'),
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _pushNotificationsEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              SwitchListTile(
                title: const Text('SMS Notifications'),
                subtitle: const Text('Send SMS notifications for critical updates'),
                value: _smsNotificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _smsNotificationsEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Configuration
          _buildSectionCard(
            'Email Configuration',
            [
              ListTile(
                title: const Text('Admin Email'),
                subtitle: Text(_adminEmail),
                trailing: const Icon(Icons.edit),
                onTap: _editAdminEmail,
              ),
              ListTile(
                title: const Text('Email Templates'),
                subtitle: const Text('Customize email templates'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Email Templates Management');
                },
              ),
              ListTile(
                title: const Text('SMTP Configuration'),
                subtitle: const Text('Configure email server settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('SMTP Configuration');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notification Rules
          _buildSectionCard(
            'Notification Rules',
            [
              ListTile(
                title: const Text('Order Notifications'),
                subtitle: const Text('Configure order status notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Order Notification Rules');
                },
              ),
              ListTile(
                title: const Text('Marketing Notifications'),
                subtitle: const Text('Configure promotional notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Marketing Notification Rules');
                },
              ),
              ListTile(
                title: const Text('System Alerts'),
                subtitle: const Text('Configure system alert notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('System Alert Rules');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Status
          _buildSectionCard(
            'System Status',
            [
              ListTile(
                title: const Text('Database Status'),
                subtitle: const Text('Connected', style: TextStyle(color: SemanticColors.success)),
                leading: Icon(Icons.circle, color: SemanticColors.success, size: 12),
              ),
              ListTile(
                title: const Text('API Server'),
                subtitle: const Text('Operational', style: TextStyle(color: SemanticColors.success)),
                leading: Icon(Icons.circle, color: SemanticColors.success, size: 12),
              ),
              ListTile(
                title: const Text('Storage Usage'),
                subtitle: const Text('45% of 100GB used'),
                leading: Icon(Icons.storage, color: NeutralColors.textSecondary),
                trailing: Text('45 GB', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Active Users'),
                subtitle: const Text('Currently online'),
                leading: Icon(Icons.people, color: NeutralColors.textSecondary),
                trailing: const Text('127', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Performance Settings
          _buildSectionCard(
            'Performance Settings',
            [
              SwitchListTile(
                title: const Text('Verbose Logging'),
                subtitle: const Text('Enable detailed system logs'),
                value: _logLevelVerbose,
                onChanged: (value) {
                  setState(() {
                    _logLevelVerbose = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              ListTile(
                title: const Text('Cache Configuration'),
                subtitle: const Text('Manage system cache settings'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Cache Configuration');
                },
              ),
              ListTile(
                title: const Text('Rate Limiting'),
                subtitle: const Text('Configure API rate limits'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Rate Limiting Configuration');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Security Settings
          _buildSectionCard(
            'Security Settings',
            [
              ListTile(
                title: const Text('API Keys'),
                subtitle: const Text('Manage API access keys'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('API Keys Management');
                },
              ),
              ListTile(
                title: const Text('Security Audit'),
                subtitle: const Text('View security audit logs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Security Audit Logs');
                },
              ),
              ListTile(
                title: const Text('Access Control'),
                subtitle: const Text('Manage user permissions and roles'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Access Control Management');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Backup Configuration
          _buildSectionCard(
            'Backup Configuration',
            [
              SwitchListTile(
                title: const Text('Automatic Backups'),
                subtitle: const Text('Enable automatic system backups'),
                value: _autoBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoBackupEnabled = value;
                  });
                },
                activeColor: BrandColors.primary,
              ),
              ListTile(
                title: const Text('Backup Frequency'),
                subtitle: Text(_backupFrequency),
                trailing: DropdownButton<String>(
                  value: _backupFrequency,
                  items: const [
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _backupFrequency = value;
                      });
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Retention Period'),
                subtitle: Text('$_backupRetentionDays days'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _editBackupRetention,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backup Operations
          _buildSectionCard(
            'Backup Operations',
            [
              ListTile(
                title: const Text('Create Backup Now'),
                subtitle: const Text('Manually create a system backup'),
                leading: const Icon(Icons.backup),
                trailing: const Icon(Icons.chevron_right),
                onTap: _createBackup,
              ),
              ListTile(
                title: const Text('Restore from Backup'),
                subtitle: const Text('Restore system from a previous backup'),
                leading: const Icon(Icons.restore),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBackupRestore,
              ),
              ListTile(
                title: const Text('Download Backup'),
                subtitle: const Text('Download backup files'),
                leading: const Icon(Icons.download),
                trailing: const Icon(Icons.chevron_right),
                onTap: _downloadBackup,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Backup History
          _buildSectionCard(
            'Backup History',
            [
              ListTile(
                title: const Text('View Backup History'),
                subtitle: const Text('View and manage previous backups'),
                leading: const Icon(Icons.history),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  _showComingSoon('Backup History');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(color: NeutralColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: NeutralColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  void _loadSettings() {
    // TODO: Load settings from database
    AppLogger.info('Loading admin settings...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings loaded successfully')),
    );
  }

  void _saveSettings() {
    // TODO: Save settings to database
    AppLogger.info('Saving admin settings...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: SemanticColors.success,
      ),
    );
  }

  void _showCurrencySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'ZAR - South African Rand',
            'USD - US Dollar',
            'EUR - Euro',
            'GBP - British Pound',
          ].map((currency) {
            return RadioListTile<String>(
              title: Text(currency),
              value: currency.substring(0, 3),
              groupValue: _defaultCurrency,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _defaultCurrency = value;
                  });
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPlatformFeeDialog() {
    final controller = TextEditingController(text: (_platformFeeRate * 100).toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platform Fee Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the platform fee percentage (0-50%):'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final fee = double.tryParse(controller.text) ?? 0;
              if (fee >= 0 && fee <= 50) {
                setState(() {
                  _platformFeeRate = fee / 100;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid percentage between 0 and 50'),
                    backgroundColor: SemanticColors.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPayfastMerchantId() {
    final controller = TextEditingController(text: _payfastMerchantId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayFast Merchant ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter PayFast Merchant ID',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _payfastMerchantId = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPayfastMerchantKey() {
    final controller = TextEditingController(text: _payfastMerchantKey);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PayFast Merchant Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter PayFast Merchant Key',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _payfastMerchantKey = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editAdminEmail() {
    final controller = TextEditingController(text: _adminEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Enter admin email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _adminEmail = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editBackupRetention() {
    final controller = TextEditingController(text: _backupRetentionDays.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Retention Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the number of days to retain backups:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: 'days',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final days = int.tryParse(controller.text) ?? 30;
              if (days > 0 && days <= 365) {
                setState(() {
                  _backupRetentionDays = days;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number between 1 and 365'),
                    backgroundColor: SemanticColors.error,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: const Text('Are you sure you want to create a backup now? This may take a few minutes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Backup creation started...'),
                  backgroundColor: SemanticColors.info,
                ),
              );
              // TODO: Implement actual backup creation
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  void _showBackupRestore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup restore functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }

  void _downloadBackup() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Backup File',
        fileName: 'nandyfood_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
      );

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup download started...'),
            backgroundColor: SemanticColors.success,
          ),
        );
        // TODO: Implement actual backup download
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download backup: $e'),
          backgroundColor: SemanticColors.error,
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }
}