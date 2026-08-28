import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_header.dart';

class OrderDetailsMapAppBar extends StatelessWidget {
  const OrderDetailsMapAppBar({super.key, required this.orderNum});

  final String orderNum;

  @override
  Widget build(BuildContext context) {
    final label = orderNum.trim().isEmpty ? '—' : orderNum.trim();
    return AppPageHeader(title: 'تفاصيل الطلب', subtitle: 'رقم الحجز: $label');
  }
}
