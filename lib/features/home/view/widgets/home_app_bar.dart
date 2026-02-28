import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key, this.image, this.name});

  final String? image;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2), blurRadius: 12, spreadRadius: 0)],
      ),
      width: context.width,
      height: 70,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Row(
        children: [
          image != null
              ? AppImage.network(image!)
              : CircleAvatar(radius: 20, backgroundColor: context.primaryContainer, child: AppText.labelSmall(name == null ? 'n' : name![0])),
          SizedBox(width: 8,),
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
