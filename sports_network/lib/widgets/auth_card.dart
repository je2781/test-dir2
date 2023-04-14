import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:async/async.dart';
import 'package:masked_text/masked_text.dart';

import '../data/reg_express.dart';
import '../data/widget_keys.dart';
import '../screens/verify_screen.dart';
import '../screens/tabs_screen.dart';
import '../picker/user_image_picker.dart';

import '../data/extensions.dart';
import '../models/interests.dart';

enum AuthMode { Signup, Login, ForgotPassword, LoginWithMobile }

class AuthCard extends StatefulWidget {
  const AuthCard({
    Key? key,
  }) : super(key: key);

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.Login;
  var _authData = {
    'email': '',
    'password': '',
    'mobile': '',
    'interest': '',
    'username': ''
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _interestsController = TextEditingController();
  final _futureGroup = FutureGroup();
  //establishing connection to firebaseAuth api
  final _auth = FirebaseAuth.instance;
  late File _userImageFile;

  //disposing controllers to prevent memory leaks
  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _interestsController.dispose();
    // _futureGroup.close();
  }

  void _mobileVerificationFailed(FirebaseAuthException e) async {
    var errorMessage = 'Phone verification failed.';
    switch (e.code) {
      case 'invalid-phone-number':
        errorMessage = 'The provided phone number is not valid.';
        break;
      default:
        break;
    }

    await _showErrorDialog(errorMessage);
  }

