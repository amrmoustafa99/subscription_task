import 'package:flutter/material.dart';

import 'add_advertisement_page.dart';
import 'app_theme.dart';

void main() {
  runApp(const SubscriptionTestApp());
}

class SubscriptionTestApp extends StatelessWidget {
  const SubscriptionTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تجربة باقات بوعقار',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: AddAdvertisementPage(
        adValidityDays: subscriptionPlans
            .firstWhere((plan) => plan.isMostUsed)
            .adValidityDays,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Data model for a subscription / ad-posting package.
// ═══════════════════════════════════════════════════════════
class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int adsCount;
  final int adValidityDays;
  final int planValidityDays;
  final bool isMostUsed;

  final List<String> extraFeatures;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.adsCount,
    required this.adValidityDays,
    required this.planValidityDays,
    this.isMostUsed = false,
    this.extraFeatures = const [],
  });

  List<String> get features => [
    'عدد الإعلانات: $adsCount',
    'مدة صلاحية الإعلان: $adValidityDays يوم',
    'مدة صلاحية الباقة: $planValidityDays يوم',
    ...extraFeatures,
  ];

  String get durationLabel => 'لمدة $planValidityDays يوم';

  String formattedPrice([double? overridePrice]) {
    final p = overridePrice ?? price;
    final isWhole = p.truncateToDouble() == p;
    return p.toStringAsFixed(isWhole ? 0 : 1);
  }
}

final List<SubscriptionPlan> subscriptionPlans = [
  const SubscriptionPlan(
    id: 'one1',
    name: 'One-1',
    price: 2.0,
    adsCount: 1,
    adValidityDays: 30,
    planValidityDays: 30,
  ),
  const SubscriptionPlan(
    id: 'standard',
    name: 'Standard',
    price: 9.0,
    adsCount: 10,
    adValidityDays: 30,
    planValidityDays: 35,
    isMostUsed: true,
  ),
  const SubscriptionPlan(
    id: 'business',
    name: 'Business',
    price: 25.0,
    adsCount: 50,
    adValidityDays: 30,
    planValidityDays: 45,
  ),
  const SubscriptionPlan(
    id: 'plus',
    name: 'Plus',
    price: 40.0,
    adsCount: 100,
    adValidityDays: 30,
    planValidityDays: 60,
  ),
];

