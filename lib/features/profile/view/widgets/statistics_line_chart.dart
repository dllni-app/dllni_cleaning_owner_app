import 'dart:math';

import 'package:common_package/common_package.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../manager/bloc/profile_bloc.dart';

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
                  return AppText.labelMedium(state.errorMessage ?? 'حدث خطا ما', color: context.error, fontWeight: FontWeight.bold);
                case BlocStatus.failed:
                  return AppText.labelMedium(state.errorMessage ?? 'حدث خطا ما', color: context.error, fontWeight: FontWeight.bold);
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
                  return AppText.labelMedium(state.errorMessage ?? 'حدث خطا ما', color: context.error, fontWeight: FontWeight.bold);
                case BlocStatus.failed:
                  return AppText.labelMedium(state.errorMessage ?? 'حدث خطا ما', color: context.error, fontWeight: FontWeight.bold);
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
          SizedBox(height: 30),
          SizedBox(
            height: 100,
            width: context.width,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state.workerProfileUsecaseStatus == BlocStatus.success) {
                  final complete = state.workerProfileUsecase!.data!.acceptanceRate!;
                  final cancel = state.workerProfileUsecase!.data!.cancellationRate!;
                  final returned = state.workerProfileUsecase!.data!.openDisputesCount!;
                  return LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: max(complete, max(cancel, returned.toDouble())) + 50,
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(color: context.surface.withAlpha(32), strokeWidth: 1);
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            reservedSize: 35,
                            getTitlesWidget: (value, meta) {
                              return AppText.labelSmall(value.toInt().toString());
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              const titles = ['سنة', '6 أشهر', '3 أشهر', 'شهرين', '1 شهر', 'أسبوع'];
                              return Padding(padding: const EdgeInsets.only(top: 8), child: AppText.labelSmall(titles[value.toInt()]));
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [_confirmedLine(context), _cancelledLine(context), _returnedLine(context)],
                    ),
                  );
                } else {
                  return Center(child: CircularProgressIndicator.adaptive());
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Legend(color: context.primary, text: 'إرجاع'),
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

  /// الأزرق
  LineChartBarData _returnedLine(BuildContext context) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      color: context.primary,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      spots: const [FlSpot(0, -40), FlSpot(1, 15), FlSpot(2, 5), FlSpot(3, 20), FlSpot(4, 0), FlSpot(5, -10)],
    );
  }

  LineChartBarData _cancelledLine(BuildContext context) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      color: context.secondary,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      spots: const [FlSpot(0, 30), FlSpot(1, 5), FlSpot(2, 25), FlSpot(3, -5), FlSpot(4, 10), FlSpot(5, 20)],
    );
  }

  /// الوردي
  LineChartBarData _confirmedLine(BuildContext context) {
    return LineChartBarData(
      isCurved: true,
      curveSmoothness: 0.35,
      color: context.primaryContainer,
      barWidth: 1,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(show: false),
      spots: const [FlSpot(0, 5), FlSpot(1, 15), FlSpot(2, -10), FlSpot(3, -20), FlSpot(4, 35), FlSpot(5, 45)],
    );
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
