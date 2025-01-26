import 'package:coonective/package.dart';
import 'package:coonective/src/client/api_client.dart';
import 'package:jose/jose.dart';

import '../api_connection.dart';
import '../client/api_client_authorize_token.dart';

class ApiClientAccessToken {
  ApiClientAuthorizeToken apiClientAuthorize;
  String clientId = 'guest-client1';
  String tokenType = '';
  String expiresIn = '';
  String accessToken = '';
  String refreshToken = '';

  ApiClientAccessToken(this.apiClientAuthorize) {
    clientId = apiClientAuthorize.clientId;
  }

  ///Verifica se existe um token de acesso de cliente registrado na sessão local da aplicação
  ///Verifica se o token tem identificação do distribuidor e se o subject é do tipo access_token
  static Future<bool> get isValid async {
    String? accessToken = await ApiClient.getAccessToken;

    bool isValid = false;
    if (accessToken!.isNotEmpty) {
      try {
        var jwt = JsonWebToken.unverified(accessToken);
        if (jwt.claims['aud'] != null && jwt.claims['sub'] == 'access_token') {
          isValid = true;
        }
      } catch (e) {
        ApiError apiError = ApiError(
          code: "034-INVALID_ACCESS_TOKEN",
          messages: ["Token de acesso da aplicação 'client' inválido."],
          module: "ApiClientAccessToken",
          path: "isValid",
          variables: accessToken,
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

  static Future<bool> get ready async {
    String? accessToken = await ApiClient.getAccessToken;
    bool isReady = false;
    if (accessToken!.isNotEmpty) {
      try {
        var jwt = JsonWebToken.unverified(accessToken);
        if (jwt.claims['aud'] != null && jwt.claims['sub'] == 'access_token') {
          isReady = true;
        }
      } catch (e) {
        ApiError apiError = ApiError(
          code: "035-INVALID_ACCESS_TOKEN",
          messages: ["Token de acesso da aplicação 'client' inválido."],
          module: "ApiClientAccessToken",
          path: "ready",
          variables: accessToken,
        );
        Api.logError(
          apiError.toString(),
          error: apiError.code,
          stackTrace: StackTrace.current,
        );
        throw apiError.code;
      }
    }
    return isReady;
  }

  Future<String> token() async {
    ApiConnection apiConnection = ApiConnection(apiClientAuthorize.nonceToken, apiClientAuthorize.apiUri);

    const String params = r"""
mutation aclToken($input: AclTokenInput!) {
  aclToken(input: $input) {
    result {
      accessToken
      expiresIn
      refreshToken
      tokenType
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
    dynamic variable = {
      "input": {
        "clientId": apiClientAuthorize.clientId,
        "clientSecret": apiClientAuthorize.clientSecret,
        "code": apiClientAuthorize.code,
        "codeVerifier": apiClientAuthorize.codeVerifier64,
        "grantType": 'authorization_code'
      }
    };

    ApiResponse apiResponse = await apiConnection.mutation(params, variable);
    if (apiResponse.isValid()) {
      ApiEndpoint token = apiResponse.endpoint('aclToken');
      if (token.isValid) {
        tokenType = token.result['tokenType'];
        expiresIn = token.result['expiresIn'];
        accessToken = token.result['accessToken'];
        refreshToken = token.result['refreshToken'];

        ApiStorage? apiStorage = await ApiClient.storage;
        if (apiStorage != null) {
          apiStorage.add('accessToken', accessToken);
          apiStorage.add('refreshToken', refreshToken);
        }
      }else{
        token.throwException();
      }
    } else {
      apiResponse.throwException();
    }

    return accessToken;
  }
}
