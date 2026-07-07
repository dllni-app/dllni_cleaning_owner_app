import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_reviews_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_reviews_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/widgets/review_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

const int _reviewsPerPage = 20;

@AutoRoutePage(path: '/workerreviews')
class WorkerReviewsScreen extends StatefulWidget {
  const WorkerReviewsScreen({super.key});

  @override
  State<WorkerReviewsScreen> createState() => _WorkerReviewsScreenState();
}

class _WorkerReviewsScreenState extends State<WorkerReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchFirstPage() {
    context.read<ProfileBloc>().add(
      FetchWorkerReviewsEvent(
        params: FetchWorkerReviewsParams(perPage: _reviewsPerPage),
      ),
    );
  }

  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240.h) return;
    _fetchNextPage();
  }

  void _fetchNextPage() {
    final bloc = context.read<ProfileBloc>();
    final state = bloc.state;
    final meta = state.workerReviews?.meta;
    final currentPage = meta?.currentPage;
    final lastPage = meta?.lastPage;
    if (state.workerReviewsStatus == BlocStatus.loading ||
        currentPage == null ||
        lastPage == null ||
        currentPage >= lastPage) {
      return;
    }

    bloc.add(
      FetchWorkerReviewsEvent(
        params: FetchWorkerReviewsParams(
          perPage: meta?.perPage ?? _reviewsPerPage,
        ),
        loadMore: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: SafeArea(
        child: Column(
          children: [
            _ReviewsAppBar(),
            Expanded(
              child: BlocBuilder<ProfileBloc, ProfileState>(
                buildWhen: (previous, current) =>
                    previous.workerReviews != current.workerReviews ||
                    previous.workerReviewsStatus != current.workerReviewsStatus,
                builder: (context, state) {
                  if (state.workerReviews == null &&
                      state.workerReviewsStatus != BlocStatus.failed) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  if (state.workerReviewsStatus == BlocStatus.failed &&
                      state.workerReviews == null) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsetsDirectional.all(24.w),
                        child: _ReviewsStateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'تعذر تحميل التقييمات',
                          message: ErrorMessageFormatter.format(
                            state.errorMessage,
                            fallback: 'حدث خطأ غير متوقع، حاول مرة أخرى.',
                          ),
                          actionLabel: 'إعادة المحاولة',
                          onAction: _fetchFirstPage,
                        ),
                      ),
                    );
                  }

                  final reviewsModel =
                      state.workerReviews ?? const FetchWorkerReviewsModel();
                  final reviews = reviewsModel.data ?? const <WorkerReview>[];
                  final meta = reviewsModel.meta;
                  final averageRating = (meta?.averageRating ?? 0.0)
                      .clamp(0.0, 5.0)
                      .toDouble();
                  final totalCount = meta?.totalCount ?? reviews.length;
                  final ratingCounts = meta?.ratingCounts ?? _countsFromReviews(reviews);
                  final isLoadingMore =
                      state.workerReviewsStatus == BlocStatus.loading &&
                      state.workerReviews != null;
                  final showLoadMoreError =
                      state.workerReviewsStatus == BlocStatus.failed &&
                      reviews.isNotEmpty;
                  final itemCount =
                      1 +
                      (reviews.isEmpty ? 1 : reviews.length) +
                      ((isLoadingMore || showLoadMoreError) ? 1 : 0);

                  return ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsetsDirectional.fromSTEB(
                      24.w,
                      20.h,
                      24.w,
                      24.h,
                    ),
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _ReviewsSummaryCard(
                          averageRating: averageRating,
                          totalCount: totalCount,
                          ratingCounts: ratingCounts,
                        );
                      }
                      if (reviews.isEmpty) {
                        return const _ReviewsStateCard(
                          icon: Icons.rate_review_outlined,
                          title: 'لا توجد تقييمات بعد',
                          message:
                              'ستظهر تقييمات العملاء هنا بعد إكمال الطلبات.',
                        );
                      }
                      if (index > reviews.length) {
                        if (isLoadingMore) {
                          return const Center(
                            child: CircularProgressIndicator.adaptive(),
                          );
                        }
                        return _ReviewsStateCard(
                          icon: Icons.error_outline_rounded,
                          title: 'تعذر تحميل المزيد',
                          message: ErrorMessageFormatter.format(
                            state.errorMessage,
                            fallback: 'حاول مرة أخرى.',
                          ),
                          actionLabel: 'إعادة المحاولة',
                          onAction: _fetchNextPage,
                        );
                      }
                      return ReviewCard(review: reviews[index - 1]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, int> _countsFromReviews(List<WorkerReview> reviews) {
    final counts = <int, int>{for (var rating = 1; rating <= 5; rating++) rating: 0};
    for (final review in reviews) {
      final rating = review.rating?.round();
      if (rating == null || rating < 1 || rating > 5) continue;
      counts[rating] = (counts[rating] ?? 0) + 1;
    }
    return counts;
  }
}

class _ReviewsStateCard extends StatelessWidget {
  const _ReviewsStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 20.w,
        vertical: 24.h,
      ),
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff303030).withAlpha(30),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.primary, size: 36.sp),
          SizedBox(height: 12.h),
          AppText.titleMedium(
            title,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          AppText.bodyMedium(
            message,
            color: const Color(0xff6B7280),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 16.h),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ReviewsAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        border: Border(
          bottom: BorderSide(color: context.primaryContainer, width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(27),
            offset: const Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      width: context.width,
      height: 80.h,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 24.w,
        vertical: 16.h,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: context.pop,
            child: Icon(Icons.arrow_back_ios_new, color: context.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AppText.headlineLarge(
              'التقييمات والتعليقات',
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSummaryCard extends StatelessWidget {
  const _ReviewsSummaryCard({
    required this.averageRating,
    required this.totalCount,
    required this.ratingCounts,
  });

  final double averageRating;
  final int totalCount;
  final Map<int, int> ratingCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: context.onPrimary,
        boxShadow: [
          BoxShadow(
            color: const Color(0xff303030).withAlpha(30),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 20.w,
        vertical: 20.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.displaySmall(
                    averageRating.toStringAsFixed(1),
                    color: context.primary,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.start,
                  ),
                  SizedBox(height: 6.h),
                  StarRating(
                    rating: averageRating,
                    color: const Color(0xffFAE13D),
                    size: 20.sp,
                    allowHalfRating: true,
                    filledIcon: Icons.star_rate_rounded,
                    halfFilledIcon: Icons.star_half_rounded,
                    emptyIcon: Icons.star_outline_rounded,
                    starCount: 5,
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText.titleMedium(
                    '$totalCount',
                    color: context.primary,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.end,
                  ),
                  SizedBox(height: 4.h),
                  AppText.labelLarge(
                    'إجمالي التقييمات',
                    color: const Color(0xff6B7280),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          for (var rating = 5; rating >= 1; rating--)
            _RatingCountRow(
              rating: rating,
              count: ratingCounts[rating] ?? 0,
              totalCount: totalCount,
            ),
        ],
      ),
    );
  }
}

class _RatingCountRow extends StatelessWidget {
  const _RatingCountRow({
    required this.rating,
    required this.count,
    required this.totalCount,
  });

  final int rating;
  final int count;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final progress = totalCount <= 0 ? 0.0 : (count / totalCount).clamp(0.0, 1.0);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 24.w,
            child: AppText.labelLarge(
              '$count',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8.h,
                backgroundColor: const Color(0xffE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(context.primary),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Row(
            children: [
              AppText.labelLarge(
                '$rating',
                color: const Color(0xff6B7280),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.star_rate_rounded, color: Color(0xffFAE13D), size: 17),
            ],
          ),
        ],
      ),
    );
  }
}
