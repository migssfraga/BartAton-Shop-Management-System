/// Temporary/mock accounts so the login screen can route by ROLE,
/// instead of buttons. Once you connect a real backend (e.g. Firebase Auth
/// + Firestore), delete this file and replace the check in
/// login_screen.dart with a real sign-in call that reads the user's role
/// from your database.
class MockUser {
  final String email;
  final String password;
  final String role; // 'customer' | 'admin' | 'technician'
  final String displayName;

  const MockUser({
    required this.email,
    required this.password,
    required this.role,
    required this.displayName,
  });
}

final List<MockUser> mockAccounts = [
  MockUser(
    email: 'customer@bartaton.com',
    password: '123456',
    role: 'customer',
    displayName: 'Maria Santos',
  ),
  MockUser(
    email: 'admin@bartaton.com',
    password: '123456',
    role: 'admin',
    displayName: 'Admin',
  ),
  MockUser(
    email: 'technician@bartaton.com',
    password: '123456',
    role: 'technician',
    displayName: 'Carlos',
  ),
];

/// Returns the matching account, or null if the email/password is wrong.
MockUser? findAccount(String email, String password) {
  for (final account in mockAccounts) {
    if (account.email.toLowerCase() == email.trim().toLowerCase() &&
        account.password == password) {
      return account;
    }
  }
  return null;
}
