import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:literature/features/auth/bloc/auth_event.dart';
import 'package:literature/features/auth/bloc/auth_state.dart';
import 'package:literature/repositories/auth_repository.dart';

/// Authentication BLoC
/// Handles all authentication-related business logic
/// See CLAUDE.md: State Management Rules (BLoC)
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<DeleteAccountRequested>(_onDeleteAccountRequested);

    // Check initial auth state immediately
    add(AuthCheckRequested());

    // Listen to auth state changes
    _authStateSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthCheckRequested());
    });
  }

  /// Check authentication state
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser == null) {
        emit(Unauthenticated());
        return;
      }

      // Get user data from Firestore
      final userData = await _authRepository.getUserData(currentUser.uid);
      emit(Authenticated(userData));
    } catch (e) {
      // If user data not found (deleted account), sign out and go to unauthenticated
      await _authRepository.signOut();
      emit(Unauthenticated());
    }
  }
  // Future<void> _onAuthCheckRequested(
  //   AuthCheckRequested event,
  //   Emitter<AuthState> emit,
  // ) async {
  //   emit(AuthLoading());

  //   final currentUser = _authRepository.currentUser;

  //   if (currentUser == null) {
  //     emit(Unauthenticated());
  //     return;
  //   }

  //   try {
  //     final userData = await _authRepository.getUserData(currentUser.uid);
  //     emit(Authenticated(userData));
  //   } catch (e) {
  //     emit(AuthError('Failed to load user data'));
  //     // optionally still keep user authenticated
  //   }
  // }

  /// Handle sign in
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userId = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      final userData = await _authRepository.getUserData(userId);
      emit(Authenticated(userData));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  /// Handle sign up
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userId = await _authRepository.signUp(
        email: event.email,
        password: event.password,
        username: event.username,
        dateOfBirth: event.dateOfBirth,
      );

      final userData = await _authRepository.getUserData(userId);
      emit(Authenticated(userData));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  /// Handle sign out
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// Handle profile update
  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;

    try {
      final currentUser = (state as Authenticated).user;
      await _authRepository.updateUserProfile(
        userId: currentUser.id,
        username: event.username,
        bio: event.bio,
        profileImageUrl: event.profileImageUrl,
      );

      // Refresh user data
      final userData = await _authRepository.getUserData(currentUser.id);
      emit(Authenticated(userData));
    } catch (e) {
      emit(AuthError(e.toString()));
      // Restore previous state
      if (state is Authenticated) {
        emit(state);
      }
    }
  }

  /// Handle delete account
  Future<void> _onDeleteAccountRequested(
    DeleteAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! Authenticated) return;

    try {
      final currentUser = (state as Authenticated).user;
      await _authRepository.deleteAccount(currentUser.id);
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
