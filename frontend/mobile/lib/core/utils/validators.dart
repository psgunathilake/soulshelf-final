class Validators {
  Validators._();

  static final _emailRegex =
      RegExp(r'^[\w\-.+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Min 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Need 1 uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Need 1 digit';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? pin(String? value) {
    if (value == null || value.isEmpty) return 'PIN is required';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must be exactly 4 digits';
    }
    return null;
  }
}
