import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../data/formatting.dart';
import '../data/models/paged.dart';
import 'state_views.dart';

/// A `{items, total, page, limit}` list, paged the way the API pages.
///
/// Three rules from the spec are built in: `page` starts at 1, the first page
/// is never presented as the whole report (the footer always shows how much
/// of `total` is on screen), and changing the period or a filter resets to
/// page 1 while a late answer to the old question is discarded.
class PagedList<T> extends StatefulWidget {
  const PagedList({
    super.key,
    required this.fetch,
    required this.requestKey,
    required this.itemBuilder,
    this.header,
    this.storageKey,
    this.emptyTitle = 'Записей нет',
    this.emptyMessage = 'За выбранный период сервер ничего не вернул.',
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.separator = 10,
  });

  final Future<Paged<T>> Function(int page) fetch;
  final Object requestKey;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? header;
  final String? storageKey;
  final String emptyTitle;
  final String emptyMessage;
  final EdgeInsets padding;
  final double separator;

  @override
  State<PagedList<T>> createState() => PagedListState<T>();
}

class PagedListState<T> extends State<PagedList<T>> {
  final List<T> _items = [];
  int _generation = 0;
  int _page = 0;
  int _total = 0;
  int _limit = kPageSize;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  bool get _hasMore => _page * _limit < _total;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(covariant PagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestKey != widget.requestKey) _reset();
  }

  /// A new question always starts at page 1 with nothing carried over from
  /// the previous answer.
  Future<void> _reset() async {
    final generation = ++_generation;
    setState(() {
      _items.clear();
      _page = 0;
      _total = 0;
      _loading = true;
      _loadingMore = false;
      _error = null;
    });
    await _fetch(1, generation);
  }

  Future<void> refresh() => _reset();

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetch(_page + 1, _generation);
  }

  Future<void> _fetch(int page, int generation) async {
    try {
      final result = await widget.fetch(page);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (page == 1) _items.clear();
        _items.addAll(result.items);
        _page = result.page;
        _total = result.total;
        _limit = result.limit == 0 ? kPageSize : result.limit;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: widget.padding,
        children: [
          if (widget.header != null) widget.header!,
          const LoadingView(),
        ],
      );
    }
    if (_error != null && _items.isEmpty) {
      return ListView(
        padding: widget.padding,
        children: [
          if (widget.header != null) widget.header!,
          ErrorView(error: _error!, onRetry: _reset),
        ],
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _reset,
        child: ListView(
          padding: widget.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (widget.header != null) widget.header!,
            EmptyView(title: widget.emptyTitle, message: widget.emptyMessage),
          ],
        ),
      );
    }

    final headerCount = widget.header == null ? 0 : 1;
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _reset,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 240) {
            _loadMore();
          }
          return false;
        },
        child: ListView.separated(
          key: widget.storageKey == null
              ? null
              : PageStorageKey<String>(widget.storageKey!),
          padding: widget.padding,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: headerCount + _items.length + 1,
          separatorBuilder: (_, index) => SizedBox(
            height: index == 0 && headerCount == 1 ? 0 : widget.separator,
          ),
          itemBuilder: (context, index) {
            if (headerCount == 1 && index == 0) return widget.header!;
            final position = index - headerCount;
            if (position == _items.length) return _footer();
            return widget.itemBuilder(context, _items[position], position);
          },
        ),
      ),
    );
  }

  Widget _footer() {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Text(
              errorMessage(_error!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: gilroyRegular,
                fontSize: 13,
                color: kNegativeColor,
              ),
            ),
            TextButton(
              onPressed: () => _fetch(_page + 1, _generation),
              child: const Text('Загрузить ещё',
                  style: TextStyle(fontFamily: gilroySemiBold)),
            ),
          ],
        ),
      );
    }
    if (_loadingMore) return const LoadingView(compact: true);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Center(
        child: Text(
          _hasMore
              ? 'Показано ${Fmt.count(_items.length)} из ${Fmt.count(_total)}'
              : 'Всего записей: ${Fmt.count(_total)}',
          style: const TextStyle(
            fontFamily: gilroyMedium,
            fontSize: 13,
            color: kMutedColor,
          ),
        ),
      ),
    );
  }
}
