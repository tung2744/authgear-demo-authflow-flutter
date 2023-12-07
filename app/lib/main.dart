import 'package:flutter/material.dart';
import 'package:flutter_authgear/flutter_authgear.dart'
    show AuthenticateRequest, Authgear;

import 'config.dart';
import 'PhoneNumberScreen.dart';
import 'OTPScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool configured = false;
  final Authgear authgear = Authgear(
    endpoint: ENDPOINT,
    clientID: CLIENT_ID,
  );

  @override
  void initState() {
    super.initState();
    authgear.configure().then((_) {
      setState(() {
        configured = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!configured) {
      return const SizedBox.shrink();
    }
    return AppViewModel(
      authgear: authgear,
      child: MaterialApp(
        title: 'Authflow Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const PhoneNumberScreen(),
        routes: <String, WidgetBuilder>{
          "/otp": (BuildContext context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            final stateToken = args["stateToken"] as String;
            final authRequest = args["authRequest"] as AuthenticateRequest;

            return OTPScreen(
              stateToken: stateToken,
              request: authRequest,
            );
          },
        },
      ),
    );
  }
}

class AppViewModel extends InheritedWidget {
  final Authgear authgear;

  const AppViewModel({
    super.key,
    required super.child,
    required this.authgear,
  });

  static AppViewModel of(BuildContext context) {
    final AppViewModel? result =
        context.dependOnInheritedWidgetOfExactType<AppViewModel>();
    assert(result != null, 'No AppViewModel found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppViewModel oldWidget) =>
      authgear != oldWidget.authgear;
}
