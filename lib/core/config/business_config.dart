import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Business configuration values loaded from environment with safe defaults
class BusinessConfig {
  static double get defaultTaxRate =>
      double.tryParse(dotenv.env['DEFAULT_TAX_RATE'] ?? '') ?? 0.085;

  static double get defaultDeliveryFee =>
      double.tryParse(dotenv.env['DEFAULT_DELIVERY_FEE'] ?? '') ?? 2.99;

  static double get freeDeliveryThreshold =>
      double.tryParse(dotenv.env['FREE_DELIVERY_THRESHOLD'] ?? '') ?? 25.0;

  static double get minOrderAmount =>
      double.tryParse(dotenv.env['MIN_ORDER_AMOUNT'] ?? '') ?? 10.0;
}

