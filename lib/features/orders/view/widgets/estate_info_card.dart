import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../data/models/fetch_orders_usecase_model.dart';

class EstateInfoCard extends StatefulWidget {
  const EstateInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  State<EstateInfoCard> createState() => _EstateInfoCardState();
}

class _EstateInfoCardState extends State<EstateInfoCard> {
  List<String> attributes = [];
  @override
  void initState() {
    super.initState();
    attributes = [
      '${widget.order.propertyDetails?.bathrooms ?? 0} حمام',
      '${widget.order.propertyDetails?.bedRooms ?? 0} غرف نوم',
      if (widget.order.propertyDetails?.kitchen == true) 'مطبخ',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xffF4F5F7), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [AppText.labelMedium("معلومات العقار", fontWeight: FontWeight.w400)],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: context.secondary, size: 18),
                  SizedBox(width: 6),
                  AppText.labelMedium("نوع العقار", fontWeight: FontWeight.w400),
                ],
              ),
              AppText.labelMedium(widget.order.locationName ?? '', fontWeight: FontWeight.w300),
            ],
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.square_foot, color: context.secondary, size: 18),
                  SizedBox(width: 6),
                  AppText.labelMedium("المساحة التقديرية", fontWeight: FontWeight.w400),
                ],
              ),
              AppText.labelMedium('${widget.order.estimatedSqm} متر مربع', fontWeight: FontWeight.w300),
            ],
          ),
          SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(attributes.length, (i) => _buildFeatureChip(attributes[i], context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: context.secondary.withAlpha(40), borderRadius: BorderRadius.circular(12)),
      child: AppText.labelMedium(text, fontWeight: FontWeight.w300, color: context.secondary),
    );
  }
}
