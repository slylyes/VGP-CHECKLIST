import 'package:flutter/material.dart';
import 'models.dart';
import 'pdf_generator.dart';
import 'package:share_plus/share_plus.dart';

class RapportFinalScreen extends StatefulWidget {
  final RapportVerification rapport;

  const RapportFinalScreen({super.key, required this.rapport});

  @override
  State<RapportFinalScreen> createState() => _RapportFinalScreenState();
}

class _RapportFinalScreenState extends State<RapportFinalScreen> {
  String? _generatedPdfInitialPath;
  String? _generatedPdfFinalPath;
  bool _isGeneratingInitial = false;
  bool _isGeneratingFinal = false;

  // Contrôleurs pour les défauts
  final List<TextEditingController> _defautControllers = 
    List.generate(8, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    // Initialiser les défauts existants
    for (int i = 0; i < widget.rapport.defauts.length && i < 8; i++) {
      _defautControllers[i].text = widget.rapport.defauts[i];
    }
  }

  void _persistRemarques() {
    widget.rapport.defauts = _defautControllers
        .map((c) => c.text)
        .where((text) => text.isNotEmpty)
        .toList();
  }

  // Génère le PDF initial
  Future<void> _generatePdfInitial() async {
    setState(() {
      _isGeneratingInitial = true;
    });

    try {
      final pdfPath = await generateRapportInitial(widget.rapport);
      
      setState(() {
        _generatedPdfInitialPath = pdfPath;
        _isGeneratingInitial = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport initial généré avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingInitial = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Génère le PDF final
  Future<void> _generatePdfFinal() async {
    setState(() {
      _isGeneratingFinal = true;
    });

    try {
      // Sauvegarder les remarques
      _persistRemarques();

      final pdfPath = await generateRapportFinal(widget.rapport);
      
      setState(() {
        _generatedPdfFinalPath = pdfPath;
        _isGeneratingFinal = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapport final généré avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingFinal = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Partage le PDF
  Future<void> _sharePdf(String path, String type) async {
    try {
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Rapport $type - ${widget.rapport.immatriculation}',
        text: 'Rapport de vérification pour ${widget.rapport.nomClient}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Partage les deux PDF ensemble
  Future<void> _shareBothPdfs() async {
    if (_generatedPdfInitialPath == null || _generatedPdfFinalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez générer les deux rapports avant de les partager ensemble'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await Share.shareXFiles(
        [
          XFile(_generatedPdfInitialPath!),
          XFile(_generatedPdfFinalPath!),
        ],
        subject: 'Rapports complets - ${widget.rapport.immatriculation}',
        text: 'Rapports de vérification initial et final pour ${widget.rapport.nomClient}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('4/4 - Finalisation'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Résumé ---
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Résumé', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Client : ${widget.rapport.nomClient}', style: const TextStyle(fontSize: 16)),
                    Text('Véhicule : ${widget.rapport.marqueModele}', style: const TextStyle(fontSize: 16)),
                    Text('Immatriculation : ${widget.rapport.immatriculation}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Section Remarques supplémentaires ---
            const Text('REMARQUES SUPPLÉMENTAIRES', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text(
              'Les observations saisies dans la checklist seront automatiquement reportées dans le rapport final. Ajoutez ici des remarques complémentaires si nécessaire.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ...List.generate(8, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _defautControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Remarque ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // --- Conclusions ---
            const Text('CONCLUSIONS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            CheckboxListTile(
              title: const Text('L\'appareil peut être utilisé par l\'opérateur'),
              value: widget.rapport.appareilUtilisable,
              onChanged: (value) {
                setState(() {
                  widget.rapport.appareilUtilisable = value ?? true;
                });
              },
            ),
            CheckboxListTile(
              title: const Text('Une contre-visite sera obligatoire'),
              value: widget.rapport.contreVisiteObligatoire,
              onChanged: (value) {
                setState(() {
                  widget.rapport.contreVisiteObligatoire = value ?? false;
                });
              },
            ),
            const Divider(height: 30),

            // --- Boutons de génération ---
            const Text('GÉNÉRATION DES RAPPORTS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Rapport Initial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rapport Initial', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Contient la checklist détaillée avec les statuts B/D/V/F/NEO'),
                    const SizedBox(height: 12),
                    if (_generatedPdfInitialPath == null && !_isGeneratingInitial)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generatePdfInitial,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Générer Rapport Initial'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (_isGeneratingInitial)
                      const Center(child: CircularProgressIndicator()),
                    if (_generatedPdfInitialPath != null && !_isGeneratingInitial) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Généré !', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePdf(_generatedPdfInitialPath!, 'Initial'),
                          icon: const Icon(Icons.share),
                          label: const Text('Partager'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Rapport Final
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rapport Final', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Contient toutes les informations détaillées et les conclusions'),
                    const SizedBox(height: 12),
                    if (_generatedPdfFinalPath == null && !_isGeneratingFinal)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _generatePdfFinal,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Générer Rapport Final'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (_isGeneratingFinal)
                      const Center(child: CircularProgressIndicator()),
                    if (_generatedPdfFinalPath != null && !_isGeneratingFinal) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Généré !', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _sharePdf(_generatedPdfFinalPath!, 'Final'),
                          icon: const Icon(Icons.share),
                          label: const Text('Partager'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Bouton pour partager les deux rapports ensemble
            if (_generatedPdfInitialPath != null && _generatedPdfFinalPath != null)
              Card(
                color: Colors.purple[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Partager les deux rapports',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Envoyer les rapports initial et final dans le même email'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _shareBothPdfs,
                          icon: const Icon(Icons.email),
                          label: const Text('Partager les deux rapports ensemble'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _persistRemarques();
    for (var controller in _defautControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}