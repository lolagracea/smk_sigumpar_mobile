class FormatUtils {
  static String nullSafe(String? value, {String fallback = '-'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }
}
