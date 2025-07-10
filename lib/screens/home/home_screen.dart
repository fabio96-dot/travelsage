import 'package:flutter/material.dart';
import 'package:travel_sage/screens/login/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Benvenuto")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ciao ${user?.email ?? 'utente'}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AuthService().signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}