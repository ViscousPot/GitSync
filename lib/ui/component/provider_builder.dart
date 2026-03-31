import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderBuilder<T> extends ConsumerWidget {
  const ProviderBuilder({
    super.key,
    required this.provider,
    required this.builder,
    this.loading,
    this.error,
  });

  final ProviderListenable<AsyncValue<T>> provider;
  final Widget Function(BuildContext context, T? value) builder;
  final Widget Function(BuildContext context, T? lastValue)? loading;
  final Widget Function(BuildContext context, T? lastValue, Object error, StackTrace stackTrace)? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(provider);
    return asyncValue.when(
      data: (value) => builder(context, value),
      loading: () => loading?.call(context, asyncValue.valueOrNull) ?? builder(context, asyncValue.valueOrNull),
      error: (e, st) => error?.call(context, asyncValue.valueOrNull, e, st) ?? builder(context, null),
    );
  }
}
