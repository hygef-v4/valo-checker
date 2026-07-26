/// First element matching [test], or null when there is none.
///
/// Unlike `firstWhere(..., orElse: () => null)` this is safe on
/// strongly-typed lists, where returning null from orElse throws.
dynamic firstWhereOrNull(List? list, bool Function(dynamic) test) {
  if (list == null) return null;
  for (final item in list) {
    if (test(item)) return item;
  }
  return null;
}
