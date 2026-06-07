import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const PdfColor primaryColor = PdfColors.blue800;

// Clés pour persister le numéro de rapport (par jour)
const String _rapportCounterDateKey = 'numero_rapport_date_key';
const String _rapportCounterIndexKey = 'numero_rapport_index_key';

String _lettersFromIndex(int index) {
  var value = index;
  var letters = '';
  do {
    letters = String.fromCharCode(65 + (value % 26)) + letters;
    value = (value ~/ 26) - 1;
  } while (value >= 0);
  return letters;
}

Future<String> _getNextNumeroRapport() async {
  final prefs = await SharedPreferences.getInstance();
  final todayKey = DateFormat('ddMMyy').format(DateTime.now());
  final savedDateKey = prefs.getString(_rapportCounterDateKey);

  int index;
  if (savedDateKey == todayKey) {
    final currentIndex = prefs.getInt(_rapportCounterIndexKey) ?? -1;
    index = currentIndex + 1;
  } else {
    index = 0;
  }

  await prefs.setString(_rapportCounterDateKey, todayKey);
  await prefs.setInt(_rapportCounterIndexKey, index);

  return '$todayKey${_lettersFromIndex(index)}';
}

// --- FONCTION GÉNÉRATION RAPPORT INITIAL ---
Future<String> generateRapportInitial(RapportVerification rapport) async {
  final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
  final ttf = pw.Font.ttf(fontData);
  
  // Charger le logo
  final logoData = await rootBundle.load('assets/logo.png');
  final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
  
  final pdf = pw.Document();

  // Balanced font sizes: single-column layout fitting one page
  final customStyle = pw.TextStyle(fontSize: 6.5, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final titleStyle = boldStyle.copyWith(fontSize: 9, color: primaryColor);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);
  final clientUpper = rapport.nomClient.toUpperCase();

  // --- Auto-numérotation des observations ---
  final Map<ChecklistItem, int> observationNumbers = {};
  int obsCounter = 1;
  for (var item in rapport.checklist) {
    if (!item.isCategory && item.numeroObservation.isNotEmpty) {
      observationNumbers[item] = obsCounter;
      obsCounter++;
    }
  }

  // Séparation des items par type de rendu
  final conditionsItems = rapport.checklist.where((i) => i.type == ChecklistType.ouiNon).toList();
  final allOtherItems = rapport.checklist.where((i) => i.type != ChecklistType.ouiNon).toList();

  // Grouper par catégorie
  final List<List<ChecklistItem>> allCategories = [];
  List<ChecklistItem> currentCategory = [];
  for (var item in allOtherItems) {
    if (item.isCategory) {
      if (currentCategory.isNotEmpty) allCategories.add(List.from(currentCategory));
      currentCategory = [item];
    } else {
      currentCategory.add(item);
    }
  }
  if (currentCategory.isNotEmpty) allCategories.add(List.from(currentCategory));

  // Séparer les catégories spéciales (OUI/NON séparées) des catégories standard (7 colonnes)
  final documentsCategories = allCategories.where((cat) => cat.first.titre == 'DOCUMENTS REGLEMENTAIRE A PRESENTER').toList();
  final examensCategories = allCategories.where((cat) => cat.first.titre == 'EXAMENS ET ÉPREUVES').toList();
  final ossatureCategories = allCategories.where((cat) => cat.first.titre == 'OSSATURE ET PLATEAU').toList();
  final standardCategories = allCategories.where((cat) =>
    cat.first.titre != 'DOCUMENTS REGLEMENTAIRE A PRESENTER' &&
    cat.first.titre != 'EXAMENS ET ÉPREUVES' &&
    cat.first.titre != 'OSSATURE ET PLATEAU'
  ).toList();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      build: (pw.Context context) {
        return pw.Center(
          child: pw.SizedBox(
            width: 520,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
            // Logo + titre centré
            pw.Center(
              child: pw.Container(
                width: 140,
                height: 95,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'VÉRIFICATIONS RÈGLEMENTAIRES DES HAYON ÉLÉVATEURS (COMPTE RENDU INITIAL)',
                style: boldStyle.copyWith(fontSize: 10, color: primaryColor),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
              ),
            ),
            pw.SizedBox(height: 4),

            // Infos Client et Dates
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Client : $clientUpper', style: boldStyle.copyWith(fontSize: 8)),
                  pw.Text('Date : $dateActuelle', style: boldStyle.copyWith(fontSize: 8)),
                  pw.Text('Prochaine date de contrôle : $dateProchaine', style: boldStyle.copyWith(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            // DOCUMENTS REGLEMENTAIRE A PRESENTER (OUI/NON) - en premier
            if (documentsCategories.isNotEmpty)
              _wrapInitialTable(_buildDocumentsOuiNonTableCompact(documentsCategories.first, boldStyle, customStyle)),

            pw.SizedBox(height: 4),

            // Section légende standard
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    'EXAMEN DE L\'ÉTAT DE CONSERVATION',
                    style: titleStyle,
                  ),
                ),
                pw.Expanded(
                  flex: 5,
                  child: pw.Text(
                    'B = Bon | D = Défaut | V = Visuel | F = Fonctionnel | NEO = Non équipé | N° = n° obs.',
                    style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 5.5),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ]
            ),
            pw.SizedBox(height: 3),

            // Tableau Conditions Préalables (juste sous le titre)
            if (conditionsItems.isNotEmpty)
              _wrapInitialTable(_buildConditionsTableCompact(conditionsItems, boldStyle, customStyle)),

            pw.SizedBox(height: 4),

            // Tableau OSSATURE ET PLATEAU (juste sous Conditions)
            if (ossatureCategories.isNotEmpty)
              _wrapInitialTable(_buildOuiNonSeparateTableCompact(
                ossatureCategories.first, boldStyle, customStyle, observationNumbers)),

            pw.SizedBox(height: 4),

            // Tableau standard en une seule colonne (7 colonnes)
            _wrapInitialTable(_buildTableHeaderCompact(boldStyle)),
            ...standardCategories.map((cat) => _wrapInitialTable(_buildCategoryTableCompact(cat, boldStyle, customStyle, observationNumbers))),

            pw.SizedBox(height: 4),

            // Tableau EXAMENS ET ÉPREUVES (OUI/NON séparé)
            if (examensCategories.isNotEmpty)
              _wrapInitialTable(_buildOuiNonSeparateTableCompact(
                examensCategories.first, boldStyle, customStyle, observationNumbers)),
              ],
            ),
          ),
        );
      },
    ),
  );

  // Sauvegarde dans le répertoire temporaire de l'app (compatible Android 11+)
  final directory = await getTemporaryDirectory();

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

  final customStyle = pw.TextStyle(fontSize: 9, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final sectionStyle = boldStyle.copyWith(fontSize: 11, color: primaryColor);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);
  final finalClientUpper = rapport.nomClient.toUpperCase();
  final finalNomResponsableUpper = (rapport.nomResponsable ?? '').toUpperCase();
  final finalSocieteResponsableUpper = (rapport.societeResponsable ?? '').toUpperCase();
  final finalMarqueModeleUpper = rapport.marqueModele.toUpperCase();
  final finalTypeVehiculeUpper = (rapport.typeVehicule ?? '').toUpperCase();
  final finalCategorieUpper = (rapport.categorieVehicule ?? '').toUpperCase();
  final finalNumeroSerieUpper = (rapport.numeroSerie ?? '').toUpperCase();
  final finalImmatUpper = rapport.immatriculation.toUpperCase();
  final finalAccessoiresUpper = (rapport.accessoires ?? '').toUpperCase();
  final finalChargeMaxUpper = (rapport.chargeMaxiLevage ?? '').toUpperCase();
  final finalAnneeFabUpper = (rapport.anneeFabrication ?? '').toUpperCase();
  final finalMarquageCEUpper = (rapport.marquageCE ?? '').toUpperCase();
  final finalCompteurUpper = (rapport.compteurHorametre ?? '').toUpperCase();
  final finalNumeroParcUpper = (rapport.numeroParc ?? '').toUpperCase();
  final finalKilometrageUpper = '${rapport.kilometrage} km'.toUpperCase();

  final numeroRapport = await _getNextNumeroRapport();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            pw.Center(
              child: pw.Image(logoImage, width: 110, height: 78, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 3),
            
            // Titre
            pw.Center(
              child: pw.Text(
                'VÉRIFICATIONS RÈGLEMENTAIRES DES HAYON ÉLÉVATEURS (COMPTE RENDU FINAL)',
                style: boldStyle.copyWith(fontSize: 12, color: primaryColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

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
                      _buildInfoRowFinal('Société :', 'ACCESS VGP', boldStyle, customStyle),
                      _buildInfoRowFinal('Nom :', 'RENAI KOCEILA', boldStyle, customStyle),
                      _buildInfoRowFinal('Mail :', 'vgpaccess@gmail.com', boldStyle, customStyle),
                      _buildInfoRowFinal('Tél :', '06.19.60.31.72', boldStyle, customStyle),
                      _buildInfoRowFinal('Date :', dateActuelle, boldStyle, customStyle),
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
                      _buildInfoRowFinal('Client :', finalClientUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('N° rapport :', '$numeroRapport', boldStyle, customStyle),
                      _buildInfoRowFinal('Prochaine vérification :', dateProchaine, boldStyle, customStyle),

                      pw.SizedBox(height: 8),

                      pw.Text('RESPONSABLE DE L\'APPAREIL', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRowFinal('Nom :', finalNomResponsableUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Société :', finalSocieteResponsableUpper, boldStyle, customStyle),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        height: 35,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
                        child: pw.Center(child: pw.Text("Signature", style: customStyle.copyWith(color: PdfColors.grey600, fontSize: 9))),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Types de vérification
            pw.Text('TYPE DE VÉRIFICATION', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                _buildCheckBoxPdf(rapport.typesVerification.contains(TypeVerification.miseEnService), customStyle),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text('Vérification de mise en service (Article R4323-22)', style: customStyle.copyWith(fontSize: 8))),
              ]
            ),
            pw.SizedBox(height: 2),
             pw.Row(
              children: [
                _buildCheckBoxPdf(rapport.typesVerification.contains(TypeVerification.generalePeriodique), customStyle),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text('Vérification générale périodique (VGP)(Article R4323-23, 24, 25, 26, 27)', style: customStyle.copyWith(fontSize: 8))),
              ]
            ),
            pw.SizedBox(height: 2),
             pw.Row(
              children: [
                _buildCheckBoxPdf(rapport.typesVerification.contains(TypeVerification.remiseEnService), customStyle),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text('Vérification de remise en service (Article R4323-28)', style: customStyle.copyWith(fontSize: 8))),
              ]
            ),

            pw.SizedBox(height: 6),

            // Texte légal
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: primaryColor, width: 0.5)),
              child: pw.Text(
                "Selon les articles R.4323-22 à R.4323-28 du code du travail et arrêté du 1er mars 2004 relatif aux vérifications des appareils de levage.\nPossibilité d'imprimer l'arrêté sur www.vgp-online.fr\nRecommandations d'utilisation qui définissent les conditions d'obtention du certificat d'aptitude à la conduite en sécurité",
                style: customStyle.copyWith(fontSize: 6),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

            // Documents et Identification
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Documents
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DOCUMENTS OBLIGATOIRES REMPLIS ET FOURNIS', style: sectionStyle),
                      pw.Divider(color: primaryColor, height: 2),
                      ...rapport.documentsObligatoires.map((doc) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildCheckBoxPdf(doc.fourni, customStyle),
                              pw.SizedBox(width: 5),
                              pw.Expanded(
                                child: pw.Text(doc.titre, style: customStyle.copyWith(fontSize: 7.5)),
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
                      _buildInfoRowFinal('Marque et Modèle :', finalMarqueModeleUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Type :', finalTypeVehiculeUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Catégorie :', finalCategorieUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('N° Série :', finalNumeroSerieUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('N° Immatriculation :', finalImmatUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Accessoires :', finalAccessoiresUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Charge max de levage :', finalChargeMaxUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Année de fabrication :', finalAnneeFabUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Marquage CE :', finalMarquageCEUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Compteur Horamètre :', finalCompteurUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('N° Parc :', finalNumeroParcUpper, boldStyle, customStyle),
                      _buildInfoRowFinal('Kilométrage :', finalKilometrageUpper, boldStyle, customStyle),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Remarques - observations auto-collectées + remarques supplémentaires
            pw.Text('REMARQUES', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
            pw.SizedBox(height: 2),
            pw.Text(
              'Observations issues de la vérification :',
              style: customStyle.copyWith(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            // Auto-collected observations from checklist items
            ..._buildObservationsFromChecklist(rapport, customStyle),
            // Manual additional remarks
            if (rapport.defauts.where((d) => d.isNotEmpty).isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Remarques supplémentaires :',
                style: customStyle.copyWith(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              ...rapport.defauts.where((d) => d.isNotEmpty).map((defaut) {
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
                  ),
                  child: pw.Text('• $defaut', style: customStyle.copyWith(fontSize: 7.5)),
                );
              }),
            ],
            pw.SizedBox(height: 8),

            // Conclusions
            pw.Text('CONCLUSIONS', style: sectionStyle),
            pw.Divider(color: primaryColor, height: 2),
            pw.SizedBox(height: 3),
             pw.Row(
               children: [
                 _buildCheckBoxPdf(rapport.appareilUtilisable, customStyle),
                pw.SizedBox(width: 6),
                pw.Text('L\'appareil peut être utilisé par l\'opérateur', style: customStyle.copyWith(fontSize: 8.5)),

                pw.SizedBox(width: 25),

                _buildCheckBoxPdf(rapport.contreVisiteObligatoire, customStyle),
                pw.SizedBox(width: 6),
                pw.Text('Contre-visite obligatoire', style: customStyle.copyWith(fontSize: 8.5)),
               ]
             ),

             pw.SizedBox(height: 8),
             pw.Text(
              'Rappel : le chef d\'établissement de l\'appareil doit consigner le résultat des vérifications règlementaires, sur le registre de sécurité prévu à l\'article L.4711-5 du code du travail et tenir à jour le carnet de maintenance prévu aux articles R.4323-19.',
              style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 6.5),
              textAlign: pw.TextAlign.justify
            ),
          ],
        );
      },
    ),
  );

  // Sauvegarde dans le répertoire temporaire de l'app (compatible Android 11+)
  final directory = await getTemporaryDirectory();

  final fileName = 'rapport_final_${rapport.immatriculation}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final path = '${directory.path}/$fileName';
  final file = File(path);
  await file.writeAsBytes(await pdf.save());

  return path;
}

// --- HELPERS ---

pw.Widget _buildCheckBoxPdf(bool checked, pw.TextStyle style) {
  return pw.Container(
    width: 12,
    height: 12,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: primaryColor, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
      color: PdfColors.white,
    ),
    child: checked
        ? pw.Center(
            child: pw.Text(
              'X',
              style: style.copyWith(
                color: primaryColor,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          )
        : pw.Container(),
  );
}

// Auto-collect observations from checklist items for the final report REMARQUES
List<pw.Widget> _buildObservationsFromChecklist(RapportVerification rapport, pw.TextStyle style) {
  final widgets = <pw.Widget>[];
  int obsNum = 1;
  for (var item in rapport.checklist) {
    if (!item.isCategory && item.numeroObservation.isNotEmpty) {
      widgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Text(
            'N° $obsNum - ${item.titre} : ${item.numeroObservation}',
            style: style.copyWith(fontSize: 7.5),
          ),
        ),
      );
      obsNum++;
    }
  }
  if (widgets.isEmpty) {
    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Text('Aucune observation.', style: style.copyWith(fontSize: 7.5, fontStyle: pw.FontStyle.italic)),
      ),
    );
  }
  return widgets;
}

