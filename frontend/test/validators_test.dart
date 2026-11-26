import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/core/utils/validators.dart';

void main() {
  group('Iranian phone validation', () {
    test('normalizes common local and international formats', () {
      expect(normalizeIranianPhone('0912 123 4567'), '+989121234567');
      expect(normalizeIranianPhone('989121234567'), '+989121234567');
      expect(normalizeIranianPhone('9121234567'), '+989121234567');
    });

    test('rejects malformed mobile numbers', () {
      expect(isValidIranianPhone('02112345678'), isFalse);
      expect(isValidIranianPhone('0912123'), isFalse);
    });
  });

  group('Iranian National ID validation', () {
    test('accepts a valid checksum', () {
      expect(isValidIranianNationalId('1234567891'), isTrue);
    });

    test('rejects invalid and repeated digits', () {
      expect(isValidIranianNationalId('1234567890'), isFalse);
      expect(isValidIranianNationalId('1111111111'), isFalse);
    });

    test('masks all but the final four digits', () {
      expect(maskNationalId('1234567891'), '••••••7891');
    });
  });
}
