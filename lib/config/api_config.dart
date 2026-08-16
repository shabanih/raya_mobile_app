class ApiConfig {
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String baseUrl = 'http://192.168.100.4:8000/api';
  // static const String baseUrl =
  //     'http://10.0.2.2:8000';

  static const String login = '$baseUrl/auth/login/';
  static const String refresh = '$baseUrl/auth/refresh/';
  static const String me = '$baseUrl/auth/me/';

  static const String charges = '$baseUrl/charges/';
  static const String paymentHistory = '$baseUrl/payments/history/';
}