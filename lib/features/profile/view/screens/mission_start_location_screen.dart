import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MissionStartLocationScreen extends StatefulWidget {
  const MissionStartLocationScreen({super.key});

  static const String latPreferenceKey = 'mission_start_location_lat';
  static const String lngPreferenceKey = 'mission_start_location_lng';

  @override
  State<MissionStartLocationScreen> createState() =>
      _MissionStartLocationScreenState();
}

class _MissionStartLocationScreenState
    extends State<MissionStartLocationScreen> {
  static const LatLng _fallbackCenter = LatLng(36.2021, 37.1343);

  LatLng? _selectedCenter;
  bool _isLoadingCenter = true;
  bool _isSaving = false;
  ProfileBloc? _profileBloc;

  @override
  void initState() {
    super.initState();
    _resolveInitialCenter();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileBloc ??= _maybeReadProfileBloc();
  }

  ProfileBloc? _maybeReadProfileBloc() {
    try {
      return context.read<ProfileBloc>();
    } catch (_) {
      return null;
    }
  }

  LatLng? _readSavedCenter() {
    final lat = SharedPreferencesHelper.getData(
      key: MissionStartLocationScreen.latPreferenceKey,
    );
    final lng = SharedPreferencesHelper.getData(
      key: MissionStartLocationScreen.lngPreferenceKey,
    );
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  Future<void> _resolveInitialCenter() async {
    final savedCenter = _readSavedCenter();
    if (savedCenter != null) {
      if (!mounted) return;
      setState(() {
        _selectedCenter = savedCenter;
        _isLoadingCenter = false;
      });
      return;
    }

    var initialCenter = _fallbackCenter;
    try {
      final position = await _getCurrentLocation();
      initialCenter = LatLng(position.latitude, position.longitude);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _selectedCenter = initialCenter;
      _isLoadingCenter = false;
    });
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

  String _formatCoordinateAddress(LatLng center) {
    final lat = center.latitude.toStringAsFixed(6);
    final lng = center.longitude.toStringAsFixed(6);
    return '$lat, $lng';
  }

  Future<BlocStatus?> _waitForUpdateProfileResult() async {
    final bloc = _profileBloc;
    if (bloc == null) return null;

    var loadingSeen =
        bloc.state.updateWorkerProfileStatus == BlocStatus.loading;
    if (bloc.state.updateWorkerProfileStatus == BlocStatus.success ||
        bloc.state.updateWorkerProfileStatus == BlocStatus.failed) {
      loadingSeen = false;
    }

    final resolvedState = await bloc.stream.firstWhere((state) {
      final status = state.updateWorkerProfileStatus;
      if (status == BlocStatus.loading) {
        loadingSeen = true;
        return false;
      }
      final isTerminal =
          status == BlocStatus.success || status == BlocStatus.failed;
      if (!isTerminal) return false;
      return loadingSeen;
    });
    return resolvedState.updateWorkerProfileStatus;
  }

  Future<void> _saveSelection() async {
    final center = _selectedCenter;
    if (center == null || _isSaving) return;

    final profileBloc = _profileBloc;
    if (profileBloc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تهيئة تحديث بيانات الموقع.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    profileBloc.add(
      UpdateWorkerProfileEvent(
        params: UpdateWorkerProfileParams(
          homeLatitude: center.latitude,
          homeLongitude: center.longitude,
          homeAddress: _formatCoordinateAddress(center),
        ),
      ),
    );

    final status = await _waitForUpdateProfileResult();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (status != BlocStatus.success) return;

    await SharedPreferencesHelper.saveData(
      key: MissionStartLocationScreen.latPreferenceKey,
      value: center.latitude,
    );
    await SharedPreferencesHelper.saveData(
      key: MissionStartLocationScreen.lngPreferenceKey,
      value: center.longitude,
    );
    if (!mounted) return;

    final locationStatus =
        profileBloc.state.updateWorkerProfile?.data?.homeLocationStatus
            ?.trim()
            .toLowerCase();
    final isPendingApproval = locationStatus == 'pending';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isPendingApproval
              ? 'تم إرسال موقع بدء المهمة وبانتظار موافقة الإدارة.'
              : 'تم حفظ موقع بدء المهمة.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaveDisabled =
        _isLoadingCenter || _selectedCenter == null || _isSaving;
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            12.verticalSpace,
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 18.w),
              child: Container(
                width: context.width,
                decoration: BoxDecoration(
                  color: const Color(0xffEEF2FF),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffA5B4FC)),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 10.w,
                  vertical: 12.h,
                ),
                child: AppText.labelMedium(
                  'حرّك الخريطة واجعل المؤشر في منتصف موقع بداية المهمة.',
                  color: const Color(0xff1E3A8A),
                  textAlign: TextAlign.start,
                ),
              ),
            ),
            10.verticalSpace,
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(18.w, 0, 18.w, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.r),
                  child: _isLoadingCenter || _selectedCenter == null
                      ? const ColoredBox(
                          color: Colors.white,
                          child: Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                        )
                      : Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _selectedCenter!,
                                initialZoom: 14,
                                onPositionChanged: (camera, _) {
                                  _selectedCenter = camera.center;
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.dllni.clOwner',
                                ),
                              ],
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: context.primaryContainer,
                                  size: 44.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            12.verticalSpace,
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.w, 0, 20.w, 14.h),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: isSaveDisabled ? null : _saveSelection,
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: isSaveDisabled
                              ? const Color(0xff9CA3AF)
                              : context.primary,
                        ),
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        child: AppText.labelLarge(
                          _isSaving ? 'جارٍ الحفظ...' : 'حفظ',
                          color: context.onPrimary,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: context.error.withAlpha(50),
                          border: Border.all(color: context.error),
                        ),
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: 6.w,
                          vertical: 12.h,
                        ),
                        child: AppText.labelLarge(
                          'إلغاء',
                          color: context.error,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        border: Border(
          bottom: BorderSide(color: context.primaryContainer, width: 2),
        ),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 22.w,
        vertical: 16.h,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: context.primaryContainer,
            ),
          ),
          10.horizontalSpace,
          AppText.headlineLarge(
            'موقع بدء المهمة',
            color: context.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
