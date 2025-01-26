import 'package:coonective/package.dart';
import 'package:coonective/src/api_params.dart';
import 'package:coonective/src/api_query_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';

class ApiConnection {
  GraphQLClient? _graphQLClient;
  GraphQLClient? _graphQLClientSubscription;

  ApiConnection(String token, String serverUri) {
    serverUri = "http://localhost:4600/coonective";
    //serverUri = "http://54.90.249.204:4600/coonective";
    //serverUri = "http://100.25.197.120:4600/coonective"; //RAMON
    //serverUri = "http://44.222.237.145:4600/coonective"; //RAMON
    //serverUri = "http://23.20.39.252:4600/coonective"; //TERESINA
    //serverUri = "http://api.kdltelegestao.com/coonective";
    final HttpLink httpLink = HttpLink(
      serverUri,
    );

    final AuthLink authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );
    Link link = authLink.concat(httpLink);

    /// subscriptions must be split otherwise `HttpLink` will. swallow them
    String subscriptionUri = 'ws://127.0.0.1:4600/coonective';
    //String subscriptionUri = 'ws://100.25.197.120:4600/coonective';

    final wsLink = WebSocketLink(
      subscriptionUri,
      config: const SocketClientConfig(
        autoReconnect: true,
        inactivityTimeout: Duration(seconds: 30),
      ),
    );

    Link linkSubscription = Link.split((request) => request.isSubscription, wsLink, link);

    _graphQLClient ??= GraphQLClient(
      link: link,
      cache: GraphQLCache(),
      alwaysRebroadcast: true,
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

  Future<void> subscription(String params, dynamic variables, ValueChanged<ApiResponse> callback,
      {FetchPolicy fetchPolicy = FetchPolicy.cacheFirst}) async {
    ApiParams apiParams = ApiParams(params);
    try {
      final options = SubscriptionOptions(
        document: gql(params),
        variables: Map<String, dynamic>.from(variables),
        fetchPolicy: fetchPolicy,
      );

      Stream<QueryResult<Object?>> queryResult = _graphQLClientSubscription!.subscribe(options);

      queryResult.listen((result) {
        if (result.hasException) {
          ApiQueryResult apiQueryResult = ApiQueryResult(result.toString());
          ApiError apiError = ApiError(
            createdAt: apiQueryResult.timestamp!.toIso8601String(),
            code: "017-${apiQueryResult.code!}",
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
        } else {
          callback(ApiResponse(success: true, data: result.data));
        }
      });
    } catch (e) {
      ApiError apiError = ApiError(
        code: "018-GRAPHQL_SUBSCRIPTION_FAILED",
        messages: ["GraphQLClient.subscription() falhou"],
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
  }
}
