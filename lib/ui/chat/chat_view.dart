import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants.dart';
import '../../providers/chat_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/gemini_service.dart';

// Official Google test ad unit IDs — swap for real ones before release.
const String _androidRewardedAdUnitId =
    'ca-app-pub-3940256099942544/5224354917';
const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

const int _contextWindow = 10;

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final String _sessionId;

  bool _isSending = false;
  bool _isAdLoading = false;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    _sessionId = _resolveSessionId();
    _loadRewardedAd();
  }

  // Riverpod forbids mutating a provider's state synchronously during any
  // widget's initState (it threw "Tried to modify a provider while the
  // widget tree was building" here originally). The session id is still
  // needed immediately for `messagesProvider(_sessionId)` in build(), so a
  // brand-new session is constructed as a plain local value here, and the
  // actual provider registration (Hive write + state update) is deferred to
  // a post-frame callback.
  String _resolveSessionId() {
    final sessions = ref.read(chatSessionsProvider);
    if (sessions.isNotEmpty) return sessions.first.id;

    final newSession = ChatSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'New Session',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(chatSessionsProvider.notifier).registerSession(newSession);
    });

    return newSession.id;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }

  // ---- Messaging -----------------------------------------------------

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    final credits = ref.read(walletProvider);
    if (text.isEmpty || credits <= 0 || _isSending) return;

    _inputController.clear();

    final messagesNotifier =
        ref.read(messagesProvider(_sessionId).notifier);
    final walletNotifier = ref.read(walletProvider.notifier);

    // Snapshot the context window BEFORE appending the new message —
    // this is the exact set sent to Gemini, capped at the last 10.
    final contextMessages = messagesNotifier.lastN(_contextWindow);

    await walletNotifier.spendCredit();
    await messagesNotifier.addMessage(role: 'user', text: text);

    setState(() => _isSending = true);
    _scrollToBottom();

    try {
      final reply = await ref.read(geminiServiceProvider).send(
            contextMessages: contextMessages,
            newMessage: text,
          );
      await messagesNotifier.addMessage(
        role: 'model',
        text: reply.isEmpty ? '...' : reply,
      );
    } catch (_) {
      await messagesNotifier.addMessage(
        role: 'model',
        text: 'Connection failed. Try again.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  // ---- Rewarded ads ----------------------------------------------------

  // google_mobile_ads only ships Android/iOS platform implementations;
  // dart:io Platform.* also throws outright on web, so kIsWeb must be
  // checked first, before Platform.isAndroid/isIOS ever runs.
  bool get _adsSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _rewardedAdUnitId =>
      Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId;

  void _loadRewardedAd() {
    if (!_adsSupported) return;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  Future<void> _handleWatchAd() async {
    if (_isAdLoading || !_adsSupported) return;

    final ad = _rewardedAd;
    if (ad == null) {
      setState(() => _isAdLoading = true);
      _loadRewardedAd();
      // Give the SDK a moment to fetch; the button re-enables regardless.
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _isAdLoading = false);
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        // The user can background/close the app during ad playback;
        // `ref` is unusable once this State is disposed.
        if (!mounted) return;
        final granted = 3 + Random().nextInt(3); // 3, 4, or 5
        ref.read(walletProvider.notifier).addCredits(granted);
      },
    );
  }

  // ---- UI ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(_sessionId));
    final credits = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('REEDPILL'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$credits',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) =>
                    _MessageBubble(message: messages[index]),
              ),
            ),
            if (_isSending) const _TypingIndicator(),
            _buildComposer(credits),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(int credits) {
    if (credits <= 0) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isAdLoading ? null : _handleWatchAd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              _isAdLoading ? 'LOADING AD...' : '[ CHARGE FRAME: WATCH AD ]',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isSending,
              style: const TextStyle(color: AppColors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: const InputDecoration(
                hintText: 'Ask directly...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.red,
                disabledBackgroundColor: AppColors.gray,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Icon(Icons.send, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.gray : Colors.transparent,
          border: isUser
              ? null
              : Border.all(color: AppColors.white, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: AppColors.white, height: 1.3),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '...',
          style: TextStyle(color: AppColors.red, letterSpacing: 2),
        ),
      ),
    );
  }
}
