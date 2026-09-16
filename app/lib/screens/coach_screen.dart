import 'package:flutter/material.dart';

import '../analysis/coach_controller.dart';
import '../analysis/move_grader.dart';
import '../analysis/pv_replay.dart';
import '../app_theme.dart';
import '../board/xiangqi_board.dart';
import '../engine/engine_line.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key, required this.controller});

  final CoachController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Header(controller: controller),
                      const SizedBox(height: 16),
                      XiangqiBoard(
                        position: controller.position,
                        selectedIndex: controller.selectedIndex,
                        lastMove: controller.lastMove,
                        suggestedMove: controller.suggestedMove,
                        onTap: controller.tapSquare,
                      ),
                      const SizedBox(height: 16),
                      _Actions(controller: controller),
                      if (controller.errorMessage case final message?) ...[
                        const SizedBox(height: 12),
                        _ErrorCard(message: message),
                      ],
                      if (controller.lastEvaluation case final evaluation?) ...[
                        const SizedBox(height: 12),
                        _EvaluationCard(evaluation: evaluation),
                      ],
                      const SizedBox(height: 20),
                      _AnalysisPanel(controller: controller),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final CoachController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: PikaTheme.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.psychology_alt_rounded, color: PikaTheme.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PIKA COACH',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusText(controller.status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _statusColor(controller.status),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Ván mới',
          onPressed: controller.isBusy ? null : controller.reset,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    );
  }

  String _statusText(CoachStatus status) => switch (status) {
    CoachStatus.starting => 'Đang khởi động Pikafish…',
    CoachStatus.ready => 'Pikafish sẵn sàng',
    CoachStatus.analyzing => 'Pikafish đang phân tích…',
    CoachStatus.engineUnavailable => 'Pikafish chưa sẵn sàng',
  };

  Color _statusColor(CoachStatus status) => switch (status) {
    CoachStatus.ready => PikaTheme.accent,
    CoachStatus.analyzing || CoachStatus.starting => PikaTheme.gold,
    CoachStatus.engineUnavailable => Colors.redAccent,
  };
}

class _Actions extends StatelessWidget {
  const _Actions({required this.controller});

  final CoachController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: controller.isBusy || !controller.engineAvailable
                ? null
                : controller.analyzeCurrent,
            icon: controller.status == CoachStatus.analyzing
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Gợi ý & phân tích'),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Đi lại',
          onPressed: controller.isBusy ? null : controller.undo,
          icon: const Icon(Icons.undo_rounded),
        ),
      ],
    );
  }
}

class _AnalysisPanel extends StatelessWidget {
  const _AnalysisPanel({required this.controller});

  final CoachController controller;

  @override
  Widget build(BuildContext context) {
    final lines = controller.lines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'LỰA CHỌN CỦA PIKAFISH',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (lines.isNotEmpty)
              Text(
                'Depth ${lines.first.depth}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (lines.isEmpty)
          const _EmptyAnalysis()
        else
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _CandidateTile(
                line: line,
                notation: controller.notationFor(line),
                onTap: () => _showPv(context, controller, line),
              ),
            ),
          ),
      ],
    );
  }

  void _showPv(
    BuildContext context,
    CoachController controller,
    EngineLine line,
  ) {
    final replay = PvReplay.replay(controller.positionForLines, line.pv);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biến chính · ${line.score.display}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (replay.frames.isEmpty)
                const Text('Pikafish chưa trả về đủ nước để phát lại.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: replay.frames
                      .map(
                        (frame) => Chip(
                          avatar: CircleAvatar(child: Text('${frame.ply}')),
                          label: Text(frame.notation),
                        ),
                      )
                      .toList(),
                ),
              if (replay.rejectedMove case final rejected?) ...[
                const SizedBox(height: 12),
                Text(
                  'Dừng ở nước không hợp lệ: $rejected',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.line,
    required this.notation,
    required this.onTap,
  });

  final EngineLine line;
  final String notation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: line.multiPv == 1
              ? PikaTheme.accent
              : Colors.white10,
          foregroundColor: line.multiPv == 1 ? Colors.black : Colors.white,
          child: Text('${line.multiPv}'),
        ),
        title: Text(notation, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${line.pv.length} ply · ${line.nps} nps'),
        trailing: Text(
          line.score.display,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: line.score.orderingValue >= 0
                ? PikaTheme.accent
                : Colors.redAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EvaluationCard extends StatelessWidget {
  const _EvaluationCard({required this.evaluation});

  final MoveEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final loss = evaluation.lossCentipawns;
    return Card(
      color: _gradeColor(evaluation.grade).withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: _gradeColor(evaluation.grade)),
                const SizedBox(width: 8),
                Text(
                  evaluation.grade.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _gradeColor(evaluation.grade),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nước của bạn ${evaluation.playedScore.display} · '
              'Tốt nhất ${evaluation.bestScore.display}'
              '${loss == null ? '' : ' · Mất ${(loss / 100).toStringAsFixed(2)}'}',
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(MoveGrade grade) => switch (grade) {
    MoveGrade.best || MoveGrade.excellent => PikaTheme.accent,
    MoveGrade.good => Colors.lightGreenAccent,
    MoveGrade.inaccuracy => PikaTheme.gold,
    MoveGrade.mistake => Colors.deepOrangeAccent,
    MoveGrade.blunder => Colors.redAccent,
  };
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.touch_app_outlined, color: Colors.white54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tự đi một nước hoặc bấm “Gợi ý & phân tích” để xem ba lựa chọn mạnh nhất.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
