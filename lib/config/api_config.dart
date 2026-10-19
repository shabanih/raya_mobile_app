class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  // static const String baseUrl = 'http://192.168.100.4:8000/api';
  // static const String baseUrl =
  //     'http://10.0.2.2:8000';
  // static const String baseUrl = 'https://www.rayacharge.ir/api';

  static const String login =
      '$baseUrl/auth/login/';

  static const String refresh =
      '$baseUrl/auth/refresh/';

  static const String me =
      '$baseUrl/auth/me/';

  static const String managerDashboard =
      '$baseUrl/manager/dashboard/';

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

  // Managers Urls


  static const String managerAnnouncements =
      '${baseUrl}/manager/announcements/';

  // =====================================================
  // Manager Messages
  // =====================================================

  static String get managerMessages =>
      '${baseUrl}/manager/messages/';

  static String get managerMessageUnits =>
      '${baseUrl}/manager/messages/units/';

  static String managerMessageDetail(
      int id,
      ) =>
      '${baseUrl}/manager/messages/$id/';

  static String managerMessageSend(
      int id,
      ) =>
      '${baseUrl}/manager/messages/$id/send/';

  // =====================================================
  // Manager Banks
  // =====================================================
  static const String managerHouses =
      '$baseUrl/manager/houses/';

  static const String managerBanks =
      '$baseUrl/manager/banks/';

  static String managerBankDetail(int id) =>
      '$baseUrl/manager/banks/$id/';

  static const String managerBankTransfers =
      '$baseUrl/manager/bank-transfers/';

  static String managerBankTransferDetail(int id) =>
      '$baseUrl/manager/bank-transfers/$id/';

  // =====================================================
// Manager Polls
// =====================================================

  static const String managerPolls =
      '$baseUrl/manager/polls/';

  static String managerPollDetail(int id) =>
      '$baseUrl/manager/polls/$id/';

  static String managerPollToggleActive(int id) =>
      '$baseUrl/manager/polls/$id/toggle-active/';

  static String managerPollResults(int id) =>
      '$baseUrl/manager/polls/$id/results/';

  // =====================================================
// Manager Support / Tickets
// =====================================================

  static const String managerSupportTickets =
      '$baseUrl/manager/support/tickets/';

  static String managerSupportTicketDetail(int ticketId) =>
      '$baseUrl/manager/support/tickets/$ticketId/';

  static String managerSupportTicketMessages(int ticketId) =>
      '$baseUrl/manager/support/tickets/$ticketId/messages/';

  static String managerSupportTicketWaiting(int ticketId) =>
      '$baseUrl/manager/support/tickets/$ticketId/waiting/';

  static String managerSupportTicketClose(int ticketId) =>
      '$baseUrl/manager/support/tickets/$ticketId/close/';

  static const String managerSupportUnreadCount =
      '$baseUrl/manager-support/unread-count/';


  static const String userSupportTickets =
      '$baseUrl/user-support/tickets/';

  static const String userSupportUnreadCount =
      '${baseUrl}/user-support/unread-count/';

  // =====================================================
// مدیریت پشتیبانی مدیر ساختمان
// =====================================================

  static const String managerAdminSupportTickets =
      '$baseUrl/manager/admin-support/tickets/';

  static const String managerAdminSupportCreateTicket =
      '$baseUrl/manager/admin-support/tickets/create/';

  static String managerAdminSupportTicketDetail(int ticketId) =>
      '$baseUrl/manager/admin-support/tickets/$ticketId/';

  static String managerAdminSupportTicketMessage(int ticketId) =>
      '$baseUrl/manager/admin-support/tickets/$ticketId/message/';

  static String managerAdminSupportTicketClose(int ticketId) =>
      '$baseUrl/manager/admin-support/tickets/$ticketId/close/';

  static String managerAdminSupportTicketRead(int ticketId) =>
      '$baseUrl/manager/admin-support/tickets/$ticketId/read/';

  static const String managerAdminSupportUnreadCount =
      '$baseUrl/manager/admin-support/unread-count/';

// =====================================================
// Manager Units - مدیریت واحدها
// =====================================================

  static const String managerUnits =
      '$baseUrl/manager/units/';

// دریافت جزئیات واحد
  static String managerUnitDetail(int unitId) =>
      '$baseUrl/manager/units/$unitId/';

// مسیر مدیریت مالک
  static String managerUnitOwner(int unitId) =>
      '$baseUrl/manager/units/$unitId/owner/';

// دریافت و ثبت مستأجران واحد
  static String managerUnitRenters(int unitId) =>
      '$baseUrl/manager/units/$unitId/renters/';

// ویرایش مستأجر
  static String managerRenterUpdate(int renterId) =>
      '$baseUrl/manager/renters/$renterId/update/';

  static String managerRenterDeactivate(int renterId) =>
      '$baseUrl/manager/renters/$renterId/deactivate/';

  static String managerRenterDelete(int renterId) =>
      '$baseUrl/manager/renters/$renterId/delete/';

  static String managerUnitStatus(int unitId) {
    return '$baseUrl/manager/units/$unitId/status/';
  }


// -----------------------------------------------------
// Charges - شارژها
// -----------------------------------------------------

  static const String managerCharges =
      '${baseUrl}/manager/charges/';

  static const String managerFixedCharges =
      '$baseUrl/manager/charges/fixed/';

  static const String managerAreaCharges =
      '$baseUrl/manager/charges/area/';

  static const String managerPersonCharges =
      '${baseUrl}/manager/charges/person/';

  static const String managerFixAreaCharges =
      '$baseUrl/manager/charges/fix-area/';

  static const String managerFixPersonCharges =
      '$baseUrl/manager/charges/fix-person/';

  static const String managerPersonAreaCharges =
      '$baseUrl/manager/person-area-charges/';

  static const String managerFixPersonAreaCharges =
      '$baseUrl/manager/fix-person-area-charges/';

  static const String managerFixVariableCharges =
      '$baseUrl/manager/fix-variable-charges/';

  static const String managerChargeCalculations =
      '$baseUrl/manager/charge-calculations/';




  
}
