import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_pickers.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

@AutoRoutePage()
class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key, required this.params});

  final UpdateProfileScreenParams params;

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _aboutMeController;
  late TextEditingController _cityMeController;
  late TextEditingController phoneNumberController;

  String _preferredWorkType = 'both';

  static const List<({String value, String title, String subtitle, IconData icon, Color color})>
      _workTypeOptions = [
    (
      value: 'cleaning',
      title: 'طلبات التنظيف فقط',
      subtitle: 'استقبال طلبات تنظيف المنازل والمكاتب فقط',
      icon: Icons.cleaning_services_outlined,
      color: Color(0xff3B82F6),
    ),
    (
      value: 'events',
      title: 'طلبات الفعاليات فقط',
      subtitle: 'استقبال طلبات مساعدة وتنظيف الفعاليات فقط',
      icon: Icons.event_outlined,
      color: Color(0xffA855F7),
    ),
    (
      value: 'both',
      title: 'كلا النوعين',
      subtitle: 'استقبال طلبات التنظيف وطلبات الفعاليات معاً',
      icon: Icons.all_inclusive,
      color: Color(0xff22C55E),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.params.name);
    _emailController = TextEditingController(text: widget.params.email ?? '');
    _dateOfBirthController = TextEditingController(
      text: widget.params.birth ?? '',
    );
    _aboutMeController = TextEditingController(text: widget.params.bio ?? '');
    _cityMeController = TextEditingController(text: widget.params.city ?? '');
    phoneNumberController = TextEditingController(
      text: widget.params.phone ?? '',
    );
    _preferredWorkType = widget.params.preferredWorkType ?? 'both';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _aboutMeController.dispose();
    _cityMeController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    _dateOfBirthController.text = await AppPickers.showAppDatePicker(
      context: context,
    );
    setState(() {});
  }

  ProfileBloc _resolveProfileBloc(BuildContext context) {
    try {
      return context.read<ProfileBloc>();
    } catch (_) {
      final bloc = getIt<ProfileBloc>();
      bloc.add(
        FetchWorkerProfileUsecaseEvent(
          params: FetchWorkerProfileUsecaseParams(),
        ),
      );
      return bloc;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileBloc = _resolveProfileBloc(context);
    return BlocProvider<ProfileBloc>.value(
      value: profileBloc,
      child: Scaffold(
        backgroundColor: const Color(0xffF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.onPrimary,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: context.primaryContainer,
                      width: 5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(27),
                      offset: Offset(0, -2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                width: context.width,
                height: 80,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        context.pop();
                      },
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: context.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppText.headlineLarge(
                        'التفاصيل الشخصية',
                        fontWeight: FontWeight.w700,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
              ),
              24.verticalSpace,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    20.w,
                    16.h,
                    20.w,
                    24.h,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          sectionNumber: '1',
                          title: 'معلومات الحساب',
                          child: Column(
                            children: [
                              _buildField(
                                label: 'الاسم الكامل',
                                controller: _nameController,
                                isRequired: true,
                                enabled: false,
                              ),
                              14.verticalSpace,
                              _buildField(
                                label: 'رقم الهاتف الأساسي',
                                controller: phoneNumberController,
                                enabled: false,
                              ),
                              14.verticalSpace,
                              _buildField(
                                label: 'البريد الإلكتروني',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                isRequired: false,
                              ),
                              14.verticalSpace,
                              _buildField(
                                label: 'المدينة',
                                controller: _cityMeController,
                                isRequired: true,
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        _buildSectionCard(
                          sectionNumber: '2',
                          title: 'معلومات إضافية',
                          child: Column(
                            children: [
                              _buildDateField(
                                label: 'تاريخ الميلاد',
                                controller: _dateOfBirthController,
                              ),
                              14.verticalSpace,
                              _buildTextAreaField(
                                label: 'نبذة عني',
                                controller: _aboutMeController,
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        _buildSectionCard(
                          sectionNumber: '3',
                          title: 'نوع الطلبات المفضلة',
                          child: Column(
                            children: [
                              for (var i = 0; i < _workTypeOptions.length; i++) ...[
                                if (i > 0) 12.verticalSpace,
                                _buildWorkTypeOption(_workTypeOptions[i]),
                              ],
                            ],
                          ),
                        ),
                        32.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: BlocConsumer<ProfileBloc, ProfileState>(
                                listenWhen: (previous, current) =>
                                    previous.updateWorkerProfileStatus !=
                                    current.updateWorkerProfileStatus,
                                buildWhen: (previous, current) =>
                                    previous.updateWorkerProfileStatus !=
                                    current.updateWorkerProfileStatus,
                                listener: (context, state) {
                                  if (state.updateWorkerProfileStatus ==
                                      BlocStatus.success) {
                                    Loading.close();
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!context.mounted) return;
                                      context.maybePop(true);
                                    });
                                  } else if (state.updateWorkerProfileStatus ==
                                      BlocStatus.failed) {
                                    Loading.close();
                                  } else if (state.updateWorkerProfileStatus ==
                                      BlocStatus.loading) {
                                    Loading.show(context);
                                  }
                                },
                                builder: (context, state) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      if (!(_formKey.currentState?.validate() ??
                                          false)) {
                                        return;
                                      }

                                      final email = _emailController.text.trim();

                                      if (!context.mounted) return;
                                      context.read<ProfileBloc>().add(
                                        UpdateWorkerProfileEvent(
                                          params: UpdateWorkerProfileParams(
                                            bio: _aboutMeController.text,
                                            birthday: _dateOfBirthController.text,
                                            city: _cityMeController.text,
                                            email: email.isEmpty ? '' : email,
                                            isActive: 1,
                                            name: widget.params.name,
                                            phone: widget.params.phone,
                                            preferredWorkType: _preferredWorkType,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1E3A8A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.r),
                                      ),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                    child: AppText.labelLarge(
                                      'حفظ التغييرات',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                            12.horizontalSpace,
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.maybePop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: const Color(0xffE11D48).withAlpha(150),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                child: AppText.labelLarge(
                                  'إلغاء',
                                  color: const Color(0xffE11D48),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String sectionNumber,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            offset: const Offset(0, 4),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.primary,
                radius: 15.r,
                child: AppText.labelLarge(
                  sectionNumber,
                  color: context.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              10.horizontalSpace,
              AppText.titleLarge(
                title,
                color: context.primary,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          16.verticalSpace,
          child,
        ],
      ),
    );
  }

  Widget _buildWorkTypeOption(
    ({String value, String title, String subtitle, IconData icon, Color color})
        option,
  ) {
    final isSelected = _preferredWorkType == option.value;
    return InkWell(
      onTap: () => setState(() => _preferredWorkType = option.value),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          color: isSelected
              ? option.color.withAlpha(20)
              : const Color(0xffF9FAFB),
          border: Border.all(
            color: isSelected ? option.color : const Color(0xffE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: 14.w,
          vertical: 14.h,
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: option.color.withAlpha(27),
              ),
              padding: EdgeInsetsDirectional.all(8.w),
              child: Icon(option.icon, size: 22.sp, color: option.color),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    option.title,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.start,
                  ),
                  4.verticalSpace,
                  AppText.labelLarge(
                    option.subtitle,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff6B7280),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            8.horizontalSpace,
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? option.color : const Color(0xff9CA3AF),
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool isRequired = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.bodyMedium(label, fontWeight: FontWeight.w500),
            if (isRequired)
              AppText.bodyMedium(
                '*',
                color: context.error,
                fontWeight: FontWeight.w500,
              ),
          ],
        ),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(
            color: enabled
                ? const Color(0xff2F2B3D)
                : const Color(0xff6B7280),
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled
                ? const Color(0xffF9FAFB)
                : const Color(0xffF3F4F6),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: context.primary, width: 1.1.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, fontWeight: FontWeight.w500),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: _selectDate,
          style: TextStyle(
            color: const Color(0xff2F2B3D),
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            suffixIcon: Icon(
              Icons.calendar_today,
              size: 18.sp,
              color: const Color(0xff6B7280),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: context.primary, width: 1.1.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, fontWeight: FontWeight.w500),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(
            color: const Color(0xff2F2B3D),
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xffE5E7EB), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: context.primary, width: 1.1.w),
            ),
          ),
        ),
      ],
    );
  }
}

class UpdateProfileScreenParams {
  const UpdateProfileScreenParams({
    required this.name,
    this.email,
    this.phone,
    this.gender,
    this.birth,
    this.city,
    this.bio,
    this.avatarUrl,
    this.preferredWorkType,
  });

  factory UpdateProfileScreenParams.fromWorkerProfile(
    FetchWorkerProfileUsecaseModelData data,
  ) {
    return UpdateProfileScreenParams(
      name: data.user?.name ?? data.firstName ?? '',
      email: data.user?.email,
      phone: data.user?.phone,
      bio: data.bio,
      city: data.homeAddress,
      avatarUrl: data.avatar?.url,
      preferredWorkType: data.preferredWorkType ?? 'both',
    );
  }

  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birth;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final String? preferredWorkType;
}
