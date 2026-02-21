import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

@AutoRoutePage(path: '/')
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen'),
      ),
    );
  }
}
