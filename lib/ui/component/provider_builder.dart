import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderBuilder<T> extends ConsumerWidget {
  const ProviderBuilder({super.key, required this.provider, required this.builder});

  final ProviderListenable<AsyncValue<T>> provider;
  final Widget Function(BuildContext context, AsyncValue<T> value) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(context, ref.watch(provider));
  }
}
