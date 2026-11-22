/// Looks up an enum value by its stored name. Returns null for unknown or
/// missing names so that malformed stored data is rejected, never guessed.
T? enumFromName<T extends Enum>(Iterable<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
