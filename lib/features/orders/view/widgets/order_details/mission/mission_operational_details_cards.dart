import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/cleaning_booking_operational_details.dart';
import '../../../helpers/order_open_time_presentation.dart';

class MissionMaterialsInfoCard extends StatelessWidget {
  const MissionMaterialsInfoCard({super.key, required this.materials});

  final List<CleaningBookingMaterialLine> materials;

  @override
  Widget build(BuildContext context) {
    return _OperationalDetailsCard(
      icon: Icons.inventory_2_outlined,
      title: 'مواد التنظيف المطلوبة',
      subtitle: 'كميات تشغيلية محددة من النظام',
      children: materials
          .where((material) => (material.name ?? '').trim().isNotEmpty)
          .map(
            (material) => _OperationalLine(
              title: material.name!.trim(),
              details: <String?>[
                _quantityWithUnit(
                  material.quantity,
                  material.unitLabel ?? material.unit,
                ),
              ].whereType<String>().toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }
}

class MissionSpecialServicesInfoCard extends StatelessWidget {
  const MissionSpecialServicesInfoCard({super.key, required this.services});

  final List<CleaningSpecialServiceLine> services;

  @override
  Widget build(BuildContext context) {
    return _OperationalDetailsCard(
      icon: Icons.cleaning_services_outlined,
      title: 'الخدمات الخاصة',
      subtitle: 'تفاصيل التشغيل المطلوبة لهذه المهمة',
      children: services
          .where((service) => (service.name ?? '').trim().isNotEmpty)
          .map(
            (service) => _OperationalLine(
              title: service.name!.trim(),
              details: <String?>[
                _quantityWithUnit(
                  service.quantity,
                  service.pricingUnitLabel ?? service.pricingUnit,
                ),
                _prefixed(
                  'مستوى الاتساخ',
                  service.dirtinessLabel ?? service.dirtinessLevel,
                ),
                _prefixed(
                  'المعدات',
                  service.equipment
                      .map((equipment) => equipment.name?.trim())
                      .whereType<String>()
                      .where((name) => name.isNotEmpty)
                      .join('، '),
                ),
                _prefixed('ملاحظات', service.notes),
              ].whereType<String>().toList(growable: false),
            ),
          )
          .toList(growable: false),
    );
  }
}

class MissionOpenTimeInfoCard extends StatelessWidget {
  const MissionOpenTimeInfoCard({
    super.key,
    required this.openTime,
    required this.presentation,
  });

  final CleaningOpenTimeDetails openTime;
  final OpenTimePresentationState presentation;

  @override
  Widget build(BuildContext context) {
    final elapsed = presentation.elapsed;
    return Semantics(
      container: true,
      label: 'طلب وقت مفتوح. المدة والتكلفة النهائية يحددهما النظام.',
      child: _OperationalDetailsCard(
        icon: Icons.timelapse_outlined,
        title: 'طلب وقت مفتوح',
        subtitle: presentation.isFinal
            ? 'تم توثيق انتهاء العمل من النظام'
            : 'المدة المعروضة للمتابعة فقط',
        children: <Widget>[
          if (!presentation.hasStarted)
            const _OperationalLine(
              title: 'لم يبدأ العمل بعد',
              details: <String>['سيظهر وقت العمل بعد تأكيد النظام لبدئه.'],
            )
          else ...<Widget>[
            _OperationalLine(
              title: presentation.isFinal
                  ? 'المدة الفعلية للعمل'
                  : 'الوقت المنقضي في العمل',
              details: <String>[
                if (elapsed != null) _formatDuration(elapsed),
                if (presentation.startedAt != null)
                  _prefixed(
                    'بدأ العمل',
                    _formatDateTime(presentation.startedAt!),
                  )!,
                if (presentation.finishedAt != null)
                  _prefixed(
                    'انتهى العمل',
                    _formatDateTime(presentation.finishedAt!),
                  )!,
              ],
            ),
          ],
          if (openTime.billableDurationMinutes != null)
            _OperationalLine(
              title: 'المدة القابلة للفوترة',
              details: <String>[
                '${openTime.billableDurationMinutes} دقيقة وفق احتساب النظام',
              ],
            ),
          if (openTime.requestedWorkerCount != null)
            _OperationalLine(
              title: 'عدد العمال المطلوب',
              details: <String>['${openTime.requestedWorkerCount}'],
            ),
          const _OperationalLine(
            title: 'ملاحظة',
            details: <String>[
              'المبلغ والمستحقات النهائية يتم احتسابهما في النظام ولا يتم احتسابهما في التطبيق.',
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationalDetailsCard extends StatelessWidget {
  const _OperationalDetailsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: const Color(0xff19B7C3)),
              const SizedBox(width: 8),
              Expanded(
                child: AppText.titleMedium(
                  title,
                  color: const Color(0xff19B7C3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText.bodySmall(subtitle, color: const Color(0xff6B7280)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _OperationalLine extends StatelessWidget {
  const _OperationalLine({required this.title, required this.details});

  final String title;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppText.bodyMedium(title, fontWeight: FontWeight.w700),
          ...details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(top: 3),
              child: AppText.bodySmall(detail, color: const Color(0xff64748B)),
            ),
          ),
        ],
      ),
    );
  }
}

String? _quantityWithUnit(double? quantity, String? unit) {
  if (quantity == null) return null;
  final quantityLabel = quantity % 1 == 0
      ? quantity.toStringAsFixed(0)
      : quantity.toString();
  final unitLabel = unit?.trim();
  return unitLabel == null || unitLabel.isEmpty
      ? 'الكمية: $quantityLabel'
      : 'الكمية: $quantityLabel $unitLabel';
}

String? _prefixed(String prefix, String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return '$prefix: $text';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year/$month/$day $hour:$minute';
}
