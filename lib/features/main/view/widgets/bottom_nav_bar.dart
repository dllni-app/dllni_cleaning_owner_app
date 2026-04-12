import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/manager/notifier/main_notifier.dart';
import 'package:flutter/material.dart';

import '../../../../generated/assets.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key, required this.controller});

  final TabController controller;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
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
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                widget.controller.animateTo(i);
                setState(() {});
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: widget.controller.index == i ? context.primaryContainer.withAlpha(63) : Colors.transparent,
                    child: AppImage.asset(
                      images[i],
                      color: widget.controller.index == i ? context.primaryContainer : Color(0xff526D6B),
                      width: 30,
                      height: 30,
                    ),
                  ),
                  SizedBox(height: 8),
                  AppText.labelMedium(titles[i], fontWeight: FontWeight.w300, color: Color(0xff526D6B)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
