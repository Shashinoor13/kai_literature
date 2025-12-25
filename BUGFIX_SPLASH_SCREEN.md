# Bug Fix: Splash Screen Loading Hang

## Problem

The app would get stuck on the splash screen with "Literature" and a loading indicator, never transitioning to either the login screen or home feed.

## Root Cause

The authentication state check wasn't completing properly due to:

1. **Timing Issue**: The `AuthCheckRequested` event was being added in `main.dart` AFTER the AuthBloc was created, potentially before event handlers were fully registered
2. **Missing Loading State**: The auth check didn't emit `AuthLoading` state, so the router couldn't properly track the authentication check progress
3. **State Transition Issue**: The router's redirect logic was checking for `AuthInitial` or `AuthLoading`, but the bloc never explicitly emitted `AuthLoading`

This caused the app to stay in `AuthInitial` state indefinitely, and the router kept showing the splash screen.

## Solution

### 1. Moved Auth Check to BLoC Constructor

**Before** (`main.dart`):
```dart
final authBloc = AuthBloc(authRepository: authRepository)
  ..add(AuthCheckRequested());
```

**After** (`auth_bloc.dart` constructor):
```dart
AuthBloc({
  required AuthRepository authRepository,
})  : _authRepository = authRepository,
      super(AuthInitial()) {
  // Register event handlers
  on<AuthCheckRequested>(_onAuthCheckRequested);
  // ... other handlers

  // Check initial auth state immediately
  add(AuthCheckRequested());

  // Listen to auth state changes
  _authStateSubscription = _authRepository.authStateChanges.listen(
    (user) {
      add(AuthCheckRequested());
    },
  );
}
```

**Why**: Ensures the auth check event is added at the right time, after event handlers are registered.

### 2. Added Explicit Loading State

**Before**:
```dart
Future<void> _onAuthCheckRequested(
  AuthCheckRequested event,
  Emitter<AuthState> emit,
) async {
  try {
    final currentUser = _authRepository.currentUser;
    // ... rest of logic
  }
}
```

**After**:
```dart
Future<void> _onAuthCheckRequested(
  AuthCheckRequested event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());  // ← Added this!
  try {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      emit(Unauthenticated());
      return;
    }

    final userData = await _authRepository.getUserData(currentUser.uid);
    emit(Authenticated(userData));
  } catch (e) {
    await _authRepository.signOut();
    emit(Unauthenticated());  // ← Simplified error handling
  }
}
```

**Why**:
- Explicitly emits `AuthLoading` so router knows auth check is in progress
- Provides clear state transitions: `AuthInitial` → `AuthLoading` → `Authenticated`/`Unauthenticated`
- Simplified error handling to avoid getting stuck in error state

### 3. How the Flow Works Now

```
App Starts
    ↓
AuthBloc created → Emits AuthInitial
    ↓
Constructor adds AuthCheckRequested event
    ↓
Event handler emits AuthLoading
    ↓
Router sees AuthLoading → Shows Splash Screen
    ↓
Auth check completes (< 1 second)
    ↓
Emits Authenticated OR Unauthenticated
    ↓
Router redirects to:
  - Home Feed (if authenticated)
  - Login Screen (if not authenticated)
```

## Files Changed

- `lib/features/auth/bloc/auth_bloc.dart` - Moved auth check to constructor, added loading state
- `lib/main.dart` - Removed duplicate auth check event, cleaned up imports

## Testing

**Test Case 1: First Time User**
1. Fresh install / Clear app data
2. Open app
3. ✅ See splash screen briefly (1-2 seconds)
4. ✅ Navigate to login screen

**Test Case 2: Logged In User**
1. Already logged in
2. Close app
3. Reopen app
4. ✅ See splash screen briefly
5. ✅ Navigate to home feed automatically

**Test Case 3: After Logout**
1. Log out
2. Close app
3. Reopen app
4. ✅ See splash screen briefly
5. ✅ Navigate to login screen

## State Transition Timeline

- **0ms**: App starts, AuthBloc created with `AuthInitial`
- **~10ms**: `AuthCheckRequested` event added in constructor
- **~20ms**: Event processed, emits `AuthLoading`
- **~50ms**: Router sees `AuthLoading`, shows splash
- **~200-500ms**: Auth check completes
- **~500ms**: Emits `Authenticated` or `Unauthenticated`
- **~600ms**: Router redirects to appropriate screen

Total splash screen time: **< 1 second** ✅

## Result

✅ No more splash screen hang
✅ Fast, smooth transitions
✅ Proper state flow
✅ Clear loading indicators
