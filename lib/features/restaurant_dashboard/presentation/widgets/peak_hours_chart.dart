import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PeakHoursChart extends StatelessWidget {
  final List<Map<String, dynamic>> peakHoursData;

  const PeakHoursChart({
    Key? key,
    required this.peakHoursData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (peakHoursData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Peak Hours',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('No peak hours data available'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Peak Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxOrders() * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hour = group.x.toInt();
                        final orders = group.barRods[0].toY.toInt();
                        return BarTooltipItem(
                          '$hour:00\n$orders orders',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final hour = value.toInt();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        interval: 2,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: peakHoursData.map((data) {
                    return BarChartGroupData(
                      x: data['hour'] as int,
                      barRods: [
                        BarChartRodData(
                          toY: data['orders'] as double,
                          color: _getBarColor(data['orders'] as int),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPeakHoursInsights(),
          ],
        ),
      ),
    );
  }

  double _getMaxOrders() {
    if (peakHoursData.isEmpty) return 10;
    return peakHoursData
        .map((data) => data['orders'] as double)
        .reduce((a, b) => a > b ? a : b);
  }

  Color _getBarColor(int orders) {
    final maxOrders = _getMaxOrders();
    final ratio = orders / maxOrders;

    if (ratio > 0.8) {
      return Colors.black87;
    } else if (ratio > 0.6) {
      return Colors.black87;
    } else if (ratio > 0.4) {
      return Colors.black87;
    } else {
      return Colors.black87;
    }
  }

  Widget _buildPeakHoursInsights() {
    if (peakHoursData.isEmpty) return const SizedBox.shrink();

    // Find peak hour
    final peakHourData = peakHoursData.reduce((a, b) =>
        (a['orders'] as double) > (b['orders'] as double) ? a : b);
    final peakHour = peakHourData['hour'] as int;
    final peakOrders = peakHourData['orders'] as int;

    // Calculate total orders for percentage
    final totalOrders = peakHoursData
        .map((data) => data['orders'] as double)
        .reduce((a, b) => a + b);
    final peakPercentage = (peakOrders / totalOrders * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: Colors.black87.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Peak hour is ${peakHour.toString().padLeft(2, '0')}:00 with $peakOrders orders ($peakPercentage% of daily total)',
              style: TextStyle(
                color: Colors.black87.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}