import 'package:common_package/common_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
  late TextEditingController _phoneController;
  late TextEditingController _aboutMeController;
  late TextEditingController _cityMeController;

  String? _selectedGender;

  final List<String> _genderOptions = ['ذكر', 'أنثى'];

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
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 5, 3),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: context.primary),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy_MM_dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                20.verticalSpace,
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back_ios, color: context.primary, size: 20.sp),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: AppText.titleLarge('حسابك', color: context.primary, fontWeight: FontWeight.w700, textAlign: TextAlign.start),
                    ),
                  ],
                ),
                24.verticalSpace,
                AppText.bodyLarge('مرحبا ${widget.params.name} !', color: context.primary, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
                24.verticalSpace,
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50.r,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: const NetworkImage('https://via.placeholder.com/100'),
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      AppText.labelMedium('التعديل صورة الملف الشخصي', color: Colors.grey.shade600, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                32.verticalSpace,
                _buildFormField(label: 'الاسم', controller: _nameController),
                16.verticalSpace,
                _buildFormField(label: 'البريد الإلكاروني', controller: _emailController, keyboardType: TextInputType.emailAddress),
                16.verticalSpace,
                _buildDateField(label: 'تاريخ الميلاد', controller: _dateOfBirthController),
                16.verticalSpace,
                _buildFormField(label: 'رقم الهاتف', controller: _phoneController, keyboardType: TextInputType.phone),
                16.verticalSpace,
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
                16.verticalSpace,
                _buildFormField(label: 'مدينتك', controller: _cityMeController, keyboardType: TextInputType.text),
                16.verticalSpace,
                _buildTextAreaField(label: 'نبذة عني', controller: _aboutMeController),
                32.verticalSpace,
                InkWell(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {}
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(12.r)),
                    child: AppText.labelLarge('حفظ', color: context.onPrimary, fontWeight: FontWeight.w500, textAlign: TextAlign.center),
                  ),
                ),
                24.verticalSpace,
                Center(
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 18.sp, color: Colors.grey.shade600),
                        8.horizontalSpace,
                        AppText.labelMedium('التسجيل الخروج', color: Colors.grey.shade600, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                32.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required TextEditingController controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(label, color: Colors.grey.shade700, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xffE9EBEF),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: context.primary, width: 1.w),
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
        AppText.labelLarge(label, color: Colors.grey.shade700, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: _selectDate,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xffE9EBEF),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            suffixIcon: Icon(Icons.calendar_today, size: 18.sp, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: context.primary, width: 1.w),
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
        AppText.labelLarge(label, color: Colors.grey.shade700, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
        8.verticalSpace,
        Container(
          decoration: BoxDecoration(color: Color(0xffE9EBEF), borderRadius: BorderRadius.circular(12.r)),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xffE9EBEF),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: context.primary, width: 1.w),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14.sp),
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(label, color: Colors.grey.shade700, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
        8.verticalSpace,
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: context.primary, width: 1.w),
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
