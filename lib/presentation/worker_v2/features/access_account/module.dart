/// S04 public entry: all dependencies come from the frozen V2 ports.
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

typedef StartLocationSelector = Future<StartLocationDraft?> Function();

class AccessAccountModule extends StatefulWidget {
  const AccessAccountModule({
    super.key,
    required this.port,
    required this.runtime,
    required this.onNavigate,
    this.initialPage,
    this.initialLocale = const Locale('ar'),
    this.authorizedAreaIds,
    this.selectStartLocation,
    this.legalContent = const {},
    this.onLanguageChanged,
  });

  final wr.AccessAccountPort port;
  final wr.WorkerRuntimePort runtime;
  final ValueChanged<RouteIntent> onNavigate;
  final WorkerDestination? initialPage;
  final Locale initialLocale;

  /// Only an authoritative catalogue provided by S00 can enable area editing.
  final List<String>? authorizedAreaIds;

  /// S00 owns OS permission, maps and picker implementation.
  final StartLocationSelector? selectStartLocation;

  /// Last available legal content, never synthesized by this module.
  final Map<WorkerDestination, String> legalContent;
  final ValueChanged<Locale>? onLanguageChanged;

  @override
  State<AccessAccountModule> createState() => _AccessAccountModuleState();
}

class _AccessAccountModuleState extends State<AccessAccountModule> {
  late WorkerDestination _page;
  late Locale _locale;
  WorkerSessionContext? _session;
  StreamSubscription<DomainInvalidation>? _invalidations;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, List<String>> _fieldErrors = const {};
  String? _notice;
  ReadinessView? _readiness;
  WorkerProfileView? _profile;
  bool _profileFresh = false;
  List<String>? _areas;
  List<WorkingHoursSlot>? _hours;
  StartLocationDraft? _location;
  StartLocationDraft? _proposedLocation;
  Page<String>? _reviews;
  int _reviewsPage = 1;
  Set<String> _selectedAreas = {};
  Map<String, String?> _editValues = {};
  List<WorkingHoursSlot> _draftHours = [];
  final Map<String, TextEditingController> _profileControllers = {};
  final List<(TextEditingController, TextEditingController)> _hourControllers =
      [];
  final _phone = TextEditingController();
  final _password = TextEditingController();
  int _identityEpoch = 0;
  int _readEpoch = 0;
  bool _outcomeUnknown = false;
  WorkerDestination? _recoveryPage;

  bool get _offline => widget.runtime.connection != wr.ConnectionState.online;
  bool _runtimeOwns(WorkerSessionContext? identity) {
    final live = widget.runtime.context;
    return identity != null &&
        widget.runtime.phase == wr.RuntimePhase.signedIn &&
        live != null &&
        _sameIdentity(identity, live);
  }

