import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class ProvisionalPricingNotice extends StatelessWidget {
  const ProvisionalPricingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3D6A1)),
      ),
      child: AppText.bodySmall(
        'السعر المعروض تقديري وغير نهائي، وسيتم تأكيد السعر النهائي بعد قبول مقدم الخدمة للطلب.',
        color: const Color(0xFF8A5A12),
        fontWeight: FontWeight.w600,
        textAlign: TextAlign.right,
      ),
    );
  }
}
