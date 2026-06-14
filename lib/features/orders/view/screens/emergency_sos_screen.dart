import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/sos_alert_models.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/create_cleaning_booking_sos_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:geolocator/geolocator.dart';

class EmergencySosScreenParams {
  const EmergencySosScreenParams({required this.bookingId});

  final int bookingId;
}

@AutoRoutePage()
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key, required this.params});

  final EmergencySosScreenParams params;

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  static const List<({String type, String label})> _options =
      <({String type, String label})>[
        (type: 'safety_threat', label: 'أشعر بعدم الأمان / تهديد'),
        (type: 'medical_emergency', label: 'حدثت حالة طبية طارئة'),
        (type: 'severe_conflict', label: 'هنالك خلاف حاد'),
      ];

  final TextEditingController _messageController = TextEditingController();
  String? _selectedEmergencyType;
  String? _messageError;
  bool _submitting = false;
  CleaningSosAlertModel? _submittedAlert;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'acknowledged':
        return 'الدعم يتعامل مع الطلب';
      case 'resolved':
        return 'تم إغلاق الطلب';
      case 'pending':
      case 'triggered':
      default:
        return 'تم الإرسال إلى الدعم';
    }
  }

  String? _validateMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return 'يرجى وصف المشكلة قبل إرسال SOS';
    }
    if (message.length < 3) {
      return 'يرجى كتابة 3 أحرف على الأقل';
    }
    if (message.length > 1000) {
      return 'يجب ألا تتجاوز الرسالة 1000 حرف';
    }
    return null;
  }

  Future<({double? latitude, double? longitude})> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (latitude: null, longitude: null);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitude: null, longitude: null);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return (latitude: null, longitude: null);
    }
  }

  Future<void> _submit() async {
    final emergencyType = _selectedEmergencyType;
    if (emergencyType == null || _submitting) {
      if (emergencyType == null && mounted) {
        AppToast.showErrorGlobal('يرجى تحديد نوع الطوارئ');
      }
      return;
    }

    final validationError = _validateMessage();
    setState(() => _messageError = validationError);
    if (validationError != null) return;

    setState(() => _submitting = true);

    final location = await _resolveLocation();
    final result = await getIt<CreateCleaningBookingSosUseCase>()(
      CreateCleaningBookingSosParams(
        orderId: widget.params.bookingId,
        emergencyType: emergencyType,
        message: _messageController.text,
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _submitting = false);
        AppToast.showErrorGlobal(failure.message);
      },
      (alert) {
        setState(() {
          _submitting = false;
          _submittedAlert = alert;
        });
        final locationNote =
            location.latitude == null || location.longitude == null
            ? ' (بدون موقع GPS)'
            : '';
        AppToast.showSuccessGlobal('تم إرسال تنبيه SOS بنجاح$locationNote');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final submitted = _submittedAlert;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppText.headlineMedium(
                      'حالة طوارئ',
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(24),
                child: submitted != null
                    ? _buildSubmittedState(submitted)
                    : _buildForm(context),
              ),
            ),
            if (submitted == null)
              Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.all(24),
                child: InkWell(
                  onTap: _submitting ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: _submitting
                          ? context.error.withValues(alpha: 0.6)
                          : context.error,
                    ),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: _submitting
                        ? const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : AppText.labelLarge(
                            'إرسال لفريق الدعم',
                            textAlign: TextAlign.center,
                            color: context.onError,
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedState(CleaningSosAlertModel alert) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsetsDirectional.all(25),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: context.error, size: 56),
          16.verticalSpace,
          AppText.titleMedium(
            _statusLabel(alert.status),
            textAlign: TextAlign.center,
            fontWeight: FontWeight.bold,
          ),
          8.verticalSpace,
          AppText.bodyMedium(
            'تم إرسال طلب الطوارئ. سيتواصل معك فريق الدعم في أقرب وقت.',
            textAlign: TextAlign.center,
            color: Colors.grey[700],
          ),
          if (alert.id != null) ...[
            12.verticalSpace,
            AppText.bodySmall(
              'رقم التنبيه: ${alert.id}',
              color: Colors.grey[600],
            ),
          ],
          20.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('العودة إلى المهمة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsetsDirectional.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: context.error, size: 24),
                  8.horizontalSpace,
                  Expanded(
                    child: AppText.titleMedium(
                      'ماهي حالة الطوارئ ؟',
                      textAlign: TextAlign.start,
                      color: context.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              12.verticalSpace,
              AppText.bodyMedium(
                'استخدم هذا الخيار فقط في حالات الخطر أو الحاجة العاجلة للمساعدة.',
                textAlign: TextAlign.start,
                color: Colors.grey[700],
              ),
              20.verticalSpace,
              ..._options.map((option) {
                final selected = _selectedEmergencyType == option.type;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: _buildEmergencyOption(
                    context: context,
                    title: option.label,
                    isSelected: selected,
                    onTap: _submitting
                        ? null
                        : () {
                            setState(() {
                              _selectedEmergencyType = option.type;
                            });
                          },
                  ),
                );
              }),
              8.verticalSpace,
              AppText.bodyMedium(
                'رسالة الطوارئ',
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w600,
              ),
              8.verticalSpace,
              TextField(
                controller: _messageController,
                enabled: !_submitting,
                maxLength: 1000,
                maxLines: 3,
                onChanged: (_) {
                  if (_messageError != null) {
                    setState(() => _messageError = _validateMessage());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'صف الموقف باختصار',
                  errorText: _messageError,
                  filled: true,
                  fillColor: const Color(0xffF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? context.error.withValues(alpha: 0.08)
              : const Color(0xffF3F4F6),
          border: Border.all(
            color: isSelected ? context.error : const Color(0xffD1D5DB),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: EdgeInsetsDirectional.all(16),
        child: Row(
          children: [
            Expanded(
              child: AppText.bodyMedium(
                title,
                textAlign: TextAlign.start,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            12.horizontalSpace,
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? context.error : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
