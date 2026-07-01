import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_global_prompt_coordinator.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_team_models.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_room_display.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_worker_order_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cleaning worker booking model parsing', () {
    test('parses worker status, counts, and assignments from snake/camel payload', () {
      final item = FetchOrdersUsecaseModelDataItem.fromJson(<String, dynamic>{
        'id': 123,
        'status': CleaningBookingStatus.pending,
        'worker_order_status': 'accepted_waiting_team',
        'worker_order_status_label': 'بانتظار اكتمال الفريق',
        'required_workers_count': 2,
        'accepted_workers_count': 1,
        'pending_workers_count': 1,
        'basePrice': 100,
        'travelFee': 20,
        'addonsTotal': 15,
        'totalPrice': 135,
        'my_assignment': <String, dynamic>{
          'workerId': 9,
          'status': 'accepted',
        },
        'room_assignments': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'roomKey': 'bedroom_1',
            'roomType': 'bedroom',
            'roomTypeLabel': 'غرفة نوم',
            'roomSize': 'large',
            'roomSizeLabel': 'كبيرة',
            'assignedWorkerId': 9,
            'isAssignedToMe': true,
          },
        ],
      });

      expect(item.workerOrderStatus, 'accepted_waiting_team');
      expect(item.workerOrderStatusLabel, 'بانتظار اكتمال الفريق');
      expect(item.requiredWorkersCount, 2);
      expect(item.acceptedWorkersCount, 1);
      expect(item.pendingWorkersCount, 1);
      expect(item.effectiveWorkerStatus, CleaningWorkerOrderStatus.acceptedWaitingTeam);
      expect(item.myAssignedRooms.length, 1);
      expect(
        assignedRoomLabel(item.myAssignedRooms.first, 0),
        'غرفة نوم 1 - كبيرة',
      );
    });
  });

  group('OrderLifecyclePolicy worker status mapping', () {
    test('maps awaiting worker start confirmation to map step', () {
      final order = FetchOrdersUsecaseModelDataItem(
        id: 1,
        status: CleaningBookingStatus.awaitingWorkerStartConfirmation,
        workerOrderStatus: CleaningBookingStatus.awaitingWorkerStartConfirmation,
      );

      expect(OrderLifecyclePolicy.isAwaitingWorkerStartConfirmation(order), isTrue);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 2);
      expect(
        OrderLifecyclePolicy.statusLabel(order),
        'تم تحقق العميل - ابدأ العمل',
      );
    });

    test('uses worker_order_status for accepted waiting team card', () {
      final order = FetchOrdersUsecaseModelDataItem(
        id: 1,
        status: CleaningBookingStatus.pending,
        workerOrderStatus: 'accepted_waiting_team',
        requiredWorkersCount: 2,
        acceptedWorkersCount: 1,
        pendingWorkersCount: 1,
        myAssignment: CleaningMyAssignmentModel(status: 'accepted'),
      );

      expect(OrderLifecyclePolicy.isAcceptedWaiting(order), isTrue);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isFalse);
      expect(
        OrderLifecyclePolicy.teamStateDescription(order),
        contains('1 من 2'),
      );
    });

    test('does not allow accepting an already accepted pending order from worker_order_status', () {
      final order = FetchOrdersUsecaseModelDataItem(
        id: 2,
        status: CleaningBookingStatus.pending,
        workerOrderStatus: 'accepted_waiting_for_order_start',
        requiredWorkersCount: 2,
        acceptedWorkersCount: 1,
        pendingWorkersCount: 1,
      );

      expect(order.effectiveWorkerStatus, CleaningWorkerOrderStatus.acceptedWaitingTeam);
      expect(OrderLifecyclePolicy.hasCurrentWorkerAccepted(order), isTrue);
      expect(OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(order), isFalse);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isFalse);
    });

    test('does not allow accepting when my assignment is start approved', () {
      final order = FetchOrdersUsecaseModelDataItem(
        id: 3,
        status: CleaningBookingStatus.pending,
        myAssignment: CleaningMyAssignmentModel(status: 'start_approved'),
      );

      expect(OrderLifecyclePolicy.hasCurrentWorkerAccepted(order), isTrue);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isFalse);
    });

    test('allows accepting only pending orders with pending worker status', () {
      final order = FetchOrdersUsecaseModelDataItem(
        id: 4,
        status: CleaningBookingStatus.pending,
        workerOrderStatus: CleaningBookingStatus.pending,
      );

      expect(OrderLifecyclePolicy.isAvailableNewOrderForCurrentWorker(order), isTrue);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isTrue);
    });
  });

  group('CleaningWorkerGlobalPromptCoordinator pending prompt filtering', () {
    test('filters already accepted pending orders from promptable pending IDs', () {
      final ids = CleaningWorkerGlobalPromptCoordinator.findPendingBookingIds([
        FetchOrdersUsecaseModelDataItem(
          id: 10,
          status: CleaningBookingStatus.pending,
          workerOrderStatus: CleaningBookingStatus.pending,
        ),
        FetchOrdersUsecaseModelDataItem(
          id: 11,
          status: CleaningBookingStatus.pending,
          workerOrderStatus: 'accepted_waiting_for_order_start',
        ),
        FetchOrdersUsecaseModelDataItem(
          id: 12,
          status: CleaningBookingStatus.pending,
          myAssignment: CleaningMyAssignmentModel(status: 'start_approved'),
        ),
      ]);

      expect(ids, <int>[10]);
    });
  });
}
