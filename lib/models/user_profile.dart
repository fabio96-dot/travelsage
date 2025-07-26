import 'package:hive/hive.dart';
part 'user_profile.g.dart';

@HiveType(typeId: 3)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String username;

  @HiveField(1)
  final String? imagePath;

  UserProfile({required this.username, this.imagePath});

  Map<String, dynamic> toMap() => {
    'username': username,
    'imagePath': imagePath,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    username: map['username'] ?? 'Utente',
    imagePath: map['imagePath'],
  );
} 
