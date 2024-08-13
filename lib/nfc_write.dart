import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nfc/constants.dart';
import 'package:nfc_manager/nfc_manager.dart';

class WriteNfc extends StatefulWidget {
  const WriteNfc({super.key});

  @override
  State<WriteNfc> createState() => _WriteNfcState();
}

class _WriteNfcState extends State<WriteNfc> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  ValueNotifier<String> result = ValueNotifier('');

  final _formkey = GlobalKey<FormState>();

  bool isSetPassword = false;
  bool isConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        result.value = 'NFC is not available on this device';
      }
    } catch (e) {
      result.value = 'Error checking NFC availability: $e';
    }
  }

// clear nfc tag data
  void _clearNfcData() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not NDEF writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      try {
        // Create an empty NDEF message to clear the tag
        NdefMessage emptyMessage = NdefMessage([
          NdefRecord.createText(''), // Write an empty text record
        ]);

        await ndef.write(emptyMessage);
        result.value = 'NFC tag data cleared successfully';
        setState(() {
        //  result.value = '';
          isSetPassword = false;
          isConfirmPassword = false;
          _textController.text = '';
          _urlController.text = '';
        });
        NfcManager.instance.stopSession();
      } catch (e) {
        result.value = 'Failed to clear NFC tag: $e';
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
      }
    });
  }

// write nfc tag
  void _writeNfc(String password) {
    final text = _textController.text;
    final url = _urlController.text;

    print(text);
    print(url);

    if (text.isEmpty && url.isEmpty) {
      result.value = 'Please enter text or URL to write';
      return;
    }

    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not NDEF writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      NdefMessage message;
      if (url.isNotEmpty) {
        // Write URL
        message = NdefMessage([
          NdefRecord.createUri(Uri.parse(url)),
          NdefRecord.createText('psd:$password'),
        ]);
      } else {
        // Write Text
        message = NdefMessage([
          NdefRecord.createText(text),
          NdefRecord.createText('psd:$password'),
        ]);
      }

      try {
        await ndef.write(message);
        result.value = 'Successfully written to NFC tag';
        // Constants.toastMessage(
        //     context: context, msg: 'Successfully written to NFC tag');

        setState(() {
        //  result.value = '';
          isSetPassword = false;
          isConfirmPassword = false;
          _textController.text = '';
          _urlController.text = '';
        });
        NfcManager.instance.stopSession();
        // setState(() {
        //   isSetPassword = false;
        //   isConfirmPassword = false;
        // });
      } catch (e) {
        result.value = 'Failed to write NFC tag: $e';
        NfcManager.instance.stopSession(errorMessage: result.value.toString());
      }
    });
  }

// wrtie nfc with password confirmation
  void _writeNfcWithPasswordConfirmation() {
    final confirmPassword = _confirmPasswordController.text;
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null || !ndef.isWritable) {
        result.value = 'Tag is not NDEF writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      // Read stored password from the tag
      var records = ndef.cachedMessage?.records;
      if (records != null && records.isNotEmpty) {
        String payload = utf8.decode(records.first.payload.skip(3).toList());

        if (payload.startsWith('psd:')) {
          String storedPassword = payload.split(':')[1].trim();
          print("Stored Password: $storedPassword");

          print(storedPassword == confirmPassword);
          if (storedPassword != confirmPassword) {
            result.value = 'Incorrect password. Write operation aborted.';
            NfcManager.instance.stopSession(errorMessage: result.value);
            return;
          } else {
            print('lkajdfaklfjdaf');
            _writeNfc(storedPassword);
          }
        }
      }
    });
  }

// check nfc tag contains password key or not (based on that call the functions)
  void _checkNfc() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef == null) {
        result.value = 'Tag is not NDEF writable';
        NfcManager.instance.stopSession(errorMessage: result.value);
        return;
      }

      // Check if there is a 'password' key
      var records = ndef.cachedMessage?.records;
      if (records != null && records.isNotEmpty) {
        bool passwordFound = false;
        for (var record in records) {
          if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
              String.fromCharCodes(record.type) == 'T') {
            // Extracting text payload correctly
            String payload = utf8.decode(record.payload.skip(3).toList());
            print('Payload: $payload');

            if (payload.startsWith('psd:')) {
              passwordFound = true;
              setState(() {
                isConfirmPassword = true;
                isSetPassword = false;
              });
              break;
            } else {
              print('Password not found');
            }
          }
        }

        if (!passwordFound) {
          setState(() {
            isSetPassword = true;
          });
        }
      } else {
        result.value = 'No records found on the NFC tag';
        // setState(() {
        //    isSetPassword = true;
        // });
      }
      NfcManager.instance.stopSession();
    });
  }

// write nfc password
  void _writeNFCPassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.isEmpty) {
      result.value = 'Please enter a password';
      return;
    }

    if (password != confirmPassword) {
      result.value = "Password doesn't match";
      return;
    }

    if (_formkey.currentState!.validate()) {
      _formkey.currentState!.save();
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          result.value = 'Tag is not NDEF writable';
          NfcManager.instance.stopSession(errorMessage: result.value);
          return;
        }

        try {
          NdefMessage message = NdefMessage([
            NdefRecord.createText('psd:$password'),
          ]);

          await ndef.write(message);
          result.value = 'Password successfully written to NFC tag';
            // Constants.toastMessage(
            // context: context, msg: 'Password successfully written');

          setState(() {
          //  result.value = '';
            isSetPassword = false;
            isConfirmPassword = false;
            _textController.text = '';
            _urlController.text = '';
          });
          NfcManager.instance.stopSession();
        } catch (e) {
          result.value = 'Failed to write password to NFC tag: $e';
          NfcManager.instance
              .stopSession(errorMessage: result.value.toString());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write NFC'),
        actions: [
          TextButton(
              onPressed: () {
                setState(() {
                  isSetPassword = !isSetPassword;
                });
              },
              child: Text(isSetPassword ? 'Write NFC' : 'Set Password',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              if (!isSetPassword && !isConfirmPassword) ...[
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          labelText: 'Text to write',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL to write',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isSetPassword) ...[
                Column(
                  children: [
                    Form(
                      key: _formkey,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'This field is required';
                            } else if (value.length > 5) {
                              return 'Password lenght must be below 6 characters';
                            }
                          },
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isConfirmPassword) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Enter password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
              ElevatedButton(
                onPressed: isSetPassword
                    ? _writeNFCPassword
                    : isConfirmPassword
                        ? _writeNfcWithPasswordConfirmation
                        : _checkNfc,
                child: Text(isSetPassword
                    ? 'Write Password'
                    : isConfirmPassword
                        ? 'Confirm and Write NFC'
                        : 'Write NFC'),
              ),
              ValueListenableBuilder<String>(
                valueListenable: result,
                builder: (context, value, _) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(value),
                ),
              ),
              SizedBox(height: 150),
              ElevatedButton(
                onPressed: _clearNfcData,
                child: Text('Clear NFC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
