enum IssueStatus {
  open,
  investigating,
  resolved;

  static IssueStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'investigating':
        return IssueStatus.investigating;
      case 'resolved':
        return IssueStatus.resolved;
      case 'open':
      default:
        return IssueStatus.open;
    }
  }

  String toDbString() {
    switch (this) {
      case IssueStatus.investigating:
        return 'investigating';
      case IssueStatus.resolved:
        return 'resolved';
      case IssueStatus.open:
        return 'open';
    }
  }
}

class SupportIssueModel {
  final String id;
  final String? bookingId;
  final String reportedBy;
  final String? reporterName;
  final String userRole;
  final String issueType;
  final String description;
  final IssueStatus status;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const SupportIssueModel({
    required this.id,
    this.bookingId,
    required this.reportedBy,
    this.reporterName,
    required this.userRole,
    required this.issueType,
    required this.description,
    required this.status,
    this.resolutionNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SupportIssueModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SupportIssueModel(
      id: id ?? map['id'] ?? '',
      bookingId: map['bookingId'],
      reportedBy: map['reportedBy'] ?? '',
      reporterName: map['reporterName'],
      userRole: map['userRole'] ?? 'passenger',
      issueType: map['issueType'] ?? 'General Query',
      description: map['description'] ?? '',
      status: IssueStatus.fromString(map['status']),
      resolutionNotes: map['resolutionNotes'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null
          ? DateTime.tryParse(map['resolvedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'userRole': userRole,
      'issueType': issueType,
      'description': description,
      'status': status.toDbString(),
      'resolutionNotes': resolutionNotes,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}
