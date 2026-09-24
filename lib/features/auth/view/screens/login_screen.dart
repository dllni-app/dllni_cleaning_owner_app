import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/features/auth/domain/usecases/login_usecase_use_case.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/worker_app_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/legal_links_launcher.dart';
import '../../../../core/widgets/phone_number_widget/my_phone_number_field_widget.dart';
import '../../../../core/widgets/worker_technical_support_call_button.dart';
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
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final ValueNotifier<String> phoneValue;
  late final FocusNode phoneFocusNode;
  late final FocusNode passwordFocus;

  @override
  void initState() {
    phoneValue = ValueNotifier('');
    phoneFocusNode = FocusNode();
    passwordFocus = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    phoneValue.dispose();
    phoneFocusNode.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthBloc bloc) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    bloc.add(
      LoginUsecaseEvent(
        params: LoginUsecaseParams(
          phone: phoneValue.value,
          password: _passwordController.text,
        ),
      ),
    );
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
              break;
            case BlocStatus.success:
              Loading.close();
              unawaited(
                CleaningWorkerExtensionPrompts.coordinator?.onAuthenticated(),
              );
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
          backgroundColor: WorkerAppColors.canvas,
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
                      decoration: BoxDecoration(
                        color: WorkerAppColors.brandPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AppImage.asset(Assets.images.loginIcon.path),
                    ),
                    SizedBox(height: 24),
                    AppText.headlineLarge(
                      'مرحباً بعودتك',
                      color: WorkerAppColors.brandPrimary,
                      fontWeight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    AppText.bodyMedium(
                      'قم بتسجيل الدخول لإدارة متجرك',
                      color: WorkerAppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: WorkerAppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 6,
                            spreadRadius: -4,
                            offset: Offset(0, 5),
                          ),
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 15,
                            spreadRadius: -3,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsetsDirectional.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppText.bodyMedium(
                                'رقم الجوال',
                                fontWeight: FontWeight.w500,
                              ),
                              AppText.bodyMedium(
                                '*',
                                color: context.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          MyPhoneNumberField(
                            internationalPhoneValue: phoneValue,
                            hintText: 'رقم الجوال',
                            isMargin: false,
                            textInputAction: TextInputAction.next,
                            focusNode: phoneFocusNode,
                            onSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(passwordFocus),
                          ),
                          SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodyMedium(
                                'كلمة المرور',
                                fontWeight: FontWeight.bold,
                                color: Color(0xff111827),
                                textAlign: TextAlign.start,
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                focusNode: passwordFocus,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    passwordFocus.unfocus(),
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textDirection: TextDirection.ltr,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'أدخل كلمة المرور',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: context.onPrimary,
                                  contentPadding:
                                      EdgeInsetsDirectional.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: WorkerAppColors.brandPrimary,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: context.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: context.error,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'الرجاء إدخال كلمة المرور'
                                    : null,
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async =>
                                    _submit(context.read<AuthBloc>()),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: WorkerAppColors.brandPrimary,
                                  ),
                                  padding: EdgeInsetsDirectional.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppText.bodyLarge(
                                        'تسجيل الدخول',
                                        color: WorkerAppColors.surface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      8.horizontalSpace,
                                      Icon(
                                        Icons.arrow_forward,
                                        color: WorkerAppColors.surface,
                                        size: 20,
                                      ),
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
                    AppText.labelMedium(
                      'هل تواجه مشكلة في تسجيل الدخول؟',
                      color: WorkerAppColors.textSecondary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async => launchSupportWhatsApp(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.headset_mic_outlined,
                              color: WorkerAppColors.brandPrimary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            AppText.bodyMedium(
                              'تواصل مع الدعم الفني',
                              color: WorkerAppColors.brandPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    AppText.labelSmall(
                      '© 2026 تطبيق تاجر. جميع الحقوق محفوظة',
                      color: WorkerAppColors.textTertiary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => launchTermsAndConditions(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: AppText.labelSmall(
                            'الشروط والأحكام',
                            color: WorkerAppColors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                          ),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => launchPrivacyPolicy(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: AppText.labelSmall(
                            'سياسة الخصوصية',
                            color: WorkerAppColors.brandPrimary,
                            fontWeight: FontWeight.w500,
                          ),
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
