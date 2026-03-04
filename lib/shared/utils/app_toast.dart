// Thin wrapper around Fluttertoast for consistent quick notifications.
import 'package:fluttertoast/fluttertoast.dart';

void showAppToast(String message) {
  Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_SHORT);
}
