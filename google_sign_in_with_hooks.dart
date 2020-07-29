import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final _googleSignInProvider = Provider((_ref) {
  return GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );
});

class SignInDemo extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final googleSignIn = useProvider(_googleSignInProvider);
    final ValueNotifier<GoogleSignInAccount> _currentUser = useState(null);

    useEffect(
      () {
        final subscription = googleSignIn.onCurrentUserChanged
            .listen((GoogleSignInAccount account) {
          _currentUser.value = account;
        });
        googleSignIn.signInSilently(suppressErrors: false).then((account) {
          print(account);
          _currentUser.value = account;
        }).catchError((error) {
          print("error in signIn");
        });
        // This will cancel the subscription when the widget is disposed
        // or if the callback is called again.
        return subscription.cancel;
      },
      // when the stream change, useEffect will call the callback again.
      [googleSignIn.onCurrentUserChanged],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign In'),
      ),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: (_currentUser.value == null)
            ? NotSignedIn()
            : SignedIn(account: _currentUser.value),
      ),
    );
  }
}

class NotSignedIn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const Text("You are not currently signed in."),
        RaisedButton(
          onPressed: () async {
            try {
              await _googleSignInProvider.read(context).signIn();
            } catch (error) {
              print(error);
            }
          },
          child: const Text('SIGN IN'),
        ),
      ],
    );
  }
}

class SignedIn extends StatelessWidget {
  final GoogleSignInAccount account;
  const SignedIn({Key key, this.account}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        ListTile(
          leading: GoogleUserCircleAvatar(
            identity: account,
          ),
          title: Text(account.displayName ?? ''),
          subtitle: Text(account.email ?? ''),
        ),
        const Text("Signed in successfully."),
        FutureBuilder(
          future: account.authentication,
          builder: (BuildContext context,
              AsyncSnapshot<GoogleSignInAuthentication> snapshot) {
            if (snapshot.hasData) {
              return Column(
                children: <Widget>[
                  Text('idToken: ${snapshot.data.idToken ?? " "}'),
                  Text('accessToken: ${snapshot.data.accessToken ?? ""}'),
                  Text('serverAuthCode: ${snapshot.data.serverAuthCode ?? ""}'),
                ],
              );
            }
            return const CircularProgressIndicator();
          },
        ),
        RaisedButton(
          onPressed: () {
            _googleSignInProvider.read(context).disconnect();
          },
          child: const Text('SIGN OUT'),
        ),
      ],
    );
  }
}

