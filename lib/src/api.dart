import 'package:coonective/package.dart';
import 'package:coonective/src/api_params.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class Api {
  /// Método utilitário para logar mensagens de erro.
  static get logError => Logger(
        printer: PrettyPrinter(),
      ).e;

  /// Método utilitário para logar mensagens de informação.
  static get logInfo => Logger(
        printer: PrettyPrinter(),
      ).i;

  /// Método utilitário para logar mensagens de depuração.
  static get logDebug => Logger(
        printer: PrettyPrinter(),
      ).d;

  /// Método utilitário para logar mensagens de aviso.
  static get logWarning => Logger(
        printer: PrettyPrinter(),
      ).w;

  /// Método utilitário que encapsula a validação de [ApiResponse] e [ApiEndpoint].
  /// Se o [apiResponse] ou o [endpoint] forem inválidos, será lançada uma exceção.
  static ApiEndpoint response(ApiResponse apiResponse, String endpointName) {
    if (!apiResponse.isValid()) {
      apiResponse.throwException();
    }

    ApiEndpoint apiEndpoint = apiResponse.endpoint(endpointName);

    if (kDebugMode) {
      if (!apiEndpoint.isValid) {
        apiEndpoint.throwException();
      }
    }
    return apiEndpoint;
  }

  /// Método privado genérico para centralizar chamada de API e tratamento de erros.
  /// serviceCall: função que chama o serviço
  /// onSuccess: função que processa o resultado
  /// code: código do erro
  /// path: caminho do erro
  /// module: módulo do erro
  /// Retorna um [ApiResult] com [ApiSuccess] ou [ApiFailure]
  static Future<ApiResult<ApiSuccess<T>, ApiFailure<ApiError>>> call<T>({
    required Future<ApiEndpoint> Function() serviceCall,
    required T Function(dynamic) onSuccess,
    required String path,
    required String module,
    required ValueChanged<bool> onLoading,
  }) async {
    try {
      onLoading(true);
      final ApiEndpoint apiEndpoint = await serviceCall();
      if (apiEndpoint.success) {
        final data = onSuccess(apiEndpoint.result);

        /// Processa a paginação
        ApiPagination pagination = const ApiPagination();
        if (apiEndpoint.pagination != null) {
          pagination = ApiPagination(
            limit: apiEndpoint.pagination["limit"] ?? 0,
            page: apiEndpoint.pagination["page"] ?? 0,
            total: apiEndpoint.pagination["total"] ?? 0,
            next: apiEndpoint.pagination["next"] ?? 0,
            previous: apiEndpoint.pagination["previous"] ?? 0,
            pages: apiEndpoint.pagination["pages"] ?? 0,
          );
        }
        onLoading(false);
        return ApiResult.success(ApiSuccess(data), pagination: pagination);
      } else {
        onLoading(false);
        return ApiResult.failure(ApiFailure(apiEndpoint.error!));
      }
    } catch (e, stack) {
      print('ApiError: $e');
      final apiError = ApiError(
        code: module,
        path: path,
        module: module,
        messages: [e.toString()],
      );
      onLoading(false);
      return ApiResult.failure(ApiFailure(apiError));
    }
  }

  /// Processa uma lista [data] usando a função de criação [factoryMethod].
  /// Adiciona a chave 'index' para cada item, criando uma nova cópia do Map original.
  static List<T> addIndex<T>(List<dynamic> data, T Function(Map<String, dynamic>) factoryMethod) {
    final List<T> items = [];
    for (int i = 0; i < data.length; i++) {
      final mapCopy = Map<String, dynamic>.from(data[i]);
      mapCopy['index'] = i + 1;
      items.add(factoryMethod(mapCopy));
    }
    return items;
  }

  static Future<ApiResponse> dao(String graphQL, dynamic variable) async {
    ApiParams apiParams = ApiParams(graphQL);

    if (apiParams.isValid()) {
      if (apiParams.module.toLowerCase() == 'query') {
        ApiResponse apiResponse = await ApiConnect.exec(
          apiGraphql: ({required String accessToken, required String serverUri}) async {
            return await ApiConnect.query(graphQL, variable, accessToken, serverUri);
          },
        );

        return apiResponse;
      } else if (apiParams.module.toLowerCase() == 'mutation') {
        ApiResponse apiResponse = await ApiConnect.exec(
          apiGraphql: ({required String accessToken, required String serverUri}) async {
            return await ApiConnect.mutation(graphQL, variable, accessToken, serverUri);
          },
        );
        return apiResponse;
      }
    }

    return ApiResponse(
      success: false,
      errors: [
        ApiError(
          path: apiParams.path,
          messages: ["Falha de configuração do graphQL"],
          module: apiParams.module,
          code: "DAO_ERROR",
          variables: variable,
        ),
      ],
    );
  }

  //TODO:: Verificar se é necessário
  static Future<ApiResponse> daoMatrix(String graphQL, dynamic variable) async {
    ApiResponse apiResponse = await ApiConnect.exec(
      apiGraphql: ({required String accessToken, required String serverUri}) async {
        return await ApiConnect.query(graphQL, variable, accessToken, serverUri);
      },
    );
    return apiResponse;
  }

  static Stream<ApiResponse> subscription(String graphQL, dynamic variable) {
    return ApiConnect.execSubscription(apiGraphql: ({required String accessToken, required String serverUri}) async* {
      yield* ApiConnect.subscription(graphQL, variable, accessToken, serverUri);
    });
  }
}
