import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_viaggio.dart';

final travelBoardPostsProvider = StreamProvider<List<PostViaggio>>((ref) {
  return FirebaseFirestore.instance
      .collection('travel_board_posts')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return PostViaggio.fromMap(doc.id, doc.data());
    }).toList();
  });
});
