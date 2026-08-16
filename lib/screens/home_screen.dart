import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const HomeScreen({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // =====================================================
    // اطلاعات کاربر
    // =====================================================

    final Map<String, dynamic> user =
    data['user'] is Map
        ? Map<String, dynamic>.from(data['user'])
        : {};

    // =====================================================
    // اطلاعات ساختمان
    // =====================================================

    final Map<String, dynamic> house =
    data['house'] is Map
        ? Map<String, dynamic>.from(data['house'])
        : {};

    // =====================================================
    // اطلاعات واحدها
    // =====================================================

    final List<dynamic> units =
    data['units'] is List
        ? data['units']
        : [];

    final String fullName =
        user['full_name']?.toString() ?? 'کاربر';

    final String mobile =
        user['mobile']?.toString() ?? '-';

    final String houseName =
        house['name']?.toString() ?? '-';

    final String houseId =
        user['house_id']?.toString() ?? '-';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل کاربری'),
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [

              // =================================================
              // خوش آمدگویی
              // =================================================

              Card(
                elevation: 3,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        'سلام $fullName 👋',
                        style:
                        const TextStyle(
                          fontSize: 23,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        'به رایا شارژ خوش آمدید',
                        style:
                        TextStyle(
                          fontSize: 14,
                          color:
                          Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // اطلاعات کاربر
              // =================================================

              Card(
                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'اطلاعات کاربر',
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      _InfoRow(
                        icon: Icons.person,
                        title: 'نام و نام خانوادگی',
                        value: fullName,
                      ),

                      _InfoRow(
                        icon: Icons.phone,
                        title: 'شماره موبایل',
                        value: mobile,
                      ),

                      _InfoRow(
                        icon: Icons.home,
                        title: 'شناسه ساختمان',
                        value: houseId,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // اطلاعات ساختمان
              // =================================================

              Card(
                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'ساختمان',
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      _InfoRow(
                        icon: Icons.apartment,
                        title: 'نام ساختمان',
                        value: houseName,
                      ),

                      _InfoRow(
                        icon: Icons.location_on,
                        title: 'آدرس',
                        value:
                        house['address']
                            ?.toString() ??
                            '-',
                      ),

                      _InfoRow(
                        icon: Icons.phone,
                        title: 'تلفن ساختمان',
                        value:
                        house['phone']
                            ?.toString() ??
                            '-',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // =================================================
              // واحدها
              // =================================================

              Card(
                elevation: 2,

                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(16),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      const Text(
                        'واحدهای من',
                        style:
                        TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      if (units.isEmpty)
                        const Text(
                          'واحدی برای این کاربر ثبت نشده است.',
                        ),

                      ...units.map(
                            (unit) {

                          final Map<String, dynamic>
                          unitData =
                          unit is Map
                              ? Map<String,
                              dynamic>.from(
                            unit,
                          )
                              : {};

                          return Container(
                            margin:
                            const EdgeInsets.only(
                              bottom: 10,
                            ),

                            padding:
                            const EdgeInsets.all(
                              12,
                            ),

                            decoration:
                            BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(
                                12,
                              ),

                              border:
                              Border.all(
                                color:
                                Colors.grey.shade300,
                              ),
                            ),

                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                              children: [

                                Text(
                                  'واحد ${unitData['unit'] ?? '-'}',
                                  style:
                                  const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  'طبقه: ${unitData['floor_number'] ?? '-'}',
                                ),

                                Text(
                                  'متراژ: ${unitData['area'] ?? '-'} متر',
                                ),

                                Text(
                                  'تعداد اتاق: ${unitData['bedrooms_count'] ?? '-'}',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// ردیف اطلاعات
// =====================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            size: 21,
            color:
            const Color(0xff00ACC1),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style:
                  TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}