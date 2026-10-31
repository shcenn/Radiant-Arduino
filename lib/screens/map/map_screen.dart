import 'package:flutter/material.dart';

import '../../data/live_controller.dart';
import '../../models/streetlight.dart';
import '../../widgets/streetlight_card.dart';
import 'streetlight_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final LiveController live;
  const MapScreen({super.key, required this.live});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _query = '';
  StreetlightStatus? _filter;
  @override
  Widget build(BuildContext context) {
    final lights = widget.live.lights;
    final visible = lights.asMap().entries.where((entry) {
      final unit = entry.value;
      return (_filter == null || unit.status == _filter) &&
          '${unit.id} ${unit.location}'.toLowerCase().contains(
            _query.toLowerCase().trim(),
          );
    }).toList();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Streetlight List',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search units',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<StreetlightStatus?>(
                    isExpanded: true,
                    value: _filter,
                    hint: const Text('All statuses'),
                    items: [
                      const DropdownMenuItem<StreetlightStatus?>(
                        value: null,
                        child: Text('All statuses'),
                      ),
                      for (final status in [
                        StreetlightStatus.functional,
                        StreetlightStatus.warning,
                        StreetlightStatus.offline,
                      ])
                        DropdownMenuItem<StreetlightStatus?>(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                const SizedBox(width: 16),
                Text('${visible.length} of ${lights.length} units'),
              ],
            ),
          ),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No units match this search and filter.'),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              itemCount: visible.length,
              itemBuilder: (context, index) {
                final entry = visible[index];
                return StreetlightCard(
                  light: entry.value,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StreetlightDetailScreen(
                        live: widget.live,
                        index: entry.key,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
