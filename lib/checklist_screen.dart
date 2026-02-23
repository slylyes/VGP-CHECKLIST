import 'package:flutter/material.dart';
import 'models.dart';

// La ChecklistScreen avec le nouveau système de colonnes
class ChecklistScreen extends StatefulWidget {
  final RapportVerification rapport;

  const ChecklistScreen({super.key, required this.rapport});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<ChecklistItem> _currentChecklist;

  @override
  void initState() {
    super.initState();
    _currentChecklist = widget.rapport.checklist;
  }

  void _goToNextScreen() {
    widget.rapport.checklist = _currentChecklist;
    
    // Navigation vers l'écran 3 (verification_details_screen)
    Navigator.pushNamed(
      context,
      '/verification_details',
      arguments: widget.rapport,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2/4 - Checklist de Vérification'),
        backgroundColor: Colors.blueGrey,
        actions: [
          TextButton.icon(
            onPressed: _goToNextScreen,
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            label: const Text('Suivant', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec la légende des colonnes
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blueGrey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXAMEN DE L\'ÉTAT DE CONSERVATION DE L\'APPAREIL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pour Conditions Préalables : OUI / NON',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const Text(
                  'B = Bon état | D = Défaut | V = Visuel | F = Fonctionnel | NEO = Non équipé d\'origine',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const Text(
                  'N° = n° d\'observation à reporter sur la couverture',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          // Liste des items
          Expanded(
            child: ListView.builder(
              itemCount: _currentChecklist.length,
              itemBuilder: (context, index) {
                final item = _currentChecklist[index];
                return item.isCategory
                    ? _buildCategoryHeader(item)
                    : _buildChecklistItem(item, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(ChecklistItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue[700],
      child: Text(
        item.titre,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.titre,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            
            if (item.type == ChecklistType.ouiNon)
              // Rangée de boutons pour OUI / NON
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('OUI', ColonneStatus.oui, item),
                  _buildStatusChip('NON', ColonneStatus.non, item),
                ],
              )
            else
              // Rangée de boutons pour B, D, V, F, NEO
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip('B', ColonneStatus.b, item),
                  _buildStatusChip('D', ColonneStatus.d, item),
                  _buildStatusChip('V', ColonneStatus.v, item),
                  _buildStatusChip('F', ColonneStatus.f, item),
                  _buildStatusChip('NEO', ColonneStatus.neo, item),
                ],
              ),
            
            // Champ pour le numéro d'observation (uniquement pour les items standard)
            if (item.type != ChecklistType.ouiNon) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('N° : ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'N° observation',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          item.numeroObservation = value;
                        });
                      },
                      controller: TextEditingController(text: item.numeroObservation),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, ColonneStatus status, ChecklistItem item) {
    final isSelected = item.status == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          item.status = selected ? status : ColonneStatus.nonCoche;
        });
      },
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}