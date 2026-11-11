import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _interests = [];
  final Set<String> _selected = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = _client.auth.currentUser?.id;
      // Interessen seitenweise laden — die API liefert max. 1000 Zeilen
      // pro Anfrage, der Katalog ist inzwischen größer
      final interests = <Map<String, dynamic>>[];
      for (var from = 0;; from += 1000) {
        final page = await _client
            .from('interests')
            .select()
            .order('name_de')
            .range(from, from + 999);
        final rows = List<Map<String, dynamic>>.from(page);
        interests.addAll(rows);
        if (rows.length < 1000) break;
      }
      final results = await Future.wait([
        _client.from('interest_categories').select().order('sort_order'),
        if (userId != null)
          _client.from('user_interests').select('interest_id'),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = List.from(results[0]);
        _interests = interests;
        if (results.length > 1) {
          _selected.addAll(
            (results[1] as List).map((r) => r['interest_id'] as String),
          );
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Fehler beim Laden: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId = _client.auth.currentUser!.id;
      // Komplett ersetzen: erst eigene löschen, dann Auswahl einfügen
      await _client.from('user_interests').delete().neq('interest_id', '');
      if (_selected.isNotEmpty) {
        await _client.from('user_interests').insert(
              _selected
                  .map((id) => {'user_id': userId, 'interest_id': id})
                  .toList(),
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Interessen'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Speichern…' : 'Speichern'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Wähle so spezifisch wie möglich — '
            '($_selected ausgewählt)',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          for (final cat in _categories) ...[
            Text(
              cat['name_de'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final interest in _interests
                    .where((i) => i['category_id'] == cat['id'])
                    .toList())
                  FilterChip(
                    label: Text(interest['name_de'] as String),
                    selected: _selected.contains(interest['id']),
                    onSelected: (value) => setState(() {
                      value
                          ? _selected.add(interest['id'] as String)
                          : _selected.remove(interest['id']);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
