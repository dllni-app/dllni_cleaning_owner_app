import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_team_models.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

FetchOrdersUsecaseModelDataItem _order({
  String? status,
  String? startedTravelAt,
  String? bookingNumber,
  String? scheduledDate,
  String? scheduledTime,
  String? assignmentMode,
  int? numberOfWorkers,
  CleaningWorkerAcceptanceModel? workerAcceptance,
  CleaningMyAssignmentModel? myAssignment,
}) {
  return FetchOrdersUsecaseModelDataItem(
    id: 1,
    status: status,
    startedTravelAt: startedTravelAt,
    bookingNumber: bookingNumber ?? 'CLN-1',
    scheduledDate: scheduledDate,
    scheduledTime: scheduledTime,
    assignmentMode: assignmentMode,
    numberOfWorkers: numberOfWorkers,
    workerAcceptance: workerAcceptance,
    myAssignment: myAssignment,
  );
}

void main() {
  group('OrderLifecyclePolicy', () {
    test('pending allows accept reject only', () {
      final order = _order(status: CleaningBookingStatus.pending);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isTrue);
      expect(OrderLifecyclePolicy.isCustomerDataHidden(order), isTrue);
      expect(OrderLifecyclePolicy.canStartTravel(order), isFalse);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 0);
    });

    test('accepted pending order hides accept reject and waits for team', () {
      final order = _order(
        status: CleaningBookingStatus.pending,
        assignmentMode: 'open_count',
        numberOfWorkers: 3,
        workerAcceptance: CleaningWorkerAcceptanceModel(
          required: 3,
          accepted: 1,
          remaining: 2,
          isFulfilled: false,
        ),
        myAssignment: CleaningMyAssignmentModel(
          status: 'accepted',
          acceptedAt: '2026-06-11T18:00:00Z',
        ),
      );

      expect(OrderLifecyclePolicy.hasCurrentWorkerAccepted(order), isTrue);
      expect(OrderLifecyclePolicy.isAcceptedWaiting(order), isTrue);
      expect(OrderLifecyclePolicy.canAcceptReject(order), isFalse);
      expect(
        OrderLifecyclePolicy.statusLabel(order),
        'تم قبولك - بانتظار اكتمال الفريق',
      );
      expect(
        OrderLifecyclePolicy.acceptedWaitingMessage(order),
        contains('تم قبول 1 من 3 عمال'),
      );
    });

    test('accepted pending fulfilled team waits to start order', () {
      final order = _order(
        status: CleaningBookingStatus.pending,
        assignmentMode: 'open_count',
        numberOfWorkers: 2,
        workerAcceptance: CleaningWorkerAcceptanceModel(
          required: 2,
          accepted: 2,
          remaining: 0,
          isFulfilled: true,
        ),
        myAssignment: CleaningMyAssignmentModel(status: 'accepted'),
      );

      expect(OrderLifecyclePolicy.isAcceptedWaiting(order), isTrue);
      expect(
        OrderLifecyclePolicy.statusLabel(order),
        'تم قبولك - بانتظار بدء الطلب',
      );
      expect(
        OrderLifecyclePolicy.acceptedWaitingMessage(order),
        contains('بانتظار العميل'),
      );
    });

    test('customer data remains visible for non-pending statuses', () {
      final order = _order(status: CleaningBookingStatus.workerAssigned);
      expect(OrderLifecyclePolicy.isCustomerDataHidden(order), isFalse);
    });

    test('assigned without travel allows start travel and cancel', () {
      final order = _order(status: CleaningBookingStatus.workerAssigned);
      expect(OrderLifecyclePolicy.canStartTravel(order), isTrue);
      expect(OrderLifecyclePolicy.canCancel(order), isTrue);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 1);
    });

    test('start travel is blocked more than one hour before schedule', () {
      final order = _order(
        status: CleaningBookingStatus.workerAssigned,
        scheduledDate: '2026-06-17',
        scheduledTime: '10:00:00',
      );

      expect(
        OrderLifecyclePolicy.isStartTravelWithinAllowedWindow(
          order,
          now: DateTime(2026, 6, 16, 10),
        ),
        isFalse,
      );
    });

    test('start travel is allowed within one hour before schedule', () {
      final order = _order(
        status: CleaningBookingStatus.workerAssigned,
        scheduledDate: '2026-06-16',
        scheduledTime: '10:30:00',
      );

      expect(
        OrderLifecyclePolicy.isStartTravelWithinAllowedWindow(
          order,
          now: DateTime(2026, 6, 16, 9, 30),
        ),
        isTrue,
      );
    });

    test('traveling allows arrive on map step', () {
      final order = _order(
        status: CleaningBookingStatus.workerAssigned,
        startedTravelAt: '2026-05-18T10:00:00Z',
      );
      expect(OrderLifecyclePolicy.canArrive(order), isTrue);
      expect(OrderLifecyclePolicy.detailsStepFor(order), 2);
    });

    test('in progress allows complete', () {
      expect(
        OrderLifecyclePolicy.canCompleteWork(CleaningBookingStatus.inProgress),
        isTrue,
      );
      expect(
        OrderLifecyclePolicy.isAwaitingCustomerCompletion(
          CleaningBookingStatus.awaitingCustomerCompletion,
        ),
        isTrue,
      );
    });

    test('awaiting worker start confirmation stays on map step', () {
      final order = _order(
        status: CleaningBookingStatus.awaitingWorkerStartConfirmation,
      );

      expect(OrderLifecyclePolicy.isAwaitingStartVerification(order), isFalse);
      expect(
        OrderLifecyclePolicy.isAwaitingWorkerStartConfirmation(order),
        isTrue,
      );
      expect(OrderLifecyclePolicy.detailsStepFor(order), 2);
      expect(
        OrderLifecyclePolicy.statusLabel(order),
        'تم تحقق العميل - ابدأ العمل',
      );
      expect(
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          CleaningBookingStatus.awaitingStartVerification,
          CleaningBookingStatus.awaitingWorkerStartConfirmation,
        ),
        isTrue,
      );
    });

    test('does not downgrade from in_progress to awaiting verification', () {
      expect(
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          CleaningBookingStatus.inProgress,
          CleaningBookingStatus.awaitingStartVerification,
        ),
        isFalse,
      );
      expect(
        OrderLifecyclePolicy.shouldPreferIncomingStatus(
          CleaningBookingStatus.awaitingStartVerification,
          CleaningBookingStatus.inProgress,
        ),
        isTrue,
      );
      expect(
        OrderLifecyclePolicy.detailsStepForStatus(
          CleaningBookingStatus.inProgress,
        ),
        3,
      );
    });
  });
}
