import 'package:flutter/material.dart';
import 'models.dart';
import 'rapport_final_screen.dart';

class VerificationDetailsScreen extends StatefulWidget {
  final RapportVerification rapport;

  const VerificationDetailsScreen({super.key, required this.rapport});

  @override
  State<VerificationDetailsScreen> createState() => _VerificationDetailsScreenState();
}

class _VerificationDetailsScreenState extends State<VerificationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs supplémentaires
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _typeVehiculeController = TextEditingController();
  final TextEditingController _categorieController = TextEditingController();
  final TextEditingController _accessoiresController = TextEditingController();
  final TextEditingController _chargeMaxiController = TextEditingController();
  final TextEditingController _anneeFabricationController = TextEditingController();
  final TextEditingController _marquageCEController = TextEditingController();
  final TextEditingController _compteurHorametreController = TextEditingController();
  final TextEditingController _numeroParcController = TextEditingController();
  final TextEditingController _nomResponsableController = TextEditingController();
  final TextEditingController _societeResponsableController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser avec les valeurs existantes si disponibles
    _numeroSerieController.text = widget.rapport.numeroSerie ?? '';
    _typeVehiculeController.text = widget.rapport.typeVehicule ?? '';
    _categorieController.text = widget.rapport.categorieVehicule ?? '';
    _accessoiresController.text = widget.rapport.accessoires ?? '';
    _chargeMaxiController.text = widget.rapport.chargeMaxiLevage ?? '';
    _anneeFabricationController.text = widget.rapport.anneeFabrication ?? '';
    _marquageCEController.text = widget.rapport.marquageCE ?? '';
    _compteurHorametreController.text = widget.rapport.compteurHorametre ?? '';
    _numeroParcController.text = widget.rapport.numeroParc ?? '';
    _nomResponsableController.text = widget.rapport.nomResponsable ?? '';
    _societeResponsableController.text = widget.rapport.societeResponsable ?? '';
  }

  void _goToFinalScreen() {
    if (_formKey.currentState!.validate()) {
      // Sauvegarder les informations supplémentaires
      widget.rapport.numeroSerie = _numeroSerieController.text;
      widget.rapport.typeVehicule = _typeVehiculeController.text;
      widget.rapport.categorieVehicule = _categorieController.text;
      widget.rapport.accessoires = _accessoiresController.text;
      widget.rapport.chargeMaxiLevage = _chargeMaxiController.text;
      widget.rapport.anneeFabrication = _anneeFabricationController.text;
      widget.rapport.marquageCE = _marquageCEController.text;
      widget.rapport.compteurHorametre = _compteurHorametreController.text;
      widget.rapport.numeroParc = _numeroParcController.text;
      widget.rapport.nomResponsable = _nomResponsableController.text;
      widget.rapport.societeResponsable = _societeResponsableController.text;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RapportFinalScreen(rapport: widget.rapport),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3/4 - Détails de la Vérification'),
        backgroundColor: Colors.blueGrey,
        actions: [
          TextButton.icon(
            onPressed: _goToFinalScreen,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section Types de Vérification ---
              const Text(
                'TYPE DE VÉRIFICATION',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Vérification de mise en service (Article R4323-22)'),
                value: widget.rapport.typesVerification.contains(TypeVerification.miseEnService),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      widget.rapport.typesVerification.add(TypeVerification.miseEnService);
                    } else {
                      widget.rapport.typesVerification.remove(TypeVerification.miseEnService);
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Vérification générale périodique (VGP)(Article R4323-23, 24, 25, 26, 27)'),
                value: widget.rapport.typesVerification.contains(TypeVerification.generalePeriodique),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      widget.rapport.typesVerification.add(TypeVerification.generalePeriodique);
                    } else {
                      widget.rapport.typesVerification.remove(TypeVerification.generalePeriodique);
                    }
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Vérification de remise en service (Article R4323-28)'),
                value: widget.rapport.typesVerification.contains(TypeVerification.remiseEnService),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      widget.rapport.typesVerification.add(TypeVerification.remiseEnService);
                    } else {
                      widget.rapport.typesVerification.remove(TypeVerification.remiseEnService);
                    }
                  });
                },
              ),
              const Divider(height: 30),

              // --- Section Documents Obligatoires ---
              const Text(
                'DOCUMENT OBLIGATOIRE REMPLI ET FOURNI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...widget.rapport.documentsObligatoires.map((doc) {
                return SwitchListTile(
                  title: Text(doc.titre),
                  value: doc.fourni,
                  onChanged: (value) {
                    setState(() {
                      doc.fourni = value;
                    });
                  },
                  activeTrackColor: Colors.green,
                  subtitle: Text(doc.fourni ? 'OUI' : 'NON'),
                );
              }),
              const Divider(height: 30),

              // --- Informations Complémentaires ---
              const Text(
                'IDENTIFICATION DE L\'APPAREIL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTextField(_numeroSerieController, 'N° de Série'),
              _buildTextField(_typeVehiculeController, 'Type'),
              _buildTextField(_categorieController, 'Catégorie'),
              _buildTextField(_accessoiresController, 'Accessoire(s)'),
              _buildTextField(_chargeMaxiController, 'Charge Maxi de Levage (Kg)'),
              _buildTextField(_anneeFabricationController, 'Année de Fabrication'),
              _buildTextField(_marquageCEController, 'Marquage CE (Oui/Non)'),
              _buildTextField(_compteurHorametreController, 'Compteur Horamètre'),
              _buildTextField(_numeroParcController, 'N° du Parc'),
              const Divider(height: 30),

              // --- Responsable de l'appareil ---
              const Text(
                'RESPONSABLE DE L\'APPAREIL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildTextField(_nomResponsableController, 'Nom du Responsable'),
              _buildTextField(_societeResponsableController, 'Société'),
            ],
          ),
        ),
      ),
    );
  }

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
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _numeroSerieController.dispose();
    _typeVehiculeController.dispose();
    _categorieController.dispose();
    _accessoiresController.dispose();
    _chargeMaxiController.dispose();
    _anneeFabricationController.dispose();
    _marquageCEController.dispose();
    _compteurHorametreController.dispose();
    _numeroParcController.dispose();
    _nomResponsableController.dispose();
    _societeResponsableController.dispose();
    super.dispose();
  }
}
