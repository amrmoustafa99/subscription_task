import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_task/ad_content_validator.dart';

void main() {
  test('empty text returns a single blocking error', () {
    final messages = AdContentValidator.validate('   ');

    expect(messages, hasLength(1));
    expect(messages.single.severity, AdMessageSeverity.error);
    expect(AdContentValidator.hasBlockingError(messages), isTrue);
  });

  test('missing price blocks publishing and keeps recommendations', () {
    final messages = AdContentValidator.validate(
      'شقة قريبة من الخدمات والمدرسة والسوق وتناسب العائلات',
    );

    expect(
      messages.where((message) => message.severity == AdMessageSeverity.error),
      hasLength(1),
    );
    expect(messages.first.text, contains('السعر'));
    expect(
      messages.any(
        (message) =>
            message.severity == AdMessageSeverity.warning &&
            message.text.contains('المساحة'),
      ),
      isTrue,
    );
    expect(AdContentValidator.hasBlockingError(messages), isTrue);
  });

  test('priced text can be published while warnings remain', () {
    final messages = AdContentValidator.validate(
      'شقة للإيجار في موقع هادئ ومناسب للعائلات والسعر 250 دينار',
    );

    expect(AdContentValidator.hasBlockingError(messages), isFalse);
    expect(messages, isNotEmpty);
    expect(
      messages.every(
        (message) => message.severity == AdMessageSeverity.warning,
      ),
      isTrue,
    );
  });

  test('complete advertisement text produces no messages', () {
    final messages = AdContentValidator.validate(
      'شقة للإيجار في السالمية مساحة 120 متر 3 غرف السعر 350 د.ك التواصل 55551234',
    );

    expect(messages, isEmpty);
    expect(AdContentValidator.hasBlockingError(messages), isFalse);
  });

  test('arabic-indic digits still count as a price', () {
    final messages = AdContentValidator.validate(
      'شقة واسعة قريبة من الخدمات والسوق والسعر ٣٥٠ د.ك',
    );

    expect(messages.any((message) => message.text.contains('السعر')), isFalse);
  });
}
