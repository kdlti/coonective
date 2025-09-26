import 'package:coonective/package.dart';
import 'package:coonective/src/api_params.dart';
import 'package:coonective/src/api_query_result.dart';
import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';
import 'dart:convert';

class ApiConnection {
  GraphQLClient? _graphQLClient;
  GraphQLClient? _graphQLClientSubscription;

  ApiConnection(String token, String serverUri) {
    final normalized = serverUri.startsWith('http') ? serverUri : 'http://$serverUri';
    final wsUri = normalized.replaceFirst('http', 'ws').replaceFirst('https', 'wss');

    final httpLink = HttpLink(normalized);

    final authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final link = authLink.concat(httpLink);

    final wsLink = WebSocketLink(wsUri,
        config: SocketClientConfig(
          autoReconnect: true,
          inactivityTimeout: const Duration(seconds: 30),
          initialPayload: () async {
            return {'Authorization': token};
          },
        ));

    final linkSubscription = Link.split(
      (request) => request.isSubscription,
      wsLink,
      link,
    );

    _graphQLClient ??= GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      alwaysRebroadcast: true,
      queryRequestTimeout: Duration(seconds: 15),
    );

    _graphQLClientSubscription ??= GraphQLClient(
      link: linkSubscription,
      cache: GraphQLCache(),
      alwaysRebroadcast: true,
    );
  }

  Future<ApiResponse> query(
    String params,
    dynamic variables, {
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
  }) async {
    late ApiResponse apiResponse;
    ApiParams apiParams = ApiParams(params);
    try {
      final options = QueryOptions(
        document: gql(params),
        variables: Map<String, dynamic>.from(variables),
        fetchPolicy: fetchPolicy,
      );

      QueryResult queryResult = await _graphQLClient!.query(options);

      if (queryResult.hasException) {
        print("QUERY ERRO -->> ${queryResult.exception}");
        ApiQueryResult apiQueryResult = ApiQueryResult(queryResult.toString());
        ApiError apiError = ApiError(
          createdAt: apiQueryResult.timestamp!.toIso8601String(),
          code: "014-${apiQueryResult.code!}",
          messages: apiQueryResult.errors,
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );
        if (kDebugMode) {
          Api.logError(
            apiError.toString(),
            error: apiError.code,
            stackTrace: StackTrace.current,
          );
        }
        apiResponse = ApiResponse(
          success: false,
          errors: [apiError],
        );
      } else {
        apiResponse = ApiResponse(success: true, data: queryResult.data);
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "001-GRAPHQL_QUERY_FAILED",
        messages: ["GraphQLClient.query() falhou"],
        module: apiParams.module,
        path: apiParams.path,
        variables: variables,
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

  Future<ApiResponse> mutation(
    String params,
    dynamic variables, {
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
  }) async {
    late ApiResponse apiResponse;

    ApiParams apiParams = ApiParams(params);
    try {
      final options = MutationOptions(
        document: gql(params),
        variables: Map<String, dynamic>.from(variables),
        fetchPolicy: fetchPolicy,
      );

      QueryResult queryResult = await _graphQLClient!.mutate(options);

      if (queryResult.hasException) {
        print("MUTATION ERRO -->> ${queryResult.exception}");
        ApiQueryResult apiQueryResult = ApiQueryResult(queryResult.toString());
        ApiError apiError = ApiError(
          createdAt: apiQueryResult.timestamp!.toIso8601String(),
          code: "015-${apiQueryResult.code!}",
          messages: apiQueryResult.errors,
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );
        Api.logError(
          apiError.toString(),
          error: apiError.code,
          stackTrace: StackTrace.current,
        );
        throw apiError.code;
      } else {
        apiResponse = ApiResponse(success: true, data: queryResult.data);
      }
    } catch (e) {
      ApiError apiError = ApiError(
        code: "016-GRAPHQL_MUTATE_FAILED",
        messages: ["GraphQLClient.mutate() falhou", e.toString()],
        module: apiParams.module,
        path: apiParams.path,
        variables: variables,
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

  Stream<ApiResponse> subscription(
    String params,
    dynamic variables, {
    FetchPolicy fetchPolicy = FetchPolicy.cacheFirst,
  }) {
    final apiParams = ApiParams(params);
    final operationId = "[${apiParams.module}/${apiParams.path}]";

    final options = SubscriptionOptions(
      document: gql(params),
      variables: Map<String, dynamic>.from(variables),
      fetchPolicy: fetchPolicy,
    );

    final queryResult = _graphQLClientSubscription!.subscribe(options);

    return queryResult.map((result) {
      if (result.hasException) {
        final exception = result.exception!;
        final apiError = ApiError(
          createdAt: DateTime.now().toIso8601String(),
          code: "017-GRAPHQL_VALIDATION_FAILED",
          messages: [...exception.graphqlErrors.map((e) => e.message), if (exception.linkException != null) exception.linkException.toString()],
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );

        Api.logError(
          "$operationId ${apiError.code} ${apiError.messages.join("; ")}",
          error: apiError.code,
          stackTrace: StackTrace.current,
        );

        return ApiResponse(success: false, errors: [apiError]);
      }

      final data = result.data;
      if (data != null) {
        //debugPrint("$operationId Data received: ${jsonEncode(data)}");
        return ApiResponse(success: true, data: data);
      } else {
        final apiError = ApiError(
          code: "019-NO_DATA",
          messages: ["Nenhum dado retornado pela subscription"],
          module: apiParams.module,
          path: apiParams.path,
          variables: variables,
        );

        Api.logError(
          "$operationId ${apiError.code} ${apiError.messages.first}",
          error: apiError.code,
          stackTrace: StackTrace.current,
        );

        return ApiResponse(success: false, errors: [apiError]);
      }
    });
  }
}
