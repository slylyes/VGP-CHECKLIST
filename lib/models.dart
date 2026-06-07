// Nouveaux statuts pour les colonnes de vérification
enum ColonneStatus {
  nonCoche,  // Rien n'est coché
  b,         // Bon état
  d,         // Défaut
  v,         // Visuel
  f,         // Fonctionnel
  neo,       // Non équipé d'origine
  oui,       // OUI (pour Conditions Préalables)
  non,       // NON (pour Conditions Préalables)
}

extension ColonneStatusExtension on ColonneStatus {
  String get name {
    switch (this) {
      case ColonneStatus.nonCoche:
        return '-';
      case ColonneStatus.b:
        return 'B';
      case ColonneStatus.d:
        return 'D';
      case ColonneStatus.v:
        return 'V';
      case ColonneStatus.f:
        return 'F';
      case ColonneStatus.neo:
        return 'NEO';
      case ColonneStatus.oui:
        return 'OUI';
      case ColonneStatus.non:
        return 'NON';
    }
  }
}

// Type d'affichage de la checklist
enum ChecklistType {
  standard,              // B, D, V, F, NEO
  ouiNon,                // OUI, NON (sans N° observation)
  ouiNonAvecObservation, // OUI, NON (avec N° observation)
}

// Représente un seul point de vérification avec le nouveau système
class ChecklistItem {
  final String titre;
  final bool isCategory; // Pour différencier les catégories des items
  ColonneStatus status;
  Set<ColonneStatus> selectedStatuses; // Pour B/D/V/F/NEO en multi-sélection
  String numeroObservation; // N° d'observation
  final ChecklistType type; // Type de réponse attendue

  ChecklistItem({
    required this.titre,
    this.isCategory = false,
    this.status = ColonneStatus.nonCoche,
    Set<ColonneStatus>? selectedStatuses,
    this.numeroObservation = '',
    this.type = ChecklistType.standard,
  }) : selectedStatuses = selectedStatuses ?? <ColonneStatus>{};

  bool isChecked(ColonneStatus checkedStatus) {
    return selectedStatuses.contains(checkedStatus) || status == checkedStatus;
  }
}

// Types de vérification (pour l'écran 3)
enum TypeVerification {
  miseEnService,
  generalePeriodique,
  remiseEnService,
}

// Documents obligatoires avec réponse OUI/NON
class DocumentObligatoire {
  final String titre;
  bool fourni; // true = OUI, false = NON

  DocumentObligatoire({
    required this.titre,
    this.fourni = false,
  });
}

// Représente le rapport complet généré
class RapportVerification {
  // Informations Client & Véhicule
  String nomClient;
  String emailClient;
  String marqueModele;
  String immatriculation;
  int kilometrage;

  // Données de vérification
  DateTime dateVerification;
  List<ChecklistItem> checklist;
  String commentaireGeneral;
  
  // Types de vérification (écran 3)
  Set<TypeVerification> typesVerification;
  List<DocumentObligatoire> documentsObligatoires;
  
  // Informations supplémentaires pour le rapport final
  String? numeroSerie;
  String? typeVehicule;
  String? categorieVehicule;
  String? accessoires;
  String? chargeMaxiLevage;
  String? anneeFabrication;
  String? marquageCE;
  String? compteurHorametre;
  String? numeroParc;
  
  // Remarques et défauts
  List<String> defauts;
  bool appareilUtilisable;
  bool contreVisiteObligatoire;
  
  // Responsable de l'appareil
  String? nomResponsable;
  String? societeResponsable;

  RapportVerification({
    required this.nomClient,
    required this.emailClient,
    required this.marqueModele,
    required this.immatriculation,
    this.kilometrage = 0,
    required this.checklist,
    String? commentaireGeneral,
    Set<TypeVerification>? typesVerification,
    List<DocumentObligatoire>? documentsObligatoires,
    this.numeroSerie,
    this.typeVehicule,
    this.categorieVehicule,
    this.accessoires,
    this.chargeMaxiLevage,
    this.anneeFabrication,
    this.marquageCE,
    this.compteurHorametre,
    this.numeroParc,
    List<String>? defauts,
    this.appareilUtilisable = true,
    this.contreVisiteObligatoire = false,
    this.nomResponsable,
    this.societeResponsable,
  }) : dateVerification = DateTime.now(),
       commentaireGeneral = commentaireGeneral ?? '',
       typesVerification = typesVerification ?? {},
       documentsObligatoires = documentsObligatoires ?? _getDefaultDocuments(),
       defauts = defauts ?? [];

  // Calcule la date de la prochaine vérification (6 mois)
  DateTime get dateProchainControle {
    return DateTime(
      dateVerification.year,
      dateVerification.month + 6,
      dateVerification.day,
    );
  }
  
  static List<DocumentObligatoire> _getDefaultDocuments() {
    return [
      DocumentObligatoire(titre: 'Certificat de conformité + épreuve de mise en service'),
      DocumentObligatoire(titre: 'Manuel d\'utilisation (Article R4323-1)'),
      DocumentObligatoire(titre: 'Rapport(s) de vérification précédent(s) (Article L4711-1)'),
      DocumentObligatoire(titre: 'Carnet de maintenance (Article R4323-19, 20)'),
      DocumentObligatoire(titre: 'Registre de sécurité (Article R4323-26, 27)'),
    ];
  }
}

