import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DiabetesRiskScreen extends StatefulWidget {
  const DiabetesRiskScreen({super.key});

  @override
  State<DiabetesRiskScreen> createState() => _DiabetesRiskScreenState();
}

class _DiabetesRiskScreenState extends State<DiabetesRiskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _hba1cController = TextEditingController();
  final _glucoseController = TextEditingController();

  Interpreter? _interpreter;
  Map<String, dynamic>? _metadata;

  String? _gender;
  String? _smokingHistory;
  bool _hasHypertension = false;
  bool _hasHeartDisease = false;
  bool _unknownHba1c = false;
  bool _unknownGlucose = false;
  bool _isLoadingModel = true;
  bool _isCalculating = false;
  double? _riskScore;
  double? _calculatedBmi;
  bool _usedEstimatedLabValues = false;
  String? _resultTitle;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _hba1cController.dispose();
    _glucoseController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  Future<void> _loadModel() async {
    try {
      final metadataText = await rootBundle.loadString(
        'assets/ml/diabetes_metadata.json',
      );
      final interpreter = await Interpreter.fromAsset(
        'assets/ml/diabetes_model.tflite',
      );

      if (!mounted) return;
      setState(() {
        _metadata = jsonDecode(metadataText) as Map<String, dynamic>;
        _interpreter = interpreter;
        _isLoadingModel = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingModel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model yuklenemedi: $e')),
      );
    }
  }

  void _calculateRisk() {
    if (_interpreter == null || _metadata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model henuz hazir degil')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      final bmi = _calculateBmi();
      final rawInput = <double>[
        _gender == 'Female' ? 0.0 : 1.0,
        _parseNumber(_ageController.text),
        _hasHypertension ? 1.0 : 0.0,
        _hasHeartDisease ? 1.0 : 0.0,
        _smokingIndex(_smokingHistory!),
        bmi,
        _labValueOrMean(_hba1cController, _unknownHba1c, 6),
        _labValueOrMean(_glucoseController, _unknownGlucose, 7),
      ];

      final means = (_metadata!['scaler_mean'] as List)
          .map((value) => (value as num).toDouble())
          .toList();
      final scales = (_metadata!['scaler_scale'] as List)
          .map((value) => (value as num).toDouble())
          .toList();

      final scaledInput = List<double>.generate(
        rawInput.length,
        (index) => (rawInput[index] - means[index]) / scales[index],
      );

      final output = List.generate(1, (_) => List<double>.filled(1, 0));
      _interpreter!.run([scaledInput], output);

      final score = output.first.first.clamp(0.0, 1.0).toDouble();
      final threshold = ((_metadata!['threshold'] as num?) ?? 0.5).toDouble();

      setState(() {
        _riskScore = score;
        _calculatedBmi = bmi;
        _usedEstimatedLabValues = _unknownHba1c || _unknownGlucose;
        _resultTitle = score >= threshold
            ? 'Diyabet riski yuksek gorunuyor'
            : 'Diyabet riski dusuk gorunuyor';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hesaplama hatasi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  double _smokingIndex(String value) {
    final classes = (_metadata!['smoking_history_classes'] as List)
        .map((item) => item.toString())
        .toList();
    return classes.indexOf(value).toDouble();
  }

  double _parseNumber(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  double _calculateBmi() {
    final heightCm = _parseNumber(_heightController.text);
    final weightKg = _parseNumber(_weightController.text);
    final heightMeter = heightCm / 100;
    return weightKg / (heightMeter * heightMeter);
  }

  double _labValueOrMean(
    TextEditingController controller,
    bool useMean,
    int featureIndex,
  ) {
    if (!useMean) return _parseNumber(controller.text);
    final means = (_metadata!['scaler_mean'] as List)
        .map((value) => (value as num).toDouble())
        .toList();
    return means[featureIndex];
  }

  String? _requiredDropdown(String? value) {
    if (value == null || value.isEmpty) return 'Secim yapin';
    return null;
  }

  String? _numberValidator(
    String? value, {
    required double min,
    required double max,
    required String message,
    bool required = true,
  }) {
    if (!required) return null;
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null || number < min || number > max) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2C5282);
    const bg = Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Diyabet Risk Hesaplama',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingModel
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(
                      resultTitle: _resultTitle,
                      riskScore: _riskScore,
                      calculatedBmi: _calculatedBmi,
                      usedEstimatedLabValues: _usedEstimatedLabValues,
                    ),
                    const SizedBox(height: 16),
                    _Section(
                      title: 'Kisisel Bilgiler',
                      icon: Icons.person_search,
                      children: [
                        _ChoiceField<String>(
                          label: 'Cinsiyet',
                          value: _gender,
                          validator: _requiredDropdown,
                          items: const [
                            DropdownMenuItem(value: 'Female', child: Text('Kadin')),
                            DropdownMenuItem(value: 'Male', child: Text('Erkek')),
                          ],
                          onChanged: (value) {
                            setState(() => _gender = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _numberInput(
                          controller: _ageController,
                          label: 'Yas',
                          validator: (value) => _numberValidator(
                            value,
                            min: 1,
                            max: 120,
                            message: '1-120 arasi yas girin',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: 'Saglik Durumu',
                      icon: Icons.favorite,
                      children: [
                        _RiskToggle(
                          title: const Text('Hipertansiyon var mi?'),
                          subtitle: const Text('Tansiyon tanisi veya tedavisi'),
                          value: _hasHypertension,
                          onChanged: (value) {
                            setState(() => _hasHypertension = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        _RiskToggle(
                          title: const Text('Kalp hastaligi var mi?'),
                          subtitle: const Text('Gecirilmis veya aktif tani'),
                          value: _hasHeartDisease,
                          onChanged: (value) {
                            setState(() => _hasHeartDisease = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        _ChoiceField<String>(
                          label: 'Sigara gecmisi',
                          value: _smokingHistory,
                          validator: _requiredDropdown,
                          items: const [
                            DropdownMenuItem(
                              value: 'No Info',
                              child: Text('Bilgi yok'),
                            ),
                            DropdownMenuItem(
                              value: 'never',
                              child: Text('Hic kullanmadi'),
                            ),
                            DropdownMenuItem(
                              value: 'former',
                              child: Text('Birakti'),
                            ),
                            DropdownMenuItem(
                              value: 'current',
                              child: Text('Kullaniyor'),
                            ),
                            DropdownMenuItem(
                              value: 'ever',
                              child: Text('Daha once kullandi'),
                            ),
                            DropdownMenuItem(
                              value: 'not current',
                              child: Text('Su an kullanmiyor'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _smokingHistory = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: 'Olcumler',
                      icon: Icons.monitor_heart,
                      children: [
                        _numberInput(
                          controller: _heightController,
                          label: 'Boy (cm)',
                          validator: (value) => _numberValidator(
                            value,
                            min: 80,
                            max: 230,
                            message: '80-230 cm arasi boy girin',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _numberInput(
                          controller: _weightController,
                          label: 'Kilo (kg)',
                          validator: (value) => _numberValidator(
                            value,
                            min: 20,
                            max: 250,
                            message: '20-250 kg arasi kilo girin',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _numberInput(
                          controller: _hba1cController,
                          label: 'HbA1c seviyesi',
                          enabled: !_unknownHba1c,
                          validator: (value) => _numberValidator(
                            value,
                            min: 3,
                            max: 15,
                            message: '3-15 arasi HbA1c girin',
                            required: !_unknownHba1c,
                          ),
                        ),
                        _UnknownValueTile(
                          value: _unknownHba1c,
                          title: 'HbA1c degerimi bilmiyorum',
                          onChanged: (value) {
                            setState(() {
                              _unknownHba1c = value;
                              if (value) _hba1cController.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _numberInput(
                          controller: _glucoseController,
                          label: 'Kan sekeri seviyesi',
                          enabled: !_unknownGlucose,
                          validator: (value) => _numberValidator(
                            value,
                            min: 50,
                            max: 400,
                            message: '50-400 arasi deger girin',
                            required: !_unknownGlucose,
                          ),
                        ),
                        _UnknownValueTile(
                          value: _unknownGlucose,
                          title: 'Kan sekeri degerimi bilmiyorum',
                          onChanged: (value) {
                            setState(() {
                              _unknownGlucose = value;
                              if (value) _glucoseController.clear();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCalculating ? null : _calculateRisk,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isCalculating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.analytics),
                        label: const Text(
                          'Riski Hesapla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bu sonuc egitilmis model tahminidir; tibbi tani yerine gecmez.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _numberInput({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: _decoration(label),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
      onChanged: (value) {
        if (value.contains(',')) {
          controller.value = controller.value.copyWith(
            text: value.replaceAll(',', '.'),
            selection: TextSelection.collapsed(
              offset: value.replaceAll(',', '.').length,
            ),
          );
        }
      },
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2C5282), width: 2),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String? resultTitle;
  final double? riskScore;
  final double? calculatedBmi;
  final bool usedEstimatedLabValues;

  const _HeaderCard({
    required this.resultTitle,
    required this.riskScore,
    required this.calculatedBmi,
    required this.usedEstimatedLabValues,
  });

  @override
  Widget build(BuildContext context) {
    final hasResult = resultTitle != null && riskScore != null;
    final isHighRisk = (riskScore ?? 0) >= 0.5;
    final resultColor = isHighRisk
        ? const Color(0xFFFFD6D6)
        : const Color(0xFFD5F7E7);
    final resultTextColor = isHighRisk
        ? const Color(0xFF7F1D1D)
        : const Color(0xFF14532D);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF274472),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF274472).withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: Color(0xFF6EE7B7),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diyabet Risk Analizi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '8 klinik bilgi ile model tahmini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasResult ? resultColor : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: hasResult
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultTitle!,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: resultTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: riskScore,
                          minHeight: 9,
                          backgroundColor: Colors.white.withOpacity(0.7),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isHighRisk
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tahmin skoru: %${(riskScore! * 100).toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: resultTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (calculatedBmi != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Hesaplanan VKI: ${calculatedBmi!.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: resultTextColor.withOpacity(0.82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (usedEstimatedLabValues) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Bazi degerler bilinmedigi icin tahmin yaklasik hesaplandi.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: resultTextColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Butun degerleri girerseniz daha dogru bir sonuca ulasabilirsiniz.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: resultTextColor.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  )
                : const Text(
                    'Bilgileri girip hesapladiginda sonuc burada gorunecek.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _ChoiceField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      validator: validator,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2C5282), width: 2),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _RiskToggle extends StatelessWidget {
  final Widget title;
  final Widget subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RiskToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? const Color(0xFF2C5282) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF2C5282) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                value ? Icons.check : Icons.close,
                color: value ? Colors.white : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                    ),
                    child: title,
                  ),
                  const SizedBox(height: 3),
                  DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    child: subtitle,
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              activeColor: const Color(0xFF2C5282),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownValueTile extends StatelessWidget {
  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;

  const _UnknownValueTile({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFF2C5282),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
      onChanged: (checked) => onChanged(checked ?? false),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Color(0xFF2C5282),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
