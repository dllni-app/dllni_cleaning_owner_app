import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../../helpers/order_mission_task_mapper.dart';

class MissionServicesInfoCard extends StatelessWidget {
  const MissionServicesInfoCard({
    super.key,
    required this.services,
  });

  final List<MissionTaskItem> services;

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
        children: [
          AppText.titleMedium(
            'الخدمات المطلوبة',
            color: const Color(0xff19B7C3),
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 4),
          AppText.bodySmall(
            'خدمات الطلب المطلوبة من العميل',
            color: const Color(0xff6B7280),
          ),
          const SizedBox(height: 12),
          ...services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xff64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            service.label,
                            fontWeight: FontWeight.w700,
                          ),
                          if (service.detail != null)
                            AppText.bodySmall(
                              service.detail!,
                              color: const Color(0xff9CA3AF),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
