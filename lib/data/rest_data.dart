import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../models/cadeaubon.dart';
import '../models/handelaar.dart';

class RestData {
  static RestData _instance = new RestData.internal();
  RestData.internal();
  factory RestData() => _instance;

  static const String BASE_URL =
      "https://lekkerlokaalbralenbre.azurewebsites.net/api/mobieleapp/";

  Future<Handelaar> meldHandelaarAan(String username, String password) async {
    final response = await http.get(BASE_URL + username + "/" + password);
    final responseJson = json.decode(response.body);
    return new Handelaar.fromJson(responseJson);
  }

  Future<Cadeaubon> haalCadeaubonOp(String qrcode) async {
    final response = await http.get(BASE_URL + qrcode);
    final responseJson = json.decode(response.body);
    return new Cadeaubon.fromJson(responseJson);
  }

  Future<Response> valideerCadeaubon(Cadeaubon cadeaubon) async {
    final message = json.encode(cadeaubon.toJson());
    final response = await http.put(
        BASE_URL + cadeaubon.bestelLijnId.toString(),
        headers: {
          "Content-Type": "application/json",
          'Accept': 'application/json'
        },
        body: message);
    return response;
  }
}
