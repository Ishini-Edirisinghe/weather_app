import 'package:intl/intl.dart';

String formatDateFromTimestamp(int ts) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return DateFormat('EEE, d MMM').format(dt);
}

String formatHourFromTimestamp(int ts) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  return DateFormat('HH:mm').format(dt);
}
