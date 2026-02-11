// Nouveaux statuts pour les colonnes de vérification
enum ColonneStatus {
  nonCoche,  // Rien n'est coché
  b,         // Bon état
  d,         // Défaut
  v,         // Visuel
  f,         // Fonctionnel
  neo,       // Non équipé d'origine
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
    }
  }
}

// Représente un seul point de vérification avec le nouveau système
class ChecklistItem {
  final String titre;
  final bool isCategory; // Pour différencier les catégories des items
  ColonneStatus status;
  String numeroObservation; // N° d'observation

  ChecklistItem({
    required this.titre,
    this.isCategory = false,
    this.status = ColonneStatus.nonCoche,
    this.numeroObservation = '',
  });
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
    // --- CONDITIONS PRÉALABLES A LA VÉRIFICATION ---
    ChecklistItem(titre: 'CONDITIONS PRÉALABLES A LA VÉRIFICATION', isCategory: true),
    ChecklistItem(titre: 'État de propreté de l\'appareil satisfaisant'),
    ChecklistItem(titre: 'Charge(s) d\'essai mise(s) à disposition (ou PESON)'),
    ChecklistItem(titre: 'Mise à disposition du personnel pour la conduite de l\'appareil'),
    ChecklistItem(titre: 'Zone sécurisée pour les essais'),
    
    // --- DOCUMENTS REGLEMENTAIRE A PRESENTER ---
    ChecklistItem(titre: 'DOCUMENTS REGLEMENTAIRE A PRESENTER', isCategory: true),
    ChecklistItem(titre: 'Certificat de conformité + épreuve de mise en service'),
    ChecklistItem(titre: 'Manuel d\'utilisation (Article R4323-1)'),
    ChecklistItem(titre: 'Rapport(s) de vérification précédent(s) (Article L4711-1)'),
    ChecklistItem(titre: 'Carnet de maintenance (Article R4323-19, 20)'),
    ChecklistItem(titre: 'Registre de sécurité (Article R4323-26, 27)'),
    
    // --- CHARPENTES/MECANISMES ---
    ChecklistItem(titre: 'CHARPENTES/MECANISMES', isCategory: true),
    ChecklistItem(titre: 'Oxydation'),
    ChecklistItem(titre: 'État soudures'),
    ChecklistItem(titre: 'Ossature déformée'),
    ChecklistItem(titre: 'Plateau déformé'),
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
    ChecklistItem(titre: 'Maintenance : 1 graissage 14 points'),
    
    // --- MOUVEMENTS ---
    ChecklistItem(titre: 'MOUVEMENTS', isCategory: true),
    ChecklistItem(titre: 'Montée'),
    ChecklistItem(titre: 'Descente'),
    ChecklistItem(titre: 'Ouverture'),
    ChecklistItem(titre: 'Fermeture'),
    ChecklistItem(titre: 'Sortie'),
    ChecklistItem(titre: 'Rentrée'),
    
    // --- EXAMENS ET ÉPREUVES ---
    ChecklistItem(titre: 'EXAMENS ET ÉPREUVES', isCategory: true),
    ChecklistItem(titre: 'Épreuve dynamique (C.M.U. + 10 % ou valeur constructeur; 15 mn recommandation VGP)'),
    ChecklistItem(titre: 'Charge d\'essai : 750 Kg à une distance mesurée de : 0.600 m'),
    ChecklistItem(titre: 'Est-ce que les dispositifs de limitation de la surcharge se sont déclenchés ?'),
    ChecklistItem(titre: 'Est-ce que les dispositifs de sécurité du maintien de la charge fonctionnent ?'),
  ];
}