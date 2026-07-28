// The default counter-app smoke test (flutter create's template) referenced
// a `MyApp` widget that doesn't exist here, and pumping the real
// `ReedPillApp` requires Hive boxes + MobileAds to already be initialized
// (done in `main()`, not available in a bare widget test). Replaced with a
// bootstrap-free check on the theme until proper test fixtures exist.

import 'package:flutter_test/flutter_test.dart';
import 'package:reedpill/core/constants.dart';
import 'package:reedpill/core/theme.dart';

void main() {
  test('AppTheme applies the strict minimalist palette', () {
    final theme = AppTheme.themeFor('en');

    expect(theme.scaffoldBackgroundColor, AppColors.black);
    expect(theme.primaryColor, AppColors.red);
    expect(theme.colorScheme.secondary, AppColors.gray);
  });
}
