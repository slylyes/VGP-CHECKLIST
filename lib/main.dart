import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'package:formulaire_app/checklist_screen.dart';
import 'package:formulaire_app/verification_details_screen.dart';

class ImmatriculationInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

    String letters1 = '';
    String digits = '';
    String letters2 = '';

    var cursor = 0;

    while (cursor < raw.length && letters1.length < 2) {
      final c = raw[cursor];
      if (RegExp(r'[A-Z]').hasMatch(c)) letters1 += c;
      cursor++;
    }

    while (cursor < raw.length && digits.length < 3) {
      final c = raw[cursor];
      if (RegExp(r'[0-9]').hasMatch(c)) digits += c;
      cursor++;
    }

    while (cursor < raw.length && letters2.length < 2) {
      final c = raw[cursor];
      if (RegExp(r'[A-Z]').hasMatch(c)) letters2 += c;
      cursor++;
    }

    var formatted = letters1;
    if (letters1.length == 2 && (digits.isNotEmpty || letters2.isNotEmpty)) {
      formatted += '-';
    }
    formatted += digits;
    if (digits.length == 3 && letters2.isNotEmpty) {
      formatted += '-';
    }
    formatted += letters2;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Formulaire Véhicule',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const InfoSaisieScreen(),
      routes: {
        '/verification_details': (context) {
          final rapport = ModalRoute.of(context)!.settings.arguments as RapportVerification;
          return VerificationDetailsScreen(rapport: rapport);
        },
      },
    );
  }
}

// --- Écran de Saisie des Informations Client/Véhicule ---
class InfoSaisieScreen extends StatefulWidget {
  const InfoSaisieScreen({super.key});

  @override
  State<InfoSaisieScreen> createState() => _InfoSaisieScreenState();
}

class _InfoSaisieScreenState extends State<InfoSaisieScreen> {
  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  static const String _immatHistoryKey = 'immatriculation_history';

  // Contrôleurs pour récupérer les valeurs des champs texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _immatController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final FocusNode _immatFocusNode = FocusNode();

  final List<String> _immatriculationHistory = [];
  RapportVerification? _rapportEnCours;

  @override
  void initState() {
    super.initState();
    _loadImmatriculationHistory();
  }

  Future<void> _loadImmatriculationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_immatHistoryKey) ?? [];
    if (!mounted) return;
    setState(() {
      _immatriculationHistory
        ..clear()
        ..addAll(saved);
    });
  }

  String _normalizePlate(String value) {
    return value.toUpperCase().replaceAll('-', '').trim();
  }

  Future<void> _saveImmatriculationToHistory(String immatriculation) async {
    final normalized = immatriculation.toUpperCase().trim();
    if (!RegExp(r'^[A-Z]{2}-[0-9]{3}-[A-Z]{2}$').hasMatch(normalized)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final updated = List<String>.from(_immatriculationHistory)
      ..removeWhere((plate) => plate.toUpperCase() == normalized)
      ..insert(0, normalized);

    if (updated.length > 100) {
      updated.removeRange(100, updated.length);
    }

    await prefs.setStringList(_immatHistoryKey, updated);

    if (!mounted) return;
    setState(() {
      _immatriculationHistory
        ..clear()
        ..addAll(updated);
    });
  }

  // Fonction appelée quand on clique sur "Passer à la Checklist"

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nomClient = _nomController.text.trim();
    final emailClient = _emailController.text.trim();
    final marqueModele = _marqueController.text.trim();
    final immatriculation = _immatController.text.trim().toUpperCase();
    final kilometrage = int.tryParse(_kmController.text.trim()) ?? 0;

    if (_rapportEnCours == null) {
      _rapportEnCours = RapportVerification(
        nomClient: nomClient,
        emailClient: emailClient,
        marqueModele: marqueModele,
        immatriculation: immatriculation,
        kilometrage: kilometrage,
        checklist: defaultChecklist,
      );
    } else {
      _rapportEnCours!.nomClient = nomClient;
      _rapportEnCours!.emailClient = emailClient;
      _rapportEnCours!.marqueModele = marqueModele;
      _rapportEnCours!.immatriculation = immatriculation;
      _rapportEnCours!.kilometrage = kilometrage;
    }

    await _saveImmatriculationToHistory(immatriculation);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChecklistScreen(rapport: _rapportEnCours!),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1/4 - Infos Client & Véhicule'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- Section Client ---
              const Text('Informations Client', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField(_nomController, 'Nom et Prénom Client', required: true),
              _buildTextField(_emailController, 'Adresse E-mail du client', required: true, keyboardType: TextInputType.emailAddress),
              const Divider(height: 30),

              // --- Section Véhicule ---
              const Text('Informations Véhicule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField(_marqueController, 'Marque et Modèle'),
              _buildImmatriculationField(),
              _buildTextField(_kmController, 'Kilométrage (km)', keyboardType: TextInputType.number),
              const Divider(height: 30),

              // --- Bouton de Navigation ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Passer à la Checklist', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImmatriculationField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: RawAutocomplete<String>(
        textEditingController: _immatController,
        focusNode: _immatFocusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          final query = _normalizePlate(textEditingValue.text);
          if (query.isEmpty) {
            return const Iterable<String>.empty();
          }

          return _immatriculationHistory.where((plate) {
            return _normalizePlate(plate).startsWith(query);
          }).take(8);
        },
        onSelected: (String selection) {
          _immatController
            ..text = selection
            ..selection = TextSelection.collapsed(offset: selection.length);
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.characters,
            maxLength: 9,
            inputFormatters: [ImmatriculationInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Immatriculation',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final plate = (value ?? '').trim();
              if (plate.isEmpty) {
                return 'Ce champ est obligatoire.';
              }
              if (!RegExp(r'^[A-Z]{2}-[0-9]{3}-[A-Z]{2}$').hasMatch(plate)) {
                return 'Format attendu : AA-001-AA';
              }
              return null;
            },
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220, maxWidth: 320),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Widget réutilisable pour les champs de texte
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        TextCapitalization textCapitalization = TextCapitalization.none,
        int? maxLength,
        String? Function(String?)? customValidator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Ce champ est obligatoire.';
          }
          // Validation basique d'email (pour le champ email)
          if (keyboardType == TextInputType.emailAddress && value != null && !value.contains('@')) {
            return 'Veuillez entrer une adresse email valide.';
          }
          if (customValidator != null) {
            return customValidator(value);
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _marqueController.dispose();
    _immatController.dispose();
    _kmController.dispose();
    _immatFocusNode.dispose();
    super.dispose();
  }
}