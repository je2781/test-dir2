import 'package:mocktail/mocktail.dart';
import 'package:sports_network/provider/user_info.dart';
import 'package:sports_network/provider/country_info.dart';

import 'package:flutter/material.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockUsers extends Mock implements Users {}

class MockCountryInfo extends Mock implements CountryInfo {}
