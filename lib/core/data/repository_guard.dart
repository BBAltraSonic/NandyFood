import 'package:food_delivery_app/core/errors/error_mapper.dart';
import 'package:food_delivery_app/core/results/result.dart';

mixin RepositoryGuard {
  Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Success<T>(value);
    } catch (e, stack) {
      return Err<T>(ErrorMapper.from(e, stack));
    }
  }

  Result<T> guardSync<T>(T Function() body) {
    try {
      final value = body();
      return Success<T>(value);
    } catch (e, stack) {
      return Err<T>(ErrorMapper.from(e, stack));
    }
  }
}

