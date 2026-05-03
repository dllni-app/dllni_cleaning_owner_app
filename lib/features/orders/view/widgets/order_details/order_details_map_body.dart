import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dio/dio.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/arrive_use_case.dart';
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
  final Dio dio = Dio();
  Timer? _locationTimer;

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final response = await dio.get(
      'http://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}',
      queryParameters: {'overview': 'full', 'geometries': 'geojson'},
    );

    final coords =
        response.data['routes'][0]['geometry']['coordinates'] as List;

    return coords.map((e) => LatLng(e[1], e[0])).toList();
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
    return await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  List<LatLng> road = [];
  LatLng? myLocation;

  drawRoad(LatLng start) async {
    road = await getRoute(
      start,
      LatLng(widget.order.addressLatitude!, widget.order.addressLongitude!),
    );
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation().then((val) {
      myLocation = LatLng(val.latitude, val.longitude);
      drawRoad(LatLng(val.latitude, val.longitude));
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _startLocationTracking(),
    );
  }

  void _startLocationTracking() {
    final id = widget.order.id;
    if (id == null) return;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final pos = await getCurrentLocation();
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

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        road.isEmpty
            ? Center(child: CircularProgressIndicator.adaptive())
            : FlutterMap(
                options: MapOptions(
                  initialCenter: myLocation!,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dllni.clOwner',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: road,
                        strokeWidth: 5,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: road.first,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      Marker(
                        point: road.last,
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
            OrderDetailsMapAppBar(orderNum: widget.order.bookingNumber!),
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
                    color: Color(0xffA6A6A6),
                    thickness: 3,
                    endIndent: 120.w,
                    indent: 120.w,
                  ),
                  16.verticalSpace,
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Color(0xffE4E5EE),
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
                                    widget.order.locationName!,
                                    color: context.primary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  AppText.labelLarge(
                                    widget.order.propertyDetails?.address ??
                                        '-',
                                    color: Color(0xff727791),
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
                                  callPhone(widget.order.customer!.phone!);
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
                                          widget.order.customer!.name!,
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
                                  sendMessage(widget.order.customer!.phone!);
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
                                          widget.order.customer!.name!,
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
                    builder: (context, state) {
                      return InkWell(
                        onTap: () {
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
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: state.arriveStatus == BlocStatus.loading
                              ? Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: context.onPrimary,
                                    ),
                                  ),
                                )
                              : AppText.labelLarge(
                                  'لقد وصلت',
                                  color: context.onPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                        ),
                      );
                    },
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
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> sendMessage(String phoneNumber) async {
    final Uri url = Uri(scheme: 'sms', path: phoneNumber);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
