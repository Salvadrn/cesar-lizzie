/// Convenience extensions on [DateTime] for NeuroNav.
///
/// All human-readable output is in Spanish.
library;

extension DateExtensions on DateTime {
  // -----------------------------------------------------------------------
  // timeAgo  -- relative time in Spanish
  // -----------------------------------------------------------------------

  /// Returns a human-readable relative time string in Spanish.
  ///
  /// Examples: "hace un momento", "hace 5 minutos", "hace 2 horas",
  /// "hace 1 dia", "hace 3 semanas", "hace 2 meses".
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      return 'en el futuro';
    }

    final seconds = difference.inSeconds;
    final minutes = difference.inMinutes;
    final hours = difference.inHours;
    final days = difference.inDays;

    if (seconds < 60) {
      return 'hace un momento';
    } else if (minutes == 1) {
      return 'hace 1 minuto';
    } else if (minutes < 60) {
      return 'hace $minutes minutos';
    } else if (hours == 1) {
      return 'hace 1 hora';
    } else if (hours < 24) {
      return 'hace $hours horas';
    } else if (days == 1) {
      return 'hace 1 dia';
    } else if (days < 7) {
      return 'hace $days dias';
    } else if (days < 14) {
      return 'hace 1 semana';
    } else if (days < 30) {
      final weeks = (days / 7).floor();
      return 'hace $weeks semanas';
    } else if (days < 60) {
      return 'hace 1 mes';
    } else if (days < 365) {
      final months = (days / 30).floor();
      return 'hace $months meses';
    } else if (days < 730) {
      return 'hace 1 ano';
    } else {
      final years = (days / 365).floor();
      return 'hace $years anos';
    }
  }

  // -----------------------------------------------------------------------
  // formattedDate  -- "25 de febrero de 2026"
  // -----------------------------------------------------------------------

  /// Returns the date in long Spanish format, e.g. "25 de febrero de 2026".
  String get formattedDate {
    return '$day de ${_monthName(month)} de $year';
  }

  // -----------------------------------------------------------------------
  // formattedTime  -- "14:30"
  // -----------------------------------------------------------------------

  /// Returns the time in 24-hour format with zero-padded components,
  /// e.g. "09:05".
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // -----------------------------------------------------------------------
  // greetingPrefix
  // -----------------------------------------------------------------------

  /// Returns a greeting appropriate for the time of day.
  ///
  /// * 06:00 - 11:59 -> "Buenos dias"
  /// * 12:00 - 19:59 -> "Buenas tardes"
  /// * 20:00 - 05:59 -> "Buenas noches"
  String get greetingPrefix {
    if (hour >= 6 && hour < 12) {
      return 'Buenos dias';
    } else if (hour >= 12 && hour < 20) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Spanish month names (1-indexed).
  static String _monthName(int month) {
    const months = [
      '', // 0 placeholder
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month];
  }
}
