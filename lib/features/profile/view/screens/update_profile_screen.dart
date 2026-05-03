import 'dart:developer';
import 'dart:io';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_pickers.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';

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
  late TextEditingController _phoneController;
  late TextEditingController _aboutMeController;
  late TextEditingController _cityMeController;

  String? _selectedGender;

  final List<String> _genderOptions = ['ذكر', 'أنثى'];

  File? selectedImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.params.name);
    _emailController = TextEditingController(text: widget.params.email ?? '');
    _dateOfBirthController = TextEditingController(text: widget.params.birth ?? '');
    _phoneController = TextEditingController(text: widget.params.phone ?? '');
    _aboutMeController = TextEditingController(text: widget.params.bio ?? '');
    _cityMeController = TextEditingController(text: widget.params.city ?? '');
    _selectedGender = 'ذكر';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _aboutMeController.dispose();
    _cityMeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    _dateOfBirthController.text = await AppPickers.showAppDatePicker(context: context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => getIt<ProfileBloc>(),
      child: Scaffold(
        backgroundColor: const Color(0xffF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.onPrimary,
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(24), bottomLeft: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: context.primaryContainer, width: 5)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2), blurRadius: 12, spreadRadius: 0)],
                ),
                width: context.width,
                height: 80,
                padding: EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        context.pop();
                      },
                      child: Icon(Icons.arrow_back_ios_new, color: context.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppText.headlineLarge('التفاصيل الشخصية', fontWeight: FontWeight.w700, textAlign: TextAlign.start),
                    ),
                  ],
                ),
              ),
              24.verticalSpace,
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(20.w, 16.h, 20.w, 24.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionCard(
                          sectionNumber: '1',
                          title: 'الصورة الشخصية',
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40.r,
                                backgroundColor: const Color(0xffE5E7EB),
                                backgroundImage: selectedImage == null ? null : FileImage(selectedImage!),
                              ),
                              16.verticalSpace,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPhotoAction(icon: Icons.image_outlined, title: 'اختيار من المعرض', source: ImageSource.gallery),
                                  12.horizontalSpace,
                                  _buildPhotoAction(icon: Icons.camera_alt_outlined, title: 'التقاط صورة', source: ImageSource.camera),
                                ],
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        _buildSectionCard(
                          sectionNumber: '2',
                          title: 'معلومات الحساب',
                          child: Column(
                            children: [
                              _buildField(label: 'الاسم الكامل', controller: _nameController, isRequired: true),
                              14.verticalSpace,
                              _buildField(
                                label: 'رقم الهاتف الأساسي',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                isRequired: true,
                              ),
                              14.verticalSpace,
                              _buildField(
                                label: 'البريد الإلكتروني',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                isRequired: true,
                              ),
                              14.verticalSpace,
                              _buildField(label: 'المدينة', controller: _cityMeController, isRequired: true),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        _buildSectionCard(
                          sectionNumber: '3',
                          title: 'معلومات إضافية',
                          child: Column(
                            children: [
                              _buildDropdownField(
                                label: 'الجنس',
                                value: _selectedGender,
                                items: _genderOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                  });
                                },
                              ),
                              14.verticalSpace,
                              _buildDateField(label: 'تاريخ الميلاد', controller: _dateOfBirthController),
                              14.verticalSpace,
                              _buildTextAreaField(label: 'نبذة عني', controller: _aboutMeController),
                            ],
                          ),
                        ),
                        32.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: BlocConsumer<ProfileBloc, ProfileState>(
                                listener: (context, state) {
                                  if (state.updateWorkerProfileStatus == BlocStatus.success) {
                                    Loading.close();
                                  } else if (state.updateWorkerProfileStatus == BlocStatus.failed) {
                                    Loading.close();
                                  } else if (state.updateWorkerProfileStatus == BlocStatus.loading) {
                                    Loading.show(context);
                                  }
                                },
                                builder: (context, state) {
                                  return ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<ProfileBloc>().add(
                                          UpdateWorkerProfileEvent(
                                            params: UpdateWorkerProfileParams(
                                              avatar: selectedImage,
                                              bio: _aboutMeController.text,
                                              birthday: _dateOfBirthController.text,
                                              city: _cityMeController.text,
                                              email: _emailController.text,
                                              gender: _selectedGender,
                                              isActive: 1,
                                              name: _nameController.text,
                                              phone: _phoneController.text,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff1E3A8A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                      padding: EdgeInsets.symmetric(vertical: 12.h),
                                    ),
                                    child: AppText.labelLarge('حفظ التغييرات', color: Colors.white, fontWeight: FontWeight.w700),
                                  );
                                },
                              ),
                            ),
                            12.horizontalSpace,
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xffE11D48).withAlpha(150)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                ),
                                child: AppText.labelLarge('إلغاء', color: const Color(0xffE11D48), fontWeight: FontWeight.w600),
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

  Widget _buildSectionCard({required String sectionNumber, required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26.r),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), offset: const Offset(0, 4), blurRadius: 18, spreadRadius: -2)],
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
                child: AppText.labelLarge(sectionNumber, color: context.onPrimary, fontWeight: FontWeight.w700),
              ),
              10.horizontalSpace,
              AppText.titleLarge(title, color: context.primary, fontWeight: FontWeight.w700),
            ],
          ),
          16.verticalSpace,
          child,
        ],
      ),
    );
  }

  static Future<File?> pickSingleImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e) {
      log('Error picking image: $e');
    }
    return null;
  }

  Widget _buildPhotoAction({required IconData icon, required String title, required ImageSource source}) {
    return InkWell(
      onTap: () async {
        selectedImage = await pickSingleImage(source);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: const Color(0xff1F2A5A)),
            6.horizontalSpace,
            AppText.bodySmall(title, color: const Color(0xff1F2A5A), fontWeight: FontWeight.w500),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required String label, required TextEditingController controller, TextInputType? keyboardType, bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.bodyMedium(label, fontWeight: FontWeight.w500),
            if (isRequired) AppText.bodyMedium('*', color: context.error, fontWeight: FontWeight.w500),
          ],
        ),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: const Color(0xff2F2B3D), fontSize: 14.sp, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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

  Widget _buildDateField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, fontWeight: FontWeight.w500),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: _selectDate,
          style: TextStyle(color: const Color(0xff2F2B3D), fontSize: 14.sp, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            suffixIcon: Icon(Icons.calendar_today, size: 18.sp, color: const Color(0xff6B7280)),
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

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, fontWeight: FontWeight.w500),
        8.verticalSpace,
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff6B7280)),
          style: TextStyle(color: const Color(0xff2F2B3D), fontSize: 14.sp),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextAreaField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(label, fontWeight: FontWeight.w500),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: const Color(0xff2F2B3D), fontSize: 14.sp, fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final String? birth;
  final String? city;
  final String? bio;

  UpdateProfileScreenParams({required this.name, this.email, this.phone, this.gender, this.birth, this.city, this.bio});
}
