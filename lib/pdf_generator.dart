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

  final customStyle = pw.TextStyle(fontSize: 11, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final titleStyle = boldStyle.copyWith(fontSize: 16, color: primaryColor);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(15),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            pw.Center(
              child: pw.Image(logoImage, width: 80, height: 50, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 8),
            
            // Titre
            pw.Center(
              child: pw.Text(
                'VÉRIFICATIONS RÈGLEMENTAIRES\nDES HAYON ÉLÉVATEURS\n(COMPTE RENDU INITIAL)',
                style: boldStyle.copyWith(fontSize: 12, color: primaryColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

            // Dates
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date : $dateActuelle', style: boldStyle.copyWith(fontSize: 9)),
                pw.Text('Prochaine vérification : $dateProchaine', style: boldStyle.copyWith(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 8),

            // Section légende
            pw.Text(
              'EXAMEN DE L\'ÉTAT DE CONSERVATION DE L\'APPAREIL',
              style: titleStyle.copyWith(fontSize: 10),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'B = Bon état | D = Défaut | V = Visuel | F = Fonctionnel | NEO = Non équipé d\'origine',
              style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 8),
            ),
            pw.Text(
              'N° = n° d\'observation à reporter sur la couverture',
              style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 8),
            ),
            pw.SizedBox(height: 8),

            // Tableau de la checklist
            pw.Expanded(
              child: _buildChecklistTableInitial(rapport, boldStyle, customStyle),
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

  final customStyle = pw.TextStyle(fontSize: 10, color: PdfColors.black, font: ttf);
  final boldStyle = customStyle.copyWith(fontWeight: pw.FontWeight.bold);
  final sectionStyle = boldStyle.copyWith(fontSize: 12);

  final dateFormatter = DateFormat('dd/MM/yyyy');
  final dateActuelle = dateFormatter.format(rapport.dateVerification);
  final dateProchaine = dateFormatter.format(rapport.dateProchainControle);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(12),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            pw.Center(
              child: pw.Image(logoImage, width: 70, height: 45, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(height: 5),
            
            // Titre
            pw.Center(
              child: pw.Text(
                'VÉRIFICATIONS RÈGLEMENTAIRES DES HAYON ÉLÉVATEURS (COMPTE RENDU FINAL)',
                style: boldStyle.copyWith(fontSize: 10, color: primaryColor),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 5),

            // Section Contrôleur et Client en 2 colonnes
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('LE CONTROLEUR', style: sectionStyle.copyWith(fontSize: 9)),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Société :', 'ACCESS VGP', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Nom :', 'RENAI KOUCEILA', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Mail :', 'vgpaccess@gmail.com', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Tél :', '06.19.60.31.72', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Date :', dateActuelle, boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CLIENT', style: sectionStyle.copyWith(fontSize: 9)),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Client :', rapport.nomClient, boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('N° rapport :', '${_numeroRapport++}', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Prochain :', dateProchaine, boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      pw.SizedBox(height: 5),
                      pw.Text('RESPONSABLE DE L\'APPAREIL', style: sectionStyle.copyWith(fontSize: 9)),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Nom :', rapport.nomResponsable ?? '', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                      _buildInfoRow('Société :', rapport.societeResponsable ?? '', boldStyle.copyWith(fontSize: 7), customStyle.copyWith(fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            // Types de vérification
            pw.Text('TYPE DE VÉRIFICATION', style: sectionStyle.copyWith(fontSize: 8)),
            pw.Divider(color: primaryColor, height: 2),
            if (rapport.typesVerification.contains(TypeVerification.miseEnService))
              pw.Text('☑ Mise en service (R4323-22)', style: customStyle.copyWith(fontSize: 7)),
            if (rapport.typesVerification.contains(TypeVerification.generalePeriodique))
              pw.Text('☑ VGP (R4323-23, 24, 25, 26, 27)', style: customStyle.copyWith(fontSize: 7)),
            if (rapport.typesVerification.contains(TypeVerification.remiseEnService))
              pw.Text('☑ Remise en service (R4323-28)', style: customStyle.copyWith(fontSize: 7)),
            pw.SizedBox(height: 4),

            // Documents obligatoires et Identification en 2 colonnes
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DOCUMENTS', style: sectionStyle.copyWith(fontSize: 8)),
                      pw.Divider(color: primaryColor, height: 2),
                      ...rapport.documentsObligatoires.map((doc) {
                        return pw.Text(
                          '${doc.fourni ? "☑" : "☐"} ${doc.titre}',
                          style: customStyle.copyWith(fontSize: 6),
                        );
                      }).toList(),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Articles R.4323-22 à R.4323-28',
                        style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 6),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('IDENTIFICATION', style: sectionStyle.copyWith(fontSize: 8)),
                      pw.Divider(color: primaryColor, height: 2),
                      _buildInfoRow('Marque :', rapport.marqueModele, boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('Modèle :', rapport.typeVehicule ?? '', boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('N° Série :', rapport.numeroSerie ?? '', boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('Immat :', rapport.immatriculation, boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('Charge :', rapport.chargeMaxiLevage ?? '', boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('Année :', rapport.anneeFabrication ?? '', boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                      _buildInfoRow('Km :', '${rapport.kilometrage} km', boldStyle.copyWith(fontSize: 6), customStyle.copyWith(fontSize: 6)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // Remarques
            pw.Text('REMARQUES', style: sectionStyle.copyWith(fontSize: 8)),
            pw.Divider(color: primaryColor, height: 2),
            pw.Text(
              'Défauts susceptibles d\'engendrer un danger :',
              style: customStyle.copyWith(fontSize: 7),
            ),
            ...List.generate(4, (index) {
              final defaut = index < rapport.defauts.length ? rapport.defauts[index] : '';
              return pw.Text('N° ${index + 1}: $defaut', style: customStyle.copyWith(fontSize: 6));
            }),
            pw.SizedBox(height: 4),

            // Rappel
            pw.Text(
              'Rappel : le chef d\'établissement de l\'appareil doit consigner le résultat des vérifications règlementaires, sur le registre de sécurité prévu à l\'article L.4711-5 du code du travail et tenir à jour le carnet de maintenance prévu aux articles R.4323-19.',
              style: customStyle.copyWith(fontStyle: pw.FontStyle.italic, fontSize: 6),
            ),
            pw.SizedBox(height: 4),

            // Conclusions
            pw.Text(
              '${rapport.appareilUtilisable ? "☑" : "☐"} L\'appareil peut être utilisé',
              style: boldStyle.copyWith(fontSize: 7),
            ),
            pw.Text(
              '${rapport.contreVisiteObligatoire ? "☑" : "☐"} Contre-visite obligatoire',
              style: boldStyle.copyWith(fontSize: 7),
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
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 1),
    child: pw.Row(
      children: [
        pw.Container(width: 60, child: pw.Text(label, style: boldStyle)),
        pw.Expanded(child: pw.Text(value, style: style)),
      ],
    ),
  );
}

pw.Widget _buildChecklistTableInitial(RapportVerification rapport, pw.TextStyle boldStyle, pw.TextStyle style) {
  final List<pw.TableRow> rows = [
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: primaryColor),
      children: [
        _buildTableCell('Item', boldStyle.copyWith(color: PdfColors.white)),
        _buildTableCell('B', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        _buildTableCell('D', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        _buildTableCell('V', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        _buildTableCell('F', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        _buildTableCell('NEO', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
        _buildTableCell('N°', boldStyle.copyWith(color: PdfColors.white), alignment: pw.Alignment.center),
      ],
    ),
  ];

  for (var item in rapport.checklist) {
    if (item.isCategory) {
      // Ligne de catégorie - créer 7 cellules mais fusionner visuellement
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(item.titre, style: boldStyle),
            ),
            pw.Container(), // Cellule vide
            pw.Container(), // Cellule vide
            pw.Container(), // Cellule vide
            pw.Container(), // Cellule vide
            pw.Container(), // Cellule vide
            pw.Container(), // Cellule vide
          ],
        ),
      );
    } else {
      // Ligne d'item
      rows.add(
        pw.TableRow(
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
        ),
      );
    }
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(4),
      1: pw.FlexColumnWidth(0.8),
      2: pw.FlexColumnWidth(0.8),
      3: pw.FlexColumnWidth(0.8),
      4: pw.FlexColumnWidth(0.8),
      5: pw.FlexColumnWidth(1),
      6: pw.FlexColumnWidth(1),
    },
    children: rows,
  );
}

pw.Widget _buildTableCell(String text, pw.TextStyle style, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(2),
    child: pw.Align(
      alignment: alignment,
      child: pw.Text(text, style: style.copyWith(fontSize: 7)),
    ),
  );
}