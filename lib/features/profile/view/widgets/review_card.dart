import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_reviews_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: context.onPrimary,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff303030).withAlpha(60),
            offset: const Offset(0, 2),
            blurRadius: 16,
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: context.primary.withAlpha(30),
                child: Icon(
                  Icons.person_outline,
                  color: context.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: AppText.bodyMedium(
                  review.customerName ?? '-',
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.start,
                ),
              ),
              AppText.labelMedium(
                _formatDate(review.createdAt),
                color: const Color(0xff9CA3AF),
                textAlign: TextAlign.end,
              ),
            ],
          ),
          SizedBox(height: 10.h),
          StarRating(
            rating: review.rating ?? 0,
            color: const Color(0xffFAE13D),
            size: 18.sp,
            allowHalfRating: true,
            filledIcon: Icons.star_rate_rounded,
            halfFilledIcon: Icons.star_half_rounded,
            emptyIcon: Icons.star_outline_rounded,
            starCount: 5,
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            AppText.labelLarge(
              review.comment!,
              fontWeight: FontWeight.w400,
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }
}
