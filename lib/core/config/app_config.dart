/// Application configuration constants
class AppConfig {
  // App Information
  static const String appName = 'NandyFood';
  static const String appVersion = '1.0.0';

  // Support Configuration
  static const String supportEmail = 'support@nandyfood.com';
  static const String supportPhone = '+27 123 456 7890';
  static const int maxTicketAttachments = 5;
  static const int maxAttachmentSizeMB = 10;

  // Analytics Configuration
  static const int analyticsCacheDurationMinutes = 30;
  static const int realTimeUpdateIntervalSeconds = 30;

  // Report Configuration
  static const String reportStorageBucket = 'reports';
  static const List<String> supportedReportFormats = ['pdf', 'csv', 'xlsx'];

  // File Upload Configuration
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentTypes = ['pdf', 'doc', 'docx', 'txt'];

  // Notification Configuration
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSMSNotifications = false;

  // Performance Configuration
  static const int maxRecordsPerPage = 50;
  static const int databaseQueryTimeoutSeconds = 30;

  // Security Configuration
  static const int sessionTimeoutMinutes = 60;
  static const int maxLoginAttempts = 5;

  // Development Configuration
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const String logLevel = 'info';
}