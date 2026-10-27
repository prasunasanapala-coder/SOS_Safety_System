import 'package:intl/intl.dart';

/// Date/time helpers.
class Formatters {
  const Formatters._();

  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  /// Pending server timestamps are null until Firestore confirms the write.
  static String dateTime(DateTime? value) =>
      value == null ? 'Saving...' : _dateTime.format(value.toLocal());
}