class AppConstants {
  static const String appName = 'VitalReach';
  static const String tagline = 'Healthcare reaching everywhere';
  static const double borderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';

  // Roles
  static const String roleVillager = 'villager';
  static const String roleAsha = 'asha_worker';
  static const String roleDoctor = 'doctor';

  static const List<String> villages = [
    'Karanji Bk.',
    'Kolpewadi',
    'Manjur',
    'Pohegaon',
    'Dhamori',
    'Sanwaster',
    'Sangvi Bhusar',
    'Rawanda',
    'Chas Nali',
    'Dauch Khurd',
  ];

  static List<String> villageDropdownItems({String? current}) {
    final items = List<String>.from(villages);
    final extra = current?.trim() ?? '';
    if (extra.isNotEmpty && !items.contains(extra)) {
      items.insert(0, extra);
    }
    return items;
  }
}
