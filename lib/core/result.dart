/// Ini tipe hasil (Result) yang bisa sukses atau gagal.
///
/// Biasanya dipakai buat handle operasi yang bisa error,
/// jadi gampang bedain mana yang sukses dan mana yang gagal.
class Result<T> {
  /// Nilai hasil kalau sukses
  final T? _value;

  /// Pesan error kalau gagal
  final String? _error;

  /// True kalau hasilnya sukses
  final bool isSuccess;

  /// Constructor privat buat bikin hasil sukses
  const Result._success(this._value)
      : _error = null,
        isSuccess = true;

  /// Constructor privat buat bikin hasil gagal
  const Result._failure(this._error)
      : _value = null,
        isSuccess = false;

  /// Bikin hasil sukses dengan nilai yang dikasih
  factory Result.success(T value) {
    return Result._success(value);
  }

  /// Bikin hasil gagal dengan pesan error
  factory Result.failure(String error) {
    return Result._failure(error);
  }

  /// Ambil nilai kalau sukses, kalau gagal lempar error
  T get valueOrThrow {
    if (isSuccess) {
      return _value as T;
    }
    throw StateError('Cannot get value from a failed result: $_error');
  }

  /// Ambil nilai kalau sukses, kalau gagal pakai default
  T valueOrDefault(T defaultValue) {
    return isSuccess ? (_value as T) : defaultValue;
  }

  /// Ambil nilai kalau sukses, kalau gagal null
  T? get valueOrNull {
    return isSuccess ? (_value as T) : null;
  }

  /// Ambil pesan error kalau gagal, kalau sukses lempar error
  String get errorOrThrow {
    if (!isSuccess) {
      return _error!;
    }
    throw StateError('Cannot get error from a successful result');
  }

  /// Returns the error message if this result is a failure,
  /// otherwise returns null.
  String? get errorOrNull {
    return isSuccess ? null : _error;
  }

  /// Returns the error message if this result is a failure,
  /// otherwise returns the provided error message.
  String errorOrDefault(String defaultError) {
    return isSuccess ? defaultError : _error!;
  }

  /// Transforms the success value using the provided function.
  ///
  /// If this result is a failure, the failure is propagated unchanged.
  Result<R> map<R>(R Function(T value) transform) {
    if (isSuccess) {
      try {
        return Result.success(transform(_value as T));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(_error!);
  }

  /// Transforms the success value using the provided async function.
  ///
  /// If this result is a failure, the failure is propagated unchanged.
  Future<Result<R>> mapAsync<R>(Future<R> Function(T value) transform) async {
    if (isSuccess) {
      try {
        final result = await transform(_value as T);
        return Result.success(result);
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(_error!);
  }

  /// Executes the provided function if this result is successful.
  ///
  /// Returns this result unchanged.
  Result<T> onSuccess(void Function(T value) action) {
    if (isSuccess) {
      action(_value as T);
    }
    return this;
  }

  /// Executes the provided function if this result is a failure.
  ///
  /// Returns this result unchanged.
  Result<T> onFailure(void Function(String error) action) {
    if (!isSuccess) {
      action(_error!);
    }
    return this;
  }

  /// Executes the appropriate function based on the result state.
  ///
  /// Returns the result of the executed function.
  R fold<R>(R Function(T value) onSuccess, R Function(String error) onFailure) {
    if (isSuccess) {
      return onSuccess(_value as T);
    }
    return onFailure(_error!);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'Result.success($_value)';
    }
    return 'Result.failure($_error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result<T> &&
        other.isSuccess == isSuccess &&
        other._value == _value &&
        other._error == _error;
  }

  @override
  int get hashCode => Object.hash(isSuccess, _value, _error);
}
