import 'package:coonective/package.dart';
import 'package:coonective/src/api_security.dart';
import 'package:coonective/src/client/api_client.dart';
import 'package:jose/jose.dart';

import '../api_connection.dart';

class ApiClientAuthorizeToken {
  String apiUri = '';
  String token = '';
  String clientId = 'guest-client2';
  String clientSecret = '';
  String code = '';
  String codeChallenge = '';
  String codeVerifier = '';
  String codeVerifier64 = '';
  String nonceToken = '';
  String state = '';
  String context = '';
  String subject = '';

  ApiClientAuthorizeToken(this.token) {
    // Verifica se o token de autorização foi definido
    if (token.isEmpty) {
      ApiError apiError = ApiError(
        code: "039-AUTHORIZE_TOKEN_NOT_FOUND",
        messages: ['Nenhum token de \'autorização\' foi definido na inicialização da aplicação.'],
        module: "apiClientAuthorizeToken",
        path: "ApiClientAuthorizeToken",
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

  ///Verifica se existe um token de autorização de cliente registrado na sessão local da aplicação
  ///Verifica se o token tem identificação do distribuidor e se o subject é do tipo auth_token
  Future<bool> get isValid async {
    if (token.isEmpty) {
      return false;
    }

    bool isValid = false;

    try {
      dynamic jwt = JsonWebToken.unverified(token);
      if (jwt.claims['aud'] != null && jwt.claims['sub'] == 'auth_token') {
        apiUri = jwt.claims['aud']+"/coonective";
        clientId = jwt.claims['cid'];
        context = jwt.claims['ctx'];
        subject = jwt.claims['sub'];
        clientSecret = ApiSecurity.encodeSha256((clientId) + (codeVerifier64));

        ApiStorage? apiStorage = await ApiClient.storage;

        if (apiStorage != null && (clientId.isEmpty)) {
          apiStorage.add('clientId', clientId);
        }
        isValid = true;
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "037-AUTHORIZE_TOKEN_INVALID",
        messages: ['Token de autorização da aplicação \'client\' inválido.'],
        module: "apiClientAuthorizeToken",
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
    return isValid;
  }

  Future<bool> get ready async {
    bool ready = false;
    ApiStorage? apiStorage = await ApiClient.storage;

    if(apiStorage == null) {
      return ready;
    }

    String? clientId = await apiStorage.read('clientId') as String;
    if (clientId.isEmpty) {
      ready = true;
    }
    return ready;
  }

  Future<bool> aclAuthorize() async {
    //Cria conexão com o servidor graphql
    ApiConnection apiConnection = ApiConnection(token, apiUri);

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
