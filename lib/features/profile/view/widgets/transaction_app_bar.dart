import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_header.dart';

class TransactionAppBar extends StatelessWidget {
  const TransactionAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(
      title: 'سجل المعاملات',
      subtitle: 'راجع الإيداعات والديون والاستردادات',
    );
  }
}
