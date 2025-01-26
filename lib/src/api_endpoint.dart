import 'package:coonective/package.dart';

class ApiEndpoint {
  bool success = false;
  ApiError? error;
  dynamic result;
  dynamic pagination;
  dynamic elapsedTime;

  ApiEndpoint(dynamic value) {
    if (value['success'] == null) {
      ApiError apiError = ApiError(
        code: "019-SUCCESS_NOT_FOUND",
        path: "ApiEndpoint",
        messages: ["O parametro 'success' não foi encontrado no resultado da query/mutation de interação com a base de dados."],
        module: "ApiEndpoint",
        variables: value,
      );

      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    if (value != null) {
      success = value['success'];
      result = value['result'];
      pagination = value['pagination'];
      elapsedTime = value['elapsedTime'];

      if (value['error'] != null) {
        error = ApiError(
          createdAt: value['error']['createdAt'],
          code: "020-${value['error']['code']}",
          path: value['error']['path'],
          messages: value['error']['messages'],
          module: value['error']['module'],
          variables: value['error']['variables'],
        );
      }
    }
  }

  bool get isValid {
    return success && result != null && error == null;
  }

  void throwException() {
    if (error != null) {
      Api.logError(
        error.toString(),
        error: error!.code,
        stackTrace: StackTrace.current,
      );
      throw error!.code;
    }
  }

  @override
  String toString() {
    return 'Instance of ApiEndpoint(result:$result, success:$success, error:$error)';
  }
}
