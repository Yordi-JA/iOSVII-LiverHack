import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/glass_segmented.dart';
import '../../core/widgets/gradient_button.dart';
import '../../../backend/models/candidate.dart';
import '../../../backend/providers.dart';
import '../comparativa/comparativa_controller.dart';
import '../comparativa/hcai_scoring.dart';
import '../procesos/widgets/stage_feedback_card.dart';
import '../procesos/widgets/stage_stepper.dart';
import 'widgets/contact_card.dart';
import 'widgets/hcai_breakdown_card.dart';
import 'widgets/process_history.dart';
import 'widgets/profile_header.dart';
import 'widgets/side_cards.dart';

/// Secciones en que se divide el perfil.
enum ProfileSection { proceso, perfil, evaluacion, compensacion, contacto }

/// Perfil completo del postulante con su proceso en particular.
class CandidateProfilePage extends ConsumerStatefulWidget {
  const CandidateProfilePage({super.key, required this.candidateId});

  final String candidateId;

  @override
  ConsumerState<CandidateProfilePage> createState() => _CandidateProfilePageState();
}

class _CandidateProfilePageState extends ConsumerState<CandidateProfilePage> {
  int? _stage;
  var _section = ProfileSection.proceso;

  @override
  Widget build(BuildContext context) {
    final candidates = ref.watch(allCandidatesProvider).value;
    final vacancies = ref.watch(vacanciesProvider).value ?? const [];
    if (candidates == null) return const Center(child: CircularProgressIndicator());

    final c = candidates.where((c) => c.id == widget.candidateId).firstOrNull;
    if (c == null) {
      return Center(child: Text('No encontramos a este postulante.', style: AppTypography.title));
    }
    final vacancy = vacancies.where((v) => v.id == c.vacanteId).firstOrNull;
    final bandaMax = vacancy?.bandaMax ?? 0;
    final stage = _stage ?? c.latestFeedbackStage;
    final canAdvance = c.etapaActual < 6 && c.status != CandidateStatus.descartado;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/procesos'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(vacancy == null ? 'Procesos' : 'Procesos · ${vacancy.titulo}'),
                style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
              ),
              const Spacer(),
              GlassOutlineButton(label: 'Ver CV', icon: Icons.picture_as_pdf_outlined, onTap: () {}),
              const SizedBox(width: 10),
              GradientButton(
                label: 'Avanzar etapa',
                enabled: canAdvance,
                onTap: () {
                  ref.read(talentRepositoryProvider).moveCandidate(c.id, c.etapaActual + 1);
                  setState(() => _stage = c.etapaActual + 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProfileHeader(candidate: c),
          const SizedBox(height: 16),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Su proceso', style: AppTypography.headline),
                    const Spacer(),
                    Text('Toca un círculo para ver el feedback de esa etapa', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 16),
                StageStepper(
                  currentStep: c.etapaActual,
                  highlightedStep: stage,
                  onStepTap: (s) => setState(() {
                    _stage = s;
                    _section = ProfileSection.proceso;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GlassSegmented<ProfileSection>(
              selected: _section,
              onChanged: (s) => setState(() => _section = s),
              segments: const [
                (ProfileSection.proceso, 'Proceso', Icons.timeline_rounded),
                (ProfileSection.perfil, 'Perfil', Icons.person_outline_rounded),
                (ProfileSection.evaluacion, 'Evaluación', Icons.psychology_outlined),
                (ProfileSection.compensacion, 'Compensación', Icons.payments_outlined),
                (ProfileSection.contacto, 'Contacto', Icons.contact_page_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_section),
              child: switch (_section) {
                ProfileSection.proceso => _TwoColumns(
                    left: [
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Feedback de la etapa', style: AppTypography.headline),
                            const SizedBox(height: 12),
                            StageFeedbackCard(candidate: c, stage: stage),
                          ],
                        ),
                      ),
                      if (c.statusJustificacion.isNotEmpty) _DecisionCard(candidate: c),
                    ],
                    right: [
                      ProcessHistory(candidate: c, selectedStage: stage, onSelect: (s) => setState(() => _stage = s)),
                    ],
                  ),
                ProfileSection.perfil => _TwoColumns(
                    left: [ExperienceCard(candidate: c)],
                    right: [EducationCard(candidate: c)],
                  ),
                ProfileSection.evaluacion => _TwoColumns(
                    left: [AssessFirstCard(assessFirst: c.assessFirst)],
                    right: [
                      HcaiBreakdownCard(
                        result: scoreCandidate(c, bandaMax: bandaMax, weights: ref.watch(hcaiWeightsProvider)),
                      ),
                    ],
                  ),
                ProfileSection.compensacion => _TwoColumns(
                    left: [CompensationCard(candidate: c, bandaMax: bandaMax)],
                    right: const [],
                  ),
                ProfileSection.contacto => ContactCard(contact: c.contacto),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right});

  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              children[i],
            ],
          ],
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: column(left)),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: column(right)),
      ],
    );
  }
}

class _DecisionCard extends StatelessWidget {
  const _DecisionCard({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final color = candidate.status.color;
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              candidate.status == CandidateStatus.descartado ? Icons.block_rounded : Icons.verified_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Decisión: ${candidate.status.label}', style: AppTypography.headline.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(candidate.statusJustificacion, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
