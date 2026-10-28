import 'package:flutter/material.dart';

import '../data/couture_repository.dart';
import '../models/pattern.dart';
import '../widgets/section_card.dart';
import 'pattern_detail_screen.dart';
import 'pattern_form_screen.dart';

/// Catalogue des patrons de couture avec support pour patrons personnalisés.
class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  final CoutureRepository _repository = CoutureRepository.instance;
  late Future<Map<String, SewingPattern>> _patterns;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _patterns = _repository.getAllPatterns();
  }

  void _reload() {
    setState(() {
      _patterns = _repository.getAllPatterns();
    });
  }

  Future<void> _addPattern() async {
    final pattern = await Navigator.of(context).push<SewingPattern>(
      PageRouteBuilder<SewingPattern>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PatternFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (pattern != null && mounted) {
      await _repository.savePattern(pattern);
      _reload();
    }
  }

  Future<void> _editPattern(SewingPattern pattern) async {
    final updated = await Navigator.of(context).push<SewingPattern>(
      PageRouteBuilder<SewingPattern>(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PatternFormScreen(pattern: pattern),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
    if (updated != null && mounted) {
      await _repository.updatePattern(updated);
      _reload();
    }
  }

  Future<void> _deletePattern(SewingPattern pattern) async {
    if (pattern.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le patron'),
        content: Text(
          'Voulez-vous vraiment supprimer le patron « ${pattern.name} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _repository.deletePattern(pattern.id);
        _reload();
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATALOGUE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            const Text('Patrons du Mali'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, SewingPattern>>(
        future: _patterns,
        builder: (context, snapshot) {
          final patterns = snapshot.data ?? {};
          final defaultPatterns =
              patterns.values.where((p) => p.isDefault).toList();
          final customPatterns =
              patterns.values.where((p) => !p.isDefault).toList();

          // Filtrer par recherche
          final query = _query.trim().toLowerCase();
          final filteredDefault = query.isEmpty
              ? defaultPatterns
              : defaultPatterns.where((p) =>
                  p.name.toLowerCase().contains(query) ||
                  p.tagline.toLowerCase().contains(query)).toList();
          final filteredCustom = query.isEmpty
              ? customPatterns
              : customPatterns.where((p) =>
                  p.name.toLowerCase().contains(query) ||
                  p.tagline.toLowerCase().contains(query)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildChildren(
                filteredDefault,
                filteredCustom,
                query,
                patterns,
                context,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _addPattern,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Nouveau patron'),
      ),
    );
  }

  List<Widget> _buildChildren(
    List<SewingPattern> filteredDefault,
    List<SewingPattern> filteredCustom,
    String query,
    Map<String, SewingPattern> patterns,
    BuildContext context,
  ) {
    final children = <Widget>[
      // Barre de recherche
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un patron…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      _query = '';
                      setState(() {});
                    },
                  ),
            isDense: true,
          ),
          onChanged: (value) {
            setState(() => _query = value);
          },
        ),
      ),
      const SizedBox(height: 8),

      // Bannière d'introduction
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7B2D42), Color(0xFFA85462)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.content_cut,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${patterns.length} patrons disponibles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Boubou, taille basse, kaftan, ensemble pagne… Chaque patron '
                'affiche uniquement les mesures utiles à sa coupe, avec un '
                'dessin qui suit les mesures de la fiche.',
                style: TextStyle(
                  color: Color(0xFFF7E7EA),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(height: 18),
    ];

    // Section patrons par défaut
    if (filteredDefault.isNotEmpty) {
      children.add(_SectionHeader(
        title: 'Patrons de référence',
        subtitle: '${filteredDefault.length} patron(s) par défaut',
      ));
      children.add(const SizedBox(height: 10));
      for (final pattern in filteredDefault) {
        children.add(
          _PatternCard(
            pattern: pattern,
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PatternDetailScreen(pattern: pattern),
                transitionsBuilder: (context, animation, secondaryAnimation,
                        child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            onEdit: () => _editPattern(pattern),
            onDelete: () => _deletePattern(pattern),
            isDefault: true,
          ),
        );
        children.add(const SizedBox(height: 10));
      }
    }

    // Section patrons personnalisés
    if (filteredCustom.isNotEmpty) {
      children.add(_SectionHeader(
        title: 'Vos patrons personnalisés',
        subtitle: '${filteredCustom.length} patron(s) créé(s)',
      ));
      children.add(const SizedBox(height: 10));
      for (final pattern in filteredCustom) {
        children.add(
          _PatternCard(
            pattern: pattern,
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    PatternDetailScreen(pattern: pattern),
                transitionsBuilder: (context, animation, secondaryAnimation,
                        child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            onEdit: () => _editPattern(pattern),
            onDelete: () => _deletePattern(pattern),
            isDefault: false,
          ),
        );
        children.add(const SizedBox(height: 10));
      }
    } else if (query.isEmpty) {
      // Bouton pour ajouter un premier patron personnalisé
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SectionCard(
            title: 'Créer votre premier patron',
            icon: Icons.add_circle_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Créez un patron sur mesure avec vos propres mesures '
                  'clés et conseils de coupe. Il sera disponible dans '
                  'toutes vos fiches.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9A8A8F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addPattern,
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Nouveau patron personnalisé'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    children.add(const SizedBox(height: 24));
    return children;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7B2D42),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF9A8A8F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.pattern,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isDefault = false,
  });

  final SewingPattern pattern;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1EB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1E2D8)),
            ),
            child: Icon(
              pattern.icon,
              color: const Color(0xFF9A6A52),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pattern.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (!isDefault) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Personnalisé',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8C6239),
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                Text(
                  pattern.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF8A767D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _TinyTag(label: pattern.garmentType),
          const SizedBox(width: 6),
          _TinyTag(
            label:
                '${pattern.keyMeasurements.length} mesures clés',
          ),
        ],
      ),
      const SizedBox(height: 12),
    ];

    if (onEdit != null || onDelete != null) {
      children.add(
        Row(
          children: [
            if (onEdit != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    side: const BorderSide(
                      color: Color(0xFFEFE3DC),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (onDelete != null && !isDefault)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEFE3DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8C6A55),
        ),
      ),
    );
  }
}