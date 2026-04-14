import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/auth/domain/usecases/login_usecase_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:toastification/toastification.dart';

import '../../../../core/di/injection.dart';
import '../../../../generated/assets.dart';
import '../manager/bloc/auth_bloc.dart';

@AutoRoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          switch (state.loginUsecaseStatus) {
            case null:
              Loading.close();
              break;
            case BlocStatus.failed:
              Loading.close();
              AppToast.showToast(context: context, message: state.errorMessage ?? 'حدث خطا ما', type: ToastificationType.error);
              break;
            case BlocStatus.success:
              Loading.close();
              context.pushRouteAndRemoveUntil('/main');
              break;
            case BlocStatus.loading:
              Loading.show(context);
              break;
            case BlocStatus.init:
              Loading.close();
              break;
          }
        },
        child: Scaffold(
          backgroundColor: Color(0xffF0F0F0),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 64),
                    Container(
                      width: 80,
                      height: 80,
                      padding: EdgeInsetsDirectional.all(15.r),
                      decoration: BoxDecoration(color: Color(0xff1E2A78), borderRadius: BorderRadius.circular(16)),
                      child: AppImage.asset(Assets.images.loginIcon.path),
                    ),
                    SizedBox(height: 24),
                    AppText.headlineLarge('مرحباً بعودتك', color: Color(0xff1E2A78), fontWeight: FontWeight.bold, textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    AppText.bodyMedium('قم بتسجيل الدخول لإدارة متجرك', color: Colors.grey.shade600, textAlign: TextAlign.center),
                    SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: context.onPrimary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 6, spreadRadius: -4, offset: Offset(0, 5)),
                          BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15, spreadRadius: -3, offset: Offset(0, 10)),
                        ],
                      ),
                      padding: EdgeInsetsDirectional.all(25),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodyMedium('رقم الجوال', fontWeight: FontWeight.bold, color: Color(0xff111827), textAlign: TextAlign.start),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'أدخل رقم الجوال',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  filled: true,
                                  fillColor: context.onPrimary,
                                  contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400, size: 20),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.secondary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.error),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'الرجاء إدخال رقم الجوال';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodyMedium('كلمة المرور', fontWeight: FontWeight.bold, color: Color(0xff111827), textAlign: TextAlign.start),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'أدخل كلمة المرور',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  filled: true,
                                  fillColor: context.onPrimary,
                                  contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.secondary),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.error),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: context.error),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'الرجاء إدخال كلمة المرور';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  context.read<AuthBloc>().add(
                                    LoginUsecaseEvent(
                                      params: LoginUsecaseParams(phone: _phoneController.text, password: _passwordController.text),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Color(0xff1E2A78)),
                                  padding: EdgeInsetsDirectional.symmetric(vertical: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppText.bodyLarge('تسجيل الدخول', color: context.onPrimary, fontWeight: FontWeight.bold),
                                      8.horizontalSpace,
                                      Icon(Icons.arrow_forward, color: context.onPrimary, size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Support section
                    AppText.labelMedium('هل تواجه مشكلة في تسجيل الدخول؟', color: Colors.grey.shade600, textAlign: TextAlign.center),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () {

                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.headset_mic_outlined, color: context.secondary, size: 18),
                          SizedBox(width: 6),
                          AppText.bodyMedium('تواصل مع الدعم الفني', color: context.secondary, fontWeight: FontWeight.bold),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Copyright
                    AppText.labelSmall('© 2026 تطبيق تاجر. جميع الحقوق محفوظة', color: Colors.grey.shade500, textAlign: TextAlign.center),
                    SizedBox(height: 16),
                    // Terms and Privacy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            // TODO: Navigate to terms screen
                          },
                          child: AppText.labelSmall('الشروط والأحكام', color: context.secondary, fontWeight: FontWeight.w500),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 8),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            // TODO: Navigate to privacy policy screen
                          },
                          child: AppText.labelSmall('سياسة الخصوصية', color: context.secondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
