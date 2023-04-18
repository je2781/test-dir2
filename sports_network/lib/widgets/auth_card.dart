import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_country_code_picker/fl_country_code_picker.dart';
import "package:provider/provider.dart";

import '../data/reg_express.dart';
import '../data/widget_keys.dart';
import '../screens/verify_screen.dart';
import '../screens/tabs_screen.dart';
import '../picker/user_image_picker.dart';

import '../data/extensions.dart';
import '../models/interests.dart';
import '../provider/country_info.dart';

enum AuthMode { Signup, Login, ForgotPassword, LoginWithMobile }

class AuthCard extends StatefulWidget {
  const AuthCard({
    Key? key,
  }) : super(key: key);

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  //creating instance of country picker
  final countryPicker = const FlCountryCodePicker();
  //defining country code variable
  CountryCode? countryCode;
  //connecting key to Form state
  final _formKey = GlobalKey<FormState>();
  AuthMode _authMode = AuthMode.Login;
  //initializing authData
  var _authData = {
    'email': '',
    'password': '',
    'mobile': '',
    'interest': '',
    'username': ''
  };
  //conditional variable to control loading indicator
  var _isLoading = false;

  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _interestsController = TextEditingController();
  final _mobileController = TextEditingController();

  //establishing connection to firebaseAuth api
  final _auth = FirebaseAuth.instance;
  //defining user image file
  File? _userImageFile;

