import 'package:dartz/dartz.dart';

import 'error_handler.dart';

typedef FromJson<T> = T Function(dynamic body);

typedef QueryParams = Map<String, dynamic>;

typedef BodyMap = Map<String, dynamic>;

typedef DataResponse<T> = Future<Either<Failure, T>>;

abstract class UseCase<ResultType, ParamsType> {
  DataResponse<ResultType> call(ParamsType params);
}

mixin Params {
  BodyMap getBody() => {};

  QueryParams getParams() => {};
}

class NoParams with Params {}
