import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/manager/notifier/main_notifier.dart';
import 'package:flutter/material.dart';

import '../../../../generated/assets.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.mainNotifier});

  final MainNotifier mainNotifier;

  @override
  Widget build(BuildContext context) {
    List<String> images = [Assets.imagesNavBarHome, Assets.imagesNavBarCalender, Assets.imagesNavBarOrders, Assets.imagesNavBarMore];
    List<String> titles = ['الرئيسية', 'تقويمي', 'الطلبات', 'المزيد'];

    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2), blurRadius: 12, spreadRadius: 0)],
      ),
      width: context.width,
      height: 94,
      child: ValueListenableBuilder(
        valueListenable: mainNotifier.pageIndex,
        builder: (context, index, _) => Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  mainNotifier.changePageIndex(i);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: index == i ? context.primaryContainer.withAlpha(63) : Colors.transparent,
                      child: AppImage.asset(images[i], color: index == i ? context.primaryContainer : Color(0xff526D6B), width: 30, height: 30),
                    ),
                    SizedBox(height: 8),
                    AppText.labelMedium(titles[i], fontWeight: FontWeight.w300, color: Color(0xff526D6B)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
