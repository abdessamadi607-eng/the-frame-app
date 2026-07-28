import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../core/constants.dart';

final walletProvider = StateNotifierProvider<WalletNotifier, int>((ref) {
  return WalletNotifier();
});

class WalletNotifier extends StateNotifier<int> {
  WalletNotifier()
      : super(
          _box.get('credits', defaultValue: AppConstants.startingCredits)
              as int,
        );

  static Box get _box => Hive.box(HiveBoxes.wallet);

  bool get hasCredits => state > 0;

  Future<void> spendCredit() async {
    if (state <= 0) return;
    state -= 1;
    await _box.put('credits', state);
  }

  Future<void> addCredits(int amount) async {
    state += amount;
    await _box.put('credits', state);
  }
}
