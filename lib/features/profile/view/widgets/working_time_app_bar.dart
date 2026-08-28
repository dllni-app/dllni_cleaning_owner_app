import 'package:flutter/material.dart';

import '../../../../core/widgets/app_page_header.dart';

class WorkingTimeAppBar extends StatelessWidget {
  const WorkingTimeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageHeader(
      title: 'ساعات العمل',
      subtitle: 'حدّد الأيام والفترات التي يمكنك استقبال الطلبات خلالها',
    );
  }
}
