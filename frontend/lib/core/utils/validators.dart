String normalizeIranianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('0098') && digits.length == 14) {
    return '+98${digits.substring(4)}';
  }
  if (digits.startsWith('98') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.startsWith('0') && digits.length == 11) {
    return '+98${digits.substring(1)}';
  }
  if (digits.length == 10 && digits.startsWith('9')) return '+98$digits';
  return input.trim();
}

bool isValidIranianPhone(String input) =>
    RegExp(r'^\+989\d{9}$').hasMatch(normalizeIranianPhone(input));

bool isValidIranianNationalId(String input) {
  final value = input.replaceAll(RegExp(r'\D'), '');
  if (value.length != 10 || RegExp(r'^(\d)\1{9}$').hasMatch(value)) {
    return false;
  }
  var sum = 0;
  for (var index = 0; index < 9; index++) {
    sum += int.parse(value[index]) * (10 - index);
  }
  final remainder = sum % 11;
  final checkDigit = int.parse(value[9]);
  return checkDigit == (remainder < 2 ? remainder : 11 - remainder);
}

String maskNationalId(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return '••••••••••';
  return '••••••${digits.substring(digits.length - 4)}';
}
