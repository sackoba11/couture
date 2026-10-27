import 'package:flutter/material.dart';

import '../models/measurement.dart';
import '../models/pattern.dart';
import '../widgets/client_picker.dart';
import '../widgets/pattern_sketch.dart';
import '../widgets/section_card.dart';
import 'sheet_form_screen.dart';
import 'sheet_summary_screen.dart';

/// Détail d'un patron : dessin, mesures clés, tissus et conseils.
class PatternDetailScreen extends StatefulWidget {
  const PatternDetailScreen({super.key, required this.pattern});

  final SewingPattern pattern;

  @override
  State<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends State<PatternDetailScreen> {
  Future<void> _createSheet() async {
    final client = await showClientPicker(context);
    if (client == null || !mounted) return;

    final sheetId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SheetFormScreen(
          client: client,
          initialPattern: widget.pattern,
        ),
      ),
    );
    if (!mounted || sheetId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SheetSummaryScreen(sheetId: sheetId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.pattern;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(pattern.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EDE6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFEBDACB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pattern.icon, size: 14, color: const Color(0xFF7B5B45)),
                    const SizedBox(width: 5),
                    Text(
                      pattern.garmentType,
                      style: const TextStyle(
                        color: Color(0xFF7B5B45),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pattern.tagline,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9A8A8F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PatternSketch(
            pattern: pattern,
            measurements: kPatternDemoMeasurements,
            height: 340,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Aperçu avec des mesures d\'exemple. Sur une fiche, le dessin '
              's\'adapte aux mesures réelles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Color(0xFFB7A39B)),
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: 'La coupe',
            icon: Icons.description_outlined,
            child: Text(
              pattern.description,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.55,
                color: Color(0xFF6E5C62),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Mesures clés',
            icon: Icons.straighten,
            trailing: Text(
              '${pattern.keyMeasurements.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB7A39B),
              ),
            ),
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final id in pattern.keyMeasurements)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF7F4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF1E6DF)),
                    ),
                    child: Text(
                      measurementLabel(id),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6E5C62),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Tissus conseillés',
            icon: Icons.texture,
            child: Text(
              pattern.fabric,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF6E5C62),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Conseil du tailleur',
            icon: Icons.lightbulb_outline,
            child: Text(
              pattern.tip,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF6E5C62),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: _createSheet,
          icon: const Icon(Icons.add),
          label: Text('Créer une fiche ${pattern.name.toLowerCase()}'),
        ),
      ),
    );
  }
}
