import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final ShopModel? currentShop;
  final bool isOtpSent;
  final String? verificationId;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.currentShop,
    this.isOtpSent = false,
    this.verificationId,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    ShopModel? currentShop,
    bool? isOtpSent,
    String? verificationId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentShop: currentShop ?? this.currentShop,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      verificationId: verificationId ?? this.verificationId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  void setShop(ShopModel shop) {
    state = state.copyWith(currentShop: shop);
  }

  Future<void> sendOtp(String mobileNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _authService.sendOtp(
      phoneNumber: mobileNumber,
      onCodeSent: (vId) {
        state = state.copyWith(isLoading: false, isOtpSent: true, verificationId: vId);
      },
      onError: (err) {
        state = state.copyWith(isLoading: false, errorMessage: err);
      },
    );
  }

  Future<bool> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final cred = await _authService.verifyOtp(
        smsCode: otp,
        verificationId: state.verificationId,
      );
      if (cred?.user != null) {
        final shop = await _authService.getShopProfile(cred!.user!.uid);
        state = state.copyWith(isLoading: false, currentShop: shop);
        return true;
      }
      state = state.copyWith(isLoading: false, errorMessage: 'OTP galat hai');
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> registerShop({
    required String ownerName,
    required String mobileNumber,
    required String shopName,
    required String mandiName,
    required String city,
    required String stateName,
    required String address,
    String? gstNumber,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shop = await _authService.registerShop(
        ownerName: ownerName,
        mobileNumber: mobileNumber,
        shopName: shopName,
        mandiName: mandiName,
        city: city,
        state: stateName,
        address: address,
        gstNumber: gstNumber,
      );
      state = state.copyWith(isLoading: false, currentShop: shop);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
