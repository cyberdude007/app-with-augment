/// A Result type for handling success and error states
sealed class Result<T> {
  const Result();

  /// Create a success result
  const factory Result.success(T data) = Success<T>;

  /// Create an error result
  const factory Result.error(String message, [Object? error]) = Error<T>;

  /// Check if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Check if this is an error result
  bool get isError => this is Error<T>;

  /// Get the data if success, null otherwise
  T? get dataOrNull => switch (this) {
    Success<T> success => success.data,
    Error<T> _ => null,
  };

  /// Get the error message if error, null otherwise
  String? get errorOrNull => switch (this) {
    Success<T> _ => null,
    Error<T> error => error.message,
  };

  /// Transform the data if success
  Result<U> map<U>(U Function(T) transform) => switch (this) {
    Success<T> success => Result.success(transform(success.data)),
    Error<T> error => Result.error(error.message, error.error),
  };

  /// Transform the data if success, or return the error
  Result<U> flatMap<U>(Result<U> Function(T) transform) => switch (this) {
    Success<T> success => transform(success.data),
    Error<T> error => Result.error(error.message, error.error),
  };

  /// Handle both success and error cases
  U fold<U>(
    U Function(T) onSuccess,
    U Function(String, Object?) onError,
  ) => switch (this) {
    Success<T> success => onSuccess(success.data),
    Error<T> error => onError(error.message, error.error),
  };

  /// Get the data or throw an exception
  T get() => switch (this) {
    Success<T> success => success.data,
    Error<T> error => throw ResultException(error.message, error.error),
  };

  /// Get the data or return a default value
  T getOrElse(T defaultValue) => switch (this) {
    Success<T> success => success.data,
    Error<T> _ => defaultValue,
  };

  /// Get the data or compute a default value
  T getOrElseGet(T Function() defaultValue) => switch (this) {
    Success<T> success => success.data,
    Error<T> _ => defaultValue(),
  };
}

/// Success result containing data
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || 
      other is Success<T> && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Error result containing error message and optional error object
final class Error<T> extends Result<T> {
  final String message;
  final Object? error;

  const Error(this.message, [this.error]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T> && 
      message == other.message && 
      error == other.error;

  @override
  int get hashCode => Object.hash(message, error);

  @override
  String toString() => 'Error($message${error != null ? ', $error' : ''})';
}

/// Exception thrown when calling get() on an Error result
class ResultException implements Exception {
  final String message;
  final Object? cause;

  const ResultException(this.message, [this.cause]);

  @override
  String toString() => 'ResultException: $message${cause != null ? ' (caused by $cause)' : ''}';
}

/// Extension methods for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transform the data if success
  Future<Result<U>> mapAsync<U>(Future<U> Function(T) transform) async {
    final result = await this;
    return switch (result) {
      Success<T> success => Result.success(await transform(success.data)),
      Error<T> error => Result.error(error.message, error.error),
    };
  }

  /// Transform the data if success, or return the error
  Future<Result<U>> flatMapAsync<U>(Future<Result<U>> Function(T) transform) async {
    final result = await this;
    return switch (result) {
      Success<T> success => await transform(success.data),
      Error<T> error => Result.error(error.message, error.error),
    };
  }

  /// Handle both success and error cases
  Future<U> foldAsync<U>(
    Future<U> Function(T) onSuccess,
    Future<U> Function(String, Object?) onError,
  ) async {
    final result = await this;
    return switch (result) {
      Success<T> success => await onSuccess(success.data),
      Error<T> error => await onError(error.message, error.error),
    };
  }

  /// Get the data or return a default value
  Future<T> getOrElseAsync(T defaultValue) async {
    final result = await this;
    return result.getOrElse(defaultValue);
  }

  /// Get the data or compute a default value
  Future<T> getOrElseGetAsync(Future<T> Function() defaultValue) async {
    final result = await this;
    return switch (result) {
      Success<T> success => success.data,
      Error<T> _ => await defaultValue(),
    };
  }
}

/// Utility functions for working with Results
class Results {
  Results._();

  /// Combine multiple results into a single result containing a list
  static Result<List<T>> combine<T>(List<Result<T>> results) {
    final data = <T>[];
    
    for (final result in results) {
      switch (result) {
        case Success<T> success:
          data.add(success.data);
        case Error<T> error:
          return Result.error(error.message, error.error);
      }
    }
    
    return Result.success(data);
  }

  /// Try to execute a function and wrap the result
  static Result<T> tryCall<T>(T Function() fn) {
    try {
      return Result.success(fn());
    } catch (e, stackTrace) {
      return Result.error(e.toString(), e);
    }
  }

  /// Try to execute an async function and wrap the result
  static Future<Result<T>> tryCallAsync<T>(Future<T> Function() fn) async {
    try {
      final result = await fn();
      return Result.success(result);
    } catch (e, stackTrace) {
      return Result.error(e.toString(), e);
    }
  }

  /// Create a success result
  static Result<T> success<T>(T data) => Result.success(data);

  /// Create an error result
  static Result<T> error<T>(String message, [Object? error]) => Result.error(message, error);

  /// Create a result from a nullable value
  static Result<T> fromNullable<T>(T? value, String errorMessage) {
    return value != null ? Result.success(value) : Result.error(errorMessage);
  }
}

/// Extension methods for nullable values
extension NullableExtension<T> on T? {
  /// Convert nullable to Result
  Result<T> toResult(String errorMessage) {
    return Results.fromNullable(this, errorMessage);
  }
}

/// Extension methods for boolean values
extension BooleanResultExtension on bool {
  /// Convert boolean to Result
  Result<void> toResult(String errorMessage) {
    return this ? const Result.success(null) : Result.error(errorMessage);
  }
}

/// Extension methods for Iterable<Result<T>>
extension IterableResultExtension<T> on Iterable<Result<T>> {
  /// Combine all results into a single result containing a list
  Result<List<T>> combine() => Results.combine(toList());

  /// Get all successful results
  List<T> successes() => whereType<Success<T>>().map((s) => s.data).toList();

  /// Get all error results
  List<Error<T>> errors() => whereType<Error<T>>().toList();

  /// Check if all results are successful
  bool get allSuccess => every((result) => result.isSuccess);

  /// Check if any result is an error
  bool get anyError => any((result) => result.isError);
}
