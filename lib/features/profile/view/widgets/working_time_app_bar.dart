import 'package:flutter/material.dart';

import '../../../../core/widgets/worker_screen_header.dart';

class WorkingTimeAppBar extends StatelessWidget {
  const WorkingTimeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkerScreenHeader(
      title: 'ساعات العمل',
      subtitle: 'حدد أيام وفترات العمل المتاحة لاستقبال الطلبات',
      leading: WorkerHeaderAction(
        icon: Icons.arrow_back_rounded,
        semanticLabel: 'رجوع',
        onTap: () => Navigator.maybePop(context),
      ),
    );
  }
}
