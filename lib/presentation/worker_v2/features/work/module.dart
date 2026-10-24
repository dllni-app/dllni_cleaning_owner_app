/// S05 public entry. The server is authoritative for assignments and offers.
library;

import 'dart:async';
import 'package:flutter/material.dart' hide Page;
import '../../contracts/common.dart';
import '../../contracts/models.dart';
import '../../contracts/navigation.dart';
import '../../contracts/ports.dart' as wr;
import '../../contracts/requests.dart';
import '../../design_system/design_system.dart';
import 'catalog_ar.dart';
import 'catalog_en.dart';

class WorkDiscoveryModule extends StatefulWidget {
  const WorkDiscoveryModule({
    super.key,
    required this.port,
    required this.runtime,
    required this.onNavigate,
    this.initialPage = WorkerDestination.today,
    this.locale = const Locale('ar'),
    this.businessDate,
  }) : assert(
         initialPage == WorkerDestination.today ||
             initialPage == WorkerDestination.jobs ||
             initialPage == WorkerDestination.schedule,
       );

  final wr.WorkPort port;
  final wr.WorkerRuntimePort runtime;
  final ValueChanged<RouteIntent> onNavigate;
  final WorkerDestination initialPage;
  final Locale locale;

  /// Server/business-calendar YYYY-MM-DD. S00 can inject a clock for QA.
  final String? businessDate;

  @override
  State<WorkDiscoveryModule> createState() => _WorkDiscoveryModuleState();
}

class _WorkDiscoveryModuleState extends State<WorkDiscoveryModule> {
  late WorkerDestination _page;
  late String _date;
  StreamSubscription<DomainInvalidation>? _sub;
  TodayView? _today;
  AgendaView? _agenda;
  Page<OfferView>? _offers;
  Page<JobSummaryView>? _bookings;
  OfferView? _offer;
  int _offerPage = 1;
  int _bookingPage = 1;
  int _agendaPage = 1;
  String? _requestedOfferId;
  bool _offersTab = true;
  bool _loading = false;
  bool _detailLoading = false;
  bool _submitting = false;
  bool _uncertain = false;
  String? _error;
  String? _detailError;
  String? _message;
  DateTime? _fetchedAt;
  ReadFreshness? _freshness;
  WorkerSessionContext? _currentIdentity;
  int _requestVersion = 0;
  BuildContext? _decisionSheetContext;

