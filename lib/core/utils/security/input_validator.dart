import 'package:food_delivery_app/core/utils/app_logger.dart';

class InputValidator {
  // Email validation using regex
  static bool isValidEmail(String email) {
    AppLogger.function('InputValidator.isValidEmail', 'ENTER', params: {'email': email});
    
    const emailRegex = 
      r'^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
    
    final result = RegExp(emailRegex).hasMatch(email);
    
    AppLogger.function('InputValidator.isValidEmail', 'EXIT', result: result.toString());
    return result;
  }

  // Password validation - minimum 8 characters, at least 1 uppercase, 1 lowercase, 1 number
  static bool isValidPassword(String password) {
    AppLogger.function('InputValidator.isValidPassword', 'ENTER', 
        params: {'length': password.length});
    
    final result = password.length >= 8 &&
           RegExp(r'[A-Z]').hasMatch(password) &&
           RegExp(r'[a-z]').hasMatch(password) &&
           RegExp(r'[0-9]').hasMatch(password);
    
    AppLogger.function('InputValidator.isValidPassword', 'EXIT', result: result.toString());
    return result;
  }

  // Phone number validation (basic, can be enhanced for specific country formats)
  static bool isValidPhone(String phone) {
    AppLogger.function('InputValidator.isValidPhone', 'ENTER', params: {'phone': phone});
    
    // Remove all non-digit characters for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Basic validation: 10-15 digits
    final result = cleanPhone.length >= 10 && cleanPhone.length <= 15;
    
    AppLogger.function('InputValidator.isValidPhone', 'EXIT', result: result.toString());
    return result;
  }

  // Name validation - basic, allows letters, spaces, hyphens, apostrophes
  static bool isValidName(String name) {
    AppLogger.function('InputValidator.isValidName', 'ENTER', params: {'name': name});
    
    if (name.isEmpty || name.length > 100) {
      AppLogger.function('InputValidator.isValidName', 'EXIT', result: 'false (length)');
      return false;
    }
    
    // Allow letters, spaces, hyphens, apostrophes, and common special characters
    final result = RegExp(r"^[a-zA-Z\s\-\'\.\u00C0-\u017F]+$").hasMatch(name.trim());
    
    AppLogger.function('InputValidator.isValidName', 'EXIT', result: result.toString());
    return result;
  }

  // Address validation - basic, can be enhanced based on requirements
  static bool isValidAddress(String address) {
    AppLogger.function('InputValidator.isValidAddress', 'ENTER', 
        params: {'length': address.length});
    
    if (address.isEmpty || address.length < 5 || address.length > 500) {
      AppLogger.function('InputValidator.isValidAddress', 'EXIT', 
          result: 'false (length requirements)');
      return false;
    }
    
    // Allow alphanumeric, spaces, and common address characters
    final result = RegExp(r'^[a-zA-Z0-9\s\-\.,#&()]+$').hasMatch(address.trim());
    
    AppLogger.function('InputValidator.isValidAddress', 'EXIT', result: result.toString());
    return result;
  }

  // URL validation
  static bool isValidUrl(String url) {
    AppLogger.function('InputValidator.isValidUrl', 'ENTER', params: {'url': url});
    
    try {
      final uri = Uri.parse(url);
      final result = uri.hasScheme && uri.hasAuthority && 
                   (uri.scheme == 'http' || uri.scheme == 'https');
      
      AppLogger.function('InputValidator.isValidUrl', 'EXIT', result: result.toString());
      return result;
    } catch (e) {
      AppLogger.error('Invalid URL format', error: e);
      AppLogger.function('InputValidator.isValidUrl', 'EXIT', result: 'false (exception)');
      return false;
    }
  }

  // Numeric validation - checks if string represents a valid number
  static bool isValidNumber(String numberString) {
    AppLogger.function('InputValidator.isValidNumber', 'ENTER', 
        params: {'numberString': numberString});
    
    try {
      final result = double.tryParse(numberString) != null;
      
      AppLogger.function('InputValidator.isValidNumber', 'EXIT', result: result.toString());
      return result;
    } catch (e) {
      AppLogger.error('Invalid number format', error: e);
      AppLogger.function('InputValidator.isValidNumber', 'EXIT', result: 'false (exception)');
      return false;
    }
  }

  // Validate price format (positive number with max 2 decimal places)
  static bool isValidPrice(String priceString) {
    AppLogger.function('InputValidator.isValidPrice', 'ENTER', 
        params: {'priceString': priceString});
    
    try {
      final price = double.tryParse(priceString);
      if (price == null || price < 0) {
        AppLogger.function('InputValidator.isValidPrice', 'EXIT', 
            result: 'false (null or negative)');
        return false;
      }

      // Check if it has more than 2 decimal places
      final decimalPlaces = (price * 100) % 1;
      final result = decimalPlaces == 0;
      
      AppLogger.function('InputValidator.isValidPrice', 'EXIT', result: result.toString());
      return result;
    } catch (e) {
      AppLogger.error('Invalid price format', error: e);
      AppLogger.function('InputValidator.isValidPrice', 'EXIT', result: 'false (exception)');
      return false;
    }
  }

