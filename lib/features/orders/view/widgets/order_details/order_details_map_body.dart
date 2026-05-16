import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_security_code_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/post_booking_location_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/fetch_orders_usecase_model.dart';
import '../../manager/bloc/orders_bloc.dart';
import '../order_details_map_app_bar.dart';

class OrderDetailsMapBody extends StatefulWidget {
  const OrderDetailsMapBody({
    super.key,
    required this.order,
    required this.bloc,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;

  @override
  State<OrderDetailsMapBody> createState() => _OrderDetailsMapBodyState();
}

class _OrderDetailsMapBodyState extends State<OrderDetailsMapBody> {
  final Dio _dio = Dio();
  Timer? _locationTimer;

  List<LatLng> _road = <LatLng>[];
  LatLng? _myLocation;
  bool _requestedSecurityCode = false;

  bool get _isAwaitingVerification =>
      widget.order.status == CleaningBookingStatus.awaitingStartVerification;

  bool get _canArrive =>
      widget.order.status == CleaningBookingStatus.workerAssigned &&
      widget.order.startedTravelAt != null;

  @override
  void initState() {
    super.initState();
    _loadInitialMap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLocationTracking();
      _requestSecurityCodeIfNeeded();
    });
  }

  @override
  void didUpdateWidget(covariant OrderDetailsMapBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order.id != widget.order.id) {
      _requestedSecurityCode = false;
    }
    if (oldWidget.order.status != widget.order.status &&
        _isAwaitingVerification) {
      _requestSecurityCodeIfNeeded(force: true);
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialMap() async {
    try {
      final position = await _getCurrentLocation();
      if (!mounted) return;
      _myLocation = LatLng(position.latitude, position.longitude);
      await _drawRoad(_myLocation!);
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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

  void _startLocationTracking() {
    final id = widget.order.id;
    if (id == null) return;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final pos = await _getCurrentLocation();
        if (!mounted) return;
        widget.bloc.add(
          ReportBookingLocationEvent(
            params: PostBookingLocationParams(
              id: id,
              latitude: pos.latitude,
              longitude: pos.longitude,
            ),
          ),
        );
      } catch (_) {}
    });
  }

  void _requestSecurityCodeIfNeeded({bool force = false}) {
    final id = widget.order.id;
    if (id == null) return;
    if (!_isAwaitingVerification && !force) return;
    if (_requestedSecurityCode && !force) return;
    _requestedSecurityCode = true;
    widget.bloc.add(
      FetchSecurityCodeEvent(params: FetchSecurityCodeParams(id: id)),
    );
  }

  Widget _buildAction(OrdersState state) {
    if (_isAwaitingVerification) {
      final code = state.securityCode?.data?.securityCode ?? '----';
      final expiresAt = state.securityCode?.data?.expiresAt;
      final loading = state.securityCodeStatus == BlocStatus.loading;

      return Container(
        width: context.width,
        padding: EdgeInsetsDirectional.all(14.r),
        decoration: BoxDecoration(
          color: const Color(0xffEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffC7D2FE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(
              'بانتظار تأكيد العميل',
              fontWeight: FontWeight.w700,
              color: const Color(0xff1E3A8A),
            ),
            8.verticalSpace,
            AppText.bodyMedium(
              'أخبر العميل برمز الأمان التالي ليتم التحقق وبدء المهمة.',
              color: const Color(0xff475569),
              textAlign: TextAlign.start,
            ),
            10.verticalSpace,
            Container(
              width: context.width,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffD1D5DB)),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
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
                        AppText.headlineMedium(
                          code,
                          color: const Color(0xff1E2A78),
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
            ),
            if (expiresAt != null) ...[
              6.verticalSpace,
              AppText.bodySmall(
                'صالح حتى: $expiresAt',
                color: const Color(0xff64748B),
              ),
            ],
            10.verticalSpace,
            SizedBox(
              width: context.width,
              child: OutlinedButton.icon(
                onPressed: loading
                    ? null
                    : () => _requestSecurityCodeIfNeeded(force: true),
                icon: const Icon(Icons.refresh_rounded),
                label: AppText.labelLarge('تحديث الرمز'),
              ),
            ),
          ],
        ),
      );
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

    final loading = state.arriveStatus == BlocStatus.loading;
    return InkWell(
      onTap: loading
          ? null
          : () {
              widget.bloc.add(
                ArriveEvent(
                  params: ArriveParams(id: widget.order.id!),
                  index: 0,
                ),
              );
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _myLocation == null
            ? const Center(child: CircularProgressIndicator.adaptive())
            : FlutterMap(
                options: MapOptions(
                  initialCenter: _myLocation!,
                  initialZoom: 13,
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
                  if (_road.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _road.first,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        Marker(
                          point: _road.last,
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
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OrderDetailsMapAppBar(orderNum: widget.order.bookingNumber ?? '-'),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.r),
                  topRight: Radius.circular(40.r),
                ),
                color: context.onPrimary,
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: 19.w,
                vertical: 24.h,
              ),
              child: Column(
                children: [
                  Divider(
                    color: const Color(0xffA6A6A6),
                    thickness: 3,
                    endIndent: 120.w,
                    indent: 120.w,
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
                              child: Icon(
                                Icons.location_on,
                                color: context.primary,
                              ),
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText.bodyMedium(
                                    widget.order.locationName ?? '-',
                                    color: context.primary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  AppText.labelLarge(
                                    widget.order.propertyDetails?.address ??
                                        '-',
                                    color: const Color(0xff727791),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                                        backgroundColor:
                                            context.primaryContainer,
                                        radius: 19,
                                        child: Icon(
                                          Icons.phone_outlined,
                                          color: context.onPrimaryContainer,
                                        ),
                                      ),
                                      12.horizontalSpace,
                                      Expanded(
                                        child: AppText.labelMedium(
                                          widget.order.customer?.name ??
                                              'العميل',
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
                                        backgroundColor:
                                            context.primaryContainer,
                                        radius: 19,
                                        child: Icon(
                                          Icons.chat_bubble_outlined,
                                          color: context.onPrimaryContainer,
                                        ),
                                      ),
                                      12.horizontalSpace,
                                      Expanded(
                                        child: AppText.labelMedium(
                                          widget.order.customer?.name ??
                                              'العميل',
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
                    ),
                  ),
                  16.verticalSpace,
                  BlocBuilder<OrdersBloc, OrdersState>(
                    bloc: widget.bloc,
                    builder: (context, state) => _buildAction(state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
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
