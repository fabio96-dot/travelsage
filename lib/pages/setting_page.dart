import 'dart:io';
import '../utils/helpers/hive_istances.dart';
import 'package:travel_sage/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_sage/providers/theme_provider.dart'; // contiene themeModeProvider

// ------------------ MODELLO PROFILO ------------------

class UserProfileState {
  final String username;
  final File? profileImage;

  UserProfileState({required this.username, this.profileImage});

  UserProfileState copyWith({
    String? username,
    File? profileImage,
  }) {
    return UserProfileState(
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

// ------------------ NOTIFIER PROFILO ------------------

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier() : super(UserProfileState(username: 'Utente')) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await utenteHelper.openBox(); // assicura che il box sia aperto
    final profili = await utenteHelper.getAll();

    String username = 'Utente';
    File? imageFile;

    if (profili.isNotEmpty) {
      final profilo = profili.first;
      username = profilo.username;
      if (profilo.imagePath != null) {
        final file = File(profilo.imagePath!);
        if (file.existsSync()) imageFile = file;
      }
    }

    // 🔄 Se Firebase è loggato, prova a leggere da Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('utenti').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['username'] != null) username = data['username'];
      }
    }

    state = UserProfileState(username: username, profileImage: imageFile);
  }

  Future<void> setUsername(String newUsername) async {
    state = state.copyWith(username: newUsername);

    final imagePath = state.profileImage?.path;

    final nuovoProfilo = UserProfile(
      username: newUsername.trim(),
      imagePath: imagePath,
    );

    await utenteHelper.save('local_user', nuovoProfilo);
  }


  Future<void> setProfileImage(File? newImage) async {
    state = state.copyWith(profileImage: newImage);

    final existing = await utenteHelper.getAll();
    final username = existing.isNotEmpty ? existing.first.username : state.username;

    final nuovoProfilo = UserProfile(
      username: username,
      imagePath: newImage?.path,
    );

    await utenteHelper.save('local_user', nuovoProfilo);
  }


  /// 🔁 SINCRONIZZA SU FIREBASE
  Future<void> syncProfileWithFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('utenti').doc(user.uid).set({
      'username': state.username,
    }, SetOptions(merge: true));

    await user.updateDisplayName(state.username);
  }
}
  final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>(
  (ref) => UserProfileNotifier(),
  );

// ------------------ PAGINA IMPOSTAZIONI ------------------

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      ref.read(userProfileProvider.notifier).setProfileImage(File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();
    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.setUsername(newUsername);
    await notifier.syncProfileWithFirebase();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profilo salvato')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    _usernameController.text = userProfile.username;

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
                backgroundImage:
                    userProfile.profileImage != null ? FileImage(userProfile.profileImage!) : null,
                backgroundColor: Colors.grey[300],
                child: userProfile.profileImage == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              userProfile.username,
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

          // ------------------ BANNER PREMIUM ------------------
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.amber.shade900.withOpacity(0.3)
                  : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? Colors.amber.shade700 : Colors.amber.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined,
                    size: 36,
                    color: isDark
                        ? Colors.amber.shade300
                        : Colors.amber),
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
                          color:
                              isDark ? Colors.amber.shade300 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sblocca funzionalità extra con TravelSage PRO',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.amber.shade200
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? Colors.amber.shade700 : Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Funzionalità abbonamenti in arrivo')),
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
            onPressed: _saveProfile,
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
          const Text('Preferenze',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // ------------------ TEMA SCURO ------------------
          SwitchListTile(
            title: const Text('Modalità Scura'),
            value: themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark),
            onChanged: (val) {
              ref.read(themeModeProvider.notifier).state =
                  val ? ThemeMode.dark : ThemeMode.light;
            },
            secondary: Icon(
              (themeMode == ThemeMode.dark ||
              (themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark))
                ? Icons.dark_mode
                : Icons.light_mode,
              color: Colors.indigo,
            ),
          ),

          // ------------------ LINGUA (Mock) ------------------
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Lingua'),
            subtitle: const Text('Italiano'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Selezione lingua: funzione da implementare')),
              );
            },
          ),

          // ------------------ TEMA COLORE (Mock) ------------------
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema Colore'),
            subtitle: const Text('Indigo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Cambio colore: funzione da implementare')),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text('Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // ------------------ CAMBIA PASSWORD (Mock) ------------------
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Cambia password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Cambio password: funzione da implementare')),
              );
            },
          ),

          // ------------------ ELIMINA ACCOUNT (Mock) ------------------
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
            title: const Text('Elimina Account'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Eliminazione account: funzione da implementare')),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const Text('App',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // ------------------ INFO APP ------------------
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

          // ------------------ LOGOUT ------------------
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Esci'),
           onTap: () async {
              await utenteHelper.clearAll();
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}