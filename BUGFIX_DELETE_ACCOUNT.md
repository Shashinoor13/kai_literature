# Bug Fix: Loading State After Account Deletion

## Problem

After deleting an account and attempting to log in with the same credentials, the app would get stuck in a loading state instead of showing an error message.

## Root Cause

When an account was deleted:
1. Firestore user document was deleted
2. Firebase Auth user was deleted
3. BUT if you tried to log in with those credentials again (or if Firebase Auth still had cached state), the auth check would fail when trying to fetch the Firestore user data
4. The `AuthCheckRequested` event would catch the error but only emit `AuthError` without transitioning to `Unauthenticated`
5. This left the app stuck in the error state

## Solution

### 1. Fixed Auth State Check (`auth_bloc.dart`)

**Before:**
```dart
catch (e) {
  emit(AuthError(e.toString()));
}
```

**After:**
```dart
catch (e) {
  // If user data not found (deleted account), sign out and go to unauthenticated
  await _authRepository.signOut();
  emit(AuthError(e.toString()));
  emit(Unauthenticated());
}
```

**Why:** Now when user data is missing (deleted account), the app:
- Signs out the Firebase Auth session
- Shows the error message
- Transitions to `Unauthenticated` state → redirects to login screen

### 2. Improved Delete Account Flow (`auth_repository.dart`)

**Before:**
```dart
Future<void> deleteAccount(String userId) async {
  try {
    await _firestore.collection('users').doc(userId).delete();
    await _firebaseAuth.currentUser?.delete();
  } catch (e) {
    throw Exception('Failed to delete account: $e');
  }
}
```

**After:**
```dart
Future<void> deleteAccount(String userId) async {
  try {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No user currently signed in');
    }

    // Delete Firestore user document first
    await _firestore.collection('users').doc(userId).delete();

    // Delete Firebase Auth user
    await user.delete();

    // Sign out to clear any cached state
    await signOut();
  } catch (e) {
    // If deletion fails due to recent login requirement, throw specific error
    if (e.toString().contains('requires-recent-login')) {
      throw Exception('Please sign in again to delete your account');
    }
    throw Exception('Failed to delete account: $e');
  }
}
```

**Improvements:**
- Explicit null check for current user
- Call `signOut()` after deletion to clear all cached auth state
- Better error handling for Firebase Auth "requires-recent-login" errors
- More robust deletion sequence

### 3. Better Error Message Display

Added consistent error message styling across login/signup screens:
- Red background color
- 3-second duration
- Consistent user experience

## Testing

**Test Case 1: Delete Account → Try Login**
1. Log in with test account
2. Delete account from profile screen
3. Try to log in with same credentials
4. ✅ Shows "No user found with this email" error
5. ✅ Returns to login screen (no loading state hang)

**Test Case 2: Delete Account → Create New Account**
1. Delete account
2. Sign up again with same email
3. ✅ Creates new account successfully

**Test Case 3: Normal Login After Another User Deleted**
1. User A deletes their account
2. User B tries to log in
3. ✅ User B logs in normally (no interference)

## Files Changed

- `lib/features/auth/bloc/auth_bloc.dart` - Fixed auth check error handling
- `lib/repositories/auth_repository.dart` - Improved delete account flow
- `lib/features/auth/screens/login_screen.dart` - Better error messages
- `lib/features/auth/screens/signup_screen.dart` - Better error messages

## Result

✅ No more loading state hangs
✅ Clear error messages
✅ Proper state transitions
✅ Clean auth session cleanup
