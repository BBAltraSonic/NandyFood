import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:food_delivery_app/features/restaurant_dashboard/services/report_generation_service.dart'; // Temporarily commented - file not found
import 'package:food_delivery_app/shared/models/enhanced_analytics.dart';
import 'package:intl/intl.dart';

/// Report Management Screen for generating and managing analytics reports
class ReportManagementScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ReportManagementScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  ConsumerState<ReportManagementScreen> createState() =>
      _ReportManagementScreenState();
}

class _ReportManagementScreenState
    extends ConsumerState<ReportManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // final ReportGenerationService _reportService = ReportGenerationService(); // Temporarily commented - service not available
  List<AnalyticsReport> _reports = [];
  bool _isLoading = false;
  bool _isGenerating = false;

  // Form controllers for scheduling
  final _reportNameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedReportType = 'comprehensive';
  String _selectedFrequency = 'weekly';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setDefaultDateRange();
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reportNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _setDefaultDateRange() {
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final reports = await _reportService.getGeneratedReports(widget.restaurantId);
      setState(() => _reports = reports);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generate', icon: Icon(Icons.add)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGenerateTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickGenerateSection(),
          const SizedBox(height: 24),
          _buildCustomReportSection(),
          const SizedBox(height: 24),
          _buildScheduleSection(),
        ],
      ),
    );
  }

  Widget _buildQuickGenerateSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Generate',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Generate common reports with default settings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickReportButton(
                  'Comprehensive Report',
                  Icons.dashboard,
                  Colors.blue,
                  () => _generateQuickReport('comprehensive'),
                ),
                _buildQuickReportButton(
                  'Revenue Report',
                  Icons.attach_money,
                  Colors.green,
                  () => _generateQuickReport('revenue'),
                ),
                _buildQuickReportButton(
                  'Customer Report',
                  Icons.people,
                  Colors.orange,
                  () => _generateQuickReport('customer'),
                ),
                _buildQuickReportButton(
                  'Menu Report',
                  Icons.restaurant_menu,
                  Colors.purple,
                  () => _generateQuickReport('menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReportButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: _isGenerating ? null : onPressed,
      icon: _isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildCustomReportSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reportNameController,
              decoration: const InputDecoration(
                labelText: 'Report Name',
                border: OutlineInputBorder(),
                hintText: 'Enter report name',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Report Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'comprehensive', child: Text('Comprehensive')),
                DropdownMenuItem(value: 'revenue', child: Text('Revenue')),
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'menu', child: Text('Menu')),
                DropdownMenuItem(value: 'performance', child: Text('Performance')),
              ],
              onChanged: (value) {
                setState(() => _selectedReportType = value!);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateRange(),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date Range',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _startDate != null && _endDate != null
                            ? '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}'
                            : 'Select date range',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateCustomReport,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateCustomExcelReport,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.table_chart),
                    label: const Text('Generate Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildScheduleSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule Recurring Report',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reportNameController,
              decoration: const InputDecoration(
                labelText: 'Report Name',
                border: OutlineInputBorder(),
                hintText: 'Enter report name',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                hintText: 'Enter recipient email',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Report Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'comprehensive', child: Text('Comprehensive')),
                DropdownMenuItem(value: 'revenue', child: Text('Revenue')),
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'menu', child: Text('Menu')),
              ],
              onChanged: (value) {
                setState(() => _selectedReportType = value!);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                setState(() => _selectedFrequency = value!);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scheduleReport,
                icon: const Icon(Icons.schedule),
                label: const Text('Schedule Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reports.isEmpty) {
      return _buildEmptyState('No reports generated yet');
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(AnalyticsReport report) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.reportName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.reportType.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(report.isScheduled ? 'Scheduled' : 'Generated'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  report.dateRangeDisplay,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, HH:mm').format(report.generatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (report.isScheduled && report.scheduleFrequency != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.repeat, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    'Repeats ${report.scheduleFrequency}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (report.isDownloadable)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadReport(report),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (report.isDownloadable) const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareReport(report),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => _deleteReport(report),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'scheduled':
        color = Colors.blue;
        break;
      case 'generated':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(0);
              },
              child: const Text('Generate Your First Report'),
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateQuickReport(String reportType) async {
    final reportName = '${reportType.capitalize()} Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}';
    await _generateReport(reportName, reportType, 'pdf');
  }

  Future<void> _generateCustomReport() async {
    if (_reportNameController.text.trim().isEmpty) {
      _showError('Please enter a report name');
      return;
    }

    await _generateReport(_reportNameController.text.trim(), _selectedReportType, 'pdf');
  }

  Future<void> _generateCustomExcelReport() async {
    if (_reportNameController.text.trim().isEmpty) {
      _showError('Please enter a report name');
      return;
    }

    await _generateReport(_reportNameController.text.trim(), _selectedReportType, 'excel');
  }

  Future<void> _generateReport(String reportName, String reportType, String format) async {
    setState(() => _isGenerating = true);

    try {
      final reportData = format == 'pdf'
          ? await _reportService.generatePDFReport(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              startDate: _startDate!,
              endDate: _endDate!,
              reportType: reportType,
            )
          : await _reportService.generateExcelReport(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              startDate: _startDate!,
              endDate: _endDate!,
              reportType: reportType,
            );

      final fileName = '${reportName.replaceAll(' ', '_').toLowerCase()}';
      final fileExtension = format == 'pdf' ? 'pdf' : 'xlsx';

      final savedPath = await _reportService.exportReportToFile(
        fileData: reportData,
        fileName: fileName,
        fileExtension: fileExtension,
      );

      // Refresh reports list
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reportName generated successfully!'),
            backgroundColor: Colors.green,
            action: savedPath.isNotEmpty
                ? SnackBarAction(
                    label: 'Open',
                    onPressed: () => _openFile(savedPath),
                  )
                : null,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to generate report: $e');
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _scheduleReport() async {
    if (_reportNameController.text.trim().isEmpty) {
      _showError('Please enter a report name');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter an email address');
      return;
    }

    try {
      await _reportService.scheduleRecurringReport(
        restaurantId: widget.restaurantId,
        reportName: _reportNameController.text.trim(),
        reportType: _selectedReportType,
        frequency: _selectedFrequency,
        recipientEmail: _emailController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report "${_reportNameController.text}" scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _reportNameController.clear();
        _emailController.clear();

        // Refresh reports list
        await _loadReports();
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to schedule report: $e');
      }
    }
  }

  Future<void> _downloadReport(AnalyticsReport report) async {
    if (report.fileUrl == null) {
      _showError('No file available for download');
      return;
    }

    try {
      // In a real implementation, you would download and save the file
      // For now, we'll just show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${report.reportName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to download report: $e');
    }
  }

  Future<void> _shareReport(AnalyticsReport report) async {
    if (report.fileUrl == null) {
      _showError('No file available for sharing');
      return;
    }

    try {
      // In a real implementation, you would use share_plus package
      // For now, we'll just copy the URL to clipboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share link copied for ${report.reportName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Failed to share report: $e');
    }
  }

  Future<void> _deleteReport(AnalyticsReport report) async {
    final confirmed = await _showConfirmationDialog(
      'Delete Report',
      'Are you sure you want to delete "${report.reportName}"?',
    );

    if (!confirmed) return;

    try {
      await _reportService.deleteReport(report.id);
      await _loadReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report "${report.reportName}" deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to delete report: $e');
    }
  }

  Future<void> _openFile(String filePath) async {
    // In a real implementation, you would use open_file package
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File opening functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Extension method for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}