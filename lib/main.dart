import 'package:flutter/material.dart';
import 'models.dart';
import 'package:formulaire_app/checklist_screen.dart';
import 'package:formulaire_app/verification_details_screen.dart';

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

  // Contrôleurs pour récupérer les valeurs des champs texte
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _marqueController = TextEditingController();
  final TextEditingController _immatController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();

  // Fonction appelée quand on clique sur "Passer à la Checklist"

  void _submitForm() {
  if (_formKey.currentState!.validate()) {
    final initialRapport = RapportVerification(
      nomClient: _nomController.text,
      emailClient: _emailController.text,
      marqueModele: _marqueController.text,
      immatriculation: _immatController.text,
      kilometrage: int.tryParse(_kmController.text) ?? 0,
      checklist: defaultChecklist, 
    );

    // TODO: Naviguer vers ChecklistScreen
    // Remplacer le print() par la navigation :
    Navigator.push(
      context,
      MaterialPageRoute(
        // IMPORTANT : N'oubliez pas l'import au début de main.dart
        builder: (context) => ChecklistScreen(rapport: initialRapport),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1/3 - Infos Client & Véhicule'),
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
              _buildTextField(_immatController, 'Immatriculation', required: true),
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
  
  // Widget réutilisable pour les champs de texte
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool required = false,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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
          return null;
        },
      ),
    );
  }
}