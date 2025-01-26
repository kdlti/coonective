import 'package:coonective/package.dart';
import 'package:coonective/src/api_security.dart';
import 'package:coonective/src/user/api_user_access_token.dart';
import 'package:coonective/src/user/api_user_authorize_token.dart';

// A classe ApiToken representa o token utilizado para autenticação e autorização do usuário da API.
class ApiToken {
  //String clientId = "DEV";

  // A instância única desta classe (singleton)
  static ApiToken? _instance;

  // Construtor factory que cria a instância única desta classe, se necessário, e inicializa com os dados fornecidos.
  factory ApiToken({dynamic config}) {
    _instance ??= ApiToken._internalConstructor();

    /*if (config != null) {
      _instance!._init(config);
    }*/
    return _instance!;
  }

  // Construtor interno para criar a instância única desta classe.
  ApiToken._internalConstructor();

  // Método para validar o token de autorização e obter o token de acesso e autenticação.
  void authorize() async {
    String? accessToken = await ApiToken.getAccessToken;
    if (!accessToken!.isNotEmpty) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização da aplicação \'client\' inválido.'],
          code: "030-INVALID_CLIENT_AUTHORIZATION_TOKEN",
          module: "apiToken",
          path: "authorize",
          variables: accessToken);
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    ApiUserAuthorizeToken apiUserAuthorizeToken = ApiUserAuthorizeToken(accessToken);
    if (!await apiUserAuthorizeToken.isValid) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização do usuário \'user\' inválido.'],
          code: "031-INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiToken",
          path: "authorize",
          variables: accessToken);
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    await handleAuthorization(apiUserAuthorizeToken);
  }

  // Função para lidar com a autorização e obter o token de acesso.
  Future<void> handleAuthorization(ApiUserAuthorizeToken apiUserAuthorizeToken) async {
    bool isAuthorizeValid = await apiUserAuthorizeToken.authorize();
    if (!isAuthorizeValid) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização do usuário \'user\' inválido'],
          code: "032-INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiToken",
          path: "handleAuthorization",
          variables: {"isAuthorizeValid": isAuthorizeValid});
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
    await handleAccessToken(apiUserAuthorizeToken);
  }

  // Função para lidar com o token de acesso e validá-lo.
  Future<void> handleAccessToken(ApiUserAuthorizeToken apiUserAuthorizeToken) async {
    ApiUserAccessToken apiUserAccessToken = ApiUserAccessToken(apiUserAuthorizeToken);
    bool isTokenValid = await apiUserAccessToken.token();
    if (!isTokenValid) {
      ApiError apiError = ApiError(
          messages: ['Token de autorização do usuário \'user\' inválido'],
          code: "033-INVALID_USER_AUTHORIZATION_TOKEN",
          module: "apiToken",
          path: "handleAccessToken",
          variables: {"isAuthorizeValid": !isTokenValid});
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }
  }

  // Método para obter a instância do ApiStorage com o nome 'user'.
  static Future<ApiStorage?> get storage async {
    return await ApiStorage.init(name: 'coonective');
  }

  // Método para obter o token de acesso do usuário.
  static Future<String?> get getAccessToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('accessToken');
  }

  // Método para salvar o token de acesso do usuário.
  static void accessToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('accessToken', value);
  }

  // Método para obter o token de autenticação do usuário.
  static Future<String?> get getAuthToken async {
    ApiStorage? apiStorage = await storage;
    return apiStorage!.read('authToken');
  }

  // Método para salvar o token de autenticação do usuário.
  static void authToken(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('authToken', value);
  }

  // Método para salvar o URI do servidor.
  static void serverUri(String value) async {
    ApiStorage? apiStorage = await storage;
    apiStorage!.add('serverUri', value);
  }
}
