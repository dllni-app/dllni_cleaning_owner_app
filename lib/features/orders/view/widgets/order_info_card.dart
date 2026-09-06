import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/fetch_orders_usecase_model.dart';
import '../helpers/cleaning_enum_translations.dart';
import '../helpers/dedicated_order_helper.dart';
import '../helpers/event_assistance_order_helper.dart';
import '../helpers/order_lifecycle_policy.dart';

class OrderInfoCard extends StatelessWidget {
  const OrderInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  String get _title {
    if (EventAssistanceOrderHelper.isEventAssistance(order.propertyType)) {
      return 'حجز مساعدة مناسبة';
    }

    return 'حجز تنظيف ${CleaningEnumTranslations.propertyType(order.propertyType)}';
  }

  bool get _showCustomerContact {
    final phone = order.customer?.phone?.trim();
    return OrderLifecyclePolicy.hasCurrentWorkerAccepted(order) &&
        phone != null &&
        phone.isNotEmpty;
  }

  Future<void> _launchContact(String scheme, String phone) async {
    final uri = Uri(scheme: scheme, path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    AppToast.showErrorGlobal(
      scheme == 'tel'
          ? 'تعذر فتح تطبيق الاتصال.'
          : 'تعذر فتح تطبيق الرسائل.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDedicatedToMe =
        DedicatedOrderHelper.isDedicatedToCurrentUser(order.preferredWorkerId);
    final phone = order.customer?.phone?.trim();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium(_title, fontWeight: FontWeight.w300),
              AppText.labelMedium(
                order.bookingNumber ?? '',
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
          12.verticalSpace,
          Divider(color: Colors.black.withAlpha(42)),
          8.verticalSpace,
          if (isDedicatedToMe) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_circle_outlined,
                      color: const Color(0xffEF4444),
                      size: 18.sp,
                    ),
                    6.horizontalSpace,
                    AppText.labelMedium(
                      'طلب مخصص',
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
                AppText.labelMedium(
                  'طلب مخصص لك',
                  color: const Color(0xffEF4444),
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
            14.verticalSpace,
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tag, color: context.secondary, size: 18.sp),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    'حالة الحجز',
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xff00BA10).withAlpha(75),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppText.labelMedium(
                  order.statusNameValue,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: context.secondary,
                    size: 18.sp,
                  ),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    'جدولة الحجز',
                    fontWeight: FontWeight.w300,
                  ),
                ],
              ),
              AppText.labelMedium(
                CleaningArabicTimeFormatter.formatScheduledDate(
                  order.scheduledDate,
                  emptyValue: '',
                ),
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: context.secondary,
                    size: 18.sp,
                  ),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    'موعد الخدمة',
                    fontWeight: FontWeight.w300,
                  ),
                ],
              ),
              AppText.labelMedium(
                CleaningArabicTimeFormatter.formatScheduledTime(
                  order.scheduledTime,
                  emptyValue: '',
                ),
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
          if (_showCustomerContact && phone != null) ...[
            14.verticalSpace,
            Divider(color: Colors.black.withAlpha(42)),
            12.verticalSpace,
            AppText.labelMedium(
              'التواصل مع العميل',
              fontWeight: FontWeight.w600,
            ),
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _launchContact('tel', phone),
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('اتصال'),
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchContact('sms', phone),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('رسالة SMS'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
