import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../helpers/cleaning_enum_translations.dart';
import '../helpers/order_lifecycle_policy.dart';

class WorkerRoomAssignmentsCard extends StatelessWidget {
  const WorkerRoomAssignmentsCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  Widget build(BuildContext context) {
    final rooms = order.myAssignedRooms;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium('الغرفة المخصصة لك', fontWeight: FontWeight.w600),
          12.verticalSpace,
          if (rooms.isEmpty)
            AppText.bodySmall(
              'لم يتم تخصيص غرفة لك بعد',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            )
          else
            for (var i = 0; i < rooms.length; i++) ...[
              if (i > 0) 8.verticalSpace,
              _RoomTile(room: rooms[i]),
            ],
        ],
      ),
    );
  }
}

class WorkerTeamStatusCard extends StatelessWidget {
  const WorkerTeamStatusCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  Widget build(BuildContext context) {
    if (!order.isSearchingForWorkers) {
      return const SizedBox.shrink();
    }

    final acceptance = order.workerAcceptance;
    final accepted = acceptance?.accepted ?? 0;
    final required = acceptance?.required ?? order.numberOfWorkers ?? 0;
    final currentWorkerAccepted = OrderLifecyclePolicy.hasCurrentWorkerAccepted(
      order,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.primaryContainer.withAlpha(31),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.primaryContainer.withAlpha(80)),
      ),
      child: AppText.bodyMedium(
        currentWorkerAccepted
            ? OrderLifecyclePolicy.acceptedWaitingMessage(order)
            : (required > 0
                  ? 'تم قبول $accepted من $required عمال'
                  : 'جاري البحث عن عمال'),
        color: context.primary,
        fontWeight: FontWeight.w600,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final CleaningRoomAssignmentModel room;

  @override
  Widget build(BuildContext context) {
    final typeLabel = CleaningEnumTranslations.roomType(room.roomType);
    final sizeLabel = CleaningEnumTranslations.roomSize(room.roomSize);
    final label = room.displayLabel?.trim().isNotEmpty == true
        ? room.displayLabel!.trim()
        : typeLabel;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(Icons.meeting_room_outlined, size: 18.r, color: context.primary),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(
                  label.isEmpty ? 'غرفة' : label,
                  fontWeight: FontWeight.w500,
                ),
                4.verticalSpace,
                AppText.bodySmall(
                  'النوع: $typeLabel - الحجم: $sizeLabel',
                  color: const Color(0xff6B7280),
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
