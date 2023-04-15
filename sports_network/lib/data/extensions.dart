import '../models/interests.dart';

extension InterestsExtension on Interests {
  String toNameString() {
    return this.toString().split('.').last.replaceAll('_', ' ');
  }
}
