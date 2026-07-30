class FirebaseConfig {
  static const String webApiKey = 'AIzaSyAeEbd_TdyLQ0yyc7tCJcZfWmgKgRKsQcI';
  static const String projectId = 'karpos-6ca3d';
  static String get authUrl => 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$webApiKey';
  static String get firestoreUrl => 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
}