  //fetching country data based on geo location
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) async {
      try {
        await Provider.of<CountryInfo>(context, listen: false)
            .fetchAndSetCountryData();
      } on HttpException catch (_) {
        var errMessage = 'failed to fetch country data';
        await _showErrorDialog(errMessage);
      }
    });
  }

  //disposing controllers to prevent memory leaks
  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _interestsController.dispose();
    _mobileController.dispose();
  }

  void _mobileVerificationFailed(FirebaseAuthException e) async {
    var errorMessage = 'Phone Verification Failed!';

    if (e.message != null) {
      errorMessage = e.message!;
    }

    //removing loading indicator
    setState(() {
      _isLoading = false;
    });

    await _showErrorDialog(errorMessage);
  }

  Future<void> _handleDialog(
      String verificationId, NavigatorState navigator) async {
    final smsCode = _codeController.text.trim();
    // Create a PhoneAuthCredential with the code
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    //signing in with phone auth credentials
    await _auth.signInWithCredential(credential);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => TabsScreen(),
      ),
    );
  }

  Future<void> _showSmsCodeDialog(
      String verificationId, NavigatorState navigator) async {
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
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleDialog(verificationId, navigator),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Done"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.redAccent,
            ),
            onPressed: () => _handleDialog(verificationId, navigator),
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
    final userCreds = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    //connecting to firebasestorage api, and creating a path and file name for the profile pic
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child('${userCreds.user!.uid}.jpg');
    //wait for profile pic to be stored in path
    await ref.putFile(_userImageFile!).whenComplete(() => null);
    //download profile path url to store in firebasestore
    final imageUrl = await ref.getDownloadURL();
    //connecting to firebasestore api, and storing user signup details
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(userCreds.user!.uid)
        .set({
      'mobile': mobile,
      'email': email,
      'interest': interest,
      'username': username,
      'image_url': imageUrl
    });
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
        await _auth.signInWithEmailAndPassword(
            email: _authData['email']!, password: _authData['password']!);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => TabsScreen(),
          ),
        );
      } else if (_authMode == AuthMode.Signup) {
        // Sign user up with email/password, and store extra values in the store using the firebasefirestore api
        await _getAuthSignUp(
            _authData['email']!,
            _authData['password']!,
            _authData['mobile']!,
            _authData['interest']!,
            _authData['username']!);

        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyScreen(),
          ),
        );
      } else {
        //signin using mobile number
        await _auth.verifyPhoneNumber(
            phoneNumber: _authData['mobile'],
            verificationCompleted: (credential) async {
              //signin into account with provided phone auth credential
              await _auth.signInWithCredential(credential);
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (_) => TabsScreen(),
                ),
              );
            },
            verificationFailed: (e) => _mobileVerificationFailed(e),
            codeSent: (String verificationId, int? forceResendingToken) async {
              //show dialog to take sms code from the user
              await _showSmsCodeDialog(verificationId, navigator);
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
    //clearing text fields
    _emailController.clear();
    _passwordController.clear();
    _interestsController.clear();
    _mobileController.clear();

    if (_authMode == AuthMode.Login || _authMode == AuthMode.LoginWithMobile) {
      setState(() {
        //resetting country code varriable
        countryCode = null;
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  void _switchToForgotPasswordMode() {
    //clearing text field
    _emailController.clear();

    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.ForgotPassword;
      });
    }
  }

  void _switchLoginMode(AuthMode mode) {
    //clearing text fields
    _emailController.clear();
    _passwordController.clear();
    _interestsController.clear();
    _mobileController.clear();

    if (mode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Login;
      });
    } else {
      setState(() {
        //resetting country code varriable
        countryCode = null;
        _authMode = AuthMode.LoginWithMobile;
      });
    }
  }

  void _pickedImage(File image) {
    _userImageFile = image;
  }

  @override
  Widget build(BuildContext context) {
    //connecting to country store to be aware of changes in country info state
    final countryStore = Provider.of<CountryInfo>(context);
    //connecting to navigator state to be aware of route changes
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
            ? 600
            : _authMode == AuthMode.Login
                ? 320
                : 220,
        constraints: BoxConstraints(
            minHeight: _authMode == AuthMode.Signup
                ? 600
                : _authMode == AuthMode.Login
                    ? 320
                    : 220),
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
                        key: WidgetKey.popupMenuButton,
                        onSelected: (mode) => _switchLoginMode(mode),
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            key: WidgetKey.popupMenuItemLoginWithMobile,
                            child: Text('Login With Mobile'),
                            value: AuthMode.LoginWithMobile,
                          ),
                          PopupMenuItem(
                            key: WidgetKey.popupMenuItemLogin,
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
                    textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.next,
                    controller: _passwordController,
                    validator: (value) {
                      if (value!.isEmpty || value.length < 6) {
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
                    textInputAction: TextInputAction.next,
                    validator: _authMode == AuthMode.Signup
                        ? (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match!';
                            }
                            return null;
                          }
                        : null,
                  ),
                if (_authMode == AuthMode.Signup ||
                    _authMode == AuthMode.LoginWithMobile)
                  TextFormField(
                    key: WidgetKey.mobileTextField,
                    controller: _mobileController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(
                          right: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final code = await countryPicker.showPicker(
                                    context: context);
                                setState(() {
                                  countryCode = code;
                                });
                              },
                              child: Row(
                                children: [
                                  Container(
                                      child: countryCode?.flagImage() ??
                                          Image.network(
                                              countryStore.imageUrl!)),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          countryCode?.dialCode ??
                                              countryStore.dialCode!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'please provide a mobile number!';
                      }

                      if (value.trim().length < 10) {
                        return 'invalid number!';
                      }

                      return null;        
                    },
                    onSaved: (value) {
                      _authData['mobile'] =
                          '${countryCode?.dialCode ?? countryStore.dialCode}${value!.trim().substring(1)}';
                    },
                  ),
                if (_authMode == AuthMode.Signup)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: WidgetKey.interestsTextField,
                          controller: _interestsController,
                          textInputAction: TextInputAction.done,
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
                          onFieldSubmitted: (_) => _submit(navigator),
                        ),
                      ),
                      PopupMenuButton<Interests>(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        // Array list of items
                        itemBuilder: (_) => Interests.values.map((interest) {
                          return PopupMenuItem(
                            value: interest,
                            child: Text(interest.toNameString()),
                          );
                        }).toList(),
                        // After selecting the desired option,it will
                        // change button value to selected value
                        onSelected: (Interests? newValue) {
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
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                                  var errorMessage =
                                      'Password Reset failed. Please check your entered email address';

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
                                  //clearing email text field
                                  _emailController.clear();

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
                        setState(() {
                          //clearing email text field
                          _emailController.clear();
                          _authMode = AuthMode.Login;
                        });
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
