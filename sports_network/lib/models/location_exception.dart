class LocationException implements Exception {
  String? message;

  LocationException(this.message);

  @override
  String toString() {
    return message!;
  }
}
