class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = 'http://192.168.100.4:8000/api';
  // static const String baseUrl =
  //     'http://10.0.2.2:8000';

  static const String login =
      '$baseUrl/auth/login/';

  static const String refresh =
      '$baseUrl/auth/refresh/';

  static const String me =
      '$baseUrl/auth/me/';

  static const String dashboard =
      '$baseUrl/dashboard/';

  // ==============================
  // شارژها
  // ==============================

  static const String charges =
      '$baseUrl/charges/';

  static String chargeDetail(int chargeId) {
    return '$baseUrl/charges/$chargeId/';
  }

  // ==============================
  // پرداخت‌ها
  // ==============================

  static const String paymentHistory =
      '$baseUrl/payments/history/';

  // ==============================
  // اطلاعیه‌ها
  // ==============================

  static const String announcements =
      '$baseUrl/announcements/';

  // ==============================
  // نظرسنجی‌ها
  // ==============================

  static const String polls =
      '$baseUrl/polls/';

  // ==============================
  // روش پرداخت
  // ==============================

  static String chargePaymentMethods(int chargeId) {
    return '$baseUrl/charges/$chargeId/payment-methods/';
  }
  // ==============================
  // روش پرداخت دستی
  // ==============================
  static String manualChargePayment(int chargeId) {
    return '$baseUrl/charges/$chargeId/payment/manual/';
  }
  static String paymentBanks(int chargeId) {
    return '$baseUrl/charges/$chargeId/payment-banks/';
  }

}