  Future<void> _showSmsCodeDialog(String verificationId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Enter SMS Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _codeController,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Done"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () async {
              final smsCode = _codeController.text.trim();
              // Create a PhoneAuthCredential with the code
              final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId, smsCode: smsCode);
              if (_authMode == AuthMode.Signup) {
                //linking mobile to current user account
                await _auth.currentUser!.linkWithCredential(credential);
              } else {
                //signing in using phone auth credentials
                _auth.signInWithCredential(credential).then((_) {
                  Navigator.of(context)
                      .pushReplacementNamed(TabsScreen.routeName);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String errorMsg) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'An Error Occurred!',
          style: TextStyle(
            color: Colors.black87,
          ),
        ),
        content: Text(errorMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Okay'),
          )
        ],
      ),
    );
  }

  Future<void> _getAuthSignUp(String email, String password, String mobile,
      String interest, String username) async {
    final _userCreds = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child('${_userCreds.user!.uid}.jpg');
    await ref.putFile(_userImageFile).whenComplete(() => null);

    final imageUrl = await ref.getDownloadURL();
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(_userCreds.user!.uid)
        .set({
      'mobile': mobile,
      'email': email,
      'interest': interest,
      'username': username,
      'image_url': imageUrl ?? ''
    });
  }

  Future<void> _getAuthVerifyPhone(String mobile) async {
    await _auth.verifyPhoneNumber(
        phoneNumber: mobile,
        verificationCompleted: (credential) async {
          //linking phone auth provider to current user account
          await _auth.currentUser!.linkWithCredential(credential);
        },
        timeout: const Duration(seconds: 60),
        verificationFailed: (e) => _mobileVerificationFailed(e),
        codeSent: (String verificationId, int? forceResendingToken) async {
          //show dialog to take sms code from the user
          await _showSmsCodeDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {});
  }

  Future<void> _submit(NavigatorState navigator) async {
    //closing the keyboard by removing focus from all text fields
    FocusScope.of(context).unfocus();
    //checking validity of text fields
    if (!_formKey.currentState!.validate()) {
      return;
    }
    //checking if image was picked
    if (_userImageFile == null && _authMode == AuthMode.Signup) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('please pick an image'),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
      return;
    }
    // saving values in text fields
    _formKey.currentState!.save();
    //set loading indicator
    setState(() {
      _isLoading = true;
    });
    try {
      if (_authMode == AuthMode.Login) {
        // Log in user with email/password
        _auth
            .signInWithEmailAndPassword(
                email: _authData['email']!, password: _authData['password']!)
            .then((_) {
          Navigator.of(context).pushReplacementNamed(TabsScreen.routeName);
        });
      } else if (_authMode == AuthMode.Signup) {
        // Sign user up with email/password
        final future1 = _getAuthSignUp(
                _authData['email']!,
                _authData['password']!,
                _authData['mobile']!,
                _authData['interest']!,
                _authData['username']!)
            .then(
          (_) => navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerifyScreen(),
            ),
          ),
        );

        //verify phone number
        final future3 = _getAuthVerifyPhone(_authData['mobile']!);

        //combining futures together
        _futureGroup
            .add(Future.delayed(Duration(seconds: 2)).then((_) => future1));
        _futureGroup
            .add(Future.delayed(Duration(seconds: 8)).then((_) => future3));
        _futureGroup.close();
        await _futureGroup.future;
      } else {
        //signin using mobile number
        await _auth.verifyPhoneNumber(
            phoneNumber: _authData['mobile']!,
            verificationCompleted: (credential) {
              //signing in using phone auth credentials
              _auth.signInWithCredential(credential).then((_) {
                Navigator.of(context)
                    .pushReplacementNamed(TabsScreen.routeName);
              });
            },
            timeout: const Duration(seconds: 60),
            verificationFailed: (e) => _mobileVerificationFailed(e),
            codeSent: (String verificationId, int? forceResendingToken) async {
              //show dialog to take sms code from the user
              await _showSmsCodeDialog(verificationId);
            },
            codeAutoRetrievalTimeout: (_) {});
      }
    } on FirebaseAuthException catch (err) {
      var message = 'There was an error with your credentials';

      if (err.message != null) {
        message = err.message!;
      }
      //removing loading indicator
      setState(() {
        _isLoading = false;
      });
      //scaffold page UI info dialog, informing on error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    } catch (_) {
      var message = 'Could not process your credentials. Try again later.';
      //removing loading indicator
      setState(() {
        _isLoading = false;
      });
      //scaffold page UI info dialog, informing on error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).errorColor,
        ),
      );
    }
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else if (_authMode == AuthMode.LoginWithMobile) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  void _switchToForgotPasswordMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.ForgotPassword;
        _emailController.text = '';
      });
    } else if (_authMode == AuthMode.LoginWithMobile) {
      setState(() {
        _authMode = AuthMode.ForgotPassword;
        _emailController.text = '';
      });
    }
  }

  void _switchLoginMode(AuthMode mode) {
    if (mode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Login;
      });
    } else {
      setState(() {
        _authMode = AuthMode.LoginWithMobile;
      });
    }
  }

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  @override
  Widget build(BuildContext context) {
    //connecting to naviagtor state to be aware of route changes
    final navigator = Navigator.of(context);
    //connecting to the device media
    final deviceSize = MediaQuery.of(context).size;
    //connecting to the page scaffold
    final scaffold = ScaffoldMessenger.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        height: _authMode == AuthMode.Signup
            ? 400
            : _authMode == AuthMode.Login
                ? 300
                : 200,
        constraints: BoxConstraints(
            minHeight: _authMode == AuthMode.Signup
                ? 400
                : _authMode == AuthMode.Login
                    ? 300
                    : 200),
        width: deviceSize.width * 0.85,
        padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_authMode == AuthMode.Signup) UserImagePicker(_pickedImage),
                if (_authMode == AuthMode.LoginWithMobile ||
                    _authMode == AuthMode.Login)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _authMode == AuthMode.LoginWithMobile
                            ? 'Login With Mobile'
                            : 'Login With Email/Password',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lato',
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      PopupMenuButton(
                        onSelected: (mode) => _switchLoginMode(mode),
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            child: Text('Login With Mobile'),
                            value: AuthMode.LoginWithMobile,
                          ),
                          PopupMenuItem(
                            child: Text('Login With E/P'),
                            value: AuthMode.Login,
                          )
                        ],
                      ),
                    ],
                  ),
                if (_authMode != AuthMode.LoginWithMobile)
                  TextFormField(
                    key: WidgetKey.emailTextField,
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      hintText: 'test@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value!.isEmpty ||
                          !RegExpressions.emailPattern.hasMatch(value)) {
                        return 'Invalid email!';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['email'] = value!;
                    },
                  ),
                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    key: WidgetKey.usernameTextField,
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'provide a username';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['username'] = value!;
                    },
                  ),
                if (_authMode == AuthMode.Login || _authMode == AuthMode.Signup)
                  TextFormField(
                    key: WidgetKey.passwordTextField,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                    controller: _passwordController,
                    validator: (value) {
                      if (value!.isEmpty || value.length < 5) {
                        return 'password should contain at least 6 characters';
                      }
                      if (!RegExpressions.passwordPattern.hasMatch(value)) {
                        return '''password shouldn't contain special characters 
                                  %*()#''';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['password'] = value!;
                    },
                  ),
                if (_authMode == AuthMode.Signup)
                  TextFormField(
                    key: WidgetKey.confirmPTextField,
                    enabled: _authMode == AuthMode.Signup,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                    ),
                    obscureText: true,
                    validator: _authMode == AuthMode.Signup
                        ? (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match!';
                            }
                          }
                        : null,
                  ),
                if (_authMode == AuthMode.Signup ||
                    _authMode == AuthMode.LoginWithMobile)
                  MaskedTextField(
                    key: WidgetKey.mobileTextField,
                    mask: '+### ### ### ####',
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Invalid number!';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _authData['mobile'] = value!.trim();
                    },
                  ),
                if (_authMode == AuthMode.Signup)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _interestsController,
                          decoration: const InputDecoration(
                            labelText: 'Sports Interests',
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please choose an interest';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _authData['interest'] = value!.trim();
                          },
                        ),
                      ),
                      DropdownButton<Interests>(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        // Array list of items
                        items: Interests.values.map((interest) {
                          return DropdownMenuItem(
                            value: interest,
                            child: Text(interest.toNameString()),
                          );
                        }).toList(),
                        // After selecting the desired option,it will
                        // change button value to selected value
                        onChanged: (Interests? newValue) {
                          setState(() {
                            _interestsController.text =
                                newValue!.toNameString();
                          });
                        },
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        key: WidgetKey.elevatedButton,
                        onPressed: _authMode == AuthMode.ForgotPassword
                            ? () async {
                                //set loading indicator
                                setState(() {
                                  _isLoading = true;
                                });
                                try {
                                  await _auth.sendPasswordResetEmail(
                                      email: _emailController.text);
                                  //UI dialog to inform user of  sent email
                                  scaffold.showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Reset Password email sent!'),
                                      duration: Duration(
                                        seconds: 1,
                                      ),
                                    ),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  var errorMessage = 'Password Reset failed.';
                                  switch (e.code) {
                                    case 'invalid-email':
                                      errorMessage =
                                          'This is not a valid email address';
                                      break;
                                    case 'user-not-found':
                                      errorMessage =
                                          'There is no user corresponding to this email address.';
                                      break;
                                    default:
                                      break;
                                  }

                                  await _showErrorDialog(errorMessage);
                                }
                                setState(() {
                                  //removing loading indicator
                                  _isLoading = false;
                                  //switching back to login mode
                                  _authMode = AuthMode.Login;
                                });
                              }
                            : () => _submit(navigator),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 25.0, vertical: 8.0),
                          foregroundColor:
                              Theme.of(context).primaryTextTheme.button!.color,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_authMode == AuthMode.ForgotPassword
                                ? 'RESET PASSWORD'
                                : _authMode == AuthMode.Login ||
                                        _authMode == AuthMode.LoginWithMobile
                                    ? 'LOG IN'
                                    : 'SIGN UP'),
                          ],
                        ),
                      ),
                    if (_authMode != AuthMode.ForgotPassword)
                      TextButton(
                        key: WidgetKey.textButton1,
                        onPressed: _switchAuthMode,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 4),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                            '${_authMode == AuthMode.Login || _authMode == AuthMode.LoginWithMobile ? 'SIGNUP' : 'LOGIN'} INSTEAD'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_authMode == AuthMode.Login ||
                    _authMode == AuthMode.ForgotPassword)
                  TextButton(
                    key: WidgetKey.textButton2,
                    onPressed: () {
                      if (_authMode == AuthMode.ForgotPassword) {
                        setState(() => _authMode = AuthMode.Login);
                      } else {
                        _switchToForgotPasswordMode();
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 4),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(_authMode == AuthMode.ForgotPassword
                        ? 'Cancel'
                        : 'Forgot Password?'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
