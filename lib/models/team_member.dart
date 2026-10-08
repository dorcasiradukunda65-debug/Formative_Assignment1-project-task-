/// Represents a team member / user in the workspace.
class TeamMember {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarColorHex;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarColorHex,
  });

  /// Derives 1-2 letter initials from the member's full name.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Converts the model to a JSON Map for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatarColorHex': avatarColorHex,
    };
  }

  /// Reconstructs the model from stored JSON.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'Developer',
      avatarColorHex: json['avatarColorHex'] as String?,
    );
  }

  /// Creates a copy with modified fields.
  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarColorHex,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarColorHex: avatarColorHex ?? this.avatarColorHex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TeamMember(id: $id, name: $name, role: $role)';
}
