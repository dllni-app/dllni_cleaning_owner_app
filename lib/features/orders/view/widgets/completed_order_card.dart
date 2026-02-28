import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class CompletedOrderCard extends StatelessWidget {
  const CompletedOrderCard({super.key, required this.date});

  final FetchOrdersUsecaseModelDataItem date;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        border: Border(right: BorderSide(color: context.primaryContainer, width: 5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(vertical: 16, horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: context.primaryContainer.withAlpha(51),
                      child: Icon(Icons.check, color: context.primaryContainer),
                    ),
                    SizedBox(width: 16),
                    AppText.bodyLarge(date.bookingNumber.toString(), fontWeight: FontWeight.w500),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(14), bottomRight: Radius.circular(10)),
                      color: context.primaryContainer.withAlpha(51),
                    ),
                    padding: EdgeInsetsDirectional.symmetric(horizontal: 22, vertical: 8),
                    child: AppText.labelLarge('${date.totalPrice.toString()} ل.س', color: context.primaryContainer, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
