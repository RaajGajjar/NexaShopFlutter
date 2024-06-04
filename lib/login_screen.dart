
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:auth0_flutter/auth0_flutter_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:nexa_shop/constants.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String? usernameOrEmail;
  String? password;

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
  Widget build(BuildContext context) {
    final double padding = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding:  EdgeInsets.all(padding),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Padding(
              padding:  EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: padding),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Username or Email',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (input) => usernameOrEmail = input,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username or email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: padding),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      onChanged: (input) => password = input,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: padding),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                          // Perform login action
                        }
                      },
                      child: const Text('Login'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}