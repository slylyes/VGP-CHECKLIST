import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

const PdfColor primaryColor = PdfColors.blue800;

// Compteur de rapport (à persister dans une vraie app)
int _numeroRapport = 1;

// --- FONCTION GÉNÉRATION RAPPORT INITIAL ---
Future<String> generateRapportInitial(RapportVerification rapport) async {
  final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  
  // Charger le logo
  final logoData = await rootBundle.load('assets/logo.png');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  
  final pdf = pw.Document();

  // Adjusted font size for better readability while maintaining single page
  final customStyle = pw.TextStyle(fontSize: 7.0, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final titleStyle = boldStyle.copyWith(fontSize: 10, color: primaryColor);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);

  // Séparation des items
  final conditionsItems = rapport.checklist.where((i) => i.type == ChecklistType.ouiNon).toList();
  final standardItems = rapport.checklist.where((i) => i.type == ChecklistType.standard).toList();

  // Group standard items by category for layout
  final List<List<ChecklistItem>> categories = [];
  List<ChecklistItem> currentCategory = [];

  for (var item in standardItems) {
    if (item.isCategory) {
      if (currentCategory.isNotEmpty) {
        categories.add(List.from(currentCategory));
      }
      currentCategory = [item];
    } else {
      currentCategory.add(item);
    }
  }
  if (currentCategory.isNotEmpty) {
    categories.add(List.from(currentCategory));
  }

  // Split categories into two columns to balance height
  // Strategy: Place roughly half the items in each column, but keep categories intact.
  // Based on defaultChecklist structure:
  // Col 1: Documents (5), Charpentes/Meca 1 (9), Poste (9), Securite (6) -> ~29 items
  // Col 2: Charpentes/Meca 2 (5), Prescriptions (6), Mouvements (7), Examens (4) -> ~22 items
  // This is a reasonable split. We can try to automate or hardcode based on index.

  List<List<ChecklistItem>> col1Categories = [];
  List<List<ChecklistItem>> col2Categories = [];

  // Simple distribution: First 4 categories in Col 1, rest in Col 2
  // Assuming standard order matches defaultChecklist
  if (categories.length >= 8) {
     col1Categories = categories.sublist(0, 4);
     col2Categories = categories.sublist(4);
  } else {
     // Fallback if structure is different: split evenly by count
     int mid = (categories.length / 2).ceil();
     col1Categories = categories.sublist(0, mid);
     col2Categories = categories.sublist(mid);
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10), // Standard margin
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo et Titre
            pw.Row(
              children: [
                 pw.Container(
                   width: 60,
                   height: 40,
                   child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                 ),
                 pw.SizedBox(width: 10),
                 pw.Expanded(
                   child: pw.Text(
                    'VÉRIFICATIONS RÈGLEMENTAIRES DES HAYON ÉLÉVATEURS\n(COMPTE RENDU INITIAL)',
                    style: boldStyle.copyWith(fontSize: 12, color: primaryColor),
                    textAlign: pw.TextAlign.center,
                  ),
                 ),
              ]
            ),
            pw.SizedBox(height: 5),

            // Infos Client et Dates
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Client : ${rapport.nomClient}', style: boldStyle.copyWith(fontSize: 9)),
                  pw.Text('Date : $dateActuelle', style: boldStyle.copyWith(fontSize: 9)),
                  pw.Text('Prochaine : $dateProchaine', style: boldStyle.copyWith(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(height: 5),

            // Tableau Conditions Préalables
            if (conditionsItems.isNotEmpty)
               _buildConditionsTable(conditionsItems, boldStyle, customStyle),

            pw.SizedBox(height: 5),

            // Section légende standard
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                 pw.Text(
                  'EXAMEN DE L\'ÉTAT DE CONSERVATION',
                  style: titleStyle.copyWith(fontSize: 10),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'B = Bon | D = Défaut | V = Visuel | F = Fonctionnel | NEO = Non équipé',
                      style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 6),
                    ),
                    pw.Text(
                      'N° = n° d\'observation à reporter',
                      style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 6),
                    ),
                  ]
                )
              ]
            ),
            pw.SizedBox(height: 5),

            // Deux colonnes pour le reste
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Colonne 1
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildTableHeader(boldStyle),
                        ...col1Categories.map((cat) => _buildCategoryTable(cat, boldStyle, customStyle)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 5),
                  // Colonne 2
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        _buildTableHeader(boldStyle),
                        ...col2Categories.map((cat) => _buildCategoryTable(cat, boldStyle, customStyle)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Sauvegarde
  Directory? directory;
  if (Platform.isAndroid) {
    directory = Directory('/storage/emulated/0/Download');
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  final fileName = 'rapport_initial_${rapport.immatriculation}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final path = '${directory.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(await pdf.save());

  return path;
}

// --- FONCTION GÉNÉRATION RAPPORT FINAL ---
Future<String> generateRapportFinal(RapportVerification rapport) async {
  final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  
  // Charger le logo
  final logoData = await rootBundle.load('assets/logo.png');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  
  final pdf = pw.Document();

  final customStyle = pw.TextStyle(fontSize: 8, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final sectionStyle = boldStyle.copyWith(fontSize: 9, color: primaryColor);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            pw.Center(
              child: pw.Image(logoImage, width: 50, height: 35, fit: pw.BoxFit.contain),
            ),
            
            // Titre
            pw.Center(
              child: pw.Text(
                'VÉRIFICATIONS RÈGLEMENTAIRES DES HAYON ÉLÉVATEURS (COMPTE RENDU FINAL)',
                style: boldStyle.copyWith(fontSize: 10, color: primaryColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 5),

            // Section Contrôleur et Client
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Colonne Contrôleur
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('LE CONTROLEUR', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Société :', 'ACCESS VGP', boldStyle, customStyle),
                      _buildInfoRow('Nom :', 'RENAI KOUCEILA', boldStyle, customStyle),
                      _buildInfoRow('Mail :', 'vgpaccess@gmail.com', boldStyle, customStyle),
                      _buildInfoRow('Tél :', '06.19.60.31.72', boldStyle, customStyle),
                      _buildInfoRow('Date :', dateActuelle, boldStyle, customStyle),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                // Colonne Client & Responsable
                pw.Expanded(
                  flex: 5,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Client :', rapport.nomClient, boldStyle, customStyle),
                      _buildInfoRow('N° rapport :', '${_numeroRapport++}', boldStyle, customStyle),
                      _buildInfoRow('Prochain :', dateProchaine, boldStyle, customStyle),

                      pw.SizedBox(height: 5),

                      pw.Text('RESPONSABLE DE L\'APPAREIL', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Nom :', rapport.nomResponsable ?? '', boldStyle, customStyle),
                      _buildInfoRow('Société :', rapport.societeResponsable ?? '', boldStyle, customStyle),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        height: 30,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Center(child: pw.Text("Signature", style: customStyle.copyWith(color: PdfColors.grey600, fontSize: 8))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            // Types de vérification
            pw.Text('TYPE DE VÉRIFICATION', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
            pw.Row(
              children: [
                pw.Text(
                  rapport.typesVerification.contains(TypeVerification.miseEnService) ? "[X]" : "[ ]",
                  style: boldStyle.copyWith(fontSize: 10),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(child: pw.Text('Vérification de mise en service (Article R4323-22)', style: customStyle.copyWith(fontSize: 7))),
              ]
            ),
             pw.Row(
              children: [
                pw.Text(
                  rapport.typesVerification.contains(TypeVerification.generalePeriodique) ? "[X]" : "[ ]",
                  style: boldStyle.copyWith(fontSize: 10),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(child: pw.Text('Vérification générale périodique (VGP)(Article R4323-23, 24, 25, 26, 27)', style: customStyle.copyWith(fontSize: 7))),
              ]
            ),
             pw.Row(
              children: [
                pw.Text(
                  rapport.typesVerification.contains(TypeVerification.remiseEnService) ? "[X]" : "[ ]",
                  style: boldStyle.copyWith(fontSize: 10),
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(child: pw.Text('Vérification de remise en service (Article R4323-28)', style: customStyle.copyWith(fontSize: 7))),
              ]
            ),

            pw.SizedBox(height: 5),

            // Texte légal
            pw.Container(
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryColor, width: 0.5)),
              child: pw.Text(
                "Selon les articles R.4323-22 à R.4323-28 du code du travail et arrêté du 1er mars 2004 relatif aux vérifications des appareils de levage.\nPossibilité d'imprimer l'arrêté sur www.vgp-online.fr\nRecommandations d'utilisation qui définissent les conditions d'obtention du certificat d'aptitude à la conduite en sécurité",
                style: customStyle.copyWith(fontSize: 5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 5),

            // Documents et Identification
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Documents
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DOCUMENTS', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      ...rapport.documentsObligatoires.map((doc) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                doc.fourni ? "[X]" : "[ ]",
                                style: boldStyle.copyWith(fontSize: 9),
                              ),
                              pw.SizedBox(width: 4),
                              pw.Expanded(
                                child: pw.Text(doc.titre, style: customStyle.copyWith(fontSize: 6)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                // Identification
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('IDENTIFICATION', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Marque :', rapport.marqueModele, boldStyle, customStyle),
                      _buildInfoRow('Modèle :', rapport.typeVehicule ?? '', boldStyle, customStyle), // Might need adjustment based on user needs, but Type is below
                      _buildInfoRow('Type :', rapport.typeVehicule ?? '', boldStyle, customStyle),
                      _buildInfoRow('Catégorie :', rapport.categorieVehicule ?? '', boldStyle, customStyle),
                      _buildInfoRow('N° Série :', rapport.numeroSerie ?? '', boldStyle, customStyle),
                      _buildInfoRow('Immat :', rapport.immatriculation, boldStyle, customStyle),
                      _buildInfoRow('Accessoires :', rapport.accessoires ?? '', boldStyle, customStyle),
                      _buildInfoRow('Charge :', rapport.chargeMaxiLevage ?? '', boldStyle, customStyle),
                      _buildInfoRow('Année :', rapport.anneeFabrication ?? '', boldStyle, customStyle),
                      _buildInfoRow('Marquage CE :', rapport.marquageCE ?? '', boldStyle, customStyle),
                      _buildInfoRow('Compteur :', rapport.compteurHorametre ?? '', boldStyle, customStyle),
                      _buildInfoRow('N° Parc :', rapport.numeroParc ?? '', boldStyle, customStyle),
                      _buildInfoRow('Km :', '${rapport.kilometrage} km', boldStyle, customStyle),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            // Remarques
            pw.Text('REMARQUES', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
            pw.Text(
              'Défauts susceptibles d\'engendrer un danger :',
              style: customStyle.copyWith(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            ...List.generate(4, (index) {
              final defaut = index < rapport.defauts.length ? rapport.defauts[index] : '';
              return pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                ),
                child: pw.Text('N° ${index + 1}: $defaut', style: customStyle.copyWith(fontSize: 6)),
              );
            }),
            pw.SizedBox(height: 5),

            // Conclusions
            pw.Text('CONCLUSIONS', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
             pw.Row(
               children: [
                 pw.Text(
                  rapport.appareilUtilisable ? "[X]" : "[ ]",
                  style: boldStyle.copyWith(fontSize: 9),
                ),
                pw.SizedBox(width: 5),
                pw.Text('L\'appareil peut être utilisé', style: customStyle.copyWith(fontSize: 7)),

                pw.SizedBox(width: 20),

                pw.Text(
                  rapport.contreVisiteObligatoire ? "[X]" : "[ ]",
                  style: boldStyle.copyWith(fontSize: 9),
                ),
                pw.SizedBox(width: 5),
                pw.Text('Contre-visite obligatoire', style: customStyle.copyWith(fontSize: 7)),
               ]
             ),

             pw.SizedBox(height: 5),
             pw.Text(
              'Rappel : le chef d\'établissement de l\'appareil doit consigner le résultat des vérifications règlementaires, sur le registre de sécurité prévu à l\'article L.4711-5 du code du travail et tenir à jour le carnet de maintenance prévu aux articles R.4323-19.',
              style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 5),
              textAlign: pw.TextAlign.justify
            ),
          ],
        );
      },
    ),
  );

  // Sauvegarde
  Directory? directory;
  if (Platform.isAndroid) {
    directory = Directory('/storage/emulated/0/Download');
  } else {
    directory = await getApplicationDocumentsDirectory();
  }

  final fileName = 'rapport_final_${rapport.immatriculation}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final path = '${directory.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(await pdf.save());

  return path;
}

// --- HELPERS ---

pw.Widget _buildInfoRow(String label, String value, pw.TextStyle boldStyle, pw.TextStyle style) {
  return pw.Row(
    children: [
      pw.Container(width: 45, child: pw.Text(label, style: boldStyle.copyWith(fontSize: 6))),
      pw.Expanded(child: pw.Text(value, style: style.copyWith(fontSize: 6), maxLines: 1, overflow: pw.TextOverflow.clip)),
    ],
  );
}

// Tableau spécifique pour les Conditions Préalables (OUI/NON)
pw.Widget _buildConditionsTable(List<ChecklistItem> items, pw.TextStyle boldStyle, pw.TextStyle style) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(5),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          _buildTableCell('CONDITIONS PRÉALABLES', boldStyle.copyWith(color: PdfColors.white)),
          _buildTableCell('OUI', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
          _buildTableCell('NON', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        ],
      ),
      ...items.where((i) => !i.isCategory).map((item) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
          ),
          children: [
            _buildTableCell(item.titre, style),
            _buildTableCell(item.status == ColonneStatus.oui ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.status == ColonneStatus.non ? 'X' : '', style, alignment: pw.Alignment.center),
          ],
        );
      }).toList(),
    ],
  );
}

// Construit un tableau pour une catégorie entière
pw.Widget _buildCategoryTable(List<ChecklistItem> items, pw.TextStyle boldStyle, pw.TextStyle style) {
  if (items.isEmpty) return pw.Container();

  // Le premier item devrait être le header de catégorie
  final header = items.first;
  final contentItems = items.skip(1).toList();

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(4), // Item
      1: pw.FlexColumnWidth(0.7), // B
      2: pw.FlexColumnWidth(0.7), // D
      3: pw.FlexColumnWidth(0.7), // V
      4: pw.FlexColumnWidth(0.7), // F
      5: pw.FlexColumnWidth(0.8), // NEO
      6: pw.FlexColumnWidth(0.8), // N°
    },
    children: [
      // Header de la catégorie
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Text(header.titre, style: boldStyle.copyWith(color: PdfColors.white, fontSize: 7)),
          ),
          // Colonnes vides pour le header de catégorie, ou on pourrait fusionner
          // Fusionner est compliqué avec pw.Table simple sans colspan facile, donc on laisse vide ou on met des placeholders
           pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(),
        ]
      ),
      // Header des colonnes (Optionnel : Répéter ou mettre une fois en haut de page ?)
      // Pour gagner de la place, on ne le répète pas à chaque catégorie si c'est clair.
      // Mais si on a des colonnes séparées, il faut peut-être le mettre ?
      // Le code original avait un header global. Ici, chaque catégorie est un tableau.
      // Ajoutons une ligne de header (B, D...) pour chaque catégorie pour la clarté ?
      // Non, ça prend trop de place. On va supposer que l'entête global suffit.
      // Mais comme on a 2 colonnes, il faut un entête pour CHAQUE colonne principale.

      // Items
      ...contentItems.map((item) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
          ),
          children: [
            _buildTableCell(item.titre, style),
            _buildTableCell(item.status == ColonneStatus.b ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.status == ColonneStatus.d ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.status == ColonneStatus.v ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.status == ColonneStatus.f ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.status == ColonneStatus.neo ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildTableCell(item.numeroObservation, style, alignment: pw.Alignment.center),
          ],
        );
      }).toList(),
    ],
  );
}

pw.Widget _buildTableCell(String text, pw.TextStyle style, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(1.5), // Slightly more padding
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(text, style: style.copyWith(fontSize: 7)),
    ),
  );
}

// Header pour les colonnes de checklist (B, D, V, F, NEO, N°)
pw.Widget _buildTableHeader(pw.TextStyle boldStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(4), // Item
      1: pw.FlexColumnWidth(0.7), // B
      2: pw.FlexColumnWidth(0.7), // D
      3: pw.FlexColumnWidth(0.7), // V
      4: pw.FlexColumnWidth(0.7), // F
      5: pw.FlexColumnWidth(0.8), // NEO
      6: pw.FlexColumnWidth(0.8), // N°
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildTableCell('Rubrique', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('B', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('D', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('V', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('F', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('NEO', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
          _buildTableCell('N°', boldStyle.copyWith(fontSize: 6), alignment: pw.Alignment.center),
        ],
      ),
    ],
  );
}