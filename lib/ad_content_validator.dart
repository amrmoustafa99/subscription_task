enum AdMessageSeverity { warning, error }

class AdValidationMessage {
  final AdMessageSeverity severity;
  final String text;

  const AdValidationMessage({required this.severity, required this.text});
}

/// Errors block publishing. Warnings stay visible and can be ignored.
class AdContentValidator {
  const AdContentValidator._();

  static List<AdValidationMessage> validate(String raw) {
    final text = _normalizeDigits(raw).trim();
    if (text.isEmpty) {
      return const [
        AdValidationMessage(
          severity: AdMessageSeverity.error,
          text: 'يرجى كتابة نص الإعلان قبل المتابعة',
        ),
      ];
    }

    final messages = <AdValidationMessage>[];
    if (text.length < 25) {
      messages.add(
        const AdValidationMessage(
          severity: AdMessageSeverity.error,
          text: 'نص الإعلان قصير. أضف تفاصيل أوضح عن العقار',
        ),
      );
    }
    if (!_hasPrice(text)) {
      messages.add(
        const AdValidationMessage(
          severity: AdMessageSeverity.error,
          text: 'يرجى ذكر السعر في نص الإعلان حتى يكتمل',
        ),
      );
    }
    if (!_hasArea(text)) {
      messages.add(
        const AdValidationMessage(
          severity: AdMessageSeverity.warning,
          text: 'يفضّل ذكر المساحة بالمتر ليكون الإعلان أوضح',
        ),
      );
    }
    if (!_hasRooms(text)) {
      messages.add(
        const AdValidationMessage(
          severity: AdMessageSeverity.warning,
          text: 'يفضّل ذكر عدد الغرف في نص الإعلان',
        ),
      );
    }
    if (!_hasPhone(text)) {
      messages.add(
        const AdValidationMessage(
          severity: AdMessageSeverity.warning,
          text: 'يمكنك إضافة رقم للتواصل داخل نص الإعلان',
        ),
      );
    }
    return messages;
  }

  static bool hasBlockingError(List<AdValidationMessage> messages) {
    return messages.any(
      (message) => message.severity == AdMessageSeverity.error,
    );
  }

  static String _normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final arabicIndex = arabic.indexOf(char);
      if (arabicIndex >= 0) {
        buffer.write(arabicIndex);
        continue;
      }
      final persianIndex = persian.indexOf(char);
      if (persianIndex >= 0) {
        buffer.write(persianIndex);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  static bool _hasPrice(String text) {
    final hasNumber = RegExp(r'\d').hasMatch(text);
    final hasCurrency = RegExp(
      r'د\s*\.?\s*ك|دينار|\bkd\b|\bkwd\b',
      caseSensitive: false,
    ).hasMatch(text);
    final hasPriceWord = text.contains('سعر');
    return hasNumber && (hasCurrency || hasPriceWord);
  }

  static bool _hasArea(String text) {
    return text.contains('مساحة') ||
        text.contains('متر') ||
        text.contains('م2') ||
        text.contains('م²') ||
        text.contains('م٢');
  }

  static bool _hasRooms(String text) {
    return text.contains('غرف') ||
        text.contains('غرفة') ||
        text.contains('نوم');
  }

  static bool _hasPhone(String text) {
    final compact = text.replaceAll(RegExp(r'[\s\-–]'), '');
    return RegExp(r'(?<!\d)(?:\+?965)?[24569]\d{7}(?!\d)').hasMatch(compact);
  }
}
