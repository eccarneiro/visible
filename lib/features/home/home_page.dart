import 'package:flutter/material.dart';

import '../../core/services/app_state.dart';
import '../../core/utils/geo.dart';
import '../../core/utils/relevance.dart';
import '../../models/urban_issue.dart';
import '../../shared/widgets/brand_mark.dart';
import '../../shared/widgets/impact_chip.dart';
import '../../shared/widgets/profile_sheet.dart';
import '../issue_details/issue_details_sheet.dart';
import '../issue_reporting/report_page.dart';

/// Tela de início: ação principal, atalhos, prioridades do perfil e resumo.
class HomePage extends StatelessWidget {
  /// Troca a aba do shell (0 início, 1 mapa, 2 observar, 3 contribuições, 4 perfil).
  final ValueChanged<int> onNavigate;
  const HomePage({super.key, required this.onNavigate});

  static const _tips = [
    'Fotografe o problema de frente e de perto para facilitar a identificação.',
    'Confirmar um registro existente é tão útil quanto criar um novo.',
    'Evite fotografar rostos e placas de veículos.',
    'A observação de trajeto usa o acelerômetro para indicar trechos irregulares.',
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.issues]),
      builder: (context, _) {
        final repo = app.issues;
        final open = repo.issues.where((i) => !i.resolved).toList()
          ..sort((a, b) => priorityScore(b, app.profile)
              .compareTo(priorityScore(a, app.profile)));
        final top = open.take(3).toList();
        final confirmed = repo.issues.where((i) => i.communityConfirmed).length;
        final resolved = repo.issues.where((i) => i.resolved).length;
        final tip = _tips[DateTime.now().day % _tips.length];

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 16,
            title: const BrandMark(),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              _Greeting(app: app),
              const SizedBox(height: 16),
              if (!repo.online) ...[
                const _OfflineNotice(),
                const SizedBox(height: 12),
              ],
              _ReportCta(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ReportPage())),
              ),
              const SizedBox(height: 12),
              _QuickActions(onNavigate: onNavigate),
              const SizedBox(height: 28),
              _SectionTitle(
                title: 'Prioridades para ${app.profile.label.toLowerCase()}',
                action: 'Ver mapa',
                onAction: () => onNavigate(1),
              ),
              const SizedBox(height: 8),
              if (top.isEmpty)
                _EmptyHighlights(onOpenMap: () => onNavigate(1))
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var k = 0; k < top.length; k++) ...[
                        if (k > 0) const Divider(height: 1),
                        _IssueRow(
                          issue: top[k],
                          app: app,
                          onTap: () => showIssueDetails(context, top[k].id),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Resumo da comunidade'),
              const SizedBox(height: 8),
              Card(
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _Stat(value: '${repo.issues.length}', label: 'Registros'),
                      const VerticalDivider(width: 1),
                      _Stat(value: '$confirmed', label: 'Confirmados'),
                      const VerticalDivider(width: 1),
                      _Stat(value: '$resolved', label: 'Resolvidos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _TipCard(text: tip),
            ],
          ),
        );
      },
    );
  }
}

class _Greeting extends StatelessWidget {
  final AppState app;
  const _Greeting({required this.app});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bom dia'
        : hour < 18
            ? 'Boa tarde'
            : 'Boa noite';
    final name = app.displayName.isEmpty ? '' : ', ${app.displayName}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting$name',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Acessibilidade urbana mapeada pela comunidade.',
                  style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Perfil de mobilidade: ${app.profile.label}. Toque para mudar.',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => showProfileSheet(context),
            icon: Icon(app.profile.icon, size: 18),
            label: Text(app.profile.label),
          ),
        ),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.error.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: cs.error, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
                'Sem conexão com o servidor. Exibindo os últimos dados salvos.'),
          ),
        ],
      ),
    );
  }
}

class _ReportCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_a_photo_outlined, color: cs.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Registrar ocorrência',
                        style: TextStyle(
                            color: cs.onPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Foto, localização e detalhes',
                        style: TextStyle(
                            color: cs.onPrimary.withValues(alpha: .75),
                            fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const _QuickActions({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = [
      (Icons.map_outlined, 'Mapa', 1),
      (Icons.route_outlined, 'Trajeto', 2),
      (Icons.history, 'Histórico', 3),
      (Icons.tune, 'Preferências', 4),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (final i in items)
            Expanded(
              child: InkWell(
                onTap: () => onNavigate(i.$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Icon(i.$1, color: cs.primary),
                      const SizedBox(height: 6),
                      Text(i.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IssueRow extends StatelessWidget {
  final UrbanIssue issue;
  final AppState app;
  final VoidCallback onTap;
  const _IssueRow({required this.issue, required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final i = issue;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: i.category.color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(i.category.icon, color: i.category.color, size: 20),
      ),
      title: Text(i.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
          '${i.category.label} · ${i.confirmationCount} confirmações · ${timeAgo(i.lastConfirmedAt)}',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
      trailing: ImpactChip(level: app.profile.impactOf(i.category)),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionTitle({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    );
  }
}

class _EmptyHighlights extends StatelessWidget {
  final VoidCallback onOpenMap;
  const _EmptyHighlights({required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 32, color: cs.onSurfaceVariant),
            const SizedBox(height: 10),
            const Text('Nenhum registro na região',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                'Abra o mapa para consultar a sua região ou registre a primeira ocorrência.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 14),
            OutlinedButton(
                onPressed: onOpenMap, child: const Text('Abrir o mapa')),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.primary)),
            const SizedBox(height: 2),
            Text(label,
                style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: .15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: cs.onSurface, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