pw.Widget _buildInfoRowFinal(String label, String value, pw.TextStyle boldStyle, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      children: [
        pw.Container(width: 100, child: pw.Text(label, style: boldStyle.copyWith(fontSize: 8))),
        pw.Expanded(child: pw.Text(value, style: style.copyWith(fontSize: 8), maxLines: 1, overflow: pw.TextOverflow.clip)),
      ],
    ),
  );
}

// --- COMPACT HELPERS FOR INITIAL REPORT (single column, one page) ---

pw.Widget _wrapInitialTable(pw.Widget child) {
  return child;
}

pw.Widget _buildCompactCell(String text, pw.TextStyle style, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(text, style: style.copyWith(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
    ),
  );
}

pw.Widget _buildConditionsTableCompact(List<ChecklistItem> items, pw.TextStyle boldStyle, pw.TextStyle style) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(6),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          _buildCompactCell('CONDITIONS PRÉALABLES À LA VÉRIFICATION', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5)),
          _buildCompactCell('OUI', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('NON', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
        ],
      ),
      ...items.where((i) => !i.isCategory).map((item) {
        return pw.TableRow(
          children: [
            _buildCompactCell(item.titre, style),
            _buildCompactCell(item.status == ColonneStatus.oui ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.status == ColonneStatus.non ? 'X' : '', style, alignment: pw.Alignment.center),
          ],
        );
      }),
    ],
  );
}

