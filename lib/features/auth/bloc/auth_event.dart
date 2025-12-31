import 'package:equatable/equatable.dart';

/// Authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check authentication state on app start
class AuthCheckRequested extends AuthEvent {}

/// Sign in with email and password
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Sign up with email, password, and username
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final DateTime? dateOfBirth;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.username,
    this.dateOfBirth,
  });

  @override
  List<Object?> get props => [email, password, username, dateOfBirth];
}

/// Sign out
class SignOutRequested extends AuthEvent {}

/// Update user profile
class UpdateProfileRequested extends AuthEvent {
  final String? username;
  final String? bio;
  final String? profileImageUrl;

  const UpdateProfileRequested({
    this.username,
    this.bio,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [username, bio, profileImageUrl];
}

/// Delete account
class DeleteAccountRequested extends AuthEvent {}
