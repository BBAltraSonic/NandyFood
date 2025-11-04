import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenuePieChart extends StatelessWidget {
  final double grossRevenue;
  final double platformFees;
  final double deliveryFees;

  const RevenuePieChart({
    Key? key,
    required this.grossRevenue,
    required this.platformFees,
    required this.deliveryFees,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final netRevenue = grossRevenue - platformFees - deliveryFees;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.black87,
                      value: netRevenue,
                      title: 'Net Revenue\nR${netRevenue.toStringAsFixed(2)}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.black87,
                      value: platformFees,
                      title: 'Platform Fees\nR${platformFees.toStringAsFixed(2)}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.black87,
                      value: deliveryFees,
                      title: 'Delivery Fees\nR${deliveryFees.toStringAsFixed(2)}',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        _buildLegendItem('Net Revenue', Colors.black87, grossRevenue - platformFees - deliveryFees),
        const SizedBox(height: 8),
        _buildLegendItem('Platform Fees', Colors.black87, platformFees),
        const SizedBox(height: 8),
        _buildLegendItem('Delivery Fees', Colors.black87, deliveryFees),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                'R${value.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}