// Fonction pour générer une checklist de base pour un nouveau rapport
List<ChecklistItem> get defaultChecklist {
  return [
    // --- CONDITIONS PRÉALABLES A LA VÉRIFICATION (OUI/NON) ---
    ChecklistItem(titre: 'CONDITIONS PRÉALABLES A LA VÉRIFICATION', isCategory: true, type: ChecklistType.ouiNon),
    ChecklistItem(titre: 'État de propreté de l\'appareil satisfaisant', type: ChecklistType.ouiNon),
    ChecklistItem(titre: 'Charge(s) d\'essai mise(s) à disposition (ou PESON)', type: ChecklistType.ouiNon),
    ChecklistItem(titre: 'Mise à disposition du personnel pour la conduite de l\'appareil', type: ChecklistType.ouiNon),
    ChecklistItem(titre: 'Zone sécurisée pour les essais', type: ChecklistType.ouiNon),
    
    // --- DOCUMENTS REGLEMENTAIRE A PRESENTER ---
    ChecklistItem(titre: 'DOCUMENTS REGLEMENTAIRE A PRESENTER', isCategory: true),
    ChecklistItem(titre: 'Certificat de conformité + épreuve de mise en service', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Manuel d\'utilisation (Article R4323-1)', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Rapport(s) de vérification précédent(s) (Article L4711-1)', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Carnet de maintenance (Article R4323-19, 20)', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Registre de sécurité (Article R4323-26, 27)', type: ChecklistType.ouiNonAvecObservation),
    
    // --- OSSATURE ET PLATEAU (OUI/NON séparé) ---
    ChecklistItem(titre: 'OSSATURE ET PLATEAU', isCategory: true, type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Ossature déformée', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Plateau déformé', type: ChecklistType.ouiNonAvecObservation),
    
    // --- CHARPENTES/MECANISMES ---
    ChecklistItem(titre: 'CHARPENTES/MECANISMES', isCategory: true),
    ChecklistItem(titre: 'Oxydation'),
    ChecklistItem(titre: 'État soudures'),
    ChecklistItem(titre: 'État des flexibles'),
    ChecklistItem(titre: 'Fonctionnement'),
    ChecklistItem(titre: 'Signalisation de la plate-forme'),
    ChecklistItem(titre: 'Verrouillage route'),
    
    // --- POSTE DE COMMANDES PRINCIPALES ---
    ChecklistItem(titre: 'POSTE DE COMMANDES PRINCIPALES', isCategory: true),
    ChecklistItem(titre: 'Emplacement'),
    ChecklistItem(titre: 'Éclairage poste de commande'),
    ChecklistItem(titre: 'Consignes de sécurité'),
    ChecklistItem(titre: 'Coupe batterie'),
    ChecklistItem(titre: 'Fusible'),
    ChecklistItem(titre: 'Sélecteur int/ext (commande intérieure)'),
    ChecklistItem(titre: 'Sélecteur commande de deux mains'),
    ChecklistItem(titre: 'Commande privative'),
    
    // --- DISPOSITIFS SECURITE ---
    ChecklistItem(titre: 'DISPOSITIFS SECURITE', isCategory: true),
    ChecklistItem(titre: 'Protection contre les défaillances du circuit hydraulique'),
    ChecklistItem(titre: 'Limiteur de pression (limiteur de charge)'),
    ChecklistItem(titre: 'Régulateur de débit (vitesse de descente)'),
    ChecklistItem(titre: 'Maintien à l\'arrêt clapet de sécurité (électrovalve)'),
    ChecklistItem(titre: 'Blocage des charges roulantes'),
    
    // --- CHARPENTES/MECANISMES (2ème partie) ---
    ChecklistItem(titre: 'CHARPENTES/MECANISMES', isCategory: true),
    ChecklistItem(titre: 'Visibilité du gabarit du plateau de jour comme de nuit'),
    ChecklistItem(titre: 'Bandes rétroréfléchissantes'),
    ChecklistItem(titre: 'Drapeaux'),
    ChecklistItem(titre: 'Autres dispositifs de signalisation'),
    
    // --- PRESCRIPTIONS DIVERSES ---
    ChecklistItem(titre: 'PRESCRIPTIONS DIVERSES', isCategory: true),
    ChecklistItem(titre: 'Livret de sécurité'),
    ChecklistItem(titre: 'Abaque de charges (un à chaque poste de commande)'),
    ChecklistItem(titre: 'Consignes de sécurité avec dateur de contrôle Périodique'),
    ChecklistItem(titre: 'Vidange du groupe'),
    ChecklistItem(titre: 'Graissage'),
    
    // --- MOUVEMENTS ---
    ChecklistItem(titre: 'MOUVEMENTS', isCategory: true),
    ChecklistItem(titre: 'Montée'),
    ChecklistItem(titre: 'Descente'),
    ChecklistItem(titre: 'Ouverture'),
    ChecklistItem(titre: 'Fermeture'),
    ChecklistItem(titre: 'Sortie'),
    ChecklistItem(titre: 'Rentrée'),
    
    // --- EXAMENS ET ÉPREUVES (OUI/NON séparé) ---
    ChecklistItem(titre: 'EXAMENS ET ÉPREUVES', isCategory: true, type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Épreuve dynamique (C.M.U. + 10 % ou valeur constructeur; 15 mn recommandation VGP)', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Mise à disposition de charges d\'essai', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Est-ce que les dispositifs de limitation de la surcharge se sont déclenchés ?', type: ChecklistType.ouiNonAvecObservation),
    ChecklistItem(titre: 'Est-ce que les dispositifs de sécurité du maintien de la charge fonctionnent ?', type: ChecklistType.ouiNonAvecObservation),
  ];
}