pw.Widget _buildDocumentsOuiNonTableCompact(List<ChecklistItem> items, pw.TextStyle boldStyle, pw.TextStyle style) {
  if (items.isEmpty) return pw.Container();

  final header = items.first;
  final contentItems = items.skip(1).toList();

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(6),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          _buildCompactCell(header.titre, boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5)),
          _buildCompactCell('OUI', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('NON', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
        ],
      ),
      ...contentItems.map((item) {
        return pw.TableRow(
          children: [
            _buildCompactCell(item.titre, style),
            _buildCompactCell(item.status == ColonneStatus.oui ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.status == ColonneStatus.non ? 'X' : '', style, alignment: pw.Alignment.center),
          ],
        );
      }),
    ],
  );
}

// Table OUI/NON séparée pour OSSATURE ET PLATEAU et EXAMENS ET ÉPREUVES
pw.Widget _buildOuiNonSeparateTableCompact(
  List<ChecklistItem> items,
  pw.TextStyle boldStyle,
  pw.TextStyle style,
  Map<ChecklistItem, int> observationNumbers,
) {
  if (items.isEmpty) return pw.Container();

  final header = items.first;
  final contentItems = items.skip(1).toList();

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(6),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(1),
      3: pw.FlexColumnWidth(0.7),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          _buildCompactCell(header.titre, boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5)),
          _buildCompactCell('OUI', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('NON', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('N°', boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5), alignment: pw.Alignment.center),
        ],
      ),
      ...contentItems.map((item) {
        return pw.TableRow(
          children: [
            _buildCompactCell(item.titre, style),
            _buildCompactCell(item.status == ColonneStatus.oui ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.status == ColonneStatus.non ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(observationNumbers[item]?.toString() ?? '', style, alignment: pw.Alignment.center),
          ],
        );
      }),
    ],
  );
}

