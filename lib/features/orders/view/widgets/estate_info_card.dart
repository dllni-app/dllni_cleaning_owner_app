import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/fetch_orders_usecase_model.dart';
import '../helpers/cleaning_enum_translations.dart';
import '../helpers/event_assistance_order_helper.dart';
import '../helpers/order_address_visibility_helper.dart';
import '../helpers/property_attribute_labels_helper.dart';

class EstateInfoCard extends StatefulWidget {
  const EstateInfoCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  State<EstateInfoCard> createState() => _EstateInfoCardState();
}

class _EstateInfoCardState extends State<EstateInfoCard> {
  bool get _isEventAssistance =>
      EventAssistanceOrderHelper.isEventAssistance(widget.order.propertyType);

  String get address => visibleOrderAddress(
        address:
            widget.order.propertyDetails?.address ?? widget.order.locationName,
        status: widget.order.status,
      );

  List<String> get attributes {
    if (_isEventAssistance) {
      final labels = <String>[];
      final guests = widget.order.propertyDetails?.guestCount;
      final venue = widget.order.propertyDetails?.venueType;
      final hours = EventAssistanceOrderHelper.resolveBookedHours(
        propertyHours: widget.order.propertyDetails?.hours,
        assignmentHours: widget.order.myAssignment?.totalHours,
        totalHours: widget.order.totalHours,
        estimatedHours: widget.order.estimatedHours,
      );
      appLog('guests: ${guests.toString()}');
      appLog('venue: ${venue.toString()}');
      appLog('hours: ${hours.toString()}');
      if (guests != null) labels.add('$guests ضيف');
      if (venue != null && venue.isNotEmpty) {
        labels.add(CleaningEnumTranslations.venueType(venue));
      }
      if (hours != null) {
        labels.add(EventAssistanceOrderHelper.formatHours(hours));
      }
      return labels;
    }

    return PropertyAttributeLabelsHelper.build(
      widget.order.propertyDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelMedium(
                _isEventAssistance ? 'تفاصيل المناسبة' : 'معلومات العقار',
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
          12.verticalSpace,
          Divider(color: Colors.black.withAlpha(42)),
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.apartment, color: context.secondary, size: 18.sp),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    _isEventAssistance ? 'نوع المناسبة' : 'نوع العقار',
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              AppText.labelMedium(
                _isEventAssistance
                    ? CleaningEnumTranslations.eventType(
                        widget.order.propertyDetails?.eventType,
                      )
                    : CleaningEnumTranslations.propertyType(widget.order.propertyType),
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
          if (widget.order.displayNeighborhoodName != null) ...[
            14.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: context.secondary,
                      size: 18.sp,
                    ),
                    6.horizontalSpace,
                    AppText.labelMedium(
                      'الحي',
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
                Expanded(
                  child: AppText.labelMedium(
                    widget.order.displayNeighborhoodName!,
                    fontWeight: FontWeight.w300,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
          14.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: context.secondary,
                    size: 18.sp,
                  ),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    _isEventAssistance ? 'عنوان المناسبة' : 'عنوان العقار',
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              6.horizontalSpace,

              Expanded(
                child: AppText.labelMedium(
                  address.trim().isEmpty ? 'العنوان غير متوفر' : address,
                  fontWeight: FontWeight.w300,
                  textAlign: TextAlign.end,
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
                    _isEventAssistance
                        ? Icons.schedule
                        : Icons.square_foot,
                    color: context.secondary,
                    size: 18.sp,
                  ),
                  6.horizontalSpace,
                  AppText.labelMedium(
                    _isEventAssistance ? 'مدة الحجز' : 'المساحة التقديرية',
                    fontWeight: FontWeight.w400,
                  ),
                ],
              ),
              AppText.labelMedium(
                _isEventAssistance
                    ? EventAssistanceOrderHelper.formatHoursDetail(
                        EventAssistanceOrderHelper.resolveBookedHours(
                          propertyHours: widget.order.propertyDetails?.hours,
                          assignmentHours: widget.order.myAssignment?.totalHours,
                          totalHours: widget.order.totalHours,
                          estimatedHours: widget.order.estimatedHours,
                        ),
                      )
                    : '${widget.order.estimatedSqm} متر مربع',
                fontWeight: FontWeight.w300,
              ),
            ],
          ),
          if (attributes.isNotEmpty) ...[
            18.verticalSpace,
            Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
              children: List.generate(
                attributes.length,
                (i) => _buildFeatureChip(attributes[i], context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Color(0xFFE2E5EE),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.black)
      ),
      child: AppText.labelMedium(
        text,
        fontWeight: FontWeight.w300,
        color: context.secondary,
      ),
    );
  }
}

