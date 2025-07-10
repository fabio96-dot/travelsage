import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _username;
  File? _profileImage;
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Utente';
      _usernameController.text = _username!;
      final imagePath = prefs.getString('profileImagePath');
      if (imagePath != null && imagePath.isNotEmpty) {
        _profileImage = File(imagePath);
      }
    });
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text.trim());
    if (_profileImage != null) {
      await prefs.setString('profileImagePath', _profileImage!.path);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profilo salvato')),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------ PROFILO ------------------
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                backgroundColor: Colors.grey[300],
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _username ?? 'Utente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Nome Utente',
              border: OutlineInputBorder(),
            ),
          ),

          // Banner elegante per abbonamento con supporto dark mode
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.amber.shade700 : Colors.amber.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 36, color: isDark ? Colors.amber.shade300 : Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Abbonamento Gratuito',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.amber.shade300 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sblocca funzionalità extra con TravelSage PRO',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.amber.shade200 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.amber.shade700 : Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funzionalità abbonamenti in arrivo')),
                    );
                  },
                  child: const Text('Scopri'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Salva Profilo'),
            onPressed: _saveUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text('Preferenze', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Modalità scura
          SwitchListTile(
            title: const Text('Modalità Scura'),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleTheme(),
            secondary: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Colors.indigo,
            ),
          ),

          // Lingua (mock)
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Lingua'),
            subtitle: const Text('Italiano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selezione lingua: funzione da implementare')),
              );
            },
          ),

          // Tema colore (mock)
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema Colore'),
            subtitle: const Text('Indigo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cambio colore: funzione da implementare')),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Cambio password (mock)
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambia password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cambio password: funzione da implementare')),
              );
            },
          ),

          // Elimina account (mock)
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Elimina Account'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eliminazione account: funzione da implementare')),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text('App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Info App (mock)
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info App'),
            subtitle: const Text('TravelSage v1.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'TravelSage',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 TravelSage Inc.',
              );
            },
          ),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Esci'),
            onTap: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
