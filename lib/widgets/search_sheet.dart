import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'app_chrome.dart';
import 'search_sheet_status.dart';

/// Builds the tile for one search result. [selecting] is true while that item
/// is awaiting an async selection, so the builder can show a per-item spinner;
/// [onTap] starts the selection.
typedef SearchSheetItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      bool selecting,
      VoidCallback onTap,
    );

class SearchSheetTexts {
  const SearchSheetTexts({
    required this.title,
    required this.hintText,
    required this.emptyHint,
    required this.loading,
    required this.notFound,
    required this.searchError,
    this.selectError = 'Não foi possível concluir agora.',
  });

  final String title;
  final String hintText;
  final String emptyHint;
  final String loading;
  final String notFound;
  final String searchError;
  final String selectError;
}

class SearchSheet<T> extends StatefulWidget {
  const SearchSheet({
    required this.texts,
    required this.search,
    required this.itemBuilder,
    required this.onSelect,
    this.minimumSearchLength = 2,
    this.resultLimit = 20,
    super.key,
  });

  final SearchSheetTexts texts;
  final Future<List<T>> Function(String search, int limit) search;
  final SearchSheetItemBuilder<T> itemBuilder;
  final Future<bool> Function(T item) onSelect;
  final int minimumSearchLength;
  final int resultLimit;

  @override
  State<SearchSheet<T>> createState() => _SearchSheetState<T>();
}

class _SearchSheetState<T> extends State<SearchSheet<T>> {
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  List<T> _results = const [];
  bool _loading = false;
  String? _errorMessage;
  bool _hasSearched = false;
  int _requestVersion = 0;
  T? _selectingItem;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.texts.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                    ),
                    hintText: widget.texts.hintText,
                  ),
                ),
                const SizedBox(height: 14),
                const SectionLabel('Resultados'),
                const SizedBox(height: 8),
                Flexible(child: _resultContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultContent() {
    if (!_hasSearched) {
      return SearchSheetMessage(widget.texts.emptyHint);
    }

    if (_loading) {
      return SearchSheetMessage.withProgress(widget.texts.loading);
    }

    if (_errorMessage != null) {
      return SearchSheetError(message: _errorMessage!, onRetry: _retrySearch);
    }

    if (_results.isEmpty) {
      return SearchSheetMessage(widget.texts.notFound);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];

        return widget.itemBuilder(
          context,
          item,
          _selectingItem == item,
          () => _select(item),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    final search = value.trim();
    final requestVersion = ++_requestVersion;
    _debounce?.cancel();

    if (search.length < widget.minimumSearchLength) {
      _resetSearch();
      return;
    }

    _startSearching();
    _debounce = Timer(
      _debounceDuration,
      () => _search(search, requestVersion),
    );
  }

  void _startSearching() {
    setState(() {
      _results = const [];
      _loading = true;
      _errorMessage = null;
      _selectingItem = null;
      _hasSearched = true;
    });
  }

  Future<void> _search(String search, int requestVersion) async {
    if (!mounted) {
      return;
    }

    try {
      final results = await widget.search(search, widget.resultLimit);

      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }

      setState(() {
        _results = const [];
        _loading = false;
        _errorMessage = widget.texts.searchError;
      });
    }
  }

  Future<void> _select(T item) async {
    if (_selectingItem != null) {
      return;
    }

    setState(() {
      _selectingItem = item;
      _errorMessage = null;
    });

    try {
      final shouldClose = await widget.onSelect(item);

      if (!mounted) {
        return;
      }

      if (shouldClose) {
        Navigator.pop(context);
        return;
      }

      setState(() => _selectingItem = null);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectingItem = null;
        _errorMessage = widget.texts.selectError;
      });
    }
  }

  void _retrySearch() {
    final search = _controller.text.trim();
    if (search.length < widget.minimumSearchLength) {
      return;
    }

    _debounce?.cancel();
    final requestVersion = ++_requestVersion;
    _startSearching();
    _search(search, requestVersion);
  }

  void _resetSearch() {
    setState(() {
      _results = const [];
      _loading = false;
      _errorMessage = null;
      _selectingItem = null;
      _hasSearched = false;
    });
  }
}