  void _closeOldDecisionSheet() {
    final sheet = _decisionSheetContext;
    _decisionSheetContext = null;
    if (sheet == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sheet.mounted && ModalRoute.of(sheet)?.isCurrent == true) {
        Navigator.pop(sheet);
      }
    });
  }

  void _clearPrivateViews() {
    _requestVersion++;
    _closeOldDecisionSheet();
    _currentIdentity = null;
    _today = null;
    _offers = null;
    _bookings = null;
    _agenda = null;
    _offer = null;
    _requestedOfferId = null;
    _detailError = null;
    _freshness = null;
    _fetchedAt = null;
    _uncertain = false;
    _message = null;
    _error = null;
    _loading = false;
    _detailLoading = false;
    _submitting = false;
  }

  @override
  void didUpdateWidget(covariant WorkDiscoveryModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.runtime, widget.runtime)) {
      unawaited(_sub?.cancel());
      _sub = widget.runtime.invalidations.listen(_onInvalidation);
    }
    if (!identical(oldWidget.runtime, widget.runtime) ||
        !identical(oldWidget.port, widget.port) ||
        !_identityValid(_currentIdentity)) {
      _clearPrivateViews();
      unawaited(_load());
    }
  }

  void _onInvalidation(DomainInvalidation event) {
    final identity = widget.runtime.context;
    if (!mounted ||
        identity == null ||
        event.generation != identity.generation ||
        !_identityValid(identity)) {
      return;
    }
    if (event.topic == InvalidationTopic.agenda ||
        event.topic == InvalidationTopic.booking) {
      unawaited(_load());
    }
  }

  String t(String key) =>
      (widget.locale.languageCode == 'en' ? workEn : workAr)[key] ?? key;
  bool get _offline =>
      widget.runtime.connection != wr.ConnectionState.online ||
      _freshness == ReadFreshness.offline ||
      _freshness == ReadFreshness.stale;

  // Syria observes UTC+03:00 for present-day calendar navigation. Scheduled
  // visit dates themselves always come from the backend's Damascus projection.
  static String _currentDamascusDate() {
    final d = DateTime.now().toUtc().add(const Duration(hours: 3));
    return _iso(d);
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _parse(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return DateTime.utc(1970);
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  DateRange get _week {
    final day = _parse(_date);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return DateRange(
      from: _iso(monday),
      to: _iso(monday.add(const Duration(days: 6))),
    );
  }

  @override
  void initState() {
    super.initState();
    _page = widget.initialPage;
    _date = widget.businessDate ?? _currentDamascusDate();
    _currentIdentity = widget.runtime.context;
    _sub = widget.runtime.invalidations.listen(_onInvalidation);
    _load();
  }

  @override
  void dispose() {
    _requestVersion++;
    _sub?.cancel();
    super.dispose();
  }

  bool _identityValid(WorkerSessionContext? initial) {
    final current = widget.runtime.context;
    return initial != null &&
        current != null &&
        initial.userId == current.userId &&
        initial.workerId == current.workerId &&
        initial.generation == current.generation &&
        widget.runtime.phase == wr.RuntimePhase.signedIn;
  }

  /// An expired/offline cache is unavailable, even when a buggy adapter returns it.
  bool _acceptable<T>(ReadSuccess<T> success) {
    final isCache = success.freshness != ReadFreshness.fresh;
    if (isCache &&
        DateTime.now().toUtc().difference(success.fetchedAt.toUtc()) >
            const Duration(hours: 24)) {
      return false;
    }
    return true;
  }

  Future<void> _load() async {
    final identity = widget.runtime.context;
    final version = ++_requestVersion;
    if (!_identityValid(identity)) {
      setState(() {
        _clearPrivateViews();
        _error = t('unavailable');
      });
      return;
    }
    if (_currentIdentity == null ||
        !_identityValid(_currentIdentity) ||
        identity!.generation != _currentIdentity!.generation) {
      _today = null;
      _offers = null;
      _bookings = null;
      _agenda = null;
      _offer = null;
      _currentIdentity = identity;
      _freshness = null;
      _fetchedAt = null;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      if (_page == WorkerDestination.today) {
        final result = await widget.port.fetchToday();
        if (!mounted ||
            version != _requestVersion ||
            !_identityValid(identity)) {
          return;
        }
        _capture(result, (TodayView v) => _today = v);
      } else if (_page == WorkerDestination.jobs && _offersTab) {
        final result = await widget.port.fetchOffers(
          OfferQuery(page: PageQuery(page: _offerPage)),
        );
        if (!mounted ||
            version != _requestVersion ||
            !_identityValid(identity)) {
          return;
        }
        _capture(result, (Page<OfferView> v) => _offers = v);
      } else if (_page == WorkerDestination.jobs) {
        final result = await widget.port.fetchMyBookings(
          BookingQuery(page: PageQuery(page: _bookingPage)),
        );
        if (!mounted ||
            version != _requestVersion ||
            !_identityValid(identity)) {
          return;
        }
        _capture(result, (Page<JobSummaryView> v) => _bookings = v);
      } else if (_page == WorkerDestination.schedule) {
        final result = await widget.port.fetchAgenda(
          AgendaQuery(
            dates: _week,
            page: PageQuery(page: _agendaPage),
          ),
        );
        if (!mounted ||
            version != _requestVersion ||
            !_identityValid(identity)) {
          return;
        }
        _capture(result, (AgendaView v) => _agenda = v);
      }
    } catch (_) {
      if (mounted && version == _requestVersion) _error = t('error');
    } finally {
      if (mounted && version == _requestVersion) {
        setState(() => _loading = false);
      }
    }
  }

  void _capture<T>(ReadResult<T> result, void Function(T) assign) {
    if (result is ReadSuccess<T>) {
      if (!_acceptable(result)) {
        _error = t('unavailable');
        return;
      }
      _fetchedAt = result.fetchedAt;
      _freshness = result.freshness;
      assign(result.value);
    } else if (result is ReadFailure<T>) {
      _error = result.failure.safeMessage ?? t('error');
      if (result.failure.kind == FailureKind.forbidden ||
          result.failure.kind == FailureKind.unauthenticated ||
          result.failure.kind == FailureKind.notFound) {
        _today = null;
        _agenda = null;
        _offers = null;
        _bookings = null;
        _offer = null;
        _requestedOfferId = null;
        _freshness = null;
        _fetchedAt = null;
      }
    }
  }

  void _navigate(WorkerDestination page) {
    if (_submitting) return;
    setState(() {
      _page = page;
      _offer = null;
      _requestedOfferId = null;
      _detailError = null;
    });
    _load();
  }

  // Matched to the reviewed worker-assignment acceptedValues() state family.
  // Never treat an unrecognized or merely offered state as acceptance.
  static const _committedStatuses = {
    'accepted',
    'accepted_waiting_for_order_start',
    'awaiting_start_verification',
    'start_approved',
    'in_progress',
    'awaiting_customer_completion',
    'time_extension_requested',
    'completed',
  };

  bool _committed(AgendaItemView item) =>
      _committedStatuses.contains(item.ownAssignmentStatus);

  bool get _missionNavigationAllowed =>
      _identityValid(_currentIdentity) &&
      !_loading &&
      !_detailLoading &&
      _error == null &&
      !_offline &&
      _freshness == ReadFreshness.fresh;

  void _openMission(AgendaItemView item, RouteOrigin origin) {
    if (!_missionNavigationAllowed) return;
    // The agenda contains only assigned visits. If backend explicitly revokes
    // an assignment, do not turn the card into a mission despite its scope.
    if (!_committed(item) || !item.operational.permits(WorkerAction.view)) {
      return;
    }
    widget.onNavigate(
      RouteIntent(
        destination: WorkerDestination.mission,
        origin: origin,
        scope: item.scope,
        entityId: item.scope.bookingId,
      ),
    );
  }

  Future<void> _openOffer(String bookingId) async {
    if (_detailLoading) return;
    setState(() {
      _detailLoading = true;
      _detailError = null;
      _offer = null;
      _requestedOfferId = bookingId;
    });
    final initial = widget.runtime.context;
    try {
      final result = await widget.port.fetchOffer(bookingId);
      if (!mounted || !_identityValid(initial)) return;
      if (result is ReadSuccess<OfferView> &&
          result.value.bookingId == bookingId &&
          _acceptable(result)) {
        setState(() {
          _offer = result.value;
          _fetchedAt = result.fetchedAt;
          _freshness = result.freshness;
          _uncertain = false;
        });
      } else {
        setState(() => _detailError = t('unavailable'));
      }
    } catch (_) {
      if (mounted) setState(() => _detailError = t('error'));
    } finally {
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  bool _permits(OfferView offer, OfferDecisionKind kind) {
    final modes = offer.acceptanceModes.toSet();
    return switch (kind) {
      OfferDecisionKind.decline =>
        modes.contains('decline') || modes.contains('reject'),
      OfferDecisionKind.acceptLegacy =>
        modes.contains('accept_legacy') || modes.contains('legacy'),
      OfferDecisionKind.acceptAll => modes.contains('accept_all'),
      OfferDecisionKind.acceptSelected => modes.contains('accept_selected'),
    };
  }

  bool _decisionOwnerCurrent(
    WorkerSessionContext? owner,
    int version,
    wr.WorkPort port,
    wr.WorkerRuntimePort runtime,
  ) =>
      mounted &&
      identical(widget.port, port) &&
      identical(widget.runtime, runtime) &&
      version == _requestVersion &&
      _identityValid(owner) &&
      _identityValid(_currentIdentity);

  bool _decisionAuthorized(
    WorkerSessionContext? owner,
    int version,
    wr.WorkPort port,
    wr.WorkerRuntimePort runtime,
    OfferView selected,
  ) =>
      _decisionOwnerCurrent(owner, version, port, runtime) &&
      _page == WorkerDestination.jobs &&
      identical(_offer, selected) &&
      _requestedOfferId == selected.bookingId &&
      !_detailLoading &&
      !_offline &&
      _freshness == ReadFreshness.fresh &&
      _error == null &&
      _detailError == null;

  Future<void> _decisionSheet(OfferDecisionKind kind) async {
    final selected = _offer;
    final owner = widget.runtime.context;
    final version = _requestVersion;
    final ownerPort = widget.port;
    final ownerRuntime = widget.runtime;
    if (selected == null ||
        !_decisionAuthorized(
          owner,
          version,
          ownerPort,
          ownerRuntime,
          selected,
        ) ||
        _offline ||
        _uncertain ||
        !selected.eligible ||
        !selected.discoverable ||
        !_permits(selected, kind)) {
      return;
    }
    final exactChoices = selected.visitChoices
        .where(
          (scope) =>
              scope.bookingId == selected.bookingId && scope.sessionId != null,
        )
        .toList();
    final chosen = <String>{};
    String? sheetError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        _decisionSheetContext = sheetContext;
        return StatefulBuilder(
          builder: (sheetContext, refreshSheet) => WrSheetFrame(
            title: kind == OfferDecisionKind.decline
                ? t('decline')
                : t('chooseMode'),
            submitting: _submitting,
            submittingLabel: t('saving'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(selected.work.label),
                if (selected.work.area != null) Text(selected.work.area!),
                if (selected.workerAmount != null)
                  WrAmountText(
                    amount: selected.workerAmount,
                    unavailableLabel: t('priceUnavailable'),
                  ),
                if (kind == OfferDecisionKind.acceptSelected) ...[
                  Text(t('selectVisits')),
                  for (final choice in exactChoices)
                    Material(
                      color: WrColors.surface,
                      child: CheckboxListTile(
                        title: Text(choice.sessionId!),
                        subtitle: Text(choice.bookingId),
                        value: chosen.contains(choice.sessionId),
                        onChanged:
                            _submitting ||
                                !_decisionAuthorized(
                                  owner,
                                  version,
                                  ownerPort,
                                  ownerRuntime,
                                  selected,
                                )
                            ? null
                            : (checked) => refreshSheet(() {
                                if (checked == true) {
                                  chosen.add(choice.sessionId!);
                                } else {
                                  chosen.remove(choice.sessionId);
                                }
                              }),
                      ),
                    ),
                ],
                if (sheetError != null)
                  WrEligibilityNotice(
                    title: t('rejected'),
                    message: sheetError!,
                  ),
                const SizedBox(height: 12),
                WrActionButton(
                  label: switch (kind) {
                    OfferDecisionKind.decline => t('decline'),
                    OfferDecisionKind.acceptLegacy => t('acceptLegacy'),
                    OfferDecisionKind.acceptAll => t('acceptAll'),
                    OfferDecisionKind.acceptSelected => t('acceptSelected'),
                  },
                  role: kind == OfferDecisionKind.decline
                      ? WrActionRole.destructive
                      : WrActionRole.primary,
                  busy: _submitting,
                  busyLabel: t('saving'),
                  onPressed:
                      _submitting ||
                          _uncertain ||
                          !_decisionAuthorized(
                            owner,
                            version,
                            ownerPort,
                            ownerRuntime,
                            selected,
                          ) ||
                          (kind == OfferDecisionKind.acceptSelected &&
                              chosen.isEmpty)
                      ? null
                      : () async {
                          if (!_decisionAuthorized(
                            owner,
                            version,
                            ownerPort,
                            ownerRuntime,
                            selected,
                          )) {
                            if (sheetContext.mounted &&
                                ModalRoute.of(sheetContext)?.isCurrent ==
                                    true) {
                              Navigator.pop(sheetContext);
                            }
                            return;
                          }
                          refreshSheet(() {
                            _submitting = true;
                            sheetError = null;
                          });
                          try {
                            // The parent booking scope is used only for the booking-level
                            // decision. Selected exact session identities travel in the
                            // typed OfferDecision; never silently use parent acceptance.
                            final result = await ownerPort.submitOfferDecision(
                              WorkScope(bookingId: selected.bookingId),
                              OfferDecision(
                                kind: kind,
                                selectedSessionIds:
                                    kind == OfferDecisionKind.acceptSelected
                                    ? (chosen.toList()..sort())
                                    : const [],
                              ),
                            );
                            if (!sheetContext.mounted ||
                                !_decisionAuthorized(
                                  owner,
                                  version,
                                  ownerPort,
                                  ownerRuntime,
                                  selected,
                                )) {
                              return;
                            }
                            if (result.status == CommandStatus.confirmed) {
                              Navigator.pop(sheetContext);
                              setState(() {
                                _offer = null;
                                _requestedOfferId = null;
                                _uncertain = false;
                                _submitting = false;
                              });
                              await _load();
                            } else {
                              refreshSheet(() {
                                sheetError =
                                    result.status ==
                                        CommandStatus.outcomeUnknown
                                    ? t('unknownOutcome')
                                    : (result.reasonCode ?? t('rejected'));
                                _uncertain =
                                    result.status ==
                                    CommandStatus.outcomeUnknown;
                              });
                              if (result.status ==
                                      CommandStatus.outcomeUnknown ||
                                  result.reasonCode == 'conflict' ||
                                  result.reasonCode == 'state_changed') {
                                // A later retry must follow an explicit fresh detail load.
                                _detailError = _uncertain
                                    ? t('unknownOutcome')
                                    : t('changed');
                              }
                            }
                          } catch (_) {
                            if (sheetContext.mounted &&
                                _decisionAuthorized(
                                  owner,
                                  version,
                                  ownerPort,
                                  ownerRuntime,
                                  selected,
                                )) {
                              refreshSheet(() {
                                sheetError = t('error');
                                _uncertain = true;
                              });
                            }
                          } finally {
                            if (_decisionOwnerCurrent(
                              owner,
                              version,
                              ownerPort,
                              ownerRuntime,
                            )) {
                              setState(() => _submitting = false);
                              if (sheetContext.mounted) refreshSheet(() {});
                            } else if (sheetContext.mounted &&
                                ModalRoute.of(sheetContext)?.isCurrent ==
                                    true) {
                              // An old worker's result must never mutate B's UI.
                              Navigator.pop(sheetContext);
                            }
                          }
                        },
                ),
                const SizedBox(height: 8),
                WrActionButton(
                  label: t('cancel'),
                  role: WrActionRole.secondary,
                  onPressed: _submitting
                      ? null
                      : () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (mounted &&
        _decisionOwnerCurrent(owner, version, ownerPort, ownerRuntime)) {
      _decisionSheetContext = null;
    }
    if (_decisionAuthorized(
          owner,
          version,
          ownerPort,
          ownerRuntime,
          selected,
        ) &&
        (_uncertain || _detailError != null)) {
      await _openOffer(selected.bookingId);
    }
  }

  Widget _status() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offline)
          WrEligibilityNotice(title: t('offline'), message: t('readOnly')),
        if (_freshness != null &&
            _freshness != ReadFreshness.fresh &&
            _fetchedAt != null)
          Text(
            t('cachedAt') + _fetchedAt!.toUtc().toIso8601String(),
            textDirection: TextDirection.ltr,
            style: WrType.support,
          ),
        if (_error != null)
          WrFeedbackPanel(
            kind: _today != null || _agenda != null || _offers != null
                ? WrFeedbackKind.refreshError
                : WrFeedbackKind.initialError,
            title: _error!,
            retryLabel: t('retry'),
            onRetry: _load,
          ),
        if (_message != null) Text(_message!),
      ],
    );
  }

  Widget _agendaCard(AgendaItemView item, RouteOrigin origin) {
    final time = item.startsAt == null
        ? t('unknownTime')
        : _damascusTime(item.startsAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WrSectionPanel(
        title: item.work.label,
        subtitle: item.work.area,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item.scheduledDate.isEmpty
                  ? t('unknownDate')
                  : item.scheduledDate,
              textDirection: TextDirection.ltr,
            ),
            Text(time, textDirection: TextDirection.ltr),
            if (item.taskIntervalLabel != null) Text(item.taskIntervalLabel!),
            WrStatusBadge(label: item.status),
            const SizedBox(height: 8),
            WrActionButton(
              label: t('view'),
              role: WrActionRole.secondary,
              onPressed:
                  _missionNavigationAllowed &&
                      _committed(item) &&
                      item.operational.permits(WorkerAction.view)
                  ? () => _openMission(item, origin)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  String _damascusTime(DateTime utc) {
    // Current deployment calendar offset. API owns original instants and
    // business dates, so no local visit date/duration is derived from this.
    final t = utc.toUtc().add(const Duration(hours: 3));
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _todayBody() {
    final today = _today;
    if (today == null) {
      return WrFeedbackPanel(
        kind: _loading ? WrFeedbackKind.loading : WrFeedbackKind.unavailable,
        title: _loading ? t('loading') : t('noSummary'),
        retryLabel: _loading ? null : t('retry'),
        onRetry: _loading ? null : _load,
      );
    }
    final next = today.agenda.nextVisit;
    final assigned = today.agenda.items.items.where(_committed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WrSectionPanel(
          title: t('active'),
          child: Text(today.agenda.activeVisits.toString()),
        ),
        const SizedBox(height: 12),
        if (next != null && _committed(next)) ...[
          Text(t('nextVisit'), style: WrType.section),
          _agendaCard(next, RouteOrigin.today),
        ],
        WrSectionPanel(
          title: t('assigned'),
          child: assigned.isEmpty
              ? Text(t('noAssigned'))
              : Column(
                  children: [
                    for (final item in assigned)
                      _agendaCard(item, RouteOrigin.today),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        WrActionButton(
          label: t('offers'),
          role: WrActionRole.secondary,
          onPressed: () {
            _offersTab = true;
            _navigate(WorkerDestination.jobs);
          },
        ),
        const SizedBox(height: 8),
        WrActionButton(
          label: t('schedule'),
          role: WrActionRole.secondary,
          onPressed: () => _navigate(WorkerDestination.schedule),
        ),
      ],
    );
  }

  Widget _offerCard(OfferView item) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: WrSectionPanel(
      title: item.work.label,
      subtitle: item.work.area,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(item.work.type),
          Text(t('unknownTime')),
          WrStatusBadge(label: t('notAssigned'), tone: WrStatusTone.warning),
          if (item.workerAmount != null)
            WrAmountText(
              amount: item.workerAmount,
              unavailableLabel: t('priceUnavailable'),
            ),
          const SizedBox(height: 8),
          WrActionButton(
            label: t('view'),
            role: WrActionRole.secondary,
            onPressed: () => _openOffer(item.bookingId),
          ),
        ],
      ),
    ),
  );

  Widget _offerDetails() {
    if (_detailLoading) {
      return WrFeedbackPanel(kind: WrFeedbackKind.loading, title: t('loading'));
    }
    if (_offer == null) {
      return WrFeedbackPanel(
        kind: WrFeedbackKind.unavailable,
        title: _detailError ?? t('unavailable'),
        retryLabel: t('retry'),
        onRetry: () {
          final id = _requestedOfferId;
          if (id != null) _openOffer(id);
        },
      );
    }
    final offer = _offer!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WrSectionPanel(
          title: offer.work.label,
          subtitle: offer.work.area ?? offer.work.locationSummary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(offer.work.type),
              Text(offer.bookingType),
              Text(t('unknownTime')),
              WrAmountText(
                amount: offer.workerAmount,
                unavailableLabel: t('priceUnavailable'),
              ),
              Text(
                offer.pricingIsFinal ? t('finalPrice') : t('provisionalPrice'),
              ),
              if (offer.visitChoices.isNotEmpty)
                for (final visit in offer.visitChoices)
                  WrListRow(title: visit.sessionId ?? t('unknownTime')),
            ],
          ),
        ),
        if (_detailError != null)
          WrEligibilityNotice(title: t('error'), message: _detailError!),
        for (final mode in OfferDecisionKind.values)
          if (_permits(offer, mode))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: WrActionButton(
                label: switch (mode) {
                  OfferDecisionKind.decline => t('decline'),
                  OfferDecisionKind.acceptLegacy => t('acceptLegacy'),
                  OfferDecisionKind.acceptAll => t('acceptAll'),
                  OfferDecisionKind.acceptSelected => t('acceptSelected'),
                },
                role: mode == OfferDecisionKind.decline
                    ? WrActionRole.destructive
                    : WrActionRole.primary,
                onPressed:
                    _offline || _uncertain || !offer.eligible || _submitting
                    ? null
                    : () => _decisionSheet(mode),
                disabledExplanation: _offline
                    ? t('offline')
                    : t('notPermitted'),
              ),
            ),
        const SizedBox(height: 12),
        WrActionButton(
          label: t('refresh'),
          role: WrActionRole.secondary,
          onPressed: () => _openOffer(offer.bookingId),
        ),
        WrActionButton(
          label: t('cancel'),
          role: WrActionRole.secondary,
          onPressed: () => setState(() {
            _offer = null;
            _requestedOfferId = null;
          }),
        ),
      ],
    );
  }

  Widget _jobsBody() {
    if (_requestedOfferId != null || _detailLoading) return _offerDetails();
    final page = _offersTab ? _offers : _bookings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(t('offers'))),
            ButtonSegment(value: false, label: Text(t('assigned'))),
          ],
          selected: {_offersTab},
          onSelectionChanged: (selection) {
            setState(() => _offersTab = selection.first);
            _load();
          },
        ),
        const SizedBox(height: 16),
        if (_loading && page == null)
          WrFeedbackPanel(kind: WrFeedbackKind.loading, title: t('loading'))
        else if (_offersTab) ...[
          if (_offers?.items.isEmpty ?? true)
            WrFeedbackPanel(kind: WrFeedbackKind.empty, title: t('noOffers')),
          for (final item in _offers?.items ?? <OfferView>[]) _offerCard(item),
          if (_offers != null && _offers!.page < _offers!.lastPage)
            WrActionButton(
              label: t('more'),
              onPressed: () {
                _offerPage++;
                _load();
              },
            ),
          if (_offers != null) Text('${_offers!.total} ${t('offers')}'),
        ] else ...[
          if (_bookings?.items.isEmpty ?? true)
            WrFeedbackPanel(kind: WrFeedbackKind.empty, title: t('noAssigned')),
          for (final item in (_bookings?.items ?? <JobSummaryView>[]).where(
            (job) => _committedStatuses.contains(job.ownAssignmentStatus),
          ))
            WrSectionPanel(
              title: item.work.label,
              subtitle: item.reference,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WrStatusBadge(label: item.ownAssignmentStatus),
                  if (item.visitCount != null)
                    Text('${item.visitCount} ${t('assigned')}'),
                  WrActionButton(
                    label: t('schedule'),
                    role: WrActionRole.secondary,
                    onPressed: () => _navigate(WorkerDestination.schedule),
                  ),
                ],
              ),
            ),
          if (_bookings != null && _bookings!.page < _bookings!.lastPage)
            WrActionButton(
              label: t('more'),
              onPressed: () {
                _bookingPage++;
                _load();
              },
            ),
        ],
      ],
    );
  }

  Widget _scheduleBody() {
    final week = _week;
    final monday = _parse(week.from);
    final items = (_agenda?.items.items ?? <AgendaItemView>[])
        .where(_committed)
        .toList();
    final dated = items
        .where((item) => item.scheduledDate == _date && item.startsAt != null)
        .toList();
    final unknown = items
        .where(
          (item) =>
              item.scheduledDate.isEmpty ||
              (item.scheduledDate == _date && item.startsAt == null),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: WrIconAction(
                icon: Icons.chevron_left,
                label: t('weekPrevious'),
                onPressed: () => _shiftWeek(-7),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                '${week.from} — ${week.to}',
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: WrIconAction(
                icon: Icons.chevron_right,
                label: t('weekNext'),
                onPressed: () => _shiftWeek(7),
              ),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: ChoiceChip(
                    selected: _date == _iso(monday.add(Duration(days: i))),
                    label: Text(
                      '${t('week${i + 1}')}\n${monday.add(Duration(days: i)).day}',
                    ),
                    onSelected: (_) => setState(
                      () => _date = _iso(monday.add(Duration(days: i))),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading && _agenda == null)
          WrFeedbackPanel(kind: WrFeedbackKind.loading, title: t('loading'))
        else if (dated.isEmpty)
          WrFeedbackPanel(kind: WrFeedbackKind.empty, title: t('noVisits'))
        else
          for (final item in dated) _agendaCard(item, RouteOrigin.schedule),
        if (unknown.isNotEmpty) ...[
          Text(t('noDate'), style: WrType.section),
          for (final item in unknown) _agendaCard(item, RouteOrigin.schedule),
        ],
        if (_agenda != null) ...[
          Text('${t('assigned')} ${_agenda!.items.total}'),
          if (_agendaPage > 1)
            WrActionButton(
              label: t('weekPrevious'),
              role: WrActionRole.secondary,
              onPressed: () {
                _agendaPage--;
                _load();
              },
            ),
          if (_agenda!.items.page < _agenda!.items.lastPage)
            WrActionButton(
              label: t('more'),
              onPressed: () {
                _agendaPage++;
                _load();
              },
            ),
        ],
      ],
    );
  }

  void _shiftWeek(int days) {
    _date = _iso(_parse(_date).add(Duration(days: days)));
    _agendaPage = 1;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.locale.languageCode != 'en';
    final verified = _identityValid(_currentIdentity);
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: WrPageFrame(
        title: t(
          _page == WorkerDestination.today
              ? 'today'
              : _page == WorkerDestination.jobs
              ? 'jobs'
              : 'schedule',
        ),
        headerAction: WrIconAction(
          icon: Icons.refresh,
          label: t('refresh'),
          onPressed: _loading ? null : _load,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!verified)
              WrFeedbackPanel(
                kind: WrFeedbackKind.unavailable,
                title: t('unavailable'),
                retryLabel: t('retry'),
                onRetry: _load,
              )
            else ...[
              _status(),
              if (_page == WorkerDestination.today) _todayBody(),
              if (_page == WorkerDestination.jobs) _jobsBody(),
              if (_page == WorkerDestination.schedule) _scheduleBody(),
            ],
          ],
        ),
      ),
    );
  }
}
