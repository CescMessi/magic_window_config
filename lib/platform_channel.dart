import 'package:flutter/services.dart';

class AndroidMethods {
  static const platform = MethodChannel('get_activities_channel');

  static Future<List<String>> getActivities(String packageName) {
    return platform.invokeMethod('getActivities', packageName).then((result) {
      List<dynamic> activities = result;
      return activities.cast<String>();
    }).catchError((error) {
      print("Failed to get activities: '$error'.");
      return [];
    });
  }
}
