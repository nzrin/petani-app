import 'package:petani/project/models/crop_variety_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:petani/core/theme/app_theme.dart';
import 'package:petani/project/models/project_form_data.dart';
import 'package:petani/project/models/crop_row_terminology.dart';
import 'package:petani/shared/widgets/app_button.dart';
import 'package:petani/shared/widgets/keyboard_inset_padding.dart';

class SeedlingCountResult {
  const SeedlingCountResult({
    required this.seedlingCount,
    this.saveAndContinue = false,
    this.onlyUnset = true,
    this.varieties = const [],
  });

  final int seedlingCount;
  final bool saveAndContinue;
  final bool onlyUnset;
  final List<CropVariety> varieties;
}

Future<SeedlingCountResult?> showSeedlingCountSheet({
  required BuildContext context,
  required int? initialCount,
  required String cropCode,
  int? bedNumber,
  bool isBulk = false,
  List<CropVariety> availableVarieties = const [],
  List<CropVariety> initialVarieties = const [],
}) {
  return showModalBottomSheet<SeedlingCountResult>(
    context: context,
    isDismissible: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SeedlingCountSheet(
      initialCount: initialCount,
      cropCode: cropCode,
      bedNumber: bedNumber,
      isBulk: isBulk,
      availableVarieties: availableVarieties,
      initialVarieties: initialVarieties,
    ),
  );
}

class _SeedlingCountSheet extends StatefulWidget {
  const _SeedlingCountSheet({
    required this.initialCount,
    required this.cropCode,
    required this.bedNumber,
    required this.isBulk,
    required this.availableVarieties,
    required this.initialVarieties,
  });

  final int? initialCount;
  final String cropCode;
  final int? bedNumber;
  final bool isBulk;
  final List<CropVariety> availableVarieties;
  final List<CropVariety> initialVarieties;

  @override
  State<_SeedlingCountSheet> createState() => _SeedlingCountSheetState();
}

class _SeedlingCountSheetState extends State<_SeedlingCountSheet> {
  late final TextEditingController _countController;
  bool _onlyUnset = true;
  late final Set<String> _selectedVarietyCodes;

  int? get _count => int.tryParse(_countController.text.trim());
  bool get _canSave {
    final hasValidCount = _count != null && _count! >= 0;
    final hasRequiredVariety = _selectedVarietyCodes.isNotEmpty;
    return hasValidCount && hasRequiredVariety;
  }

