import 'package:coonective/package.dart';
import 'package:coonective/src/user/api_user_authorize_token.dart';
import 'package:jose/jose.dart';

import '../api_connection.dart';


class ApiUserAccessToken {
  ApiUserAuthorizeToken apiUserAuthorize;
  String clientId = 'guest-user1';
  String tokenType = '';
  String expiresIn = '';
  String accessToken = '';
  String refreshToken = '';
  bool isValid = false;

  ApiUserAccessToken(this.apiUserAuthorize);

  Future<bool> token() async {

    String clientId = "guest-user2";
    ApiUser? apiUser = await ApiUser.load();
    if(apiUser != null){
      clientId = apiUser.sessionId;
    }

    ApiConnection apiConnection = ApiConnection(apiUserAuthorize.nonceToken, apiUserAuthorize.apiUri);

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
        "clientId": clientId,
        "clientSecret": apiUserAuthorize.clientSecret,
        "code": apiUserAuthorize.code,
        "codeVerifier": apiUserAuthorize.codeVerifier64,
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
        isValid = true;

        ApiStorage? apiStorage = await ApiToken.storage;
        if (apiStorage != null) {
          apiStorage.add('accessToken', accessToken);
          apiStorage.add('refreshToken', refreshToken);

          try {
            var jwt = JsonWebToken.unverified(accessToken);
            if (jwt.claims['aud'] != null) {
              apiStorage.add('serverUri', jwt.claims['aud']);
            }
          } catch (e) {
            ApiError apiError = ApiError(
              code: "038-ACCESS_TOKEN_INVALID",
              messages: ['Token de inicialização \'User token\' inválido.'],
              module: "ApiUserAccessToken",
              path: "token",
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
      } else {
        token.throwException();
      }
    } else {
      apiResponse.throwException();
    }
    return false;
  }
}
