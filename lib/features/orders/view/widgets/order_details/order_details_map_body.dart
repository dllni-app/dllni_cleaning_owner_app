import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/start_work_use_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../helpers/order_address_visibility_helper.dart';
import '../../helpers/order_lifecycle_policy.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../order_details_map_app_bar.dart';
import '../../helpers/cleaning_security_code_display.dart';

bool _securityCodeInFlightForBooking(OrdersBloc bloc, int bookingId) {
  return bloc.state.securityCodeStatus == BlocStatus.loading &&
      bloc.state.securityCode?.data == null;
}

class OrderDetailsMapBody extends StatefulWidget {
  const OrderDetailsMapBody({
    super.key,
    required this.order,
    required this.bloc,
    required this.index,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;
  final int index;

  @override
  State<OrderDetailsMapBody> createState() => _OrderDetailsMapBodyState();
}

class _OrderDetailsMapBodyState extends State<OrderDetailsMapBody> {
  static const double _mapInitialZoom = 13;
  /// Matches [DraggableScrollableSheet.initialChildSize] so the worker pin
  /// sits in the visible map area above the sheet.
  static const double _bottomSheetInitialFraction = 0.36;

  final Dio _dio = Dio();
  final MapController _mapController = MapController();

  List<LatLng> _road = <LatLng>[];
  LatLng? _myLocation;
  StreamSubscription<Position>? _positionSub;
  bool _requestedSecurityCode = false;
  bool _suppressLocationReporting = false;
  bool _isVerificationDialogOpen = false;
  bool _autoVerificationDialogShown = false;
  BuildContext? _verificationDialogContext;

  bool get _isAwaitingVerification =>
      OrderLifecyclePolicy.isAwaitingStartVerification(widget.order);

  bool get _isAwaitingWorkerStartConfirmation =>
      OrderLifecyclePolicy.isAwaitingWorkerStartConfirmation(widget.order);

  bool _isAwaitingVerificationAfterArrive(OrdersState state) {
    if (_isAwaitingWorkerStartConfirmation) return false;

    if (state.arriveStatus == BlocStatus.loading) {
      return _isAwaitingVerification || _suppressLocationReporting;
    }

    final arrive = state.arrive?.data;
    if (state.arriveStatus != BlocStatus.success || arrive == null) {
      return _suppressLocationReporting && _isAwaitingVerification;
    }
    if (arrive.id != widget.order.id) return false;
    final status = (arrive.status ?? widget.order.status ?? '').toLowerCase();
    if (status == CleaningBookingStatus.awaitingWorkerStartConfirmation) {
      return false;
    }
    return status.isEmpty ||
        status == CleaningBookingStatus.awaitingStartVerification;
  }

  bool _shouldShowVerificationUi(OrdersState state) {
    if (_isAwaitingWorkerStartConfirmation) return false;
    return _isAwaitingVerification || _isAwaitingVerificationAfterArrive(state);
  }

  bool get _canArrive => OrderLifecyclePolicy.canArrive(widget.order);

  /// Straight-line distance from worker to order address, in km.
  double? get _distanceToCustomerKm {
    final my = _myLocation;
    final lat = widget.order.addressLatitude;
    final lng = widget.order.addressLongitude;
    if (my != null && lat != null && lng != null) {
      final meters = Geolocator.distanceBetween(
        my.latitude,
        my.longitude,
        lat,
        lng,
      );
      return meters / 1000;
    }
    return widget.order.travelDistanceKm;
  }

  String? get _distanceLabel {
    final km = _distanceToCustomerKm;
    if (km == null) return null;
    final value = km >= 10
        ? km.toStringAsFixed(0)
        : km.toStringAsFixed(1);
    return 'يبعد تقريباً $value كم';
  }

  @override
  void initState() {
    super.initState();
    _loadInitialMap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAwaitingVerification) {
        _requestSecurityCodeIfNeeded();
      }
      _maybeShowVerificationDialog(widget.bloc.state);
    });
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isAwaitingVerification) {
      _closeVerificationDialogIfOpen();
    }
    if (oldWidget.order.id != widget.order.id) {
      _requestedSecurityCode = false;
      _suppressLocationReporting = false;
      _autoVerificationDialogShown = false;
    }
    if (oldWidget.order.status != widget.order.status &&
        _isAwaitingVerification) {
      _requestSecurityCodeIfNeeded();
    }
    if (oldWidget.order.status != widget.order.status &&
        !_isAwaitingVerification) {
      _requestedSecurityCode = false;
      _suppressLocationReporting = false;
      _autoVerificationDialogShown = false;
    }
    if (oldWidget.order.status != widget.order.status &&
        _isAwaitingVerification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _maybeShowVerificationDialog(widget.bloc.state);
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    _closeVerificationDialogIfOpen();
    super.dispose();
  }

  LocationSettings _locationSettings() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      ),
      _ => const LocationSettings(accuracy: LocationAccuracy.high),
    };
  }

  /// Centers the map on [worker], shifted up so the pin is above the bottom sheet.
  void _centerMapOnWorker(LatLng worker, {double? zoom}) {
    try {
      final camera = _mapController.camera;
      final z = zoom ?? camera.zoom;
      final offsetY =
          camera.nonRotatedSize.height * (_bottomSheetInitialFraction / 2);
      _mapController.move(worker, z, offset: Offset(0, offsetY));
    } catch (_) {
      // Map not rendered yet; next update will recenter.
    }
  }

  void _startLocationStream() {
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings(),
        ).listen((position) {
          if (!mounted) return;
          final next = LatLng(position.latitude, position.longitude);
          setState(() => _myLocation = next);
          _centerMapOnWorker(next);
        });
  }

  Future<void> _loadInitialMap() async {
    try {
      final position = await _getCurrentLocation();
      if (!mounted) return;
      _myLocation = LatLng(position.latitude, position.longitude);
      await _drawRoad(_myLocation!);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _myLocation == null) return;
        _centerMapOnWorker(_myLocation!, zoom: _mapInitialZoom);
      });
      _startLocationStream();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _road = <LatLng>[];
      });
    }
  }

  Future<List<LatLng>> _getRoute(LatLng start, LatLng end) async {
    final response = await _dio.get(
      'http://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
      queryParameters: const <String, dynamic>{
        'overview': 'full',
        'geometries': 'geojson',
      },
    );
    final routes = response.data['routes'];
    if (routes is! List || routes.isEmpty) {
      return <LatLng>[];
    }
    final geometry = routes.first['geometry'];
    if (geometry is! Map) {
      return <LatLng>[];
    }
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) {
      return <LatLng>[];
    }
    return coordinates
        .whereType<List>()
        .where((e) => e.length >= 2)
        .map((e) => LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()))
        .toList();
  }

  Future<Position> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    return Geolocator.getCurrentPosition(
      locationSettings: _locationSettings(),
    );
  }

  Future<void> _drawRoad(LatLng start) async {
    final lat = widget.order.addressLatitude;
    final lng = widget.order.addressLongitude;
    if (lat == null || lng == null) {
      if (!mounted) return;
      setState(() => _road = <LatLng>[]);
      return;
    }
    final road = await _getRoute(start, LatLng(lat, lng));
    if (!mounted) return;
    setState(() {
      _road = road;
    });
  }

  void _requestSecurityCodeIfNeeded({bool force = false}) {
    final id = widget.order.id;
    if (id == null) return;
    if (!_isAwaitingVerification &&
        !_shouldShowVerificationUi(widget.bloc.state) &&
        !force) {
      return;
    }
    if (_requestedSecurityCode && !force) return;

    final blocState = widget.bloc.state;
    if (!force &&
        blocState.securityCode?.data?.hasCode == true &&
        blocState.securityCodeStatus == BlocStatus.success) {
      _requestedSecurityCode = true;
      return;
    }
    if (!force && _securityCodeInFlightForBooking(widget.bloc, id)) {
      return;
    }

    _requestedSecurityCode = true;
    widget.bloc.add(
      FetchSecurityCodeEvent(
        params: FetchSecurityCodeParams(id: id),
        force: force,
      ),
    );
  }

  Future<void> _showVerificationDialog({bool manual = false}) async {
    if (!mounted || !_shouldShowVerificationUi(widget.bloc.state)) return;
    if (_isVerificationDialogOpen) return;
    if (!manual && _autoVerificationDialogShown) return;

    if (!manual) {
      _autoVerificationDialogShown = true;
    }

    _isVerificationDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        _verificationDialogContext = dialogContext;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
          child: BlocBuilder<OrdersBloc, OrdersState>(
            bloc: widget.bloc,
            builder: (_, state) {
              return _CustomerVerificationContent(
                state: state,
                order: widget.order,
                onRefresh: () => _requestSecurityCodeIfNeeded(force: true),
                onClose: () => Navigator.of(dialogContext).pop(),
              );
            },
          ),
        );
      },
    );

    if (mounted) {
      setState(() => _isVerificationDialogOpen = false);
    } else {
      _isVerificationDialogOpen = false;
    }
    _verificationDialogContext = null;
  }

  void _closeVerificationDialogIfOpen() {
    if (!_isVerificationDialogOpen) return;
    final dialogContext = _verificationDialogContext;
    _verificationDialogContext = null;
    _isVerificationDialogOpen = false;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
  }

  void _maybeShowVerificationDialog(OrdersState state) {
    if (!_shouldShowVerificationUi(state)) {
      _autoVerificationDialogShown = false;
      _closeVerificationDialogIfOpen();
      return;
    }
    if (_isVerificationDialogOpen) return;
    unawaited(_showVerificationDialog());
  }

  Widget _buildVerificationReminderAction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: context.width,
          padding: EdgeInsetsDirectional.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xffEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffC7D2FE)),
          ),
          child: AppText.bodySmall(
            'بانتظار تأكيد العميل — اعرض رمز الأمان للعميل لبدء المهمة.',
            color: const Color(0xff475569),
            textAlign: TextAlign.start,
          ),
        ),
        10.verticalSpace,
        SizedBox(
          width: context.width,
          child: FilledButton.icon(
            onPressed: () => _showVerificationDialog(manual: true),
            icon: const Icon(Icons.pin_outlined),
            label: AppText.labelLarge(
              'عرض رمز الأمان',
              color: context.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartWorkConfirmationAction(OrdersState state) {
    final id = widget.order.id;
    final loading = state.startWorkStatus == BlocStatus.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: context.width,
          padding: EdgeInsetsDirectional.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xffECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffA7F3D0)),
          ),
          child: AppText.bodySmall(
            'تم تحقق العميل من رمز الأمان. اضغط بدء العمل للانتقال إلى تنفيذ المهمة.',
            color: const Color(0xff047857),
            textAlign: TextAlign.start,
          ),
        ),
        10.verticalSpace,
        SizedBox(
          width: context.width,
          child: FilledButton.icon(
            onPressed: loading || id == null
                ? null
                : () {
                    widget.bloc.add(
                      StartWorkEvent(params: StartWorkParams(id: id)),
                    );
                  },
            icon: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: context.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: AppText.labelLarge('بدء العمل', color: context.onPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(OrdersState state) {
    if (_shouldShowVerificationUi(state)) {
      return _buildVerificationReminderAction();
    }

    if (_isAwaitingWorkerStartConfirmation) {
      return _buildStartWorkConfirmationAction(state);
    }

    if (!_canArrive || widget.order.id == null) {
      return Container(
        width: context.width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xffE5E7EB),
        ),
        child: AppText.labelLarge(
          'جاري التوجه إلى موقع العميل',
          color: const Color(0xff475569),
          textAlign: TextAlign.center,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final loading = OrderLifecyclePolicy.isLoadingForOrderIndex(
      state: state,
      orderIndex: widget.index,
      actionStatus: state.arriveStatus,
    );
    return InkWell(
      onTap: loading
          ? null
          : () {
              setState(() => _suppressLocationReporting = true);
              widget.bloc.add(
                ArriveEvent(
                  params: ArriveParams(id: widget.order.id!),
                  index: widget.index,
                ),
              );
              _requestSecurityCodeIfNeeded(force: true);
              unawaited(_showVerificationDialog(manual: true));
            },
      child: Container(
        width: context.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: context.onPrimary),
                ),
              )
            : AppText.labelLarge(
                'لقد وصلت',
                color: context.onPrimary,
                fontWeight: FontWeight.w500,
              ),
      ),
    );
  }

  Widget _buildDraggableBottomSheet(ScrollController scrollController) {
    final hideCustomerData = OrderLifecyclePolicy.isCustomerDataHidden(
      widget.order,
    );
    final visibleLocationName = visibleOrderAddress(
      address: widget.order.locationName,
      status: widget.order.status,
    );
    final visibleAddress = visibleOrderAddress(
      address: widget.order.propertyDetails?.address,
      status: widget.order.status,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.r),
          topRight: Radius.circular(40.r),
        ),
        color: context.onPrimary,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.only(top: 16),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsetsDirectional.only(
          start: 19.w,
          end: 19.w,
          top: 18.h,
          bottom: MediaQuery.of(context).padding.bottom + 24.h,
        ),
        children: [
          Center(
            child: Container(
              width: 62.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: const Color(0xffA6A6A6),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
          16.verticalSpace,
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xffE4E5EE),
            ),
            padding: EdgeInsetsDirectional.all(16.r),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: context.primary.withAlpha(77),
                      child: Icon(Icons.location_on, color: context.primary),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.bodyMedium(
                            visibleLocationName,
                            color: context.primary,
                            fontWeight: FontWeight.w400,
                          ),
                          AppText.labelLarge(
                            visibleAddress,
                            color: const Color(0xff727791),
                            fontWeight: FontWeight.w400,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!hideCustomerData) ...[
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final phone = widget.order.customer?.phone;
                            if (phone == null || phone.isEmpty) return;
                            callPhone(phone);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.onPrimary,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: context.primaryContainer,
                                  radius: 19,
                                  child: Icon(
                                    Icons.phone_outlined,
                                    color: context.onPrimaryContainer,
                                  ),
                                ),
                                12.horizontalSpace,
                                Expanded(
                                  child: AppText.labelMedium(
                                    widget.order.customer?.name ?? '-',
                                    color: context.primaryContainer,
                                  ),
                                ),
                                12.horizontalSpace,
                              ],
                            ),
                          ),
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final phone = widget.order.customer?.phone;
                            if (phone == null || phone.isEmpty) return;
                            sendMessage(phone);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.onPrimary,
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: context.primaryContainer,
                                  radius: 19,
                                  child: Icon(
                                    Icons.chat_bubble_outlined,
                                    color: context.onPrimaryContainer,
                                  ),
                                ),
                                12.horizontalSpace,
                                Expanded(
                                  child: AppText.labelMedium(
                                    widget.order.customer?.name ?? '-',
                                    color: context.primaryContainer,
                                  ),
                                ),
                                12.horizontalSpace,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          16.verticalSpace,
          BlocBuilder<OrdersBloc, OrdersState>(
            bloc: widget.bloc,
            builder: (context, state) => _buildAction(state),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrdersBloc, OrdersState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          previous.arriveStatus != current.arriveStatus ||
          previous.arrive != current.arrive ||
          previous.securityCodeStatus != current.securityCodeStatus,
      listener: (_, state) {
        if (state.arriveStatus == BlocStatus.success &&
            _isAwaitingVerificationAfterArrive(state)) {
          _requestSecurityCodeIfNeeded();
        }
        _maybeShowVerificationDialog(state);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _myLocation == null
                ? const Center(child: CircularProgressIndicator.adaptive())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _myLocation!,
                      initialZoom: _mapInitialZoom,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.dllni.clOwner',
                      ),
                      if (_road.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _road,
                              strokeWidth: 5,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _myLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          if (_road.isNotEmpty)
                            Marker(
                              point: _road.last,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            )
                          else if (widget.order.addressLatitude != null &&
                              widget.order.addressLongitude != null)
                            Marker(
                              point: LatLng(
                                widget.order.addressLatitude!,
                                widget.order.addressLongitude!,
                              ),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
          SafeArea(
            bottom: false,
            child: OrderDetailsMapAppBar(
              orderNum: widget.order.bookingNumber ?? '-',
            ),
          ),
          if (_distanceLabel != null)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(top: 56.h),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xffECFDF5),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: const Color(0xffA7F3D0)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      child: AppText.labelMedium(
                        _distanceLabel!,
                        color: const Color(0xff0F766E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              expand: false,
              minChildSize: 0.24,
              initialChildSize: 0.36,
              maxChildSize: 0.5,
              builder: (context, scrollController) =>
                  _buildDraggableBottomSheet(scrollController),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> callPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }
    throw 'Could not launch $url';
  }

  Future<void> sendMessage(String phoneNumber) async {
    final Uri url = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return;
    }
    throw 'Could not launch $url';
  }
}

