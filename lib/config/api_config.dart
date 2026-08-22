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
  // ==============================
  // شارژ عمرانی
  // ==============================
  static String get civilCharges =>
      '$baseUrl/civil-charges/';

// =====================================================
// شارژ عمرانی - اقساط
// =====================================================

  static String civilInstallments(int civilId) {
    return '$baseUrl/civil-charges/$civilId/installments/';
  }
  // =====================================================
// شارژ عمرانی - روش‌های پرداخت
// =====================================================

  static String civilInstallmentPaymentMethods(
      int installmentId,
      ) =>
      '$baseUrl/civil-installments/$installmentId/payment-methods/';

// =====================================================
// شارژ عمرانی - پرداخت دستی
// =====================================================

  static String manualCivilInstallmentPayment(
      int installmentId,
      ) =>
      '$baseUrl/civil-installments/$installmentId/manual-payment/';

  // ==============================
  // هزینه فاضلاب
  // ==============================
  static String get sewageCharges =>
      '$baseUrl/sewage-charges/';

// =====================================================
// هزینه فاضلاب - اقساط
// =====================================================

  static String sewageInstallments(int sewageId) {
    return '$baseUrl/sewage-charges/$sewageId/installments/';
  }
  // =====================================================
// هزینه فاضلاب - روش‌های پرداخت
// =====================================================

  static String sewageInstallmentPaymentMethods(
      int installmentId,
      ) =>
      '$baseUrl/sewage-installments/$installmentId/payment-methods/';

// =====================================================
// هزینه فاضلاب - پرداخت دستی
// =====================================================

  static String manualSewageInstallmentPayment(
      int installmentId,
      ) =>
      '$baseUrl/sewage-installments/$installmentId/manual-payment/';

  // =====================================================
// Messages
// =====================================================

  static String get messages => '$baseUrl/messages/';

  static String messageRead(int messageId) =>
      '$baseUrl/messages/$messageId/read/';

  // ==============================
  // کمک به ساختمان
  // ==============================

  static const String userPayments =
      '$baseUrl/user-payments/';

  static String userPaymentPaymentMethods(
      int paymentId,
      ) =>
      '$baseUrl/user-payments/$paymentId/payment-methods/';

  static String manualUserPayment(
      int paymentId,
      ) =>
      '$baseUrl/user-payments/$paymentId/manual-payment/';


}
