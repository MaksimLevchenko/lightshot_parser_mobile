import 'package:flutter/material.dart';
import 'package:lightshot_parser_mobile/pages/settings_page.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Widget _gallery() {
    return Placeholder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) => SettingsPage()));
            },
            icon: Icon(Icons.settings),
          )
        ],
        title: Text('Lightshot Parser'),
        centerTitle: true,
      ),
      body: SafeArea(
        minimum: EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                child: _gallery(),
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text('Download'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