  bool get _authenticated => _session != null && _runtimeOwns(_session);
  String t(String key) =>
      (_locale.languageCode == 'en' ? accessEn : accessAr)[key] ?? key;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale.languageCode == 'en'
        ? const Locale('en')
        : const Locale('ar');
    _page = widget.initialPage ?? WorkerDestination.login;
    _listenForInvalidations();
    final active = widget.runtime.context;
    if (active != null && widget.runtime.phase == wr.RuntimePhase.signedIn) {
      _session = active;
      _page = widget.initialPage ?? WorkerDestination.readiness;
      _load();
    } else {
      _restore();
    }
  }

  void _listenForInvalidations() {
    _invalidations = widget.runtime.invalidations.listen((event) {
      final active = _authenticated ? _session : null;
      if (active == null ||
          event.generation != active.generation ||
          event.topic != InvalidationTopic.profile) {
        return;
      }
      if (mounted && !_busy) _load();
    });
  }

  @override
  void didUpdateWidget(covariant AccessAccountModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.runtime, widget.runtime)) {
      unawaited(_invalidations?.cancel());
      _listenForInvalidations();
    }
    if (!identical(oldWidget.runtime, widget.runtime) ||
        !identical(oldWidget.port, widget.port) ||
        (_session != null && !_authenticated)) {
      _clearPrivateState();
      _page = WorkerDestination.login;
      unawaited(_restore());
    }
  }

  @override
  void dispose() {
    _invalidations?.cancel();
    for (final controller in _profileControllers.values) {
      controller.dispose();
    }
    _disposeHourControllers();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setError(PortFailure failure) {
    _fieldErrors = failure.fieldErrors;
    _error =
        failure.safeMessage ??
        (failure.kind == FailureKind.unauthenticated
            ? t('invalidLogin')
            : t('error'));
  }

  void _setProfileDraft(WorkerProfileView view) {
    for (final controller in _profileControllers.values) {
      controller.dispose();
    }
    _profileControllers.clear();
    _editValues = Map.of(view.editableValues);
    for (final field in _editValues.entries) {
      _profileControllers[field.key] = TextEditingController(
        text: field.value ?? '',
      );
    }
  }

  void _clearProfileScope() {
    _profile = null;
    _profileFresh = false;
    _editValues = {};
    final staleControllers = _profileControllers.values.toList();
    _profileControllers.clear();
    for (final controller in staleControllers) {
      controller.clear();
    }
    // Old editable fields can still be mounted until the current frame exits.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in staleControllers) {
        controller.dispose();
      }
    });
  }

  void _disposeHourControllers() {
    for (final pair in _hourControllers) {
      pair.$1.dispose();
      pair.$2.dispose();
    }
    _hourControllers.clear();
  }

  void _setHourDraft(List<WorkingHoursSlot> slots) {
    _disposeHourControllers();
    _draftHours = List.of(slots);
    for (final slot in slots) {
      _hourControllers.add((
        TextEditingController(text: slot.startLocalTime),
        TextEditingController(text: slot.endLocalTime),
      ));
    }
  }

  bool _sameIdentity(WorkerSessionContext a, WorkerSessionContext b) =>
      a.userId == b.userId &&
      a.workerId == b.workerId &&
      a.generation == b.generation;

  void _clearPrivateState() {
    _identityEpoch++;
    _readEpoch++;
    _session = null;
    _profile = null;
    _profileFresh = false;
    _readiness = null;
    _areas = null;
    _hours = null;
    _location = null;
    _proposedLocation = null;
    _reviews = null;
    _selectedAreas = {};
    _editValues = {};
    _draftHours = [];
    _notice = null;
    _error = null;
    _fieldErrors = const {};
    _outcomeUnknown = false;
    _recoveryPage = null;
    _busy = false;
    _loading = false;
    for (final controller in _profileControllers.values) {
      controller.clear();
    }
    for (final pair in _hourControllers) {
      pair.$1.clear();
      pair.$2.clear();
    }
  }

  Future<void> _restore() async {
    final epoch = _identityEpoch;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.port.restoreSession();
      if (!mounted || epoch != _identityEpoch) return;
      if (result is ReadSuccess<WorkerSessionContext?>) {
        final next = result.value;
        if (next != null && !_runtimeOwns(next)) {
          setState(() {
            _clearPrivateState();
            _page = WorkerDestination.login;
          });
          return;
        }
        _session = next;
        _page = next == null
            ? WorkerDestination.login
            : (widget.initialPage ?? WorkerDestination.readiness);
        if (next != null) {
          await _load();
          return;
        }
      } else if (result is ReadFailure<WorkerSessionContext?>) {
        _setError(result.failure);
        _page = WorkerDestination.login;
      }
    } catch (_) {
      if (mounted && epoch == _identityEpoch) _error = t('error');
    } finally {
      if (mounted && epoch == _identityEpoch) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _read<T>(
    Future<ReadResult<T>> request,
    void Function(T) accept,
  ) async {
    final epoch = _identityEpoch;
    final read = ++_readEpoch;
    final sourceSession = _session;
    if (!_runtimeOwns(sourceSession)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await request;
      if (!mounted || epoch != _identityEpoch || read != _readEpoch) return;
      if (!_authenticated || !_sameIdentity(sourceSession!, _session!)) {
        setState(() {
          _clearPrivateState();
          _page = WorkerDestination.login;
        });
        return;
      }
      if (result is ReadSuccess<T>) {
        accept(result.value);
        if (_page == WorkerDestination.account ||
            _page == WorkerDestination.profileEdit) {
          _profileFresh =
              _error == null &&
              result.freshness == ReadFreshness.fresh &&
              _profile?.workerId == _session?.workerId;
        }
        if (result.freshness != ReadFreshness.fresh) _notice = t('offline');
        if (_error == null &&
            result.freshness == ReadFreshness.fresh &&
            _recoveryPage == _page) {
          _outcomeUnknown = false;
          _recoveryPage = null;
        }
      } else if (result is ReadFailure<T>) {
        _setError(result.failure);
        if (result.failure.kind == FailureKind.unauthenticated ||
            result.failure.kind == FailureKind.forbidden ||
            result.failure.kind == FailureKind.notFound) {
          // The user may still be signed in while this private resource is
          // revoked. Denial removes its content and writable draft, never
          // preserves a previously verified profile for retry or mutation.
          _clearProfileScope();
          _readiness = null;
          _areas = null;
          _hours = null;
          _location = null;
          _proposedLocation = null;
          _reviews = null;
        }
      }
    } catch (_) {
      if (mounted && epoch == _identityEpoch) _error = t('error');
    } finally {
      if (mounted && epoch == _identityEpoch && read == _readEpoch) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _load() async {
    if (_session != null && !_authenticated) {
      setState(() {
        _clearPrivateState();
        _page = WorkerDestination.login;
      });
      return;
    }
    if (!_authenticated &&
        _page != WorkerDestination.login &&
        _page != WorkerDestination.privacy &&
        _page != WorkerDestination.terms &&
        _page != WorkerDestination.language) {
      setState(() {
        _page = WorkerDestination.login;
        _loading = false;
      });
      return;
    }
    switch (_page) {
      case WorkerDestination.readiness:
        await _read(
          widget.port.fetchReadiness(),
          (ReadinessView v) => _readiness = v,
        );
        return;
      case WorkerDestination.account:
      case WorkerDestination.profileEdit:
        _profileFresh = false;
        await _read(widget.port.fetchProfile(), (WorkerProfileView v) {
          if (v.workerId != _session!.workerId) {
            _error = t('unavailable');
            _clearProfileScope();
            return;
          }
          _profile = v;
          _setProfileDraft(v);
        });
        return;
      case WorkerDestination.workAreas:
        await _read(widget.port.fetchWorkAreas(), (List<String> ids) {
          _areas = ids;
          _selectedAreas = ids.toSet();
        });
        return;
      case WorkerDestination.workingHours:
        await _read(widget.port.fetchWorkingHours(), (
          List<WorkingHoursSlot> items,
        ) {
          _hours = items;
          _setHourDraft(items);
        });
        return;
      case WorkerDestination.startLocation:
        await _read(widget.port.fetchStartLocation(), (StartLocationDraft? v) {
          _location = v;
          _proposedLocation = null;
        });
        return;
      case WorkerDestination.reviews:
        await _read(
          widget.port.fetchReviews(PageQuery(page: _reviewsPage)),
          (Page<String> page) => _reviews = page,
        );
        return;
      default:
        if (mounted) setState(() => _loading = false);
        return;
    }
  }

  void _open(WorkerDestination destination) {
    if (_busy) return;
    if (!_authenticated &&
        destination != WorkerDestination.login &&
        destination != WorkerDestination.privacy &&
        destination != WorkerDestination.terms &&
        destination != WorkerDestination.language) {
      return;
    }
    if (destination == WorkerDestination.support ||
        destination == WorkerDestination.earnings) {
      widget.onNavigate(
        RouteIntent(destination: destination, origin: RouteOrigin.profile),
      );
      return;
    }
    setState(() {
      _page = destination;
      _error = null;
      _notice = null;
    });
    _load();
  }

  Future<void> _login() async {
    if (_busy ||
        _offline ||
        _phone.text.trim().isEmpty ||
        _password.text.isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final epoch = _identityEpoch;
    try {
      final result = await widget.port.signIn(
        phone: _phone.text.trim(),
        password: _password.text,
      );
      if (!mounted || epoch != _identityEpoch) return;
      if (result is ReadSuccess<WorkerSessionContext>) {
        if (!_runtimeOwns(result.value)) return;
        _session = result.value;
        _password.clear();
        _page = WorkerDestination.readiness;
      } else if (result is ReadFailure<WorkerSessionContext>) {
        _setError(result.failure);
      }
    } catch (_) {
      if (mounted) _error = t('error');
    } finally {
      if (mounted && epoch == _identityEpoch) setState(() => _busy = false);
    }
    if (mounted && _page == WorkerDestination.readiness) await _load();
  }

  Future<bool> _command(
    Future<CommandResult> Function() call, {
    required VoidCallback onSuccess,
    bool signOut = false,
  }) async {
    if (_busy || _offline || !_authenticated || _outcomeUnknown) return false;
    final issuing = _session!;
    final epoch = _identityEpoch;
    final currentPort = widget.port;
    final currentRuntime = widget.runtime;
    var confirmed = false;
    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const {};
    });
    try {
      final result = await call();
      if (!mounted ||
          epoch != _identityEpoch ||
          !identical(currentPort, widget.port) ||
          !identical(currentRuntime, widget.runtime) ||
          !_sameIdentity(issuing, _session!)) {
        return false;
      }
      if (!_authenticated) {
        if (signOut &&
            result.status == CommandStatus.confirmed &&
            widget.runtime.context == null &&
            widget.runtime.phase != wr.RuntimePhase.signedIn) {
          // The real sign-out port can revoke A before acknowledging success.
          // A is already gone; clear local A without purging another runtime.
          setState(() {
            _clearPrivateState();
            _page = WorkerDestination.login;
            _password.clear();
            _phone.clear();
          });
          return true;
        }
        return false;
      }
      if (result.status == CommandStatus.confirmed) {
        onSuccess();
        _notice = t('saved');
        confirmed = true;
      } else if (result.status == CommandStatus.outcomeUnknown) {
        _outcomeUnknown = true;
        _recoveryPage = signOut ? null : _page;
        _error = t('unavailable');
      } else {
        _error = result.reasonCode ?? t('error');
        _fieldErrors = result.fieldErrors;
      }
    } catch (_) {
      if (mounted &&
          epoch == _identityEpoch &&
          identical(currentPort, widget.port) &&
          identical(currentRuntime, widget.runtime) &&
          _authenticated &&
          _sameIdentity(issuing, _session!)) {
        _outcomeUnknown = true;
        _recoveryPage = signOut ? null : _page;
        _error = t('unavailable');
      }
    } finally {
      if (mounted && epoch == _identityEpoch) {
        setState(() => _busy = false);
      }
    }
    return confirmed;
  }

  Future<void> _signOut() async {
    if (_busy || _offline || !_authenticated) return;
    final issuing = _session!;
    final issuingRuntime = widget.runtime;
    final completed = await _command(
      () => widget.port.signOut(),
      signOut: true,
      onSuccess: () {},
    );
    if (completed &&
        mounted &&
        identical(issuingRuntime, widget.runtime) &&
        _runtimeOwns(issuing)) {
      // The runtime method revokes the current identity synchronously before
      // awaiting storage teardown; never call it for a successor session.
      final purge = issuingRuntime.purgeSessionData();
      setState(() {
        _clearPrivateState();
        _page = WorkerDestination.login;
        _password.clear();
        _phone.clear();
      });
      await purge;
    }
  }

  Future<void> _recoverUnknown() async {
    if (_busy || !_outcomeUnknown || !_authenticated || _offline) return;
    if (_recoveryPage != null) {
      if (_page == _recoveryPage) await _load();
      return;
    }
    final original = _session!;
    final epoch = _identityEpoch;
    setState(() => _loading = true);
    try {
      final result = await widget.port.restoreSession();
      if (!mounted || epoch != _identityEpoch) return;
      if (result is ReadSuccess<WorkerSessionContext?> &&
          result.freshness == ReadFreshness.fresh &&
          result.value != null &&
          _runtimeOwns(original) &&
          _sameIdentity(result.value!, original)) {
        setState(() {
          _outcomeUnknown = false;
          _error = null;
        });
      } else if (result is ReadSuccess<WorkerSessionContext?> &&
          result.value == null &&
          widget.runtime.context == null) {
        setState(() {
          _clearPrivateState();
          _page = WorkerDestination.login;
        });
      }
    } catch (_) {
      if (mounted && epoch == _identityEpoch) {
        setState(() => _error = t('unavailable'));
      }
    } finally {
      if (mounted && epoch == _identityEpoch) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => WrConfirmDialog(
        title: t('signOut'),
        message: t('signOutQuestion'),
        confirmLabel: t('signOut'),
        cancelLabel: t('cancel'),
        destructive: true,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
    if (accepted == true && mounted) await _signOut();
  }

  Future<void> _saveProfile() async {
    final profile = _profile;
    if (profile == null ||
        !_authenticated ||
        _busy ||
        _offline ||
        !_profileFresh ||
        profile.workerId != _session?.workerId) {
      return;
    }
    final changes = <String, String?>{};
    for (final entry in _editValues.entries) {
      if (profile.editableValues.containsKey(entry.key) &&
          entry.value != profile.editableValues[entry.key]) {
        changes[entry.key] = entry.value;
      }
    }
    if (changes.isEmpty) {
      _open(WorkerDestination.account);
      return;
    }
    await _command(
      () => widget.port.saveProfile(ProfileDraft(changes)),
      onSuccess: () => _page = WorkerDestination.account,
    );
    if (_page == WorkerDestination.account) await _load();
  }

  Future<void> _backToAccount() async {
    if (_busy) return;
    final changed =
        _page == WorkerDestination.profileEdit &&
        _profile != null &&
        _editValues.entries.any(
          (entry) => _profile!.editableValues[entry.key] != entry.value,
        );
    if (changed) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => WrConfirmDialog(
          title: t('discard'),
          message: t('discardQuestion'),
          confirmLabel: t('discard'),
          cancelLabel: t('keepEditing'),
          destructive: true,
          onConfirm: () => Navigator.pop(ctx, true),
          onCancel: () => Navigator.pop(ctx, false),
        ),
      );
      if (discard != true || !mounted) return;
    }
    _open(WorkerDestination.account);
  }

  Future<void> _saveAreas() async {
    final ids = widget.authorizedAreaIds;
    if (ids == null || _areas == null) return;
    if (!_selectedAreas.every(ids.contains)) return;
    await _command(
      () => widget.port.saveWorkAreas(
        WorkAreaDraft(_selectedAreas.toList()..sort()),
      ),
      onSuccess: () {},
    );
    if (_error == null) await _load();
  }

  static bool _validTime(String v) {
    final match = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$').firstMatch(v);
    return match != null;
  }

  bool get _hoursAdvisory {
    for (final day in List.generate(7, (i) => i + 1)) {
      final slots = _draftHours.where((s) => s.day == day).toList();
      final ordered = [...slots]
        ..sort((a, b) => a.startLocalTime.compareTo(b.startLocalTime));
      for (var i = 0; i < slots.length; i++) {
        if (slots[i].startLocalTime.compareTo(slots[i].endLocalTime) >= 0) {
          return true;
        }
        if (i > 0 &&
            slots[i].startLocalTime.compareTo(slots[i - 1].startLocalTime) <
                0) {
          return true;
        }
      }
      for (var i = 1; i < ordered.length; i++) {
        if (ordered[i].startLocalTime.compareTo(ordered[i - 1].endLocalTime) <
            0) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveHours() async {
    if (_draftHours.any(
      (s) => !_validTime(s.startLocalTime) || !_validTime(s.endLocalTime),
    )) {
      setState(() => _error = t('badTime'));
      return;
    }
    await _command(
      () => widget.port.saveWorkingHours(WorkingHoursDraft(_draftHours)),
      onSuccess: () {},
    );
    if (_error == null) await _load();
  }

  Widget _banner() => Column(
    children: [
      if (_offline) ...[
        WrEligibilityNotice(title: t('offline'), message: t('unavailable')),
        const SizedBox(height: 12),
      ],
      if (_notice != null) ...[
        WrStatusBadge(label: _notice!, tone: WrStatusTone.info),
        const SizedBox(height: 12),
      ],
      if (_error != null) ...[
        WrFeedbackPanel(
          kind: WrFeedbackKind.refreshError,
          title: _error!,
          retryLabel: _authenticated ? t('retry') : null,
          onRetry: !_authenticated
              ? null
              : _outcomeUnknown
              ? _recoverUnknown
              : _load,
        ),
        const SizedBox(height: 12),
      ],
    ],
  );

  Widget _body() {
    if (!_authenticated &&
        _page != WorkerDestination.login &&
        _page != WorkerDestination.privacy &&
        _page != WorkerDestination.terms &&
        _page != WorkerDestination.language) {
      return WrFeedbackPanel(
        kind: WrFeedbackKind.unavailable,
        title: t('unavailable'),
        retryLabel: t('retry'),
        onRetry: _load,
      );
    }
    if (_loading) {
      return WrFeedbackPanel(kind: WrFeedbackKind.loading, title: t('loading'));
    }
    switch (_page) {
      case WorkerDestination.login:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WrPhoneField(
              label: t('phone'),
              controller: _phone,
              hint: '+963',
              enabled: !_busy,
            ),
            const SizedBox(height: 16),
            WrPasswordField(
              label: t('password'),
              revealLabel: t('showPassword'),
              hideLabel: t('hidePassword'),
              controller: _password,
              enabled: !_busy,
            ),
            const SizedBox(height: 18),
            WrActionButton(
              label: t('signIn'),
              onPressed: _offline ? null : _login,
              busy: _busy,
              busyLabel: t('loading'),
            ),
            const SizedBox(height: 16),
            WrListRow(
              title: t('terms'),
              onTap: () => _open(WorkerDestination.terms),
            ),
            WrListRow(
              title: t('privacy'),
              onTap: () => _open(WorkerDestination.privacy),
            ),
          ],
        );
      case WorkerDestination.readiness:
        final v = _readiness;
        if (v == null) {
          return WrFeedbackPanel(
            kind: WrFeedbackKind.unavailable,
            title: t('unavailable'),
            retryLabel: t('retry'),
            onRetry: _load,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WrSectionPanel(title: t('active'), child: Text(v.accountState)),
            const SizedBox(height: 12),
            WrEligibilityNotice(
              title: t('receive'),
              message: v.canReceiveRequests ? t('yes') : t('no'),
              tone: v.canReceiveRequests
                  ? WrStatusTone.success
                  : WrStatusTone.warning,
            ),
            for (final item in v.completenessItems)
              WrListRow(title: item, trailing: const Icon(Icons.info_outline)),
            for (final code in v.financialRestrictionCodes)
              WrEligibilityNotice(title: t('blocked'), message: code),
            WrListRow(
              title: t('workAreas'),
              onTap: () => _open(WorkerDestination.workAreas),
            ),
            WrListRow(
              title: t('hours'),
              onTap: () => _open(WorkerDestination.workingHours),
            ),
            WrListRow(
              title: t('location'),
              onTap: () => _open(WorkerDestination.startLocation),
            ),
            WrActionButton(
              label: t('account'),
              onPressed: () => _open(WorkerDestination.account),
            ),
          ],
        );
      case WorkerDestination.account:
        final v = _profile;
        if (v == null) {
          return WrFeedbackPanel(
            kind: WrFeedbackKind.unavailable,
            title: t('noProfile'),
            retryLabel: t('retry'),
            onRetry: _load,
          );
        }
        final phone = v.phone;
        final masked = phone == null || phone.length < 4
            ? t('notProvided')
            : '•••• ${phone.substring(phone.length - 4)}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WrSectionPanel(
              title: v.displayName,
              subtitle: masked,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  WrStatusBadge(label: v.accountState),
                  if (v.reviewAverage != null)
                    WrStatusBadge(
                      label: '${t('reviewRating')}: ${v.reviewAverage!}',
                    ),
                ],
              ),
            ),
            for (final dest in [
              WorkerDestination.profileEdit,
              WorkerDestination.workAreas,
              WorkerDestination.workingHours,
              WorkerDestination.startLocation,
              WorkerDestination.reviews,
              WorkerDestination.language,
              WorkerDestination.privacy,
              WorkerDestination.terms,
              WorkerDestination.support,
              WorkerDestination.earnings,
            ])
              WrListRow(
                title: _title(dest),
                onTap: () => _open(dest),
                trailing: const Icon(Icons.chevron_right),
              ),
            const SizedBox(height: 16),
            WrActionButton(
              label: t('signOut'),
              role: WrActionRole.destructive,
              onPressed: _offline ? null : _confirmSignOut,
              busy: _busy,
              busyLabel: t('loading'),
            ),
          ],
        );
      case WorkerDestination.profileEdit:
        if (_profile == null) return Text(t('noProfile'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WrSectionPanel(title: t('phone'), child: Text(t('readOnlyPhone'))),
            for (final field in _editValues.keys)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: WrField(
                  key: ValueKey('profile_$field'),
                  label: field,
                  enabled: !_busy && !_offline && _profileFresh,
                  // Keyed draft field keeps server values while editing.
                  controller: _profileControllers[field],
                  onChanged: (value) => _editValues[field] = value,
                  errorText: _fieldErrors[field]?.join(', '),
                ),
              ),
            WrActionButton(
              label: t('save'),
              onPressed: _offline || !_profileFresh ? null : _saveProfile,
              busy: _busy,
              busyLabel: t('saving'),
            ),
          ],
        );
      case WorkerDestination.workAreas:
        final current = _areas;
        if (current == null) return Text(t('noAreas'));
        final catalog = widget.authorizedAreaIds;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (catalog == null)
              WrEligibilityNotice(
                title: t('unavailable'),
                message: t('catalogMissing'),
              ),
            WrSectionPanel(
              title: t('selected'),
              child: Text(_selectedAreas.length.toString()),
            ),
            if (catalog == null)
              for (final id in current)
                WrListRow(title: id, trailing: const Icon(Icons.check))
            else
              for (final id in catalog)
                CheckboxListTile(
                  title: Text(id),
                  value: _selectedAreas.contains(id),
                  onChanged: _busy || _offline
                      ? null
                      : (value) => setState(() {
                          if (value == true) {
                            _selectedAreas.add(id);
                          } else {
                            _selectedAreas.remove(id);
                          }
                        }),
                ),
            WrActionButton(
              label: t('save'),
              onPressed: _offline || catalog == null ? null : _saveAreas,
              busy: _busy,
              busyLabel: t('saving'),
            ),
          ],
        );
      case WorkerDestination.workingHours:
        if (_hours == null) return Text(t('unavailable'));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('hoursHint')),
            if (_hoursAdvisory)
              WrEligibilityNotice(
                title: t('hoursWarning'),
                message: t('hoursHint'),
              ),
            for (var day = 1; day <= 7; day++) _dayEditor(day),
            WrActionButton(
              label: t('save'),
              onPressed: _offline ? null : _saveHours,
              busy: _busy,
              busyLabel: t('saving'),
            ),
          ],
        );
      case WorkerDestination.startLocation:
        final value = _location;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WrSectionPanel(
              title: t('location'),
              child: Text(
                value?.savedLocationId ??
                    (value?.latitude != null && value?.longitude != null
                        ? '${value!.latitude}, ${value.longitude}'
                        : t('noLocation')),
              ),
            ),
            if (value?.source == 'pending')
              WrStatusBadge(label: t('pending'), tone: WrStatusTone.warning),
            if (value?.source == 'rejected')
              WrStatusBadge(label: t('blocked'), tone: WrStatusTone.danger),
            Text(t('startHint')),
            if (widget.selectStartLocation == null)
              WrEligibilityNotice(
                title: t('startUnavailable'),
                message: t('unavailable'),
              ),
            WrActionButton(
              label: t('chooseLocation'),
              onPressed: _offline || _busy || widget.selectStartLocation == null
                  ? null
                  : () async {
                      final epoch = _identityEpoch;
                      final worker = _session;
                      final runtime = widget.runtime;
                      final selector = widget.selectStartLocation!;
                      if (!_authenticated || worker == null) return;
                      final selection = await selector();
                      if (!mounted ||
                          selection == null ||
                          epoch != _identityEpoch ||
                          !identical(widget.runtime, runtime) ||
                          !identical(widget.selectStartLocation, selector) ||
                          !_authenticated ||
                          !_runtimeOwns(worker) ||
                          !_sameIdentity(worker, _session!) ||
                          _page != WorkerDestination.startLocation) {
                        return;
                      }
                      if (selection.savedLocationId == null &&
                          (selection.latitude == null ||
                              selection.longitude == null)) {
                        return;
                      }
                      setState(() => _proposedLocation = selection);
                    },
            ),
            if (_proposedLocation != null) ...[
              Text(_proposedLocation!.savedLocationId ?? t('pending')),
              WrActionButton(
                label: t('saveLocation'),
                onPressed: _offline
                    ? null
                    : () async {
                        await _command(
                          () =>
                              widget.port.saveStartLocation(_proposedLocation!),
                          onSuccess: () {},
                        );
                        if (_error == null) await _load();
                      },
                busy: _busy,
                busyLabel: t('saving'),
              ),
            ],
          ],
        );
      case WorkerDestination.reviews:
        final page = _reviews;
        if (page == null) return Text(t('unavailable'));
        if (page.items.isEmpty) {
          return WrFeedbackPanel(
            kind: WrFeedbackKind.empty,
            title: t('noReviews'),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final review in page.items)
              WrSectionPanel(child: Text(review)),
            Text('${t('page')} ${page.page} / ${page.lastPage}'),
            if (page.page < page.lastPage)
              WrActionButton(
                label: t('more'),
                onPressed: () {
                  _reviewsPage = page.page + 1;
                  _load();
                },
              ),
          ],
        );
      case WorkerDestination.language:
        return RadioGroup<String>(
          groupValue: _locale.languageCode,
          onChanged: (value) {
            if (value == null) return;
            final next = Locale(value);
            setState(() => _locale = next);
            widget.onLanguageChanged?.call(next);
          },
          child: Column(
            children: [
              for (final code in ['ar', 'en'])
                RadioListTile<String>(
                  title: Text(code == 'ar' ? t('arabic') : t('english')),
                  value: code,
                ),
            ],
          ),
        );
      case WorkerDestination.terms:
      case WorkerDestination.privacy:
        final text = widget.legalContent[_page];
        return text == null || text.isEmpty
            ? WrFeedbackPanel(
                kind: WrFeedbackKind.unavailable,
                title: t('unavailable'),
              )
            : SelectableText(text);
      default:
        return WrFeedbackPanel(
          kind: WrFeedbackKind.unavailable,
          title: t('unavailable'),
        );
    }
  }

  Widget _dayEditor(int day) {
    final slots = <(int, WorkingHoursSlot)>[];
    for (var i = 0; i < _draftHours.length; i++) {
      if (_draftHours[i].day == day) slots.add((i, _draftHours[i]));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WrSectionPanel(
        title: t('weekday$day'),
        child: Column(
          children: [
            for (final (index, _) in slots)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    WrTimeField(
                      key: ValueKey('start_${day}_$index'),
                      label: t('begin'),
                      enabled: !_offline,
                      controller: _hourControllers[index].$1,
                      onChanged: (value) => setState(
                        () => _draftHours[index] = WorkingHoursSlot(
                          day: day,
                          startLocalTime: value,
                          endLocalTime: _draftHours[index].endLocalTime,
                        ),
                      ),
                    ),
                    WrTimeField(
                      key: ValueKey('end_${day}_$index'),
                      label: t('end'),
                      enabled: !_offline,
                      controller: _hourControllers[index].$2,
                      onChanged: (value) => setState(
                        () => _draftHours[index] = WorkingHoursSlot(
                          day: day,
                          startLocalTime: _draftHours[index].startLocalTime,
                          endLocalTime: value,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _offline
                          ? null
                          : () => setState(() {
                              _draftHours.removeAt(index);
                              final removed = _hourControllers.removeAt(index);
                              // Controllers are disposed after the old TextFields unmount.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                removed.$1.dispose();
                                removed.$2.dispose();
                              });
                            }),
                      icon: const Icon(Icons.remove_circle_outline),
                      label: Text(t('remove')),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: _offline
                  ? null
                  : () => setState(() {
                      _draftHours.add(
                        WorkingHoursSlot(
                          day: day,
                          startLocalTime: '',
                          endLocalTime: '',
                        ),
                      );
                      _hourControllers.add((
                        TextEditingController(),
                        TextEditingController(),
                      ));
                    }),
              icon: const Icon(Icons.add),
              label: Text(t('addRange')),
            ),
          ],
        ),
      ),
    );
  }

  String _title(WorkerDestination destination) => switch (destination) {
    WorkerDestination.login => t('signIn'),
    WorkerDestination.readiness => t('readiness'),
    WorkerDestination.account => t('account'),
    WorkerDestination.profileEdit => t('editProfile'),
    WorkerDestination.workAreas => t('workAreas'),
    WorkerDestination.workingHours => t('hours'),
    WorkerDestination.startLocation => t('location'),
    WorkerDestination.reviews => t('reviews'),
    WorkerDestination.language => t('language'),
    WorkerDestination.privacy => t('privacy'),
    WorkerDestination.terms => t('terms'),
    WorkerDestination.support => t('support'),
    WorkerDestination.earnings => t('earnings'),
    _ => t('account'),
  };

  @override
  Widget build(BuildContext context) {
    final privateStateInvalid = _session != null && !_authenticated;
    return Directionality(
      textDirection: _locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: WrPageFrame(
        title: _title(_page),
        subtitle: _page == WorkerDestination.login ? t('loginHelp') : null,
        headerAction:
            _page == WorkerDestination.login ||
                _page == WorkerDestination.readiness
            ? null
            : WrIconAction(
                icon: Icons.arrow_back,
                label: t('account'),
                onPressed: _backToAccount,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (!privateStateInvalid) _banner(), _body()],
        ),
      ),
    );
  }
}