class _CustomerVerificationContent extends StatelessWidget {
  const _CustomerVerificationContent({
    required this.state,
    required this.order,
    required this.onRefresh,
    required this.onClose,
  });

  final OrdersState state;
  final FetchOrdersUsecaseModelDataItem order;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final code = state.securityCode?.data?.securityCode ?? '----';
    final expiresAt = state.securityCode?.data?.expiresAt;
    final formattedExpiry = formatCleaningSecurityCodeDateTime(expiresAt);
    final bookingLabel = formatCleaningBookingLabel(
      bookingId: order.id,
      bookingNumber: order.bookingNumber,
    );
    final loading = state.securityCodeStatus == BlocStatus.loading;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText.titleSmall(
                    'بانتظار تأكيد العميل',
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff1E3A8A),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xff64748B),
                ),
              ],
            ),
            AppText.bodyMedium(
              'أخبر العميل برمز الأمان التالي ليتم التحقق وبدء المهمة.',
              color: const Color(0xff475569),
              textAlign: TextAlign.start,
            ),
            8.verticalSpace,
            AppText.bodySmall(
              'رقم الحجز: $bookingLabel',
              color: const Color(0xff374151),
              fontWeight: FontWeight.w600,
            ),
            if (formattedExpiry.isNotEmpty) ...[
              4.verticalSpace,
              AppText.bodySmall(
                'صالح حتى: $formattedExpiry',
                color: const Color(0xff64748B),
              ),
            ],
            12.verticalSpace,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xffEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffC7D2FE)),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.labelLarge(
                          'رمز الأمان',
                          color: const Color(0xff6B7280),
                        ),
                        AppText.headlineLarge(
                          code,
                          color: const Color(0xff1E2A78),
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
            ),
            12.verticalSpace,
            OutlinedButton.icon(
              onPressed: loading ? null : onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: AppText.labelLarge('تحديث الرمز'),
            ),
          ],
        ),
      ),
    );
  }
}
