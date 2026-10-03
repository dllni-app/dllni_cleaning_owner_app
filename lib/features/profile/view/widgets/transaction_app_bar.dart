import 'package:flutter/material.dart';

import '../../../../core/widgets/worker_screen_header.dart';

class TransactionAppBar extends StatelessWidget {
  const TransactionAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return WorkerScreenHeader(
      title:
          '\u0633\u062c\u0644 \u0627\u0644\u0645\u0639\u0627\u0645\u0644\u0627\u062a',
      leading: WorkerHeaderAction(
        icon: Icons.arrow_back_rounded,
        semanticLabel: '\u0631\u062c\u0648\u0639',
        onTap: () => Navigator.maybePop(context),
      ),
    );
  }
}
