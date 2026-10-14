/// One account in the prototype's in-memory user list.
/// Mirrors the `users` table in database/radiant_schema.sql.
class UserAccount {
  final String username;
  final String fullName;
  final String email;
  final String password; // prototype only; the real database stores a hash
  final String role; // 'admin' or 'technician'

  const UserAccount({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });
}

/// Prototype-only authentication and registration.
///
/// Accounts live in memory, so anything registered is lost when the app
/// restarts. A real build would call a server that checks credentials and
/// stores only a password hash (see database/radiant_schema.sql).
class AuthService {
  AuthService._();

  static final Map<String, UserAccount> _accounts = {
    'admin': const UserAccount(
      username: 'admin',
      fullName: 'Administrator',
      email: 'admin@radiant.local',
      password: 'radiant123',
      role: 'admin',
    ),
    'technician': const UserAccount(
      username: 'technician',
      fullName: 'Demo Technician',
      email: 'technician@radiant.local',
      password: 'tech1234',
      role: 'technician',
    ),
  };

  // ---------- Sign in ----------

  /// Returns true when [username] and [password] match an account.
  static bool signIn(String username, String password) {
    final account = _accounts[username.trim().toLowerCase()];
    return account != null && account.password == password;
  }

  static String displayName(String username) =>
      _accounts[username]?.fullName ?? username;

  static String roleOf(String username) =>
      _accounts[username]?.role ?? 'technician';

  // ---------- Registration ----------

  static bool usernameTaken(String username) =>
      _accounts.containsKey(username.trim().toLowerCase());

  static bool emailTaken(String email) => _accounts.values
      .any((a) => a.email.toLowerCase() == email.trim().toLowerCase());

  /// Creates a new technician account.
  /// Returns an error message, or null when the account was created.
  static String? register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) {
    final user = username.trim().toLowerCase();
    if (usernameTaken(user)) return 'That username is already taken.';
    if (emailTaken(email)) return 'An account with that email already exists.';

    _accounts[user] = UserAccount(
      username: user,
      fullName: fullName.trim(),
      email: email.trim(),
      password: password,
      role: 'technician', // only seeded accounts can be admins
    );
    return null;
  }

  // ---------- Field validators (used by the registration form) ----------

  static String? validateFullName(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter your full name';
    return null;
  }

  static String? validateUsername(String? v) {
    final s = v?.trim() ?? '';
    if (s.length < 3 || s.length > 30) return 'Use 3 to 30 characters';
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(s)) {
      return 'Letters, numbers, and underscores only';
    }
    return null;
  }

  static String? validateEmail(String? v) {
    final s = v?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'[0-9]').hasMatch(s)) {
      return 'Include at least one letter and one number';
    }
    return null;
  }
}