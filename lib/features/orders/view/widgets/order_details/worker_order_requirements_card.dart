import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_mission_task_mapper.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/event_assistance_order_helper.dart';
import 'package:flutter/material.dart';

import 'worker_detail_section.dart';

/// Shared requirements presentation for both legacy orders and V2 visits.
/// Read-only: prices and assignment details must never be inferred here.
class WorkerOrderRequirementsCard extends StatelessWidget {
  const WorkerOrderRequirementsCard({
    super.key,
    required this.order,
    this.sessionId,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final int? sessionId;

  @override
  Widget build(BuildContext context) {
    final tasks = OrderMissionTaskMapper.build(order: order);
    final descriptions = <String>[];
    for (final service in order.services ?? const []) {
      final name = service.name?.trim();
      if (name != null && name.isNotEmpty) descriptions.add(name);
    }
    for (final addon in order.addons ?? const []) {
      final name = addon.name?.trim();
      if (name != null && name.isNotEmpty) descriptions.add(name);
    }
    final specials = (order.specialServices ?? const [])
        .where(
          (service) =>
              service.sessionIds.isEmpty ||
              (sessionId != null && service.sessionIds.contains(sessionId)),
        )
        .map((service) => service.name?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
    if ((order.specialServices ?? const []).isEmpty) {
      for (final preview
          in order.specialServicesPreview ?? const <Map<String, dynamic>>[]) {
        final name = preview['name']?.toString().trim();
        if (name != null && name.isNotEmpty) specials.add(name);
      }
    }
    final customService = order.propertyDetails?.customService?.trim();
    final hasRequirements =
        tasks.isNotEmpty ||
        descriptions.isNotEmpty ||
        specials.isNotEmpty ||
        (customService?.isNotEmpty ?? false);

    return WorkerDetailSection(
      title: 'المهام والخدمات المطلوبة',
      icon: Icons.checklist_rounded,
      children: [
        for (final task in tasks)
          _row(context, task.label, detail: task.detail),
        if (customService?.isNotEmpty == true &&
            !EventAssistanceOrderHelper.isEventAssistance(order.propertyType))
          _row(context, customService!, label: 'الخدمة المطلوبة'),
        for (final service in descriptions)
          _row(context, service, label: 'الخدمة'),
        for (final service in specials)
          _row(context, service, label: 'خدمة خاصة'),
        if (!hasRequirements)
          const Text(
            'تعذّر عرض المهام المطلوبة لهذا الطلب. حدّث تفاصيل الطلب أو تواصل مع الدعم.',
            textAlign: TextAlign.start,
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    String text, {
    String? detail,
    String? label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                if (detail != null && detail.trim().isNotEmpty)
                  Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
