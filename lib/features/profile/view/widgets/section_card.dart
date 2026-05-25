import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.containerColor,
    required this.imageColor,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleTrailing,
  });

  final Color containerColor;
  final Color imageColor;
  final IconData image;
  final String title;
  final String subtitle;
  final Function() onTap;
  final Widget? titleTrailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: containerColor,
            ),
            padding: EdgeInsetsDirectional.all(8),
            child: Icon(image, size: 25.sp, color: imageColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText.bodyMedium(
                        title,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      SizedBox(width: 8.w),
                      titleTrailing!,
                    ],
                  ],
                ),
                SizedBox(height: 4),
                AppText.labelLarge(
                  subtitle,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff6B7280),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.arrow_forward_ios),
        ],
      ),
    );
  }
}
