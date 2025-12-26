/// Enum representing different reasons for reporting a post
enum ReportReason {
  spam,
  scam,
  violence,
  harassment,
  hateSpeech,
  misinformation,
  inappropriateContent,
  copyright,
  other,
}

/// Extension to get display text for report reasons
extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.violence:
        return 'Violence or Dangerous Organizations';
      case ReportReason.harassment:
        return 'Bullying or Harassment';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.misinformation:
        return 'False Information';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.copyright:
        return 'Intellectual Property Violation';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.spam:
        return 'Repetitive or unwanted content';
      case ReportReason.scam:
        return 'Fraudulent or deceptive content';
      case ReportReason.violence:
        return 'Threats, violence, or dangerous content';
      case ReportReason.harassment:
        return 'Targeted harassment or bullying';
      case ReportReason.hateSpeech:
        return 'Attacks based on identity or beliefs';
      case ReportReason.misinformation:
        return 'Deliberately false or misleading information';
      case ReportReason.inappropriateContent:
        return 'Sexually explicit or offensive content';
      case ReportReason.copyright:
        return 'Unauthorized use of copyrighted material';
      case ReportReason.other:
        return 'Something else that violates community guidelines';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

/// Model representing a post report
class PostReport {
  final String reportId;
  final String postId;
  final String reporterId;
  final ReportReason reason;
  final String? additionalDetails;
  final DateTime createdAt;

  const PostReport({
    required this.reportId,
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.additionalDetails,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason.value,
      'additionalDetails': additionalDetails,
      'createdAt': createdAt,
    };
  }

  factory PostReport.fromFirestore(Map<String, dynamic> data, String id) {
    return PostReport(
      reportId: id,
      postId: data['postId'] as String,
      reporterId: data['reporterId'] as String,
      reason: ReportReason.values.firstWhere(
        (r) => r.value == data['reason'],
        orElse: () => ReportReason.other,
      ),
      additionalDetails: data['additionalDetails'] as String?,
      createdAt: (data['createdAt'] as dynamic).toDate(),
    );
  }
}
