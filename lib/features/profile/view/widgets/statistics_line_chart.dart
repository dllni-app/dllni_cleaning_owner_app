import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../data/models/fetch_worker_statistics_model.dart';
import '../manager/bloc/profile_bloc.dart';

class StatisticsChartData {
  final String date;
  final int confirmed;
  final int cancelled;
  final int disputed;

  StatisticsChartData({required this.date, required this.confirmed, required this.cancelled, required this.disputed});
}

class StatisticsLineChart extends StatelessWidget {
  const StatisticsLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: context.primary.withAlpha(46), blurRadius: 4, offset: Offset(0, 4))],
      ),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.bodyLarge('إحصائياتي', fontWeight: FontWeight.w400),
              WeekFilterDropdown(),
            ],
          ),
          SizedBox(height: 8),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              switch (state.workerProfileUsecaseStatus) {
                case null:
                  return AppText.labelMedium(
                    ErrorMessageFormatter.format(
                      state.errorMessage,
                      fallback: 'حدث خطا ما',
                    ),
                    color: context.error,
                    fontWeight: FontWeight.bold,
                  );
                case BlocStatus.failed:
                  return AppText.labelMedium(
                    ErrorMessageFormatter.format(
                      state.errorMessage,
                      fallback: 'حدث خطا ما',
                    ),
                    color: context.error,
                    fontWeight: FontWeight.bold,
                  );
                case BlocStatus.success:
                  return AppText.displaySmall(
                    state.workerProfileUsecase?.data?.totalCompletedJobs == null ? '-' : '${state.workerProfileUsecase?.data?.totalCompletedJobs}',
                    color: context.primary,
                    fontWeight: FontWeight.bold,
                  );
                case BlocStatus.loading:
                  return Shimmer.fromColors(
                    baseColor: context.surface,
                    highlightColor: context.primary,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                      height: 10,
                      width: 60,
                    ),
                  );
                case BlocStatus.init:
                  return Shimmer.fromColors(
                    baseColor: context.surface,
                    highlightColor: context.primary,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                      height: 10,
                      width: 60,
                    ),
                  );
              }
            },
          ),
          SizedBox(height: 8),
          BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              switch (state.workerProfileUsecaseStatus) {
                case null:
                  return AppText.labelMedium(
                    ErrorMessageFormatter.format(
                      state.errorMessage,
                      fallback: 'حدث خطا ما',
                    ),
                    color: context.error,
                    fontWeight: FontWeight.bold,
                  );
                case BlocStatus.failed:
                  return AppText.labelMedium(
                    ErrorMessageFormatter.format(
                      state.errorMessage,
                      fallback: 'حدث خطا ما',
                    ),
                    color: context.error,
                    fontWeight: FontWeight.bold,
                  );
                case BlocStatus.success:
                  return AppText.labelLarge('%${state.workerProfileUsecase?.data?.trustScore} نقاط الثقة', fontWeight: FontWeight.w400);
                case BlocStatus.loading:
                  return Shimmer.fromColors(
                    baseColor: context.surface,
                    highlightColor: context.primary,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                      height: 10,
                      width: 60,
                    ),
                  );
                case BlocStatus.init:
                  return Shimmer.fromColors(
                    baseColor: context.surface,
                    highlightColor: context.primary,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                      height: 10,
                      width: 60,
                    ),
                  );
              }
            },
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                switch (state.workerStatisticsStatus) {
                  case null:
                  case BlocStatus.init:
                  case BlocStatus.loading:
                    return Center(child: CircularProgressIndicator.adaptive());
                  case BlocStatus.failed:
                    return Center(
                      child: AppText.labelMedium(
                        ErrorMessageFormatter.format(
                          state.errorMessage,
                          fallback: 'حدث خطا ما',
                        ),
                        color: context.error,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  case BlocStatus.success:
                    final chartData = state.workerStatistics?.chart;
                    if (chartData == null || chartData.isEmpty) {
                      return Center(child: AppText.labelMedium('لا توجد بيانات', color: context.onSurface));
                    }
                    return _buildScrollableBarChart(context, chartData);
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Legend(color: context.primary, text: 'متنازع عليها'),
              SizedBox(width: 24),
              _Legend(color: context.secondary, text: 'ملغية'),
              SizedBox(width: 24),
              _Legend(color: context.primaryContainer, text: 'مؤكدة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBarChart(BuildContext context, List<FetchWorkerStatisticsModelChartItem> chartData) {
    final reversedData = chartData.reversed.toList();
    final convertedData = _convertToChartData(reversedData);
    final maxValue = _calculateMaxValue(chartData);
    final chartWidth = _calculateChartWidth(context, chartData.length);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: chartWidth,
        height: 100,
        child: SfCartesianChart(
          plotAreaBorderWidth: 0,
          tooltipBehavior: TooltipBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
            color: context.surface,
            textStyle: TextStyle(fontSize: 12, color: context.onSurface, fontWeight: FontWeight.w500),
            format: 'point.y',
            header: '',
            builder: (data, point, series, pointIndex, seriesIndex) {
              final chartData = convertedData[convertedData.length - 1 - pointIndex];
              final date = chartData.date;
              String value = '';
              String label = '';

              if (seriesIndex == 0) {
                value = chartData.confirmed.toString();
                label = 'مؤكدة';
              } else if (seriesIndex == 1) {
                value = chartData.cancelled.toString();
                label = 'ملغية';
              } else if (seriesIndex == 2) {
                value = chartData.disputed.toString();
                label = 'متنازع عليها';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(fontSize: 11, color: context.primary.withAlpha(200), fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$label: $value',
                      style: TextStyle(fontSize: 12, color: context.primary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
          primaryXAxis: CategoryAxis(
            majorGridLines: const MajorGridLines(width: 0),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          primaryYAxis: NumericAxis(
            opposedPosition: true,
            majorGridLines: MajorGridLines(width: 1, color: context.surface.withAlpha(32)),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
            minimum: 0,
            maximum: maxValue > 0 ? maxValue.toDouble() + (maxValue * 0.1) : 10,
            interval: maxValue > 0 ? (maxValue / 4).ceil().toDouble() : 2,
          ),
          series: <CartesianSeries>[
            StackedColumnSeries<StatisticsChartData, String>(
              dataSource: convertedData,
              xValueMapper: (StatisticsChartData data, _) => data.date,
              yValueMapper: (StatisticsChartData data, _) => data.confirmed,
              name: 'مؤكدة',
              color: context.primaryContainer,
              sortingOrder: SortingOrder.ascending,
              enableTooltip: true,
            ),
            StackedColumnSeries<StatisticsChartData, String>(
              dataSource: convertedData,
              xValueMapper: (StatisticsChartData data, _) => data.date,
              yValueMapper: (StatisticsChartData data, _) => data.cancelled,
              name: 'ملغية',
              color: context.secondary,
              sortingOrder: SortingOrder.ascending,
              enableTooltip: true,
            ),
            StackedColumnSeries<StatisticsChartData, String>(
              dataSource: convertedData,
              xValueMapper: (StatisticsChartData data, _) => data.date,
              yValueMapper: (StatisticsChartData data, _) => data.disputed,
              name: 'متنازع عليها',
              color: context.primary,
              sortingOrder: SortingOrder.ascending,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
              enableTooltip: true,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateChartWidth(BuildContext context, int numberOfBars) {
    const double barWidth = 40;
    const double horizontalPadding = 64;

    final calculatedWidth = (numberOfBars * barWidth) + horizontalPadding;
    return calculatedWidth > context.width ? calculatedWidth : context.width;
  }

  List<StatisticsChartData> _convertToChartData(List<FetchWorkerStatisticsModelChartItem> chartData) {
    return chartData.map((item) {
      final confirmed = _parseInt(item.confirmed) ?? 0;
      final cancelled = _parseInt(item.cancelled) ?? 0;
      final disputed = _parseInt(item.disputed) ?? 0;
      final formattedDate = _formatDate(item.date);

      return StatisticsChartData(date: formattedDate, confirmed: confirmed, cancelled: cancelled, disputed: disputed);
    }).toList();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final parts = dateStr.split('-');
      if (parts.length >= 3) {
        final day = parts[2].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        return '$day/$month';
      }
    } catch (e) {
      // If parsing fails, return empty string
    }
    return '';
  }

  int? _parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  int _calculateMaxValue(List<FetchWorkerStatisticsModelChartItem> chartData) {
    int maxValue = 0;
    for (final item in chartData) {
      final confirmed = _parseInt(item.confirmed) ?? 0;
      final cancelled = _parseInt(item.cancelled) ?? 0;
      final disputed = _parseInt(item.disputed) ?? 0;
      final total = confirmed + cancelled + disputed;
      if (total > maxValue) {
        maxValue = total;
      }
    }
    return maxValue;
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}

class WeekFilterDropdown extends StatefulWidget {
  const WeekFilterDropdown({super.key});

  @override
  State<WeekFilterDropdown> createState() => _WeekFilterDropdownState();
}

class _WeekFilterDropdownState extends State<WeekFilterDropdown> {
  String selected = 'هذا الأسبوع';

  final List<String> options = ['اليوم', 'هذا الأسبوع', 'هذا الشهر', 'هذه السنة'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopupMenuButton<String>(
        color: context.onPrimary,
        onSelected: (value) {
          setState(() {
            selected = value;
          });
        },
        itemBuilder: (context) {
          return options.map((e) => PopupMenuItem<String>(value: e, child: AppText.labelMedium(e))).toList();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
            const SizedBox(width: 4),
            AppText.labelLarge(selected),
          ],
        ),
      ),
    );
  }
}
