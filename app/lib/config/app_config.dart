class AppConfig {
  // Django 后端地址（使用宿主机的局域网 IP，模拟器无法直接访问 localhost）
  static const String baseUrl = 'http://192.168.8.51:8000';

  // 认证接口
  static const String loginUrl = '$baseUrl/api/auth/login/';
  static const String registerUrl = '$baseUrl/api/auth/register/';
  static const String logoutUrl = '$baseUrl/api/auth/logout/';
  static const String profileUrl = '$baseUrl/api/auth/profile/';
  static const String changePasswordUrl = '$baseUrl/api/auth/change-password/';
  static const String forgotPasswordUrl = '$baseUrl/api/auth/forgot-password/';
  static const String resetPasswordUrl = '$baseUrl/api/auth/reset-password/';
  static const String tokenUrl = '$baseUrl/api/auth/token/';

  // 业务 API 接口
  static const String categoriesUrl = '$baseUrl/api/categories/';
  static const String productsUrl = '$baseUrl/api/products/';
  static const String ordersUrl = '$baseUrl/api/orders/';

  // IM 即时通讯接口
  static const String conversationsUrl = '$baseUrl/api/chat/conversations/';
  static const String friendsUrl = '$baseUrl/api/chat/friends/';
  static const String friendRequestsUrl = '$baseUrl/api/chat/friend-requests/';
  static const String friendSearchUrl = '$baseUrl/api/chat/friends/search/';

  // SourceForge OAuth 网关
  static const String sourceForgeGatewayUrl =
      'https://git-callback.liuhaobin486.workers.dev';
  static const String sourceForgeClientId = 'd0aaa93827ded5b677c0';
  static const String sourceForgeCallbackUrl =
      '$sourceForgeGatewayUrl/source/auth/callback';
  static const String sourceForgeTokenUrl =
      '$sourceForgeGatewayUrl/source/auth/token';
}
