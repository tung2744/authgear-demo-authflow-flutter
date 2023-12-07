import 'package:flutter_authgear/flutter_authgear.dart';

import 'config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<(Map<String, String>, AuthenticateRequest)> prepareAuthenticateRequest(
    Authgear authgear) async {
  // Create a AuthenticateRequest
  final request = await authgear.experimental.createAuthenticateRequest(
    redirectURI: "com.example.myapp://host/path",
    uiLocales: ["zh-HK"],
  );
  // GET the url to obtain the redirect uri and extract query parameters from it
  final httpRequest = http.Request("GET", request.url);
  httpRequest.followRedirects = false;
  final response = await http.Client().send(httpRequest);
  final location = response.headers["location"];
  if (location == null) {
    throw Exception("Location header missing in response");
  }
  final redirectURI = Uri.parse(location);
  final query = redirectURI.queryParameters;
  return (query, request);
}

Future<AuthgearResponse> createAuthflow(
  Map<String, String> queryParameters,
) async {
  final url = Uri.parse(ENDPOINT).replace(
    path: "/api/v1/authentication_flows",
    queryParameters: queryParameters,
  );
  final response = await http.post(
    url,
    headers: <String, String>{"Content-Type": "application/json"},
    body: jsonEncode(<String, String>{
      "type": "login",
      "name": "default",
    }),
  );
  final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
  return AuthgearResponse.fromJson(responseJson);
}

Future<AuthgearResponse> inputAuthflow(
  String stateToken,
  Map<String, dynamic> input,
) async {
  final url = Uri.parse(ENDPOINT).replace(
    path: "/api/v1/authentication_flows/states/input",
  );

  final response = await http.post(
    url,
    headers: <String, String>{"Content-Type": "application/json"},
    body: jsonEncode(<String, dynamic>{
      "state_token": stateToken,
      "input": input,
    }),
  );
  final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
  return AuthgearResponse.fromJson(responseJson);
}

Future<Uri> extractRedirectURIFromFinishUri(Uri url) async {
  // The url is /oauth2/content
  // which will return a 200 response with an HTML document
  //
  // <!DOCTYPE html>
  // <html>
  // <head>
  // <meta http-equiv="refresh" content="0;url={{ .redirect_uri }}" />
  // </head>
  // <body>
  // <script nonce="{{ $.CSPNonce }}">
  // window.location.href = "{{ .redirect_uri }}"
  // </script>
  // </body>
  // </html>
  //
  // We want to extract the redirecet URI because the redirect URI contains the authorization code
  // that we need to perform code exchange.
  final response = await http.get(url);
  final regexp = RegExp(r'content="0;url=(.*)"');
  final match = regexp.firstMatch(response.body);
  if (match == null) {
    throw Exception("incorrect response received from finish uri");
  }
  final redirectUri = Uri.parse(match[1]!);
  return redirectUri;
}

class AuthgearResponse {
  final FlowResponse? result;
  final AuthgearErrorJSON? error;

  AuthgearResponse.fromJson(Map<String, dynamic> json)
      : result = FlowResponse.fromJsonNullable(
            json['result'] as Map<String, dynamic>?),
        error = AuthgearErrorJSON.fromJsonNullable(
            json['error'] as Map<String, dynamic>?);
}

class FlowResponse {
  final String stateToken;
  final String type;
  final String name;
  final FlowAction action;

  static FlowResponse? fromJsonNullable(Map<String, dynamic>? json) {
    if (json == null) return null;
    return FlowResponse.fromJson(json);
  }

  FlowResponse.fromJson(Map<String, dynamic> json)
      : stateToken = json["state_token"] as String,
        type = json["type"] as String,
        name = json["name"] as String,
        action = FlowAction.fromJson(json["action"] as Map<String, dynamic>);
}

class FlowAction {
  final String type;
  final String? identification;
  final String? authentication;
  final dynamic data;

  FlowAction.fromJson(Map<String, dynamic> json)
      : type = json["type"] as String,
        identification = json["identification"] as String?,
        authentication = json["authentication"] as String?,
        data = json["data"];
}

class AuthgearErrorJSON {
  final String name;
  final String message;
  final String reason;

  static AuthgearErrorJSON? fromJsonNullable(Map<String, dynamic>? json) {
    if (json == null) return null;
    return AuthgearErrorJSON.fromJson(json);
  }

  AuthgearErrorJSON.fromJson(Map<String, dynamic> json)
      : name = json["name"] as String,
        message = json["message"] as String,
        reason = json["reason"] as String;
}
