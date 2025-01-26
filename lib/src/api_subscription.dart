import 'package:coonective/package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

typedef ApiSubscriptionBuilder<T> = Widget Function(ApiResponse apiResponse);

class ApiSubscription<T> extends HookWidget {
  const ApiSubscription({
    required this.options,
    required this.builder,
    super.key,
  });

  final ApiSubscriptionOptions<T> options;
  final ApiSubscriptionBuilder<T> builder;

  @override
  Widget build(BuildContext context) {
    final client = useGraphQLClient();
    return SubscriptionOnClient(
      client: client,
      options: SubscriptionOptions<T>(
        document: gql(options.query),
        operationName: options.operationName,
        variables: options.variables,
        fetchPolicy: options.fetchPolicy,
        errorPolicy: options.errorPolicy,
        context: options.context,
        optimisticResult: options.optimisticResult,
        cacheRereadPolicy: options.cacheRereadPolicy,
      ),
      builder: (value) {
        ApiResponse apiResponse = ApiResponse(success: value.data != null, data: value.data);

        if (options.next != null) {
          options.next!(apiResponse);
        }

        print("BUILDING SUBSCRIPTION");
        print(value);
        return builder(apiResponse);
      },
    );
  }
}
