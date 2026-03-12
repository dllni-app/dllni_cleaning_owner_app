import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key, this.image, this.name});

  final String? image;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 3)),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24.r), bottomLeft: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2.h), blurRadius: 12.r, spreadRadius: 0)],
      ),
      width: context.width,
      height: 70.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          image != null
              ? AppImage.network(image!)
              : CircleAvatar(radius: 20.r, backgroundColor: context.primaryContainer, child: AppText.labelSmall(name == null ? 'n' : name![0])),
          8.horizontalSpace,
          Expanded(
            child: AppText.labelMedium(
              'مرحباً $name, لنكتشف ماهي مهامك اليوم',
              color: Color(0xff2C6862),
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.start,
            ),
          ),
          Icon(Icons.notifications_none_outlined, color: context.primaryContainer),
        ],
      ),
    );
  }
}
