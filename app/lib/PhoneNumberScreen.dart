import 'main.dart';
import 'authflow.dart';
import 'package:flutter/material.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  String phoneNumber = "+852";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Input Phone Number"),
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
                  labelText: 'Phone',
                ),
                initialValue: phoneNumber,
                onChanged: (val) {
                  setState(() {
                    phoneNumber = val;
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
    final navigator = Navigator.of(context);
    final viewModel = AppViewModel.of(context);
    final authgear = viewModel.authgear;

    final (query, request) = await prepareAuthenticateRequest(authgear);

    final authflowResponse = await createAuthflow(query);
    final stateToken = authflowResponse.result?.stateToken;
    if (authflowResponse.error != null) {
      throw Exception("create flow failed");
    }
    final authflowResponse2 =
        await inputAuthflow(stateToken!, <String, dynamic>{
      "identification": "phone",
      "login_id": phoneNumber,
      "authentication": "primary_oob_otp_sms",
      "index": 0,
      "channel": "sms"
    });
    if (authflowResponse2.error != null) {
      throw Exception(
          "input phone number failed: ${authflowResponse2.error!.reason}");
    }
    navigator.pushNamed("/otp", arguments: <String, dynamic>{
      "stateToken": authflowResponse2.result!.stateToken,
      "authRequest": request,
    });
  }
}
