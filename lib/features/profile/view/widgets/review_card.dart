import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_reviews_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';

import '../../../../core/theme/worker_app_colors.dart';
import '../../../../core/widgets/worker_surface_card.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final WorkerReview review;

  @override
  Widget build(BuildContext context) {
    return WorkerSurfaceCard(
      shadow: false,
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: WorkerAppColors.brandPrimarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: WorkerAppColors.brandPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.customerName ?? '-',
                  textAlign: TextAlign.start,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: WorkerAppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StarRating(
            rating: review.rating ?? 0,
            color: const Color(0xFFFBBF24),
            size: 18,
            allowHalfRating: true,
            filledIcon: Icons.star_rate_rounded,
            halfFilledIcon: Icons.star_half_rounded,
            emptyIcon: Icons.star_outline_rounded,
            starCount: 5,
          ),
          if ((review.comment ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: WorkerAppColors.textSecondary,
                height: 1.55,
              ),
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
