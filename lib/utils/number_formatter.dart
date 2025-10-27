class NumberFormatter {
  /// Format large numbers with K, M, B suffixes
  static String formatCount(int count) {
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    } else if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Format currency amounts with K, M, B suffixes
  static String formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'LKR ${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'LKR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'LKR ${amount.toStringAsFixed(0)}';
  }

  /// Format currency amounts with compact notation but keep decimals for smaller amounts
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return 'LKR ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'LKR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'LKR ${amount.toStringAsFixed(0)}';
  }

  /// Format percentage values
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format decimal numbers with appropriate precision
  static String formatDecimal(double value, {int precision = 1}) {
    return value.toStringAsFixed(precision);
  }
}
