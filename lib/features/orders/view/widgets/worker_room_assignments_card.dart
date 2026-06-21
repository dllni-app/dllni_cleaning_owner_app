import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../data/models/cleaning_team_models.dart';
import '../../data/models/fetch_orders_usecase_model.dart';
import '../helpers/cleaning_room_display.dart';
import '../helpers/order_lifecycle_policy.dart';

class WorkerRoomAssignmentsCard extends StatelessWidget {
  const WorkerRoomAssignmentsCard({super.key, required this.order});

  final FetchOrdersUsecaseModelDataItem order;

  @override
  Widget build(BuildContext context) {
    final rooms = order.myAssignedRooms;

    return Container(
      width: context.width,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xffF4F5F7),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(
            'الغرف المخصصة لك',
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 12),
          Divider(color: Colors.black.withAlpha(42)),
          SizedBox(height: 12),
          if (rooms.isEmpty)
            AppText.bodySmall(
              'لم يتم تحديد غرف مخصصة لك بعد',
              color: const Color(0xff6B7280),
              textAlign: TextAlign.start,
            )
          else
            for (var i = 0; i < rooms.length; i++) ...[
              if (i > 0) 8.verticalSpace,
              _RoomTile(room: rooms[i], index: i),
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
    if (!OrderLifecyclePolicy.isAcceptedWaiting(order)) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: context.primaryContainer.withAlpha(31),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.primaryContainer.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelLarge(
            OrderLifecyclePolicy.teamStateTitle(order),
            color: context.primary,
            fontWeight: FontWeight.w800,
          ),
          8.verticalSpace,
          AppText.bodyMedium(
            OrderLifecyclePolicy.teamStateDescription(order),
            color: context.primary,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.index});

  final CleaningRoomAssignmentModel room;
  final int index;

  @override
  Widget build(BuildContext context) {
    final label = assignedRoomLabel(room, index);

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
            child: AppText.labelMedium(
              label,
              fontWeight: FontWeight.w500,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
