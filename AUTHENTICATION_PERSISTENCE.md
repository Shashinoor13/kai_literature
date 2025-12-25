# Authentication Persistence

## How It Works

The app now automatically persists authentication state, so users **don't have to log in every time** they open the app.

### Implementation Details

1. **Firebase Auth Persistence**: Firebase Authentication automatically persists the user's session locally on the device.

2. **App Startup Flow**:
   ```
   App Starts
       ↓
   Show Splash Screen (/splash)
       ↓
   AuthBloc checks auth state (AuthCheckRequested)
       ↓
   Firebase returns current user (if logged in)
       ↓
   Authenticated → Redirect to Home (/)
   OR
   Not Authenticated → Redirect to Login (/login)
   ```

3. **Router Logic** (in `app_router.dart`):
   - Starts at `/splash` screen
   - While auth state is being checked (`AuthInitial` or `AuthLoading`), shows splash screen
   - Once auth check completes:
     - If user is authenticated → Navigate to home feed
     - If not authenticated → Navigate to login screen

4. **Auth State Listener** (in `auth_bloc.dart`):
   - Listens to Firebase auth state changes via `authStateChanges` stream
   - Automatically updates BLoC state when user signs in/out
   - Triggers router redirects via `GoRouterRefreshStream`

### Key Files

- `lib/core/routing/app_router.dart` - Router configuration with auth-based redirects
- `lib/core/screens/splash_screen.dart` - Splash screen shown during auth check
- `lib/features/auth/bloc/auth_bloc.dart` - Auth state management
- `lib/repositories/auth_repository.dart` - Firebase Auth integration

### Testing

1. **First Time**:
   - Open app → See login screen
   - Sign up or log in
   - Close app

2. **Subsequent Opens**:
   - Open app → See splash screen briefly
   - Automatically redirected to home feed (no login required)

3. **After Logout**:
   - Tap logout button
   - Close app
   - Open app → See login screen again

### Session Persistence Duration

Firebase Auth persists the session **indefinitely** until:
- User explicitly logs out
- User deletes account
- Auth token is manually revoked (admin action)
- App data is cleared (device settings)

No need to implement custom session management - Firebase handles it all!
