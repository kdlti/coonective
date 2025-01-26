// Classe Success
// Representa um caso de sucesso e armazena o valor do tipo "TSuccess".
import 'package:coonective/package.dart';

class ApiSuccess<TSuccess> {
  final TSuccess value; // O valor associado ao sucesso.
  ApiSuccess(this.value);
}

// Classe Failure
// Representa um caso de falha e armazena o valor do tipo "TFailure".
class ApiFailure<TFailure> {
  final TFailure value; // O valor associado à falha.
  ApiFailure(this.value);
}

/// Classe central que representa o resultado de uma operação,
/// podendo ser sucesso (com valor de tipo [TSuccess]) ou falha
/// (com valor de tipo [TFailure]).
class ApiResult<TSuccess, TFailure> {
  final TSuccess? success;
  final TFailure? failure;
  final ApiPagination pagination;

  const ApiResult._({
    this.success,
    this.failure,
    this.pagination = const ApiPagination(),
  });

  /// Construtor de sucesso.
  factory ApiResult.success(TSuccess data, {ApiPagination? pagination}) {
    return ApiResult._(
      success: data,
      pagination: pagination ?? const ApiPagination(),
    );
  }

  /// Construtor de falha.
  factory ApiResult.failure(TFailure error, {ApiPagination? pagination}) {
    return ApiResult._(
      failure: error,
      pagination: pagination ?? const ApiPagination(),
    );
  }

  /// Getter que indica se houve sucesso.
  bool get isSuccess => success != null && failure == null;

  /// Getter que indica se houve falha.
  bool get isFailure => failure != null && success == null;

  /// Função para "destruir" (ou mapear) o resultado,
  /// chamando o callback correspondente (onSuccess ou onFailure).
  R fold<R>({
    required R Function(TSuccess data, ApiPagination pagination) onSuccess,
    required R Function(TFailure error, ApiPagination pagination) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(success as TSuccess, pagination);
    } else {
      return onFailure(failure as TFailure, pagination);
    }
  }

  /// Retorna uma representação em string do resultado.
  @override
  String toString() {
    return 'ApiResult(success: $success, failure: $failure, pagination: $pagination)';
  }
}