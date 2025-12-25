# Bug Fix: Main.dart and Router Configuration Issues

## Problems Found

### 1. BLoC Lifecycle Issue in main.dart

**Critical Problem**: The `LiteratureApp` was a `StatelessWidget` that created repositories, BLoCs, and the router inside the `build()` method.

**Why This Is Bad**:
- The `build()` method can be called multiple times (when the widget rebuilds)
- Each time it rebuilds, NEW instances of:
  - Repositories are created
  - BLoCs are created (triggering new auth checks)
  - Router is created
  - Auth state subscriptions are created
- This causes:
  - **Memory leaks** (old subscriptions never cancelled)
  - **Multiple auth checks running simultaneously**
  - **Splash screen hanging** (conflicting auth state updates)
  - **BLoC state loss** (new BLoC = reset state)
  - **Router confusion** (router recreated mid-navigation)

**Example of the Problem**:
```dart
// BAD - Every rebuild creates NEW instances
class LiteratureApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authBloc = AuthBloc(...);  // ← Creates NEW bloc on every build!
    final router = AppRouter(...);   // ← Creates NEW router on every build!

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => authBloc),  // ← New instance
      ],
      // ...
    );
  }
}
```

### 2. Router Configuration Issues

While the router structure is mostly correct, the combination with the main.dart issue meant:
- Router redirect logic could be called with stale auth state
- Navigation could fail if router was recreated mid-navigation
- Splash screen logic couldn't reliably track auth state changes

## Solution

### Changed LiteratureApp to StatefulWidget

**Before**:
```dart
class LiteratureApp extends StatelessWidget {
  const LiteratureApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final authBloc = AuthBloc(authRepository: authRepository);
    final router = AppRouter(authBloc: authBloc);
    // ...
  }
}
```

**After**:
```dart
class LiteratureApp extends StatefulWidget {
  const LiteratureApp({super.key});

  @override
  State<LiteratureApp> createState() => _LiteratureAppState();
}

class _LiteratureAppState extends State<LiteratureApp> {
  // Create once in initState, persist throughout app lifecycle
  late final AuthRepository _authRepository;
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();

    // Initialize ONCE
    _authRepository = AuthRepository();
    _authBloc = AuthBloc(authRepository: _authRepository);
    _appRouter = AppRouter(authBloc: _authBloc);
  }

  @override
  void dispose() {
    // Properly clean up
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),  // ← Use .value() for existing instance
      ],
      child: MaterialApp.router(
        routerConfig: _appRouter.router,
      ),
    );
  }
}
```

## Key Changes

### 1. Repository/BLoC Creation
- **Before**: Created in `build()` → recreated on every rebuild
- **After**: Created in `initState()` → created ONCE, persists forever

### 2. BLoC Provider Pattern
- **Before**: `BlocProvider(create: (context) => authBloc)` → creates new instance
- **After**: `BlocProvider.value(value: _authBloc)` → uses existing instance

### 3. Lifecycle Management
- **Added**: `dispose()` method to properly close BLoCs when app shuts down
- **Added**: `late final` declarations to ensure one-time initialization

### 4. Router Stability
- Router is now created once and never recreated
- Auth state changes are tracked via the existing subscription
- No more conflicting router instances

## How It Works Now

```
App Starts
    ↓
initState() called ONCE
    ↓
Repositories created
    ↓
AuthBloc created → Starts auth check in constructor
    ↓
Router created with reference to AuthBloc
    ↓
MultiBlocProvider provides SAME BLoC instances
    ↓
MaterialApp.router uses SAME router instance
    ↓
build() can be called multiple times...
    ↓
...but BLoCs/Router are NOT recreated! ✅
```

## Benefits

✅ **No memory leaks** - Subscriptions created once, cleaned up in dispose()
✅ **Consistent state** - BLoCs persist across rebuilds
✅ **Single auth check** - No duplicate auth state subscriptions
✅ **Stable routing** - Router never recreated mid-navigation
✅ **Splash screen works** - Auth state changes tracked reliably
✅ **Better performance** - No unnecessary object creation

## Testing

**Test Case 1: Multiple Rebuilds**
1. Navigate between screens
2. Change theme/orientation (triggers rebuilds)
3. ✅ Auth state should remain consistent
4. ✅ No duplicate splash screens
5. ✅ No auth re-checks

**Test Case 2: Memory**
1. Navigate extensively through app
2. Monitor memory usage
3. ✅ No memory leaks from duplicate subscriptions
4. ✅ Single BLoC instance throughout

**Test Case 3: Auth Flow**
1. Login → Should work smoothly
2. Logout → Should work smoothly
3. Reopen app → Should check auth once
4. ✅ No hanging or duplicate checks

## Files Changed

- `lib/main.dart` - Changed to StatefulWidget with proper lifecycle

## Result

✅ No more BLoC recreation issues
✅ No more router instability
✅ Proper resource cleanup
✅ Stable auth state tracking
✅ Splash screen works reliably
✅ Better performance and memory usage
