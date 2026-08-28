import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_worker_extension_prompts.dart';
import 'package:dllni_cleaninig_owner_app/features/auth/domain/usecases/login_usecase_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_layout.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_gradient_hero.dart';
import '../../../../core/widgets/app_surface_card.dart';
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
  final _phoneValue = ValueNotifier<String>('');
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneValue.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit(AuthBloc bloc) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    bloc.add(
      LoginUsecaseEvent(
        params: LoginUsecaseParams(
          phone: _phoneValue.value,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.loginUsecaseStatus != BlocStatus.success) return;
          unawaited(
            CleaningWorkerExtensionPrompts.coordinator?.onAuthenticated(),
          );
          context.pushRouteAndRemoveUntil('/main');
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppSpace.pagePadding(context).add(
                  const EdgeInsetsDirectional.symmetric(vertical: AppSpace.lg),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppGradientHero(
                            title: 'أهلًا بعودتك',
                            subtitle:
                                'سجّل دخولك لمتابعة مهام التنظيف وأرباحك اليومية.',
                            trailing: Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsetsDirectional.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                              ),
                              child: AppImage.asset(
                                Assets.images.loginIcon.path,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          AppSurfaceCard(
                            emphasized: true,
                            padding: const EdgeInsetsDirectional.all(
                              AppSpace.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الدخول إلى حساب العامل',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpace.xxs),
                                Text(
                                  'استخدم رقم الجوال المسجل لدى دللني.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: AppSpace.lg),
                                Text(
                                  'رقم الجوال',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: AppSpace.xs),
                                MyPhoneNumberField(
                                  internationalPhoneValue: _phoneValue,
                                  hintText: '9XX XXX XXX',
                                  isMargin: false,
                                  textInputAction: TextInputAction.next,
                                  focusNode: _phoneFocusNode,
                                  onSubmitted: (_) =>
                                      _passwordFocusNode.requestFocus(),
                                ),
                                const SizedBox(height: AppSpace.md),
                                TextFormField(
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscurePassword,
                                  textDirection: TextDirection.ltr,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const <String>[
                                    AutofillHints.password,
                                  ],
                                  enableSuggestions: false,
                                  autocorrect: false,
                                  onFieldSubmitted: (_) =>
                                      _submit(context.read<AuthBloc>()),
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    hintText: 'أدخل كلمة المرور',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: _obscurePassword
                                          ? 'إظهار كلمة المرور'
                                          : 'إخفاء كلمة المرور',
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'الرجاء إدخال كلمة المرور'
                                      : null,
                                ),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final loading =
                                        state.loginUsecaseStatus ==
                                        BlocStatus.loading;
                                    final failed =
                                        state.loginUsecaseStatus ==
                                        BlocStatus.failed;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (failed) ...[
                                          const SizedBox(height: AppSpace.sm),
                                          Semantics(
                                            liveRegion: true,
                                            child: Text(
                                              ErrorMessageFormatter.format(
                                                state.errorMessage,
                                                fallback:
                                                    'تعذّر تسجيل الدخول. تحقق من البيانات وحاول مجددًا.',
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.error,
                                                  ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: AppSpace.lg),
                                        AppButton(
                                          label: 'تسجيل الدخول',
                                          icon: Icons.login_rounded,
                                          isLoading: loading,
                                          onPressed: loading
                                              ? null
                                              : () => _submit(
                                                  context.read<AuthBloc>(),
                                                ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                          AppButton(
                            label: 'التواصل مع الدعم الفني',
                            icon: Icons.support_agent_rounded,
                            variant: AppButtonVariant.text,
                            onPressed: () => launchSupportWhatsApp(context),
                          ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpace.xs,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    launchTermsAndConditions(context),
                                child: const Text('الشروط والأحكام'),
                              ),
                              ExcludeSemantics(
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => launchPrivacyPolicy(context),
                                child: const Text('سياسة الخصوصية'),
                              ),
                            ],
                          ),
                          Text(
                            '© 2026 دللني. جميع الحقوق محفوظة',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
