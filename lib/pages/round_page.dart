import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../quiz/quiz_bloc.dart';
import '../widgets/ad_overlay.dart'; // <- if your file is ad_manager.dart, change this import

class RoundPage extends StatefulWidget {
  const RoundPage({super.key});
  @override
  State<RoundPage> createState() => _RoundPageState();
}

class _RoundPageState extends State<RoundPage> {
  final _controller = PageController();
  int _lastSelectionTick = -1;
  bool _navLocked = false;
  bool _isAnimating = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _green(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(msg),
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuizBloc, QuizState>(
      listenWhen: (p, c) =>
          p.selectionTick != c.selectionTick || p.currentIndex != c.currentIndex || p.submitted != c.submitted,
      listener: (context, state) async {
        // Auto-advance on select (once)
        if (_lastSelectionTick != state.selectionTick) {
          _lastSelectionTick = state.selectionTick;
          _green('Selected ✨');
          final lastIdx = state.questions.length - 1;
          if (!_navLocked && state.currentIndex < lastIdx) {
            _navLocked = true;
            context.read<QuizBloc>().add(NextQuestion());
          }
        }

        // Drive the PageView
        if (_controller.hasClients && !_isAnimating) {
          _isAnimating = true;
          final target = state.currentIndex;
          await _controller.animateToPage(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
          _isAnimating = false;
          _navLocked = false;
        }

        // Submission → results → ads → next round → pop
        if (state.submitted) {
          await _showResult(context, state.correctCount, state.questions.length);

          for (int i = 0; i < state.adsToShow; i++) {
            await AdOverlay.show(
              context,
              seconds: 3,
              label: 'Thanks for supporting us!',
            );
          }

          final next = (state.round + 1).clamp(1, 500);
          context.read<QuizBloc>().add(ResetForNextRound(next));
          // (Bloc already updates Prefs in ResetForNextRound.)
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final total = state.questions.length; // <- 7 questions
        final atFirst = state.currentIndex == 0;
        final atLast = state.currentIndex == total - 1;

        return Scaffold(
          appBar: AppBar(
            title: Text('Round ${state.round} • Q${state.currentIndex + 1}/$total'),
            actions: [
              IconButton(
                tooltip: 'Previous',
                onPressed: atFirst ? null : () => context.read<QuizBloc>().add(PrevQuestion()),
                icon: const Icon(Icons.chevron_left, color: Colors.blue, size: 35),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: atLast ? null : () => context.read<QuizBloc>().add(NextQuestion()),
                icon: const Icon(Icons.chevron_right, color: Colors.blue, size: 35),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 8),
              _ProgressDots(total: total, current: state.currentIndex, selected: state.selected),
              const Divider(height: 1),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final q = state.questions[index];
                    final sel = state.selected[index];
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _QuestionCard(
                        key: ValueKey('q_$index'),
                        index: index,
                        text: q.text,
                        options: q.options,
                        selected: sel,
                        onSelect: (opt) => context.read<QuizBloc>().add(SelectOption(index, opt)),
                      ),
                    );
                  },
                ),
              ),
              const _BottomBar(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResult(BuildContext context, int correct, int total) async {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Round Result', style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _badge('✅ Correct', correct, Colors.green),
                _badge('❌ Wrong', (total - correct), Colors.red),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, int val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 6),
          Text('$val', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<QuizBloc>().state;
    final allAnswered = state.selected.length == state.questions.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: allAnswered && !state.submitted ? () => context.read<QuizBloc>().add(SubmitRound()) : null,
                child: const Text('Submit Round'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int total;
  final int current;
  final Map<int, int> selected;
  const _ProgressDots({required this.total, required this.current, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final done = selected.containsKey(i);
          final isCurrent = i == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 10,
            width: isCurrent ? 22 : 10,
            decoration: BoxDecoration(
              color: done ? Colors.green : (isCurrent ? Colors.blue : Colors.grey.shade400),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final String text;
  final List<String> options;
  final int? selected;
  final ValueChanged<int> onSelect;
  const _QuestionCard({
    super.key,
    required this.index,
    required this.text,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.menu_book_rounded),
                const SizedBox(width: 8),
                Text('Q${index + 1}. $text', style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 16),
              ...List.generate(options.length, (i) {
                final isSel = selected == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 120),
                    scale: isSel ? 1.02 : 1.0,
                    child: ListTile(
                      onTap: () => onSelect(i),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      tileColor: isSel ? Colors.green.withOpacity(0.15) : cs.surfaceContainerHighest,
                      leading: Icon(
                        isSel ? Icons.check_circle : Icons.circle_outlined,
                        color: isSel ? Colors.green : cs.onSurfaceVariant,
                      ),
                      title: Text(options[i]),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Row(children: [
                const Icon(Icons.touch_app, size: 16),
                const SizedBox(width: 6),
                Text('Tap an option to auto-advance', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
