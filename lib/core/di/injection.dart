import 'package:common_package/common_package.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import '../app_config.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(initializerName: r'$initGetIt', preferRelativeImports: true, asExtension: false)
Future<GetIt> configureInjection() async {
  await SharedPreferencesHelper.init();
  return $initGetIt(getIt);
}

@module
abstract class InjectableModule {
  @singleton
  DioNetwork get dio => DioNetwork(
    baseUrl: AppConfig.baseUrl,
    interceptors: [
      TokenInterceptor(
        tokenKey: 'token',
        fcmKey: 'fcm',
        lang: '',
        onRequestFunction: null,
      ),
    ],
  );
}
