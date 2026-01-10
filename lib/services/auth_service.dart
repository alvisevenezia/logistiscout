import 'package:dio/dio.dart';

class AuthService {
  final Dio dio;
  AuthService(this.dio);

  Future<(String access, String? refresh)> refresh(String refreshToken) async {
    final res = await dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(headers: {'Authorization': null}),
    );

    final access = res.data['access_token'] as String;
    final refresh = res.data['refresh_token'] as String?;
    return (access, refresh);
  }
}
