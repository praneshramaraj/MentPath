import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/user_model.dart';
import '../network/api_client.dart';
import '../network/app_exception.dart';

enum AuthStatus {
  uninitialized,
  loading,
  authenticated,
  unauthenticated,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.uninitialized);

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  static const String _tokenKey = 'jwt_access_token';

  AuthNotifier(this._apiClient) : super(AuthState.initial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);

      if (savedToken == null || savedToken.isEmpty) {
        _apiClient.setAuthToken(null);
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      _apiClient.setAuthToken(savedToken);
      final jsonResponse = await _apiClient.get('/auth/me');
      final user = User.fromJson(jsonResponse);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        token: savedToken,
      );
    } catch (e) {
      // Token is expired or invalid
      await _clearSession();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Session expired. Please log in again.',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _apiClient.post(
        '/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      final tokenData = TokenData.fromJson(response);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, tokenData.accessToken);

      _apiClient.setAuthToken(tokenData.accessToken);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: tokenData.user,
        token: tokenData.accessToken,
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected authentication error occurred.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _apiClient.post(
        '/auth/register',
        body: {
          'email': email.trim(),
          'password': password,
          'full_name': fullName.trim(),
          'role': role,
        },
      );

      // Auto-login after successful real user registration
      return await login(email, password);
    } on AppException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {
      // Proceed with local logout regardless of network status
    }
    await _clearSession();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      token: null,
    );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _apiClient.setAuthToken(null);
  }
}

// Global Providers
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
