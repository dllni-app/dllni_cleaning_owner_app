import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_details_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum TransactionCardType { underReview, closed, resolved, open }

class TransactionCard extends StatelessWidget {
  const TransactionCard({super.key, required this.type, required this.id, required this.date, required this.title, required this.disputeId});

  final TransactionCardType type;
  final String id;
  final int disputeId;
  final String date;
  final String title;

  Color cardColor(TransactionCardType type) {
    switch (type) {
      case TransactionCardType.closed:
        return Color(0xffD80024);
      case TransactionCardType.resolved:
        return Color(0xff0CBBC7);
      case TransactionCardType.underReview:
        return Color(0xffD80024);
      case TransactionCardType.open:
        return Color(0xffD80024);
    }
  }

  IconData cardIcon(TransactionCardType type) {
    switch (type) {
      case TransactionCardType.closed:
        return Icons.close;
      case TransactionCardType.resolved:
        return Icons.check;
      case TransactionCardType.underReview:
        return Icons.visibility;
      case TransactionCardType.open:
        return Icons.mark_as_unread;
    }
  }

  String getTitle(String title) {
    if (title == 'poor_quality') {
      return 'جودة الخدمة';
    } else if (title == 'property_damage') {
      return 'أضرار في الممتلكات';
    } else if (title == 'unprofessional') {
      return 'غير محترف';
    } else if (title == 'billing_issue') {
      return 'مشكلة الفواتير';
    } else {
      return 'غير ذلك';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.pushRoute(
          '/transactiondetails',
          arguments: TransactionDetailsScreenParam(id: disputeId, title: id, isOpen: type == TransactionCardType.open),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.onPrimary,
          boxShadow: [BoxShadow(color: Color(0xff303030).withAlpha(60), offset: Offset(0, 2), blurRadius: 16)],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 31),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: cardColor(type).withAlpha(51),
                        child: Icon(cardIcon(type), color: cardColor(type), size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.bodyLarge(id, fontWeight: FontWeight.w500),
                            AppText.labelLarge(
                              DateFormat('yyyy-MM-dd', 'en').format(DateTime.parse(date)),
                              fontWeight: FontWeight.w300,
                              color: Color(0xff8E939E),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(16), bottomLeft: Radius.circular(16)),
                    color: cardColor(type).withAlpha(51),
                  ),
                  width: context.width,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.bodyLarge('عرض التفاصيل', color: cardColor(type), fontWeight: FontWeight.w500),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, color: cardColor(type)),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(14), bottomRight: Radius.circular(10)),
                        color: cardColor(type).withAlpha(51),
                      ),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 8),
                      child: AppText.bodyLarge(getTitle(title), fontWeight: FontWeight.w500, color: cardColor(type)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
