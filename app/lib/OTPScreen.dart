import 'package:flutter/material.dart';
import 'package:flutter_authgear/flutter_authgear.dart';
import 'authflow.dart';
import 'main.dart';

class OTPScreen extends StatefulWidget {
  final String stateToken;
  final AuthenticateRequest request;
  const OTPScreen({super.key, required this.request, required this.stateToken});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  String otp = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Input One-Time Password"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 250,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'One-Time Password',
                ),
                initialValue: otp,
                onChanged: (val) {
                  setState(() {
                    otp = val;
                  });
                },
              ),
            ),
            TextButton(
              onPressed: () {
                submit(context);
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  void submit(BuildContext context) async {
    final viewModel = AppViewModel.of(context);
    final authgear = viewModel.authgear;
    final authflowResponse = await inputAuthflow(
      widget.stateToken,
      <String, dynamic>{
        "code": otp,
      },
    );
    if (authflowResponse.error != null) {
      throw Exception("input otp failed: ${authflowResponse.error!.reason}");
    }
    final data = authflowResponse.result!.action.data as Map<String, dynamic>;
    final finishRedirectUri = data["finish_redirect_uri"] as String;
    final redirectUri =
        await extractRedirectURIFromFinishUri(Uri.parse(finishRedirectUri));

    final user = await authgear.experimental
        .finishAuthentication(url: redirectUri, request: widget.request);

    debugPrint("authenticated as user id:  ${user.sub}");
    debugPrint("authgear.sessionState:  ${authgear.sessionState}");
    debugPrint("authgear.accessToken:  ${authgear.accessToken}");
  }
}