// ═══════════════════════════════════════════════════════════
// "اختر باقتك" — package-selection page
// ═══════════════════════════════════════════════════════════
class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  late String _selectedPlanId;
  final TextEditingController _promoCtrl = TextEditingController();

  double _discountPercent = 0;
  String? _discountMessage;
  bool _discountError = false;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = subscriptionPlans
        .firstWhere((p) => p.isMostUsed, orElse: () => subscriptionPlans.first)
        .id;
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  SubscriptionPlan get _selectedPlan =>
      subscriptionPlans.firstWhere((p) => p.id == _selectedPlanId);

  double get _finalPrice => _selectedPlan.price * (1 - _discountPercent / 100);

  void _selectPlan(String id) => setState(() => _selectedPlanId = id);

  void _applyPromo() {
    final code = _promoCtrl.text.trim();
    if (code.isEmpty) {
      setState(() {
        _discountPercent = 0;
        _discountError = true;
        _discountMessage = 'من فضلك أدخل كود الخصم';
      });
      return;
    }
    // Demo logic — replace with a real promo-code lookup/validation call.
    setState(() {
      _discountPercent = 20;
      _discountError = false;
      _discountMessage = 'أحسنت! حصلت على خصم 20%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ultraLightGray,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.base,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(onBack: () => Navigator.of(context).maybePop()),

              const SizedBox(height: AppSpacing.base),

              const _HeaderSection(),

              const SizedBox(height: AppSpacing.xl),

              for (final plan in subscriptionPlans) ...[
                _PlanCard(
                  plan: plan,
                  isSelected: plan.id == _selectedPlanId,
                  onSelect: () => _selectPlan(plan.id),
                ),
                const SizedBox(height: AppSpacing.base),
              ],

              const SizedBox(height: AppSpacing.xs),

              _PromoCodeField(
                controller: _promoCtrl,
                onApply: _applyPromo,
                message: _discountMessage,
                isError: _discountError,
              ),

              const SizedBox(height: AppSpacing.lg),

              _OrderSummaryCard(
                plan: _selectedPlan,
                discountPercent: _discountPercent,
                finalPrice: _finalPrice,
              ),

              const SizedBox(height: AppSpacing.xl),

              _BottomBar(totalPrice: _finalPrice),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.ultraLightGray,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'باقات بوعقار الإعلانية',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header: subtitle + secure-subscription chip
// ─────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          'صممنا باقات مختلفة تتناسب مع حجم نشاط كل شركة عقارية.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mediumGray,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'اختر الباقة المناسبة لك',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Plan card
// ─────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: plan.isMostUsed
                ? const EdgeInsets.only(top: 14)
                : EdgeInsets.zero,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.base,
              plan.isMostUsed ? AppSpacing.lg : AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.lightGray.withOpacity(0.7),
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(isSelected ? 0.08 : 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _FeatureList(plan: plan)),
                    const SizedBox(width: AppSpacing.base),
                    _PlanPriceColumn(plan: plan),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _SelectButton(isSelected: isSelected, onTap: onSelect),
              ],
            ),
          ),
          if (plan.isMostUsed)
            Positioned(
              top: -2,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'الأكثر استخداماً',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeatureList extends StatelessWidget {
  final SubscriptionPlan plan;
  const _FeatureList({required this.plan});

  @override
  Widget build(BuildContext context) {
    final items = plan.features;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _FeatureRow(label: items[i]),
          if (i < items.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;

  const _FeatureRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.darkGray,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanPriceColumn extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanPriceColumn({required this.plan});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            plan.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedPrice(),
                style: AppTextStyles.priceLarge.copyWith(fontSize: 22),
              ),
              const SizedBox(width: 3),
              Text(
                'د.ك',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            plan.durationLabel,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const _SelectButton({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary, width: 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              isSelected ? 'تم اختيار الباقة' : 'اختر الباقة',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Promo code field
// ─────────────────────────────────────────────
class _PromoCodeField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onApply;
  final String? message;
  final bool isError;

  const _PromoCodeField({
    required this.controller,
    required this.onApply,
    this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كود الخصم',
          style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            GestureDetector(
              onTap: onApply,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'تطبيق',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.ultraLightGray,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.lightGray.withOpacity(0.6),
                  ),
                ),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'أدخل كود الخصم',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.mediumGray,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: AppSpacing.base,
            ),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFFFDECEC) : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: isError ? const Color(0xFFD64545) : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Order summary
// ─────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final double discountPercent;
  final double finalPrice;

  const _OrderSummaryCard({
    required this.plan,
    required this.discountPercent,
    required this.finalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final discountAmount = plan.price * discountPercent / 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ملخص الطلب',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
              ),
              const Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppColors.mediumGray,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _SummaryRow(label: 'الباقة المختارة', value: plan.name),
          _SummaryRow(
            label: 'مدة الاشتراك',
            value: '${plan.planValidityDays} يوم',
          ),
          _SummaryRow(
            label: 'السعر الأصلي',
            value: '${plan.formattedPrice()} د.ك',
          ),
          if (discountPercent > 0)
            _SummaryRow(
              label: 'الخصم (${discountPercent.toStringAsFixed(0)}%)',
              value: '-${plan.formattedPrice(discountAmount)} د.ك',
              valueColor: AppColors.primary,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: AppColors.lightGray,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الكلي',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
              ),
              Text(
                '${plan.formattedPrice(finalPrice)} د.ك',
                style: AppTextStyles.price.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.mediumGray,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sticky bottom bar
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final double totalPrice;

  const _BottomBar({required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    final isWhole = totalPrice.truncateToDouble() == totalPrice;
    final priceText = totalPrice.toStringAsFixed(isWhole ? 0 : 1);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.lightGray.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              // TODO: payment flow
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تفعيل الاشتراك — $priceText د.ك',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: AppColors.mediumGray,
              ),
              const SizedBox(width: 4),
              Text(
                'بياناتك محمية وآمنة بنسبة 100%',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