  @override
  void initState() {
    super.initState();
    _countController = TextEditingController(
      text: widget.initialCount?.toString() ?? '',
    );
    _selectedVarietyCodes = widget.initialVarieties
        .map((variety) => variety.code)
        .toSet();
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  void _setCount(int value) {
    final safeValue = value < 0 ? 0 : value;
    _countController.value = TextEditingValue(
      text: '$safeValue',
      selection: TextSelection.collapsed(offset: '$safeValue'.length),
    );
    setState(() {});
  }

  void _adjustCount(int amount) {
    _setCount((_count ?? 0) + amount);
  }

  void _submit({bool saveAndContinue = false}) {
    final count = _count;
    if (!_canSave || count == null) return;
    Navigator.pop(
      context,
      SeedlingCountResult(
        seedlingCount: count,
        saveAndContinue: saveAndContinue,
        onlyUnset: _onlyUnset,
        varieties: widget.availableVarieties
            .where((variety) => _selectedVarietyCodes.contains(variety.code))
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowTerminology = CropRowTerminology.forCropCode(widget.cropCode);

    return KeyboardInsetPadding(
      child: Material(
        key: const Key('seedling-count-sheet'),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5D9D7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isBulk
                      ? 'Tetapkan Secara Pukal'
                      : '${rowTerminology.title} ${widget.bedNumber}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isBulk
                      ? 'Masukkan jumlah anak pokok untuk beberapa '
                            '${rowTerminology.lowercase}.'
                      : 'Masukkan jumlah anak pokok untuk '
                            '${rowTerminology.lowercase} ini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('seedling-count-field'),
                  controller: _countController,
                  autofocus: !widget.isBulk,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _CountAdjustButton(
                      label: '−10',
                      onPressed: () => _adjustCount(-10),
                    ),
                    const SizedBox(width: 8),
                    _CountAdjustButton(
                      label: '−1',
                      onPressed: () => _adjustCount(-1),
                    ),
                    const Spacer(),
                    _CountAdjustButton(
                      label: '+1',
                      onPressed: () => _adjustCount(1),
                    ),
                    const SizedBox(width: 8),
                    _CountAdjustButton(
                      label: '+10',
                      onPressed: () => _adjustCount(10),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      const presets = [150, 300, 500, 800];
                      final value = presets[index];
                      return ChoiceChip(
                        key: ValueKey<String>('seedling-preset-$value'),
                        label: Text('$value'),
                        selected: _count == value,
                        showCheckmark: false,
                        onSelected: (_) => _setCount(value),
                        selectedColor: AppColors.mint,
                        backgroundColor: const Color(0xFFF1F3F2),
                        side: BorderSide(
                          color: _count == value
                              ? AppColors.green
                              : const Color(0xFFDDE3E0),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: const StadiumBorder(),
                      );
                    },
                  ),
                ),
                if (widget.availableVarieties.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isBulk
                          ? 'Tetapkan ${CropVarietyCatalog.fieldTitle(widget.cropCode)} Secara Pukal'
                          : '${CropVarietyCatalog.fieldTitle(widget.cropCode)} Dalam ${rowTerminology.title}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isBulk
                          ? 'Pilih satu atau lebih varieti untuk digunakan '
                                'pada ${rowTerminology.lowercase} terlibat.'
                          : 'Pilih satu atau lebih varieti yang ditanam dalam '
                                '${rowTerminology.lowercase} ini.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      key: const Key('raised-bed-variety-options'),
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final variety in widget.availableVarieties)
                          FilterChip(
                            key: ValueKey<String>(
                              'raised-bed-variety-${variety.code}',
                            ),
                            label: Text(variety.label),
                            selected: _selectedVarietyCodes.contains(
                              variety.code,
                            ),
                            showCheckmark: false,
                            selectedColor: AppColors.mint,
                            backgroundColor: const Color(0xFFF1F3F2),
                            side: BorderSide(
                              color:
                                  _selectedVarietyCodes.contains(variety.code)
                                  ? AppColors.primaryAction
                                  : const Color(0xFFDDE3E0),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedVarietyCodes.add(variety.code);
                                } else {
                                  _selectedVarietyCodes.remove(variety.code);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
                if (widget.isBulk) ...[
                  const SizedBox(height: 18),
                  SwitchListTile.adaptive(
                    key: const Key('only-unset-switch'),
                    value: _onlyUnset,
                    onChanged: (value) => setState(() => _onlyUnset = value),
                    activeThumbColor: AppColors.green,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Hanya ${rowTerminology.lowercase} belum diisi',
                    ),
                    subtitle: const Text(
                      'Nilai yang telah disimpan tidak akan berubah.',
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Batal',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        key: const Key('save-seedling-count-button'),
                        label: widget.isBulk ? 'Tetapkan' : 'Simpan',
                        onPressed: _canSave ? _submit : null,
                        disabledBackgroundColor: const Color(0xFFCCD4CF),
                        disabledForegroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                if (!widget.isBulk) ...[
                  const SizedBox(height: 10),
                  AppButton.outlined(
                    key: const Key('save-and-next-button'),
                    label: 'Simpan & Seterusnya',
                    onPressed: _canSave
                        ? () => _submit(saveAndContinue: true)
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountAdjustButton extends StatelessWidget {
  const _CountAdjustButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.forest,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 38),
        side: const BorderSide(color: Color(0xFFDDE3E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}
