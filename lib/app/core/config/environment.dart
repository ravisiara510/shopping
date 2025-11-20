class Environment {
  static const bool isProduction = false;
  static const String apiUrl = isProduction
      ? "https://api.ledgerface.com/api/"
      : "http://192.168.1.4:8000/api/";
}
