import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/location_exception.dart';

class CountryInfo with ChangeNotifier {
  String? _imageUrl;
  String? _countryDialCode;
  Position? _position;
  String? _currentCountry;

  String? get imageUrl {
    return _imageUrl;
  }

  String? get dialCode {
    return _countryDialCode;
  }

  Future<String> _getCountryNameFromLatLng(Position position) async {
    final placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    final place = placemarks[0];
    return place.country!;
  }


  Future<void> fetchAndSetCountryData() async {
    try {
      //getting geo location of user device
      final currentPosition = await _determineLocation();
      //extracting address from location coordinates
      _currentCountry = await _getCountryNameFromLatLng(currentPosition);

      // Fetch country codes from the json file
      final countryCodesResponse =
          await rootBundle.loadString('assets/CountryCodes.json');
      final listOfCountryCodes = json.decode(countryCodesResponse);
     
      // extracting current country code data
      final countryCodeData = listOfCountryCodes
          .firstWhere((data) => data['name'] == _currentCountry);
      //setting dial code of current country
      _countryDialCode = countryCodeData['dial_code'];

      //setting flag image url of current country
      _imageUrl = 'https://flagsapi.com/${countryCodeData['code']}/flat/32.png';

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }

  Future<Position> _determineLocation() async {
    LocationPermission permission;
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error(LocationException(
          'Location services are disabled. Please enable the services'));
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error(LocationException('Location Permissions denied'));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(LocationException(
          'Location permissions are permanently denied, we cannot request permissions.'));
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}
