import 'package:coonective/package.dart';
import 'package:coonective/src/api_security.dart';
import 'package:jose/jose.dart';

import '../api_connection.dart';

/// Classe para autorização de token de usuário
class ApiUserAuthorizeToken {
  String apiUri = '';
  String token = '';
  String clientSecret = '';
  String code = '';
  String codeChallenge = '';
  String codeVerifier = '';
  String codeVerifier64 = '';
  String nonceToken = '';
  String state = '';

  ApiUserAuthorizeToken(this.token) {
    // Verifica se o token de autorização foi definido
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "039-AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "ApiUserAuthorizeToken",
        path: "ApiUserAuthorizeToken",
        variables: token,
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    // Gera um código de verificação e um desafio de código
    codeVerifier = ApiSecurity.randomBytes(32);
    codeVerifier64 = ApiSecurity.base64URLEncode(codeVerifier);
    codeChallenge = ApiSecurity.base64URLEncode(ApiSecurity.encodeSha256(codeVerifier64));

    state = ApiSecurity.randomBytes(16);
  }

  /// Verifica se o token de autorização de usuário é válido
  Future<bool> get isValid async {
    bool isValid = false;

    // Verifica se existe um token de autorização de usuário
    if (token.isNotEmpty) {
      try {
        dynamic jwt = JsonWebToken.unverified(token);
        if (jwt.claims['aud'] != null && jwt.claims['sub'] == 'auth_token') {
          apiUri = jwt.claims['aud'];
          isValid = true;
        }
      } catch (e) {
        ApiError apiError = ApiError(
          code: "040-AUTHORIZE_TOKEN_INVALID",
          messages: ['Token de autorização de usuário \'user\' inválido.'],
          module: "ApiUserAuthorizeToken",
          path: "isValid",
          variables: token,
        );
        Api.logError(
          apiError.toString(),
          error: apiError.code,
          stackTrace: StackTrace.current,
        );
        throw apiError.code;
      }
    }
    return isValid;
  }

  Future<bool> authorize() async {
    // Verifica se o token de autorização foi definido
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "041-AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "ApiUserAuthorizeToken",
        path: "authorize",
        variables: token,
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    // Recupera o clientId
    String clientId = 'guest-user3';
    ApiUser? apiUser = await ApiUser.load();

    if (apiUser != null) {
      clientId = apiUser.sessionId;
    }

    try {
      var jwt = JsonWebToken.unverified(token);
      if (jwt.claims['aud'] != null) {
        apiUri = jwt.claims['aud'];
        // Gera o clientSecret
        clientSecret = ApiSecurity.encodeSha256((clientId) + (codeVerifier64));
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "042-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização de usuário \'Client token\' inválido.'],
        module: "ApiUserAuthorizeToken",
        path: "authorize",
        variables: token,
      );
      Api.logError(
        apiError.toString(),
        error: apiError.code,
        stackTrace: StackTrace.current,
      );
      throw apiError.code;
    }

    // Conexão com a API
    //TODO: Verificar se o token de autorização é válido
    ApiConnection apiConnection = ApiConnection(token, apiUri + "/coonective");

    const String params = r"""
mutation aclAuthorize($input: AuthorizeInput!) {
  aclAuthorize(input: $input) {
    result {
      code
      nonceToken
      state
    }
    success
    error {
      code
      createdAt
      messages
      module
      path
      variables
    }
    elapsedTime
  }
}
""";
    ApiStorage? apiStorage = await ApiToken.storage;

    if (clientId.isNotEmpty && apiStorage != null) {
      apiStorage.add('clientId', clientId);
    }

    dynamic variable = {
      "input": {
        "clientId": clientId,
        "codeChallenge": codeChallenge,
        "responseType": "code",
        "scope": "mut:aclToken",
        "state": state,
      }
    };

    ApiResponse apiResponse = await apiConnection.mutation(params, variable);
    if (apiResponse.isValid()) {
      ApiEndpoint authorize = apiResponse.endpoint('aclAuthorize');
      if (authorize.isValid) {
        if (authorize.result['state'] == state) {
          code = authorize.result['code'];
          nonceToken = authorize.result['nonceToken'];
          return true;
        }
      } else {
        authorize.throwException();
      }
    } else {
      apiResponse.throwException();
    }

    return false;
  }
}
