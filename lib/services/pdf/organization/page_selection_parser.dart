class PageSelectionParser {
  List<int> parse(String input, {int? pageCount}) {
    final normalized = input.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Select at least one page.');
    }

    final pages = <int>[];
    for (final token in normalized.split(',')) {
      final value = int.tryParse(token.trim());
      if (value == null || value < 1) {
        throw FormatException('Invalid page number: "$token".');
      }
      if (pageCount != null && value > pageCount) {
        throw FormatException(
          'Page $value is outside this document. It has $pageCount pages.',
        );
      }
      final zeroBased = value - 1;
      if (pages.contains(zeroBased)) {
        throw FormatException('Page $value was selected more than once.');
      }
      pages.add(zeroBased);
    }
    return pages;
  }
}
