import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_task/add_advertisement_page.dart';
import 'package:subscription_task/main.dart';

void main() {
  testWidgets('add advertisement page keeps the form usable', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SubscriptionTestApp());
    await tester.pump();

    expect(find.text('بيع'), findsOneWidget);
    expect(find.text('إيجار'), findsOneWidget);
    expect(find.text('بدل'), findsOneWidget);
    expect(find.text('نشر الإعلان'), findsOneWidget);
    expect(find.text('مدة صلاحية الإعلان'), findsOneWidget);
    expect(find.text('30 يوم'), findsOneWidget);
    expect(find.text('0 من 8'), findsOneWidget);
    expect(find.text('0 من 4'), findsOneWidget);
    expect(find.text(kAdTextHint), findsOneWidget);
    expect(find.text('نص الإعلان'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('publish-ad')));
    await tester.pump();
    expect(find.text('يرجى اختيار نوع الإعلان'), findsOneWidget);

    await tester.tap(find.text('بيع'));
    await tester.pump();
    expect(find.text('يرجى اختيار نوع الإعلان'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('publish-ad')));
    await tester.pump();
    expect(find.text('يرجى اختيار منطقة العقار'), findsOneWidget);

    await tester.tap(find.text('اختيار منطقة العقار'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField).last, 'السالمية');
    await tester.pump();
    await tester.tap(find.text('السالمية').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('السالمية، حولي'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('ad-text-field')),
      'شقة قريبة من الخدمات والمدرسة والسوق وتناسب العائلات',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(kAdTextHint), findsNothing);
    expect(find.text('يرجى ذكر السعر في نص الإعلان حتى يكتمل'), findsOneWidget);
    expect(
      find.text('يفضّل ذكر المساحة بالمتر ليكون الإعلان أوضح'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('ad-text-field')),
      'شقة للإيجار في موقع هادئ ومناسب للعائلات والسعر 250 دينار',
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('يرجى ذكر السعر في نص الإعلان حتى يكتمل'), findsNothing);
    expect(
      find.text('يفضّل ذكر المساحة بالمتر ليكون الإعلان أوضح'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('publish-ad')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تم نشر الإعلان'), findsOneWidget);
    expect(find.text('بإمكانك الآن إضافة عقار آخر'), findsOneWidget);
  });

  testWidgets('validation floats above the keyboard without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const SubscriptionTestApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('publish-ad')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('يرجى اختيار نوع الإعلان'), findsOneWidget);
    expect(find.text('يرجى اختيار منطقة العقار'), findsOneWidget);
    expect(find.text('إضافة صور وفيديو'), findsOneWidget);
    expect(find.byKey(const ValueKey('ad-text-field')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add advertisement page fits a short phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SubscriptionTestApp());
    await tester.pump();

    expect(find.text('نشر الإعلان'), findsOneWidget);
    expect(find.text('اختيار منطقة العقار'), findsOneWidget);
    expect(find.text('إضافة صور وفيديو'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
