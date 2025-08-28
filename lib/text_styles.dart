import 'package:flutter/material.dart';

/// 앱 전체에서 사용할 텍스트 스타일들을 정의하는 클래스
/// 모든 텍스트는 Pretendard 폰트를 사용합니다.
class AppTextStyles {
  // 기본 폰트 패밀리
  static const String _fontFamily = 'Pretendard';

  // 제목 스타일들
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle h6 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // 본문 텍스트 스타일들
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // 버튼 텍스트 스타일들
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // 캡션 및 작은 텍스트
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 1.5,
  );

  // 특별한 용도의 텍스트 스타일들
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle input = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  // 가중치별 변형 스타일들
  static TextStyle get thin => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w100);
  static TextStyle get extraLight => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w200);
  static TextStyle get light => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w300);
  static TextStyle get regular => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400);
  static TextStyle get medium => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500);
  static TextStyle get semiBold => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600);
  static TextStyle get bold => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w700);
  static TextStyle get extraBold => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w800);
  static TextStyle get black => const TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w900);

  // 기존 스타일에 가중치를 적용하는 헬퍼 메서드들
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) {
    return baseStyle.copyWith(fontWeight: weight);
  }

  static TextStyle withSize(TextStyle baseStyle, double size) {
    return baseStyle.copyWith(fontSize: size);
  }

  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  static TextStyle withHeight(TextStyle baseStyle, double height) {
    return baseStyle.copyWith(height: height);
  }
}

/// 테마에서 사용할 수 있는 텍스트 테마
class AppTextTheme {
  static TextTheme get light => const TextTheme(
    displayLarge: AppTextStyles.h1,
    displayMedium: AppTextStyles.h2,
    displaySmall: AppTextStyles.h3,
    headlineLarge: AppTextStyles.h4,
    headlineMedium: AppTextStyles.h5,
    headlineSmall: AppTextStyles.h6,
    titleLarge: AppTextStyles.h5,
    titleMedium: AppTextStyles.h6,
    titleSmall: AppTextStyles.bodyMedium,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.buttonMedium,
    labelMedium: AppTextStyles.buttonSmall,
    labelSmall: AppTextStyles.caption,
  );

  static TextTheme get dark => light;
}
