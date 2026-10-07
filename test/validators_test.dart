import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/core/validators.dart';

void main() {
  group('V.required', () {
    test('пустая строка отклоняется', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
      expect(V.required()(null), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(V.required()('Болт М8'), isNull);
    });
  });

  group('V.integer', () {
    test('нечисло отклоняется', () {
      expect(V.integer()('abc'), isNotNull);
    });

    test('диапазон года поступления', () {
      expect(V.integer(min: 2000, max: 2100)('1999'), isNotNull);
      expect(V.integer(min: 2000, max: 2100)('2024'), isNull);
    });
  });

  group('V.positiveNumber', () {
    test('ноль и отрицательные отклоняются', () {
      expect(V.positiveNumber()('0'), isNotNull);
      expect(V.positiveNumber()('-1'), isNotNull);
    });

    test('положительное принимается', () {
      expect(V.positiveNumber()('12.5'), isNull);
    });
  });

  group('V.email', () {
    test('некорректный адрес отклоняется', () {
      expect(V.email()('not-mail'), isNotNull);
    });

    test('корректный адрес принимается', () {
      expect(V.email()('user@example.com'), isNull);
    });
  });

  group('V.strongPassword', () {
    test('короткий пароль отклоняется', () {
      expect(V.strongPassword()('ab1!'), isNotNull);
    });

    test('пароль без спецсимвола отклоняется', () {
      expect(V.strongPassword()('password1'), isNotNull);
    });

    test('сильный пароль принимается', () {
      expect(V.strongPassword()('admin123!'), isNull);
    });
  });
}
