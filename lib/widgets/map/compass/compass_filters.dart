import 'package:flutter/material.dart';

/// Filter controls for the compass dialog.
/// Allows filtering of contacts and SAR marker types.
class CompassFilters extends StatefulWidget {
  final bool showContacts;
  final bool showFoundPerson;
  final bool showFire;
  final bool showStagingArea;
  final ValueChanged<bool> onShowContactsChanged;
  final ValueChanged<bool> onShowFoundPersonChanged;
  final ValueChanged<bool> onShowFireChanged;
  final ValueChanged<bool> onShowStagingAreaChanged;
  final VoidCallback onShowAll;

  const CompassFilters({
    super.key,
    required this.showContacts,
    required this.showFoundPerson,
    required this.showFire,
    required this.showStagingArea,
    required this.onShowContactsChanged,
    required this.onShowFoundPersonChanged,
    required this.onShowFireChanged,
    required this.onShowStagingAreaChanged,
    required this.onShowAll,
  });

  @override
  State<CompassFilters> createState() => _CompassFiltersState();
}

class _CompassFiltersState extends State<CompassFilters> {
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.filter_list, size: 20),
              SizedBox(width: 8),
              Text('Filter Markers'),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contacts filter
              _CompactFilterItem(
                icon: Icons.person,
                color: Theme.of(context).colorScheme.primary,
                label: 'Contacts',
                value: widget.showContacts,
                onChanged: (value) {
                  widget.onShowContactsChanged(value);
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              const Divider(height: 8),
              const SizedBox(height: 4),
              // SAR Markers section
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8, top: 4),
                child: Text(
                  'SAR Markers',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _CompactFilterItem(
                icon: Icons.person_pin,
                color: Colors.green,
                label: 'Found Person',
                value: widget.showFoundPerson,
                onChanged: (value) {
                  widget.onShowFoundPersonChanged(value);
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              _CompactFilterItem(
                icon: Icons.local_fire_department,
                color: Colors.red,
                label: 'Fire',
                value: widget.showFire,
                onChanged: (value) {
                  widget.onShowFireChanged(value);
                  setDialogState(() {});
                },
              ),
              const SizedBox(height: 4),
              _CompactFilterItem(
                icon: Icons.home_work,
                color: Colors.orange,
                label: 'Staging Area',
                value: widget.showStagingArea,
                onChanged: (value) {
                  widget.onShowStagingAreaChanged(value);
                  setDialogState(() {});
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                widget.onShowAll();
                setDialogState(() {});
              },
              child: const Text('Show All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filter markers',
      onPressed: () => _showFilterDialog(),
    );
  }
}

/// Compact filter item widget
class _CompactFilterItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CompactFilterItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Checkbox(
              value: value,
              onChanged: (val) => onChanged(val ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
