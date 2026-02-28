import 'package:common_package/common_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      child: Icon(Icons.arrow_back_ios, color: context.primary, size: 20),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: AppText.titleLarge('حسابك', color: context.primary, fontWeight: FontWeight.w700, textAlign: TextAlign.start),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppText.bodyLarge('مرحبا ${widget.params.name} !', color: context.primary, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: const NetworkImage('https://via.placeholder.com/100'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppText.labelMedium('التعديل صورة الملف الشخصي', color: Colors.grey.shade600, textAlign: TextAlign.center),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildFormField(label: 'الاسم', controller: _nameController),
                const SizedBox(height: 16),
                _buildFormField(label: 'البريد الإلكاروني', controller: _emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildDateField(label: 'تاريخ الميلاد', controller: _dateOfBirthController),
                const SizedBox(height: 16),
                _buildFormField(label: 'رقم الهاتف', controller: _phoneController, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                _buildFormField(label: 'مدينتك', controller: _cityMeController, keyboardType: TextInputType.text),
                const SizedBox(height: 16),
                _buildTextAreaField(label: 'نبذة عني', controller: _aboutMeController),
                const SizedBox(height: 32),
                InkWell(
                  onTap: () {
                    if (_formKey.currentState!.validate()) {}
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: context.primary, borderRadius: BorderRadius.circular(12)),
                    child: AppText.labelLarge('حفظ', color: context.onPrimary, fontWeight: FontWeight.w500, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        AppText.labelMedium('التسجيل الخروج', color: Colors.grey.shade600, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xffE9EBEF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primary, width: 1),
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: _selectDate,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xffE9EBEF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primary, width: 1),
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Color(0xffE9EBEF), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xffE9EBEF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.primary, width: 1),
              ),
            ),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
            style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primary, width: 1),
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
