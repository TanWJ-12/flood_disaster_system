import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuickUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> center;
  final VoidCallback onUpdated;
  const QuickUpdateDialog({required this.center, required this.onUpdated});

  @override
  State<QuickUpdateDialog> createState() => _QuickUpdateDialogState();
}

class _QuickUpdateDialogState extends State<QuickUpdateDialog> {
  late TextEditingController _capacityController;
  late List<Map<String, dynamic>> _resources;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _capacityController = TextEditingController(text: widget.center['capacity']?.toString() ?? '');
    _resources = (widget.center['resources'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final capacityStr = _capacityController.text.trim();
    if (capacityStr.isEmpty || int.tryParse(capacityStr) == null) {
      setState(() { _error = 'Capacity must be a number.'; _saving = false; });
      return;
    }
    final int newCapacity = int.parse(capacityStr);
    // Update resources values
    List<Map<String, dynamic>> updatedResources = [];
    for (var r in _resources) {
      final valueStr = r['value']?.toString() ?? '';
      final remainStr = r['remain']?.toString() ?? valueStr;
      updatedResources.add({
        'name': r['name'],
        'value': valueStr,
        'remain': remainStr,
      });
    }
    // Also update remain_capacity
    String remainCapacityStr = widget.center['remain_capacity']?.toString() ?? widget.center['capacity']?.toString() ?? capacityStr;
    int remainCapacity = int.tryParse(remainCapacityStr) ?? newCapacity;
    // If capacity changed, adjust remain_capacity proportionally if needed
    int prevCapacity = widget.center['capacity'] ?? newCapacity;
    remainCapacity = remainCapacity + (newCapacity - prevCapacity);
    if (remainCapacity > newCapacity) remainCapacity = newCapacity;
    if (remainCapacity < 0) remainCapacity = 0;
    try {
      await FirebaseFirestore.instance.collection('relief_centers').doc(widget.center['id']).update({
        'capacity': newCapacity,
        'remain_capacity': remainCapacity,
        'resources': updatedResources,
      });
      widget.onUpdated();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() { _error = 'Failed to update: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quick Update'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ..._resources.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              final valueController = TextEditingController(text: r['value']?.toString() ?? '');
              final remainController = TextEditingController(text: r['remain']?.toString() ?? r['value']?.toString() ?? '');
              return Row(
                children: [
                  Expanded(child: Text(r['name'] ?? '')),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        _resources[idx]['value'] = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: remainController,
                      decoration: const InputDecoration(labelText: 'Remain'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        _resources[idx]['remain'] = val;
                      },
                    ),
                  ),
                ],
              );
            }),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update'),
        ),
      ],
    );
  }
}
