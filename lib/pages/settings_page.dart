import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _numOfImagesController = TextEditingController();
  final _startingAddressController = TextEditingController();

  bool _useNewAddress = false;
  bool _useRandomAddress = false;

  @override
  void dispose() {
    _numOfImagesController.dispose();
    _startingAddressController.dispose();
    super.dispose();
  }

  TextFormField _numOfImagesFormField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Number of images to download",
        hintText: "Enter the number of images to download",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1.5),
        ),
      ),
      textInputAction: TextInputAction.next,
      maxLength: 5,
      keyboardType: TextInputType.number,
      controller: _numOfImagesController,
      autofocus: true,
      validator: (value) {
        value = value ?? '';
        if (value.isEmpty) {
          return "Please enter the number of images to download";
        } else if (int.tryParse(value) == null) {
          return "Please enter a valid number";
        } else if (int.parse(value) < 1) {
          return "Please enter a number greater than 0";
        } else {
          return null;
        }
      },
    );
  }

  Widget _useNewAddressCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _useNewAddress,
          onChanged: (value) {
            setState(() {
              _useNewAddress = value!;
            });
          },
        ),
        const Text("Use new addresses"),
      ],
    );
  }

  _useRandomAddressCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _useRandomAddress,
          onChanged: (value) {
            setState(() {
              _useRandomAddress = value!;
            });
          },
        ),
        const Text("Use random addresses"),
      ],
    );
  }

  TextFormField _startingAddressFormField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Starting address",
        hintText: "Enter the starting address",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(width: 1.5),
        ),
      ),
      maxLength: _useNewAddress ? 12 : 6,
      controller: _startingAddressController,
      enabled: _useRandomAddress,
      validator: (value) {
        value = value ?? '';
        RegExp mask = _useNewAddress
            ? RegExp(r'^[a-zA-Z0-9_-]{12}$')
            : RegExp(r'^[a-z0-9]{6}$');
        if (value.isEmpty) {
          return "Please enter the starting address";
        } else if ((_useNewAddress && value.length != 12) ||
            (!_useNewAddress && value.length != 6)) {
          return "Please enter a max length address";
        } else if (!mask.hasMatch(value)) {
          return "Please enter a address with only a ${_useNewAddress ? '(a-z, A-Z, 0-9, _ and -)' : '(a-z, 0-9)'}";
        } else {
          return null;
        }
      },
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _numOfImagesFormField(),
              const SizedBox(height: 5),
              _useNewAddressCheckbox(),
              const SizedBox(height: 10),
              _useRandomAddressCheckbox(),
              const SizedBox(height: 16),
              _startingAddressFormField(),
              ElevatedButton(
                onPressed: _saveSettings,
                child: const Text("Save"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                        fixedSize:
                            MaterialStateProperty.all(const Size(150, 30))),
                    child: const Text('Recreate database'),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ButtonStyle(
                        fixedSize:
                            MaterialStateProperty.all(const Size(150, 30))),
                    onPressed: () {},
                    child: const Text('Clear images'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
