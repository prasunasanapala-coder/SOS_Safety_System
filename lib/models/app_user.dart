/// Minimal view of the signed-in user.
///
/// The UI and providers use this class instead of Firebase's `User`, so they
/// stay independent of Firebase and are easy to test with fakes.
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}