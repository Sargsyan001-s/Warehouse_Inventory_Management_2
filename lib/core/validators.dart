typedef Validator = String? Function(String?);

class V {
  static Validator required([String message = 'Поле обязательно']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator positiveNumber([String message = 'Число должно быть положительным']) {
    return (value) {
      final n = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
      if (n == null) return 'Введите число';
      if (n <= 0) return message;
      return null;
    };
  }

  static Validator number({num? min, num? max}) {
    return (value) {
      final n = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
      if (n == null) return 'Введите число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) =>
        re.hasMatch(value?.trim() ?? '') ? null : 'Некорректный адрес почты';
  }

  /// Пароль: ≥8, цифра, спецсимвол. Для проверки по мере ввода.
  static Validator strongPassword() {
    return (value) {
      final text = value ?? '';
      if (text.length < 8) return 'Не короче 8 символов';
      if (!RegExp(r'\d').hasMatch(text)) return 'Нужна хотя бы одна цифра';
      if (!RegExp(r'[^A-Za-zА-Яа-я0-9]').hasMatch(text)) {
        return 'Нужен специальный символ';
      }
      return null;
    };
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Локальная ошибка + ошибка уникальности/сервера из внешней карты.
  static Validator withServer(Validator local, String key, Map<String, String> errors) {
    return (value) {
      final e = local(value);
      if (e != null) return e;
      return errors[key];
    };
  }
}
