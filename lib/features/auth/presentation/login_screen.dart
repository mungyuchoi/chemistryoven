import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/demo_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fcm_service.dart';
import '../../../services/user_service.dart';
import '../../../shared/providers/app_scope.dart';

/// 소셜 로그인 화면 (UI 프로토타입 · 실제 인증 없음)
///
/// - Android: 구글, 카카오
/// - iOS: 구글, 애플, 카카오
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.onCompleted, super.key});

  /// 로그인(또는 게스트 진입) 완료 시 호출. null이면 pop으로 닫는다.
  final VoidCallback? onCompleted;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const double _buttonWidth = 280;
  bool _isLoading = false;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  _buildHero(context),
                  const SizedBox(height: 36),
                  ..._buildLoginButtons(),
                  if (_isLoading) ...[
                    const SizedBox(height: 18),
                    const CircularProgressIndicator(color: AppColors.burgundy),
                  ],
                  const SizedBox(height: 26),
                  Text(
                    '로그인 시 서비스 이용약관과 개인정보처리방침에 동의하게 됩니다.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.6, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.wine,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'asset/img/app_icon.png',
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Text(
                'C·O',
                style: TextStyle(
                  color: AppColors.butter,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'CHEMISTRY OVEN',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '오늘의 케미,\n오븐에서 구워볼까요?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.wine,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '베이킹으로 시작되는 소셜 매칭, 케미스트리오븐',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
        ),
      ],
    );
  }

  List<Widget> _buildLoginButtons() {
    final buttons = <Widget>[
      _LoginImageButton(
        onTap: _isLoading ? null : () => _showAgreementSheet('Google'),
        assetPath: 'asset/img/login/google_login_light.png',
        width: _buttonWidth,
      ),
    ];

    if (_isIOS) {
      buttons
        ..add(const SizedBox(height: 12))
        ..add(
          _LoginImageButton(
            onTap: _isLoading ? null : () => _showAgreementSheet('Apple'),
            assetPath: 'asset/img/login/apple_login_light.png',
            width: _buttonWidth,
          ),
        );
    }

    buttons
      ..add(const SizedBox(height: 12))
      ..add(
        _LoginImageButton(
          onTap: _isLoading ? null : () => _showAgreementSheet('Kakao'),
          assetPath: 'asset/img/login/kakao_login.png',
          width: _buttonWidth,
          imageFit: BoxFit.cover,
        ),
      );

    return buttons;
  }

  /// mileage_thief 로그인 동의 다이얼로그 패턴을 케미오븐 톤으로 적용.
  Future<void> _showAgreementSheet(String provider) async {
    var agreeNoAbuse = false;
    var agreePolicy = false;

    final agreed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.ivory,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canContinue = agreeNoAbuse && agreePolicy;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$provider 로그인 · 서비스 이용 동의',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: agreeNoAbuse,
                      onChanged: (value) =>
                          setSheetState(() => agreeNoAbuse = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.burgundy,
                      title: const Text(
                        '불쾌한 콘텐츠·악의적 사용자 무관용 정책 동의 (필수)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cocoa,
                        ),
                      ),
                      subtitle: const Text(
                        '욕설, 혐오, 차별 등은 허용되지 않으며 위반 시 이용이 제한될 수 있어요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: agreePolicy,
                      onChanged: (value) =>
                          setSheetState(() => agreePolicy = value ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.burgundy,
                      title: const Text(
                        '개인정보처리방침 동의 (필수)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cocoa,
                        ),
                      ),
                      subtitle: const Text(
                        '수집한 개인정보는 개인정보처리방침에 따라 안전하게 처리돼요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: canContinue
                            ? () => Navigator.pop(sheetContext, true)
                            : null,
                        child: Text('$provider 계정으로 계속하기'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (agreed == true && mounted) {
      await _handleLogin(provider);
    }
  }

  Future<void> _handleLogin(String provider) async {
    setState(() => _isLoading = true);
    try {
      final user = switch (provider) {
        'Google' => await AuthService.instance.signInWithGoogle(),
        'Apple' => await AuthService.instance.signInWithApple(),
        'Kakao' => await AuthService.instance.signInWithKakao(),
        _ => null,
      };

      if (user == null) {
        // 사용자가 로그인 창을 취소함 — 조용히 종료
        return;
      }

      await UserService.instance.saveUserOnLogin(
        user: user,
        provider: provider.toLowerCase(),
      );
      if (!mounted) {
        return;
      }

      // 앱 내부 데모 컨텍스트 유지 (실데이터 화면 연결 전까지 흐름 보존)
      final appState = AppScope.of(context);
      appState.sessionController.loginAsDemoUser(
        displayName: user.displayName ?? '참가자',
      );
      appState.modeController.setMode(DemoMode.user);
      // 실제 사용자 프로필(users/{uid}) 로드
      unawaited(appState.currentUserController.load());
      // 회차(sessions) 실시간 구독 시작
      appState.sessionsController.start();
      // 앱 접속 시 FCM 토큰을 users/{uid}.fcmToken 에 기록
      unawaited(FcmService.instance.registerForCurrentUser());

      _showInfo('$provider 로그인 완료');
      _finish();
    } catch (error) {
      if (mounted) {
        _showInfo('로그인에 실패했어요. 다시 시도해 주세요.');
      }
      debugPrint('[login] $provider 로그인 실패: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInfo(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _finish() {
    if (widget.onCompleted != null) {
      widget.onCompleted!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }
}

/// mileage_thief의 이미지 기반 소셜 로그인 버튼 패턴.
class _LoginImageButton extends StatelessWidget {
  const _LoginImageButton({
    required this.onTap,
    required this.assetPath,
    this.width = 280,
    this.height = 56,
    this.borderRadius = 22,
    this.imageFit = BoxFit.contain,
  });

  final VoidCallback? onTap;
  final String assetPath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit imageFit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.asset(
              assetPath,
              fit: imageFit,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE6E9EF),
                  alignment: Alignment.center,
                  child: Text(
                    assetPath.split('/').last,
                    style: const TextStyle(
                      color: Color(0xFF656B79),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
