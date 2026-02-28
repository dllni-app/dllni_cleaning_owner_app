import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class OrderWarningCard extends StatelessWidget {
  const OrderWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffEF6221).withAlpha(32),
        border: Border.all(color: Color(0xffEF6221)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsetsDirectional.all(16),
      margin: EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.onPrimary,
                child: Icon(Icons.access_time_filled, color: Color(0xffEF6221)),
              ),
              SizedBox(width: 8),
              Expanded(
                child: AppText.labelLarge(
                  'يوجد لديك طلب تمديد المدة للعملية التي تقوم بتنفيذها رقم  #121.',
                  color: Color(0xffEF6221),
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.start,
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: context.onError,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(63), offset: Offset(0, 1), blurRadius: 2)],
                  ),
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
                  child: AppText.labelMedium('مراجعة', color: Color(0xffEF6221), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
