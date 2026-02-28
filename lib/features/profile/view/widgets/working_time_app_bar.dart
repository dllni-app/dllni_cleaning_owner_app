import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class WorkingTimeAppBar extends StatelessWidget {
  const WorkingTimeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2), blurRadius: 12, spreadRadius: 0)],
      ),
      width: context.width,
      height: 80,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              context.pop();
            },
            child: Icon(Icons.arrow_back_ios_new, color: context.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: AppText.headlineLarge('ساعات العمل', fontWeight: FontWeight.w700, textAlign: TextAlign.start),
          ),
        ],
      ),
    );
  }
}
