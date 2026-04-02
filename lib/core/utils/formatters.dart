import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat _currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy - hh:mm a');
  static final DateFormat _time = DateFormat('hh:mm a');
  static final DateFormat _fileDate = DateFormat('yyyyMMdd');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String time(DateTime value) => _time.format(value);
  static String fileDate(DateTime value) => _fileDate.format(value);
}
