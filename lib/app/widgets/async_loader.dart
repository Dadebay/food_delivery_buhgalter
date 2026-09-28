import 'package:flutter/material.dart';

import 'state_views.dart';

/// Loads one value and rebuilds when the request key changes.
///
/// The generation counter is the point of it: changing the month or a filter
/// starts a new request, and a slow answer to the previous one is thrown
/// away instead of overwriting the new screen.
class AsyncLoader<T> extends StatefulWidget {
  const AsyncLoader({
    super.key,
    required this.request,
    required this.requestKey,
    required this.builder,
    this.loading,
  });

  final Future<T> Function() request;

  /// Anything that identifies the current question — usually the period and
  /// the filters joined together.
  final Object requestKey;

  final Widget Function(BuildContext context, T value, VoidCallback reload)
      builder;

  final Widget? loading;

  @override
  State<AsyncLoader<T>> createState() => AsyncLoaderState<T>();
}

class AsyncLoaderState<T> extends State<AsyncLoader<T>> {
  int _generation = 0;
  bool _loading = true;
  T? _value;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AsyncLoader<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestKey != widget.requestKey) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await widget.request();
      if (!mounted || generation != _generation) return;
      setState(() {
        _value = value;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  /// Lets a parent (a pull-to-refresh, or a screen that just confirmed a
  /// money packet) ask for fresh data.
  Future<void> reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading) return widget.loading ?? const LoadingView();
    final error = _error;
    if (error != null) return ErrorView(error: error, onRetry: _load);
    return widget.builder(context, _value as T, _load);
  }
}
