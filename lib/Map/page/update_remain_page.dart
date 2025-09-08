import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateRemainPage extends StatefulWidget {
  final String reliefCenterId;
  final int capacity;
  final int remainCapacity;
  final List<Map<String, dynamic>> resources;
  const UpdateRemainPage({
    required this.reliefCenterId,
    required this.capacity,
    required this.remainCapacity,
    required this.resources,
    Key? key,
  }) : super(key: key);

  @override
  State<UpdateRemainPage> createState() => _UpdateRemainPageState();
}

class _UpdateRemainPageState extends State<UpdateRemainPage> {
  late TextEditingController _remainCapacityController;
  late List<Map<String, dynamic>> _resources;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remainCapacityController = TextEditingController(text: widget.remainCapacity.toString());
    _resources = widget.resources.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  void dispose() {
    _remainCapacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    final remainStr = _remainCapacityController.text.trim();
    if (remainStr.isEmpty || int.tryParse(remainStr) == null) {
      setState(() { _error = 'Remain capacity must be a number.'; _saving = false; });
      return;
    }
    final int remain = int.parse(remainStr);
    if (remain < 0 || remain > widget.capacity) {
      setState(() { _error = 'Remain must be between 0 and ${widget.capacity}.'; _saving = false; });
      return;
    }
    List<Map<String, dynamic>> updatedResources = [];
    for (var r in _resources) {
      final remainStr = r['remain']?.toString() ?? r['value']?.toString() ?? '0';
      final valueStr = r['value']?.toString() ?? '0';
      double remainVal = double.tryParse(remainStr) ?? 0;
      double valueVal = double.tryParse(valueStr) ?? 0;
      if (remainVal < 0) remainVal = 0;
      if (remainVal > valueVal) {
        setState(() {
          _error = 'Remain for resource "${r['name']}" cannot be greater than its value ($valueVal).';
          _saving = false;
        });
        return;
      }
      updatedResources.add({
        'name': r['name'],
        'value': valueStr,
        'remain': remainVal.toString(),
      });
    }
    try {
      await FirebaseFirestore.instance.collection('relief_centers').doc(widget.reliefCenterId).update({
        'remain_capacity': remain,
        'resources': updatedResources,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = 'Failed to update: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Remain')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.blue, size: 28),
                        const SizedBox(width: 10),
                        Text('Capacity', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Total: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        Text('${widget.capacity}', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        Expanded(
                          child: TextField(
                            controller: _remainCapacityController,
                            decoration: const InputDecoration(labelText: 'Remain Capacity'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Resources', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._resources.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;
              final remainController = TextEditingController(text: r['remain']?.toString() ?? r['value']?.toString() ?? '');
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: const Icon(Icons.inventory, color: Colors.brown),
                  title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: remainController,
                          decoration: const InputDecoration(labelText: 'Remain'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _resources[idx]['remain'] = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('/ ${r['value']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            }),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
              ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                onPressed: _saving ? null : _save,
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
