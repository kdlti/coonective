import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:coonective/package.dart';
import 'package:coonective/src/api_connection.dart';
import 'package:coonective/src/client/api_client_access_token.dart';
import 'package:coonective/src/client/api_client_authorize_token.dart';
import 'package:coonective/src/user/api_user_access_token.dart';
import 'package:coonective/src/user/api_user_authorize_token.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Classe ApiConnect gerencia a conexão com a API.
class ApiConnect {
  static final ApiConnect _instance = ApiConnect._internalConstructor();

  late ApiClientAccessToken apiClientAccessToken;
  late ApiClientAuthorizeToken apiClientAuthorize;

  // Construtor da fábrica ApiConnect.
  factory ApiConnect([String authToken = ""]) {
    if (authToken.isNotEmpty) {
      _instance._init(authToken);
    }
    return _instance;
  }

  // Construtor interno ApiConnect.
  ApiConnect._internalConstructor();

  // Inicializa a conexão com a API.
  Future<void> _init(String authToken) async {
    await validateClientToken(authToken);
  }

  Future<void> validateClientToken(String authToken) async {
    // Inicializa a verificação de autorização do token da aplicação.
    // Verifica se o token de autorização foi definido
    // Gera um código de verificação e um desafio de código
    apiClientAuthorize = ApiClientAuthorizeToken(authToken);

    // Verifica se o token de autorização foi definido e se é válido
    if (!await apiClientAuthorize.isValid) {
      ApiError apiError = ApiError(
        code: "002-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"apiClientAuthorize.isValid": apiClientAuthorize.isValid},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    bool isAuthorized = await apiClientAuthorize.aclAuthorize();
    if (!isAuthorized) {
      ApiError apiError = ApiError(
        code: "003-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"isAuthorized": isAuthorized},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    apiClientAccessToken = ApiClientAccessToken(apiClientAuthorize);
    String accessToken = await apiClientAccessToken.token();

    if (!accessToken.isNotEmpty) {
      ApiError apiError = ApiError(
        code: "004-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"accessToken": accessToken},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
  }

  Future<void> validateUserToken(String authToken) async {
    // Cria a classe para autorização de token de usuário
    // Verifica se o token de autorização foi definido
    // Gera um código de verificação e um desafio de código
    ApiUserAuthorizeToken apiUserAuthorizeToken = ApiUserAuthorizeToken(authToken);

    // Verifica se o token de autorização foi definido e se é válido
    if (!await apiUserAuthorizeToken.isValid) {
      ApiError apiError = ApiError(
        code: "005-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da usuário \'user\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"apiUserAuthorizeToken.isValid": apiUserAuthorizeToken.isValid, "accessToken": authToken},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
    bool isAuthorizeValid = await apiUserAuthorizeToken.authorize();
    if (!isAuthorizeValid) {
      ApiError apiError = ApiError(
        code: "006-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da usuário \'user\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"isAuthorizeValid": !isAuthorizeValid, "accessToken": authToken},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
    ApiUserAccessToken apiUserAccessToken = ApiUserAccessToken(apiUserAuthorizeToken);
    bool isTokenValid = await apiUserAccessToken.token();
    if (!isTokenValid) {
      ApiError apiError = ApiError(
        code: "007-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
        path: "_init",
        variables: {"isTokenValid": !isTokenValid, "accessToken": authToken},
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
  }

  // Realiza uma consulta GraphQL.
  static Future<ApiResponse> query(String params, dynamic variable, String accessToken, String serverUri) async {
    ApiConnection apiConnection = ApiConnection(accessToken, serverUri);
    return apiConnection.query(params, variable);
  }

  // Realiza uma mutação GraphQL.
  static Future<ApiResponse> mutation(String params, dynamic variable, String accessToken, String serverUri) async {
    ApiConnection apiConnection = ApiConnection(accessToken, serverUri);
    return apiConnection.mutation(params, variable);
  }

  // Realiza uma assiantura GraphQL.
  static Stream<ApiResponse> subscription(String params, dynamic variable, String accessToken, String serverUri) async* {
    ApiConnection apiConnection = ApiConnection(accessToken, serverUri);
    yield* apiConnection.subscription(params, variable);
  }

  // Executa a consulta ou mutação GraphQL e trata exceções.
  static Future<ApiResponse> exec({required Function({required String accessToken, required String serverUri}) apiGraphql}) async {
    bool hasConnectivity = await checkInternetConnection();
    ApiResponse apiResponse = ApiResponse();

    // Verifica se o token de acesso está definido
    String? accessToken = await ApiToken.getAccessToken;

    if (accessToken == null || accessToken.isEmpty) {
      ApiError apiError = ApiError(
        code: "008-EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", "accessToken vazio"],
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    // Recupera o servidor URI
    String? serverUri = dotenv.get("SERVER_URI");

    // Verifica se o servidor URI está definido
    //TODO: Verificar validação de URI, parece que não está funcionando como esperado
    if (serverUri == null && serverUri!.isEmpty) {
      ApiError apiError = ApiError(
        code: "009-EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", "serverUri vazio"],
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    try {
      if (hasConnectivity) {
        apiResponse = await apiGraphql(accessToken: accessToken, serverUri: serverUri);
      } else {
        apiResponse = ApiResponse(
          errors: [
            ApiError(
              code: "010-NO_INTERNET_CONNECTION",
              module: "apiConnect",
              path: "exec",
              messages: ["Sem conexão com a Internet"],
            ),
          ],
        );
      }
    } catch (e) {
      print("ERROR: $e");
      ApiError apiError = ApiError(
        code: "011-EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", e.toString()],
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
    return apiResponse;
  }

  static Stream<ApiResponse> execSubscription({required Stream<ApiResponse> Function({required String accessToken, required String serverUri}) apiGraphql}) async* {
    final hasConnectivity = await checkInternetConnection();

    if (!hasConnectivity) {
      yield ApiResponse(
        success: false,
        errors: [
          ApiError(
            code: "012-NO_INTERNET_CONNECTION",
            module: "apiConnect",
            path: "exec AAA",
            messages: ["Sem conexão com a Internet"],
          ),
        ],
      );
      return;
    }

    // Verifica se o token de acesso está definido
    String? accessToken = await ApiToken.getAccessToken;

    if (accessToken == null || accessToken.isEmpty) {
      ApiError apiError = ApiError(
        code: "008-EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", "accessToken vazio"],
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    // Recupera o servidor URI
    String? serverUri = dotenv.get("SERVER_URI");

    // Verifica se o servidor URI está definido
    if (serverUri.isEmpty) {
      ApiError apiError = ApiError(
        code: "009-EXCEPTION",
        module: "apiConnect",
        path: "exec",
        messages: ["Falha na conexão com servidor API", "serverUri vazio"],
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    try {
      yield* apiGraphql(accessToken: accessToken, serverUri: serverUri);
    } catch (e) {
      yield ApiResponse(
        success: false,
        errors: [
          ApiError(
            code: "013-EXCEPTION",
            module: "apiConnect",
            path: "exec EEE",
            messages: ["Falha na conexão com servidor API", e.toString()],
          ),
        ],
      );
    }
  }

  // Verifica se há conexão com a Internet.
  static Future<bool> checkInternetConnection() async {
    bool hasConnectivity = false;
    //Verifica se é serviço web
    if (kIsWeb) {
      hasConnectivity = true;
    } else {
      List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
      //Verifica se tem conexão mobile ou wifi
      if (connectivityResult.contains(ConnectivityResult.mobile) || connectivityResult.contains(ConnectivityResult.wifi)) {
        hasConnectivity = true;
      }
    }
    return hasConnectivity;
  }
}
