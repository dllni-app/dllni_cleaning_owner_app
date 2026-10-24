import 'dart:async';

import 'common.dart';
import 'models.dart';
import 'requests.dart';

abstract interface class AccessAccountPort {
  Future<ReadResult<WorkerSessionContext?>> restoreSession();
  Future<ReadResult<WorkerSessionContext>> signIn({
    required String phone,
    required String password,
  });
  Future<ReadResult<ReadinessView>> fetchReadiness();
  Future<ReadResult<WorkerProfileView>> fetchProfile();
  Future<CommandResult> saveProfile(ProfileDraft draft);
  Future<CommandResult> setAccountActive(bool active);
  Future<ReadResult<List<String>>> fetchWorkAreas();
  Future<CommandResult> saveWorkAreas(WorkAreaDraft draft);
  Future<ReadResult<List<WorkingHoursSlot>>> fetchWorkingHours();
  Future<CommandResult> saveWorkingHours(WorkingHoursDraft draft);
  Future<ReadResult<StartLocationDraft?>> fetchStartLocation();
  Future<CommandResult> saveStartLocation(StartLocationDraft draft);
  Future<ReadResult<Page<String>>> fetchReviews(PageQuery query);
  Future<CommandResult> signOut();
}

abstract interface class WorkPort {
  Future<ReadResult<TodayView>> fetchToday();
  Future<ReadResult<Page<OfferView>>> fetchOffers(OfferQuery query);
  Future<ReadResult<Page<JobSummaryView>>> fetchMyBookings(BookingQuery query);
  Future<ReadResult<OfferView>> fetchOffer(String bookingId);
  Future<CommandResult> submitOfferDecision(
    WorkScope scope,
    OfferDecision decision,
  );
  Future<ReadResult<AgendaView>> fetchAgenda(AgendaQuery query);
}

abstract interface class MissionPort {
  Future<ReadResult<MissionView>> fetchMission(WorkScope scope);
  Future<ReadResult<MissionView>> fetchVisitScope(WorkScope scope);
  Future<ReadResult<InventoryView>> fetchInventory(WorkScope scope);
  Future<ReadResult<List<DecisionView>>> fetchDecisions(WorkScope scope);
  Future<ReadResult<String?>> fetchVerificationCode(WorkScope scope);
  Future<CommandResult> submit(MissionCommand command);
}

abstract interface class FinancePort {
  Future<ReadResult<EarningsView>> fetchEarnings(EarningsQuery query);
  Future<ReadResult<EarningEntryView>> fetchEarning(String entryKey);
  Future<ReadResult<DepositView>> fetchDeposit();
  Future<ReadResult<Page<DepositLedgerEntryView>>> fetchDepositLedger(
    LedgerQuery query,
  );
  Future<ReadResult<Page<DisputeView>>> fetchDisputes(DisputeQuery query);
  Future<ReadResult<DisputeView>> fetchDispute(String disputeId);
  Future<CommandResult> postDisputeMessage(String disputeId, String message);
}

abstract interface class CommunicationsPort {
  Future<ReadResult<Page<NotificationView>>> fetchNotifications(
    NotificationQuery query,
  );
  Future<CommandResult> markNotificationRead(String notificationId);
  Future<CommandResult> deleteNotification(String notificationId);
  Future<CommandResult> deleteAllNotifications();
  Future<ReadResult<List<SupportContactView>>> fetchSupportContacts();
  Future<CommandResult> sendSos(WorkScope scope, SosDraft draft);
}

enum RuntimePhase { restoring, signedOut, signedIn, revoked }

enum ConnectionState { online, reconnecting, offline }

abstract interface class WorkerRuntimePort {
  /// Null until verified; login must not invent a worker identifier.
  WorkerSessionContext? get context;
  RuntimePhase get phase;
  ConnectionState get connection;
  Stream<DomainInvalidation> get invalidations;

  /// Only current generation events are delivered after identity replacement.
  void invalidate(
    InvalidationTopic topic, {
    WorkScope? scope,
    String? entityKey,
  });
  Future<void> purgeSessionData();
}
