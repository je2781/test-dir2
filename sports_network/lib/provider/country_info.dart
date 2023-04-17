import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/http_exception.dart';

class CountryInfo with ChangeNotifier {
  String? _imageUrl;
  String? _countryDialCode;

  String? get imageUrl {
    return _imageUrl;
  }

  String? get dialCode {
    return '+$_countryDialCode';
  }

  Future<void> fetchAndSetCountryData() async {
    var url = Uri.parse('http://ip-api.com/json/');
    try {
      final geoLocationResponse = await http.get(url);

      final geoLocationData =
          json.decode(geoLocationResponse.body) as Map<String, String>;

      url = Uri.parse(
          'http://api.countrylayer.com/v2/all?access_key=4aea92b8eebc125ef99333ff6d989ea3');

      final countriesDataResponse = await http.get(url);

      final countriesData = json.decode(countriesDataResponse.body);

      final countryData = countriesData.firstWhere(
          (data) => data['alpha2Code'] == geoLocationData['countryCode']);

      _countryDialCode = countryData['callingCodes'][0];

      _imageUrl =
          'https://flagsapi.com/${countryData['alpha2Code']}/shiny/64.png';

      notifyListeners();

      if (geoLocationData['status'] != 'success' ||
          countriesData['success'] == false) {
        throw HttpException('Something went wrong');
      }
    } catch (_) {
      rethrow;
    }
  }
}