  // Sanitize string input - remove potentially dangerous characters
  static String sanitizeString(String input) {
    AppLogger.function('InputValidator.sanitizeString', 'ENTER', 
        params: {'inputLength': input.length});
    
    // Remove HTML/JavaScript injection characters
    String sanitized = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:'), '') // Remove javascript:
        .replaceAll(RegExp(r'vbscript:'), '') // Remove vbscript:
        .replaceAll(RegExp(r'onload'), '') // Remove onload
        .replaceAll(RegExp(r'&lt;'), '') // Remove HTML entities
        .replaceAll(RegExp(r'&gt;'), '')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#x27;'), "'");
    
    // Remove potentially dangerous characters but keep useful ones
    sanitized = sanitized.replaceAll(RegExp(r'[<>"\';\\]'), '');
    
    final result = sanitized.trim();
    
    AppLogger.function('InputValidator.sanitizeString', 'EXIT', 
        result: 'Sanitized to length ${result.length}');
    return result;
  }

  // Validate credit card number (Luhn algorithm)
  static bool isValidCreditCard(String cardNumber) {
    AppLogger.function('InputValidator.isValidCreditCard', 'ENTER', 
        params: {'cardLength': cardNumber.length});
    
    // Remove any spaces or dashes
    String cleanCardNumber = cardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanCardNumber.length < 13 || cleanCardNumber.length > 19) {
      AppLogger.function('InputValidator.isValidCreditCard', 'EXIT', 
          result: 'false (invalid length)');
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool isEven = false;
    
    for (int i = cleanCardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanCardNumber[i]);
      
      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      isEven = !isEven;
    }
    
    final result = sum % 10 == 0;
    
    AppLogger.function('InputValidator.isValidCreditCard', 'EXIT', 
        result: result.toString());
    return result;
  }

  // Validate a complete form input with multiple checks
  static ValidationResult validateFormInput({
    required String fieldName,
    required String value,
    bool isRequired = true,
    int? minLength,
    int? maxLength,
    String? pattern, // Custom regex pattern
    bool sanitize = true,
  }) {
    AppLogger.function('InputValidator.validateFormInput', 'ENTER', 
        params: {
          'fieldName': fieldName,
          'inputLength': value.length,
          'isRequired': isRequired.toString()
        });
    
    // Check if field is required
    if (isRequired && value.trim().isEmpty) {
      final result = ValidationResult(
        isValid: false,
        error: '${fieldName.titleCase()} is required',
        sanitizedName: fieldName.titleCase(),
      );
      AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
          result: 'false (required field empty)');
      return result;
    }

    // Skip validation if field is not required and empty
    if (!isRequired && value.trim().isEmpty) {
      final result = ValidationResult(
        isValid: true,
        error: null,
        sanitizedName: sanitize ? sanitizeString(value) : value,
      );
      AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
          result: 'true (not required, empty)');
      return result;
    }

    // Length validation
    if (minLength != null && value.length < minLength) {
      final result = ValidationResult(
        isValid: false,
        error: '${fieldName.titleCase()} must be at least $minLength characters',
        sanitizedName: fieldName.titleCase(),
      );
      AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
          result: 'false (min length)');
      return result;
    }

    if (maxLength != null && value.length > maxLength) {
      final result = ValidationResult(
        isValid: false,
        error: '${fieldName.titleCase()} must be no more than $maxLength characters',
        sanitizedName: fieldName.titleCase(),
      );
      AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
          result: 'false (max length)');
      return result;
    }

    // Custom pattern validation
    if (pattern != null && !RegExp(pattern).hasMatch(value)) {
      final result = ValidationResult(
        isValid: false,
        error: '${fieldName.titleCase()} format is invalid',
        sanitizedName: fieldName.titleCase(),
      );
      AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
          result: 'false (pattern mismatch)');
      return result;
    }

    // Return valid result with sanitized value if requested
    final result = ValidationResult(
      isValid: true,
      error: null,
      sanitizedName: sanitize ? sanitizeString(value) : value,
    );
    
    AppLogger.function('InputValidator.validateFormInput', 'EXIT', 
        result: 'true (valid)');
    return result;
  }
}

// Helper extension for string formatting
extension StringExtension on String {
  String get titleCase {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

// Result class for validation
class ValidationResult {
  final bool isValid;
  final String? error;
  final String sanitizedName;

  ValidationResult({
    required this.isValid,
    this.error,
    required this.sanitizedName,
  });
}