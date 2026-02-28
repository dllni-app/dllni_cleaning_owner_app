import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class WarningContainer extends StatelessWidget {
  const WarningContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.error.withAlpha(32),
        border: Border.all(color: context.error),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsetsDirectional.all(16),
      child: Center(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.onPrimary,
              child: Icon(Icons.warning, color: context.error),
            ),
            SizedBox(width: 8),
            Expanded(
              child: AppText.labelLarge(
                'يوجد لديك طلب يجب عليك مراجعته',
                color: context.error,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.start,
              ),
            ),
            SizedBox(width: 8,),
            InkWell(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: context.onError,
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), offset: Offset(0, 1), blurRadius: 2)],
                ),
                padding: EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                child: AppText.labelMedium('مراجعة', color: context.error, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
