import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

@AutoRoutePage()
class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  final List<bool> _emergencyOptions = [false, false, false];

  @override
  Widget build(BuildContext context) {
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
                    onTap: () {
                      context.pop();
                    },
                    child: Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  12.horizontalSpace,
                  Expanded(child: AppText.headlineMedium('حالة طوارئ', textAlign: TextAlign.start)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.all(24),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      padding: EdgeInsetsDirectional.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card title with warning icon
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
                          // Instructional text
                          AppText.bodyMedium('تحديد المهام التي قمت بتنفيذها', textAlign: TextAlign.start, color: Colors.grey[700]),
                          20.verticalSpace,
                          // Emergency options
                          _buildEmergencyOption(
                            context: context,
                            title: 'أشعر بعدم الأمان / تهديد',
                            isChecked: _emergencyOptions[0],
                            onChanged: (value) {
                              setState(() {
                                _emergencyOptions[0] = value ?? false;
                              });
                            },
                          ),
                          12.verticalSpace,
                          _buildEmergencyOption(
                            context: context,
                            title: 'حدثت حالة طبية طارئة',
                            isChecked: _emergencyOptions[1],
                            onChanged: (value) {
                              setState(() {
                                _emergencyOptions[1] = value ?? false;
                              });
                            },
                          ),
                          12.verticalSpace,
                          _buildEmergencyOption(
                            context: context,
                            title: 'هنالك خلاف حاد',
                            isChecked: _emergencyOptions[2],
                            onChanged: (value) {
                              setState(() {
                                _emergencyOptions[2] = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Submit button at bottom
            Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.all(24),
              child: InkWell(
                onTap: () {
                  // TODO: Handle form submission
                  if (_emergencyOptions.any((checked) => checked)) {
                    // Show success message or navigate back
                    context.pop();
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.error),
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                  child: AppText.labelLarge('إرسال لفريق الدعم', textAlign: TextAlign.center, color: context.onError, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOption({
    required BuildContext context,
    required String title,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xffF3F4F6)),
      padding: EdgeInsetsDirectional.all(16),
      child: Row(
        children: [
          Expanded(
            child: AppText.bodyMedium(title, textAlign: TextAlign.start, fontWeight: FontWeight.w500, color: Colors.grey[800]),
          ),
          12.horizontalSpace,
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: context.primaryContainer,
            side: BorderSide(color: Color(0xffD1D5DB), width: 2),
          ),
        ],
      ),
    );
  }
}
