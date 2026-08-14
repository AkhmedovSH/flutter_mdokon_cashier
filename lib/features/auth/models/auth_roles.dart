/// Роли пользователя и стартовые маршруты для каждой из них.
class AuthRoles {
  const AuthRoles._();

  static const String cashier = 'ROLE_CASHIER';
  static const String agent = 'ROLE_AGENT';
  static const String owner = 'ROLE_OWNER';
  static const String merchandiser = 'ROLE_MERCHANDISER';

  /// Порядок важен: если ролей несколько, берём первую подходящую.
  static const List<String> supported = [cashier, agent, owner, merchandiser];

  /// Первая поддерживаемая роль из списка `authorities` аккаунта.
  static String? resolve(dynamic authorities) {
    if (authorities is! List) return null;
    for (final role in supported) {
      if (authorities.contains(role)) return role;
    }
    return null;
  }

  static String? homeRoute(String? role) => switch (role) {
        cashier => '/cashier',
        agent => '/agent',
        owner || merchandiser => '/director',
        _ => null,
      };
}
