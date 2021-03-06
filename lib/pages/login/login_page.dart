import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/database_helper.dart';
import '../../models/handelaar.dart';
import '../../models/user.dart';
import '../scan/scan_page.dart';
import 'login_presenter.dart';

class LoginPage extends StatefulWidget {
  static String tag = 'login-page';
  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> implements LoginPageContract {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  var emailController;
  var wachtwoordController;
  User gebruiker = new User("Lekker", "Lokaal");
  User user;
  final db = new DatabaseHelper();

  LoginPagePresenter _presenter;

  _LoginPageState() {
    _presenter = new LoginPagePresenter(this);
    emailController = new TextEditingController();
    wachtwoordController = new TextEditingController();
  }

  void _submit(String gebruikersnaam, String wachtwoord) {
    user = new User(gebruikersnaam, wachtwoord);
    if (user.checkInformation) {
      _presenter.doLogin(user.username, user.password);
    } else {
      _showSnackBar(
          "Gelieve zowel uw e-mailadres als uw wachtwoord in te vullen.");
    }
  }

  void _showSnackBar(String text) {
    scaffoldKey.currentState.showSnackBar(new SnackBar(
      content: new Text(text),
      duration: Duration(seconds: 4),
    ));
  }

  Future zetGegevensKlaar() async {
    gebruiker = await db.getUser();
  }

  void slimAanmelden() async {
    await zetGegevensKlaar();
    if (gebruiker != null && gebruiker.username != "Lekker") {
      bool aanmeldenMetSmartlock = await smartlocks();
      if (aanmeldenMetSmartlock) {
        _submit(gebruiker.username, gebruiker.password);
      } else {
        setState(() {
          emailController.text = gebruiker.username;
        });
      }
    }
  }

  Future<bool> smartlocks() async {
    var localAuth = new LocalAuthentication();
    bool didAuthenticate = await localAuth.authenticateWithBiometrics(
        localizedReason:
            'Gebruik uw vingerafdruk of gezicht om sneller aan te kunnen melden.');
    return didAuthenticate;
  }

  @override
  void dispose() {
    emailController.dispose();
    wachtwoordController.dispose();
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    slimAanmelden();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Hero(
        tag: 'hero',
        child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 54.0,
            child: Image.asset('assets/LoginIcon.png')));

    final email = TextField(
      keyboardType: TextInputType.emailAddress,
      autofocus: false,
      controller: emailController,
      decoration: InputDecoration(
          hintText: 'E-mailadres',
          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );

    final password = TextField(
      autofocus: false,
      obscureText: true,
      controller: wachtwoordController,
      decoration: InputDecoration(
          hintText: 'Wachtwoord',
          contentPadding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(32.0))),
    );

    final loginButton = Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Material(
        borderRadius: BorderRadius.circular(30.0),
        shadowColor: Colors.lightBlueAccent.shade100,
        elevation: 5.0,
        child: MaterialButton(
          minWidth: 200.0,
          height: 42.0,
          onPressed: () {
            _submit(emailController.text, wachtwoordController.text);
          },
          color: Colors.lightBlueAccent,
          child: Text('Meld aan', style: TextStyle(color: Colors.white)),
        ),
      ),
    );

    final forgotLabel = FlatButton(
      child:
          Text('Wachtwoord vergeten?', style: TextStyle(color: Colors.black54)),
      onPressed: () {
        _showSnackBar(
            "Contacteer de administrator van Lekker Lokaal om een nieuw wachtwoord aan te laten maken.");
      },
    );

    return Scaffold(
      appBar: new AppBar(
        title: new Text("Lekker Lokaal", style: TextStyle(color: Colors.white)),
      ),
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(left: 24.0, right: 24.0),
          children: <Widget>[
            logo,
            SizedBox(height: 48.0),
            email,
            SizedBox(height: 8.0),
            password,
            SizedBox(height: 24.0),
            loginButton,
            forgotLabel
          ],
        ),
      ),
    );
  }

  @override
  void onLoginError(String error) {
    _showSnackBar(
        "Er is iets misgegaan. Gelieve uw netwerk te controleren en uw gegevens opnieuw in te voeren.");
  }

  @override
  void onLoginSucces(Handelaar handelaar) async {
    User huidigeUser = await db.getUser();
    if (huidigeUser == null)
      await db.saveUser(user);
    else
      await db.updateUser(user);
    Handelaar huidigeHandelaar = await db.getHandelaar();
    if (huidigeHandelaar == null)
      await db.saveHandelaar(handelaar);
    else
      await db.updateHandelaar(handelaar);
    Navigator.of(context).pushNamed(ScanPage.tag);
  }
}
