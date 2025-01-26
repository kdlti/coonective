import 'package:coonective/package.dart';


//TODO:: Verificar se essa classe precisa existir, comparar com a classe ApiEndpoint

class ApiEndpointMatrix {
  bool success = true;
  ApiError? error;
  dynamic result;

  ApiEndpointMatrix(dynamic value) {
    if (value != null) {
      if (value == null) {
        ApiError apiError = ApiError(
          code: "021-RESULT_NOT_FOUND",
          path: "ApiEndpointMatrix",
          messages: ["O parametro 'result' não foi encontrado no resultado da query/mutation de interação com a base de dados."],
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

      result = value;
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
