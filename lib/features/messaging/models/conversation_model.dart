import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation model matching Firestore conversations/ collection structure
/// See CLAUDE.md: Firebase Architecture > Firestore Collections > conversations/
class ConversationModel extends Equatable {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.updatedAt,
  });

  /// Create ConversationModel from Firestore document
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Convert ConversationModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get the other participant's ID (not the current user)
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId);
  }

  @override
  List<Object?> get props => [id, participants, lastMessage, updatedAt];
}
