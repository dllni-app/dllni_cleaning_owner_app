import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_pickers.dart';
import 'package:flutter/material.dart';

import '../../../../generated/assets.dart';
import '../../data/models/fetch_worker_profile_usecase_model.dart';

class PeriodData {
  String? from;
  String? to;

  PeriodData({this.from, this.to});
}

class WorkingTimeCard extends StatefulWidget {
  const WorkingTimeCard({super.key, required this.dayName, required this.dayNameEn, this.workingDay, required this.isToday, required this.dayIndex});

  final String dayName;
  final String dayNameEn;
  final WorkingDay? workingDay;
  final bool isToday;
  final int dayIndex;

  @override
  State<WorkingTimeCard> createState() => _WorkingTimeCardState();
}

class _WorkingTimeCardState extends State<WorkingTimeCard> {
  static const List<String> periods = [
    'الفترة الأولى',
    'الفترة الثانية',
    'الفترة الثالثة',
    'الفترة الرابعة',
    'الفترة الخامسة',
    'الفترة السادسة',
    'الفترة السابعة',
    'الفترة الثامنة',
    'الفترة التاسعة',
    'الفترة العاشرة',
    'الفترة الحادية عشر',
    'الفترة الثانية عشر',
    'الفترة الثالثة عشر',
    'الفترة الرابعة عشر',
    'الفترة الخامسة عشر',
    'الفترة السادسة عشر',
    'الفترة السابعة عشر',
    'الفترة الثامنة عشر',
    'الفترة التاسعة عشر',
    'الفترة العشرون',
    'الفترة الحادية والعشرون',
    'الفترة الثانية والعشرون',
    'الفترة الثالثة والعشرون',
    'الفترة الرابعة والعشرون',
  ];

  late bool isEnabled;
  late List<PeriodData> periodsList;

  @override
  void initState() {
    super.initState();
    isEnabled = widget.workingDay?.isWorking ?? false;
    periodsList = widget.workingDay?.hours.map((item) => PeriodData(from: item.from, to: item.to)).toList() ?? [];
  }

  void _addPeriod() {
    if (periodsList.length < 24) {
      setState(() {
        periodsList.add(PeriodData());
      });
    }
  }

  void _deletePeriod(int index) {
    if (periodsList.isNotEmpty) {
      setState(() {
        periodsList.removeAt(index);
      });
    }
  }

  void _updatePeriod(int index, String? from, String? to) {
    setState(() {
      periodsList[index].from = from;
      periodsList[index].to = to;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isToday ? const Color(0xffE6F4EF) : context.onPrimary;
    final borderColor = widget.isToday ? const Color(0xff1FAF7A) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: widget.isToday ? Border.all(color: borderColor, width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isToday && isEnabled
                          ? Color(0xff10B981)
                          : isEnabled
                          ? const Color(0xffE6F4EF)
                          : context.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isEnabled
                        ? Center(child: AppImage.asset(Assets.imagesWorkingTimeCalender))
                        : Center(child: Icon(Icons.door_front_door, color: Colors.grey.shade600, size: 24)),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!isEnabled) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                                  child: AppText.labelSmall('مغلق', color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                              ],
                              AppText.bodyMedium(widget.dayName, fontWeight: FontWeight.bold),
                              if (widget.isToday && isEnabled) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xff1FAF7A), borderRadius: BorderRadius.circular(12)),
                                  child: AppText.labelSmall('اليوم', color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          AppText.labelLarge(widget.dayNameEn, fontWeight: FontWeight.w400),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                activeTrackColor: const Color(0xff1FAF7A),
                inactiveTrackColor: const Color(0xffD1D5DB),
                onChanged: (value) {
                  setState(() {
                    isEnabled = value;
                  });
                },
              ),
            ],
          ),
          if (isEnabled) ...[
            if (periodsList.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...periodsList.asMap().entries.map((entry) {
                final index = entry.key;
                final period = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PeriodCard(
                    periodIndex: index,
                    periodName: periods[index],
                    from: period.from,
                    to: period.to,
                    onDelete: () => _deletePeriod(index),
                    onTimeChanged: (from, to) => _updatePeriod(index, from, to),
                    isDeletable: index > 0,
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: periodsList.length < 24 ? _addPeriod : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: periodsList.length < 24 ? const Color(0xff1FAF7A) : Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: periodsList.length < 24 ? const Color(0xff1FAF7A) : Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "إضافة فترة",
                      style: TextStyle(color: periodsList.length < 24 ? const Color(0xff1FAF7A) : Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(Icons.nights_stay, color: Colors.grey.shade600, size: 24),
                  const SizedBox(width: 12),
                  AppText.labelLarge('عطلة في هذا اليوم', color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PeriodCard extends StatefulWidget {
  const PeriodCard({
    super.key,
    required this.periodIndex,
    required this.periodName,
    this.from,
    this.to,
    required this.onDelete,
    required this.onTimeChanged,
    this.isDeletable = true,
  });

  final int periodIndex;
  final String periodName;
  final String? from;
  final String? to;
  final VoidCallback onDelete;
  final void Function(String?, String?) onTimeChanged;
  final bool isDeletable;

  @override
  State<PeriodCard> createState() => _PeriodCardState();
}

class _PeriodCardState extends State<PeriodCard> {
  late TextEditingController fromController;
  late TextEditingController toController;

  @override
  void initState() {
    super.initState();
    fromController = TextEditingController(text: widget.from);
    toController = TextEditingController(text: widget.to);
  }

  @override
  void didUpdateWidget(PeriodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from) {
      fromController.text = widget.from ?? '';
    }
    if (oldWidget.to != widget.to) {
      toController.text = widget.to ?? '';
    }
  }

  @override
  void dispose() {
    fromController.dispose();
    toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xffF9FAFB), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.labelLarge(widget.periodName, fontWeight: FontWeight.bold),
              if (widget.isDeletable)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _timeField(
                  title: "من",
                  controller: fromController,
                  onChanged: (value) => widget.onTimeChanged(value, toController.text.isEmpty ? null : toController.text),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeField(
                  title: "إلى",
                  controller: toController,
                  onChanged: (value) => widget.onTimeChanged(fromController.text.isEmpty ? null : fromController.text, value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeField({required String title, required TextEditingController controller, required void Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(title, fontWeight: FontWeight.bold),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: TextStyle(color: Color(0xff10B981)),
          onTap: () async {
            final pickedTime = await AppPickers.showAppTimePicker(context: context);
            controller.text = pickedTime;
            onChanged(pickedTime);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            suffixIcon: const Icon(Icons.access_time, size: 18, color: Colors.grey),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xff1FAF7A)),
            ),
          ),
        ),
      ],
    );
  }
}
