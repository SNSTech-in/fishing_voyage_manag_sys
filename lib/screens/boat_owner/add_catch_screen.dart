// screens/boat_owner/add_catch_screen.dart

import 'package:flutter/material.dart';

import '../../services/api_services/api_service.dart';

class AddCatchScreen extends StatefulWidget {
  final int voyageId;

  const AddCatchScreen({
    super.key,
    required this.voyageId,
  });

  @override
  State<AddCatchScreen> createState() => _AddCatchScreenState();
}

class _AddCatchScreenState extends State<AddCatchScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> fishSpecies = [];
  List<Map<String, dynamic>> selectedItems = [];

  bool isLoading = false;
  bool isPageLoading = true;

  // TextEditingControllers for each item
  List<TextEditingController> weightControllers = [];
  List<TextEditingController> quantityControllers = [];
  List<TextEditingController> remarksControllers = [];

  @override
  void initState() {
    super.initState();
    _loadFishSpecies();
    // Add one empty item by default
    _addNewItem();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in weightControllers) {
      controller.dispose();
    }
    for (var controller in quantityControllers) {
      controller.dispose();
    }
    for (var controller in remarksControllers) {
      controller.dispose();
    }
    _apiService.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD FISH SPECIES
  // ============================================================

  Future<void> _loadFishSpecies() async {
    setState(() {
      isPageLoading = true;
    });

    try {
      final response = await _apiService.getFishSpecies();
      if (response['success'] == true) {
        final data = response['data'];
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() {
            fishSpecies = List<Map<String, dynamic>>.from(items);
          });
          print('✅ Loaded ${fishSpecies.length} fish species');
        }
      }
    } catch (e) {
      print('❌ Error loading fish species: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading fish species: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPageLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ADD NEW ITEM
  // ============================================================

  void _addNewItem() {
    // Create new controllers
    weightControllers.add(TextEditingController());
    quantityControllers.add(TextEditingController());
    remarksControllers.add(TextEditingController());

    setState(() {
      selectedItems.add({
        'species_id': null,
        'species_name': null,
        'weight_kg': null,
        'quantity_count': null,
        'remarks': '',
      });
    });
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void _removeItem(int index) {
    // Dispose controllers
    weightControllers[index].dispose();
    quantityControllers[index].dispose();
    remarksControllers[index].dispose();

    weightControllers.removeAt(index);
    quantityControllers.removeAt(index);
    remarksControllers.removeAt(index);

    setState(() {
      selectedItems.removeAt(index);
    });
  }

  // ============================================================
  // UPDATE ITEM FIELD
  // ============================================================

  void _updateItemField(int index, String field, dynamic value) {
    setState(() {
      selectedItems[index][field] = value;
    });
  }

  // ============================================================
  // GET SPECIES NAME BY ID
  // ============================================================

  String _getSpeciesName(int? speciesId) {
    if (speciesId == null) return 'Select species';
    final species = fishSpecies.firstWhere(
          (s) => s['species_id'] == speciesId,
      orElse: () => {},
    );
    return species['fish_name']?.toString() ?? 'Unknown';
  }

  // ============================================================
  // CHECK IF SPECIES IS ALREADY SELECTED
  // ============================================================

  bool _isSpeciesSelected(int speciesId, int currentIndex) {
    for (int i = 0; i < selectedItems.length; i++) {
      if (i != currentIndex && selectedItems[i]['species_id'] == speciesId) {
        return true;
      }
    }
    return false;
  }

  // ============================================================
  // SHOW SEARCHABLE SPECIES DIALOG - FIXED OVERFLOW
  // ============================================================

  Future<void> _showSpeciesSearchDialog(int index) async {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredSpecies = List.from(fishSpecies);

    // Get already selected species IDs
    Set<int> selectedIds = {};
    for (int i = 0; i < selectedItems.length; i++) {
      if (i != index && selectedItems[i]['species_id'] != null) {
        selectedIds.add(selectedItems[i]['species_id'] as int);
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  const Icon(
                    Icons.set_meal_rounded,
                    color: Color(0xFF1257C7),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Select Fish Species',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF07347F),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        autofocus: true,
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value.toLowerCase();
                            filteredSpecies = fishSpecies.where((species) {
                              final name = species['fish_name']?.toString().toLowerCase() ?? '';
                              return name.contains(searchQuery);
                            }).toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search fish species...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF1257C7)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Species List - Fixed with Flexible
                    Flexible(
                      child: filteredSpecies.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No species found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                          : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                          minHeight: 100,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredSpecies.length,
                          itemBuilder: (context, idx) {
                            final species = filteredSpecies[idx];
                            final speciesId = species['species_id'] as int;
                            final fishName = species['fish_name']?.toString() ?? '';
                            final isBanned = species['is_banned'] == true;
                            final isAlreadySelected = selectedIds.contains(speciesId);

                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isBanned
                                      ? Colors.red.withOpacity(0.1)
                                      : const Color(0xFFF4F8FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isBanned ? Icons.block_rounded : Icons.set_meal_rounded,
                                  color: isBanned ? Colors.red : const Color(0xFF1257C7),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                fishName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isBanned ? Colors.red : const Color(0xFF07347F),
                                ),
                              ),
                              subtitle: isBanned
                                  ? const Text(
                                'BANNED',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                                  : null,
                              trailing: isAlreadySelected
                                  ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Added',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                                  : null,
                              enabled: !isAlreadySelected,
                              onTap: isAlreadySelected
                                  ? null
                                  : () {
                                _updateItemField(index, 'species_id', speciesId);
                                _updateItemField(
                                    index, 'species_name', fishName);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VALIDATE AND SUBMIT
  // ============================================================

  Future<void> _submitCatch() async {
    // Update all fields from controllers
    for (int i = 0; i < selectedItems.length; i++) {
      final weight = double.tryParse(weightControllers[i].text);
      final quantity = int.tryParse(quantityControllers[i].text);
      final remarks = remarksControllers[i].text;

      selectedItems[i]['weight_kg'] = weight;
      selectedItems[i]['quantity_count'] = quantity;
      selectedItems[i]['remarks'] = remarks;
    }

    // Validate all items
    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      if (item['species_id'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select species for item ${i + 1}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (item['weight_kg'] == null || item['weight_kg'] <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter valid weight for item ${i + 1}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one fish catch item.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Build items list for API
      List<Map<String, dynamic>> items = [];
      for (var item in selectedItems) {
        final Map<String, dynamic> apiItem = {
          'species_id': item['species_id'],
          'weight_kg': item['weight_kg'],
        };
        if (item['quantity_count'] != null && item['quantity_count'] > 0) {
          apiItem['quantity_count'] = item['quantity_count'];
        }
        if (item['remarks'] != null && item['remarks'].toString().isNotEmpty) {
          apiItem['remarks'] = item['remarks'];
        }
        items.add(apiItem);
      }

      final response = await _apiService.saveFishDetails(
        intimationId: widget.voyageId,
        items: items,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ${response['message'] ?? 'Catch details saved successfully!'}',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to save catch details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Add Catch / Fish Data',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF07347F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: isPageLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1257C7)),
            SizedBox(height: 16),
            Text(
              'Loading fish species...',
              style: TextStyle(
                color: Color(0xFF24365B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06358D), Color(0xFF1257C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Catch / Fish Data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Voyage ID: ${widget.voyageId}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fish Items List
                  ...selectedItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildFishItemCard(index, item);
                  }).toList(),

                  const SizedBox(height: 12),

                  // Add More Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _addNewItem,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Add Fish Item',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF1257C7),
                        ),
                        foregroundColor: const Color(0xFF1257C7),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submitCatch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1257C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Save Catch',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD FISH ITEM CARD
  // ============================================================

  Widget _buildFishItemCard(int index, Map<String, dynamic> item) {
    final speciesId = item['species_id'] as int?;
    final speciesName = _getSpeciesName(speciesId);
    final isSelected = speciesId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF1257C7) : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with item number and delete button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1257C7).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? const Color(0xFF1257C7) : Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              if (selectedItems.length > 1)
                IconButton(
                  onPressed: isLoading ? null : () => _removeItem(index),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Species Selection Button
          InkWell(
            onTap: isLoading ? null : () => _showSpeciesSearchDialog(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0F6FF) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1257C7) : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                    color: isSelected ? const Color(0xFF1257C7) : Colors.grey[400],
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSelected ? speciesName : 'Select fish species',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? const Color(0xFF07347F) : Colors.grey[500],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Weight and Quantity Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight (kg)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF07347F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: weightControllers[index],
                      keyboardType: TextInputType.number,
                      enabled: !isLoading && isSelected,
                      onChanged: (value) {
                        final double? weight = double.tryParse(value);
                        _updateItemField(index, 'weight_kg', weight);
                      },
                      decoration: InputDecoration(
                        hintText: '0.0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1257C7)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: isSelected ? Colors.white : Colors.grey[50]!,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF07347F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: quantityControllers[index],
                      keyboardType: TextInputType.number,
                      enabled: !isLoading && isSelected,
                      onChanged: (value) {
                        final int? quantity = int.tryParse(value);
                        _updateItemField(index, 'quantity_count', quantity);
                      },
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF1257C7)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: isSelected ? Colors.white : Colors.grey[50]!,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Remarks
          TextField(
            controller: remarksControllers[index],
            enabled: !isLoading && isSelected,
            onChanged: (value) {
              _updateItemField(index, 'remarks', value);
            },
            decoration: InputDecoration(
              hintText: 'Remarks (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF1257C7)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: isSelected ? Colors.white : Colors.grey[50]!,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}