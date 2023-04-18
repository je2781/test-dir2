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
      //fetching country data based on geo location
      final geoLocationResponse = await http.get(url);

      final geoLocationData = json.decode(geoLocationResponse.body);
      //fetching countries calling codes data
      url = Uri.parse('https://countrycode.dev/api/calls');

      final countriesCallingCodeResponse = await http.get(url);

      final countriesCallingCodeData =
          json.decode(countriesCallingCodeResponse.body);
      //extracting geo located country calling code
      final countryCallingCodeData = countriesCallingCodeData.firstWhere(
          (data) => data['country_name'] == (geoLocationData['country']));

      _countryDialCode = countryCallingCodeData['phone_code'];
      //setting flag image url of country
      _imageUrl =
          'https://flagsapi.com/${geoLocationData['countryCode']}/flat/32.png';

      if (geoLocationData['status'] != 'success' ||
          countriesCallingCodeResponse.statusCode >= 400) {
        throw HttpException('Something went wrong');
      }

      notifyListeners();
    } catch (_) {
      rethrow;
    }
  }
}