pw.Widget _buildTableHeaderCompact(pw.TextStyle boldStyle) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(5),
      1: pw.FlexColumnWidth(0.6),
      2: pw.FlexColumnWidth(0.6),
      3: pw.FlexColumnWidth(0.6),
      4: pw.FlexColumnWidth(0.6),
      5: pw.FlexColumnWidth(0.7),
      6: pw.FlexColumnWidth(0.7),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _buildCompactCell('Rubrique', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('B', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('D', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('V', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('F', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('NEO', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
          _buildCompactCell('N°', boldStyle.copyWith(fontSize: 6.5), alignment: pw.Alignment.center),
        ],
      ),
    ],
  );
}

pw.Widget _buildCategoryTableCompact(List<ChecklistItem> items, pw.TextStyle boldStyle, pw.TextStyle style, Map<ChecklistItem, int> observationNumbers) {
  if (items.isEmpty) return pw.Container();

  final header = items.first;
  final contentItems = items.skip(1).toList();

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(5),
      1: pw.FlexColumnWidth(0.6),
      2: pw.FlexColumnWidth(0.6),
      3: pw.FlexColumnWidth(0.6),
      4: pw.FlexColumnWidth(0.6),
      5: pw.FlexColumnWidth(0.7),
      6: pw.FlexColumnWidth(0.7),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: primaryColor),
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: pw.Text(header.titre, style: boldStyle.copyWith(color: PdfColors.white, fontSize: 6.5)),
          ),
          pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(), pw.Container(),
        ]
      ),
      ...contentItems.map((item) {
        if (item.type == ChecklistType.ouiNonAvecObservation) {
          return pw.TableRow(
            children: [
              _buildCompactCell(item.titre, style),
              _buildCompactCell(item.status == ColonneStatus.oui ? 'OUI' : '', style, alignment: pw.Alignment.center),
              _buildCompactCell(item.status == ColonneStatus.non ? 'NON' : '', style, alignment: pw.Alignment.center),
              _buildCompactCell('', style, alignment: pw.Alignment.center),
              _buildCompactCell('', style, alignment: pw.Alignment.center),
              _buildCompactCell('', style, alignment: pw.Alignment.center),
              _buildCompactCell(observationNumbers[item]?.toString() ?? '', style, alignment: pw.Alignment.center),
            ],
          );
        }
        return pw.TableRow(
          children: [
            _buildCompactCell(item.titre, style),
            _buildCompactCell(item.isChecked(ColonneStatus.b) ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.isChecked(ColonneStatus.d) ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.isChecked(ColonneStatus.v) ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.isChecked(ColonneStatus.f) ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(item.isChecked(ColonneStatus.neo) ? 'X' : '', style, alignment: pw.Alignment.center),
            _buildCompactCell(observationNumbers[item]?.toString() ?? '', style, alignment: pw.Alignment.center),
          ],
        );
      }),
    ],
  );
}