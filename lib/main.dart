import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexa_shop/auth_card.dart';
import 'package:nexa_shop/constants.dart';
import 'package:nexa_shop/web_auth_card.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;
  String _output = '';

  late Auth0 auth0;
  late WebAuthentication webAuth;
  late Auth0Web auth0Web;

  @override
  void initState() {
    super.initState();

    auth0 = Auth0(dotenv.env['AUTH0_DOMAIN']!, dotenv.env['AUTH0_CLIENT_ID']!);
    auth0Web =
        Auth0Web(dotenv.env['AUTH0_DOMAIN']!, dotenv.env['AUTH0_CLIENT_ID']!);
    webAuth =
        auth0.webAuthentication(scheme: dotenv.env['AUTH0_CUSTOM_SCHEME']);

    if (kIsWeb) {
      auth0Web.onLoad().then((final credentials) => setState(() {
        _output = credentials?.idToken ?? '';
        _isLoggedIn = credentials != null;
      }));
    }
  }

  Future<void> webAuthLogin() async {
    String output = '';

    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      if (kIsWeb) {
        return auth0Web.loginWithRedirect(redirectUrl: 'http://localhost:3000');
      }

      final result = await webAuth.login(useHTTPS: true);

      setState(() {
        _isLoggedIn = true;
      });

      output = result.idToken;
    } catch (e) {
      output = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _output = output;
    });
  }

  Future<void> webAuthLogout() async {
    String output;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      if (kIsWeb) {
        await auth0Web.logout(returnToUrl: 'http://localhost:3000');
      } else {
        await webAuth.logout(useHTTPS: true);

        setState(() {
          _isLoggedIn = false;
        });
      }
      output = 'Logged out.';
    } catch (e) {
      output = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _output = output;
    });
  }

  Future<void> apiLogin(
      final String usernameOrEmail, final String password) async {
    String output;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      final result = await auth0.api.login(
          usernameOrEmail: usernameOrEmail,
          password: password,
          connectionOrRealm: 'Username-Password-Authentication');
      output = result.accessToken;
    } on ApiException catch (e) {
      output = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _isLoggedIn = true;
      _output = output;
    });
  }

  @override
  Widget build(final BuildContext context) {

    var size = MediaQuery.of(context).size;

    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(title: const Text('Nexa Shops')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return _buildLargeScreen(context);
              } else {
                return _buildSmallScreen(context);
              }
            },
          )
      ),
    );
  }

  Widget _buildLargeScreen(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(_output),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(padding),
              child: Column(
                children: [
                  ApiCard(action: apiLogin, webAuthAction: webAuthLogin, label: "SSO Login"),
                  if (_isLoggedIn)
                    WebAuthCard(label: 'Web Auth Logout', action: webAuthLogout)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreen(BuildContext context) {
    return Column(
      children: [
        ApiCard(action: apiLogin, webAuthAction: webAuthLogin, label: "SSO Login"),
        if (_isLoggedIn)
          WebAuthCard(label: 'Web Auth Logout', action: webAuthLogout),
        Center(
          child: Text(_output),
        ),
      ],
    );
  }

}
