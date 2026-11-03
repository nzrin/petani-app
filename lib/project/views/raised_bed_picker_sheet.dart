import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/project/models/raised_bed_record.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

Future<Set<int>?> showRaisedBedPickerSheet({
  required BuildContext context,
  required String cropCode,
  required List<RaisedBedRecord> raisedBeds,
  required Set<int> initialSelection,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RaisedBedPickerSheet(
      cropCode: cropCode,
      raisedBeds: raisedBeds,
      initialSelection: initialSelection,
    ),
  );
}

class RaisedBedPickerSheet extends StatefulWidget {
  const RaisedBedPickerSheet({
    required this.cropCode,
    required this.raisedBeds,
    required this.initialSelection,
    super.key,
  });

  final String cropCode;
  final List<RaisedBedRecord> raisedBeds;
  final Set<int> initialSelection;

  @override
  State<RaisedBedPickerSheet> createState() => _RaisedBedPickerSheetState();
}

class _RaisedBedPickerSheetState extends State<RaisedBedPickerSheet> {
  final _searchController = TextEditingController();
  final _rangeController = TextEditingController();
  late final Set<int> _selectedIds;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelection};
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    _rangeController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<RaisedBedRecord> get _visibleRaisedBeds {
    final query = _searchController.text.trim();
    if (query.isEmpty) return widget.raisedBeds;
    return widget.raisedBeds
        .where((raisedBed) => '${raisedBed.bedNumber}'.contains(query))
        .toList(growable: false);
  }

  void _toggle(RaisedBedRecord raisedBed) {
    setState(() {
      if (!_selectedIds.add(raisedBed.id)) _selectedIds.remove(raisedBed.id);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(widget.raisedBeds.map((raisedBed) => raisedBed.id));
    });
  }

  void _clear() => setState(_selectedIds.clear);

  void _applyRange() {
    final input = _rangeController.text.trim();
    final numbers = <int>{};
    var isValid = input.isNotEmpty;
    for (final rawPart in input.split(',')) {
      final part = rawPart.trim();
      if (part.isEmpty) continue;
      if (!part.contains('-')) {
        final value = int.tryParse(part);
        if (value == null) {
          isValid = false;
          break;
        }
        numbers.add(value);
        continue;
      }

      final bounds = part.split('-').map((value) => value.trim()).toList();
      if (bounds.length != 2) {
        isValid = false;
        break;
      }
      final start = int.tryParse(bounds.first);
      final end = int.tryParse(bounds.last);
      if (start == null || end == null || start > end) {
        isValid = false;
        break;
      }
      for (var number = start; number <= end; number++) {
        numbers.add(number);
      }
    }

    final matchingIds = widget.raisedBeds
        .where((raisedBed) => numbers.contains(raisedBed.bedNumber))
        .map((raisedBed) => raisedBed.id)
        .toSet();
    if (!isValid || matchingIds.isEmpty) {
      setState(() {
        final terminology = CropRowTerminology.forCropCode(widget.cropCode);
        _rangeError =
            'Masukkan nombor atau julat ${terminology.lowercase} yang sah.';
      });
      return;
    }

    setState(() {
      _selectedIds.addAll(matchingIds);
      _rangeError = null;
      _rangeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleRaisedBeds = _visibleRaisedBeds;
    final rowTerminology = CropRowTerminology.forCropCode(widget.cropCode);
    return KeyboardInsetPadding(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Material(
          key: const Key('raised-bed-picker-sheet'),
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D9D7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih ${rowTerminology.title}',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedIds.length} daripada '
                            '${widget.raisedBeds.length} dipilih',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  key: const Key('raised-bed-search-field'),
                  controller: _searchController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Cari nombor ${rowTerminology.lowercase}',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F2),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('raised-bed-range-field'),
                        controller: _rangeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9,\-\s]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Contoh: 1-20, 25',
                          errorText: _rangeError,
                          filled: true,
                          fillColor: const Color(0xFFF1F3F2),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      key: const Key('apply-raised-bed-range-button'),
                      onPressed: _applyRange,
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _clear,
                      child: const Text('Kosongkan'),
                    ),
                    TextButton(
                      onPressed: _selectAll,
                      child: const Text('Pilih Semua'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleRaisedBeds.isEmpty
                    ? Center(
                        child: Text('${rowTerminology.title} tidak dijumpai.'),
                      )
                    : GridView.builder(
                        key: const Key('task-raised-bed-grid'),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                        itemCount: visibleRaisedBeds.length,
                        itemBuilder: (context, index) {
                          final raisedBed = visibleRaisedBeds[index];
                          final selected = _selectedIds.contains(raisedBed.id);
                          return Material(
                            color: selected
                                ? AppColors.primaryAction
                                : AppColors.creamDark,
                            shape: const CircleBorder(),
                            child: InkWell(
                              key: ValueKey<String>(
                                'task-raised-bed-${raisedBed.bedNumber}',
                              ),
                              onTap: () => _toggle(raisedBed),
                              customBorder: const CircleBorder(),
                              child: Center(
                                child: Text(
                                  '${raisedBed.bedNumber}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.creamDeep,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: AppButton(
                  key: const Key('confirm-raised-bed-selection-button'),
                  label: 'Gunakan (${_selectedIds.length})',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(context, _selectedIds),
                  disabledBackgroundColor: const Color(0xFFCCD4CF),
                  disabledForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
