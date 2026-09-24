// screens/boat_owner/add_catch_screen.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';

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

  // ─── MARITIME PALETTE ──────────────────────────────────────────
  static const Color maritime950 = Color(0xFF061633);
  static const Color maritime900 = Color(0xFF0A234E);
  static const Color maritime850 = Color(0xFF0E2D63);
  static const Color maritime800 = Color(0xFF143C7D);
  static const Color maritime700 = Color(0xFF1A51A8);
  static const Color maritime600 = Color(0xFF2269D4);
  static const Color maritime500 = Color(0xFF2F81F7);
  static const Color maritime400 = Color(0xFF38BDF8);
  static const Color maritime50  = Color(0xFFF0F7FF);
  static const Color slateBg     = Color(0xFFF8FAFC);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color emerald     = Color(0xFF10B981);

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
    super.dispose();
  }

  // ============================================================
  // LOAD FISH SPECIES (UNCHANGED)
  // ============================================================

  Future<void> _loadFishSpecies() async {
    setState(() {
      isPageLoading = true;
    });

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Working Offline. Fish species list needs internet to update.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          isPageLoading = false;
        });
        return;
      }

      final response = await _apiService.getFishSpecies();

      if (response == null) {
        print('⚠️ No response received for fish species.');
        return;
      }

      if (response['success'] == true) {
        final data = response['data'];
        if (data == null) {
          print('⚠️ Response successful but "data" field is null.');
          return;
        }

        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() {
            fishSpecies = List<Map<String, dynamic>>.from(items);
          });
          print('✅ Loaded ${fishSpecies.length} fish species');
        } else {
          print('⚠️ No items found in fish species list.');
        }
      } else {
        print('❌ Failed to load fish species: ${response['message']}');
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
  // ADD NEW ITEM (UNCHANGED)
  // ============================================================

  void _addNewItem() {
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
  // REMOVE ITEM (UNCHANGED — used by the delete icon)
  // ============================================================

  void _removeItem(int index) {
    // Guard: never allow removing the last item
    if (selectedItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one item is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
  // UPDATE ITEM FIELD (UNCHANGED)
  // ============================================================

  void _updateItemField(int index, String field, dynamic value) {
    setState(() {
      selectedItems[index][field] = value;
    });
  }

  // ============================================================
  // GET SPECIES NAME BY ID (UNCHANGED)
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
  // CHECK IF SPECIES IS ALREADY SELECTED (UNCHANGED)
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
  // SPECIES SEARCH DIALOG — RESTYLED (same logic)
  // ============================================================

  Future<void> _showSpeciesSearchDialog(int index) async {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredSpecies = List.from(fishSpecies);

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
            return Dialog(
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ─── Header ───
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [maritime800, maritime600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.20),
                              ),
                            ),
                            child: const Icon(
                              Icons.set_meal_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Fish Species',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Search & tap to add to this item',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // ─── Search Field ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: slateBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: slateBorder),
                        ),
                        child: TextField(
                          autofocus: true,
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            setDialogState(() {
                              searchQuery = value.toLowerCase();
                              filteredSpecies = fishSpecies.where((species) {
                                final name = species['fish_name']
                                    ?.toString()
                                    .toLowerCase() ??
                                    '';
                                return name.contains(searchQuery);
                              }).toList();
                            });
                          },
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search fish species...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: textMuted,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                            EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    // ─── Species List ───
                    Flexible(
                      child: filteredSpecies.isEmpty
                          ? Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 30),
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
                          maxHeight:
                          MediaQuery.of(context).size.height * 0.4,
                          minHeight: 100,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding:
                          const EdgeInsets.symmetric(vertical: 4),
                          itemCount: filteredSpecies.length,
                          itemBuilder: (context, idx) {
                            final species = filteredSpecies[idx];
                            final speciesId =
                            species['species_id'] as int;
                            final fishName =
                                species['fish_name']?.toString() ?? '';
                            final isBanned =
                                species['is_banned'] == true;
                            final isAlreadySelected =
                            selectedIds.contains(speciesId);

                            return InkWell(
                              onTap: isAlreadySelected
                                  ? null
                                  : () {
                                _updateItemField(
                                    index, 'species_id', speciesId);
                                _updateItemField(index,
                                    'species_name', fishName);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 3),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAlreadySelected
                                      ? const Color(0xFFF1F5F9)
                                      : (isBanned
                                      ? const Color(0xFFFEF2F2)
                                      : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isAlreadySelected
                                        ? slateBorder
                                        : (isBanned
                                        ? const Color(0xFFFECACA)
                                        : slateBorder),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: isBanned
                                            ? const Color(0xFFFEE2E2)
                                            : maritime50,
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isBanned
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFBAE0FD),
                                        ),
                                      ),
                                      child: Icon(
                                        isBanned
                                            ? Icons.block_rounded
                                            : Icons.set_meal_rounded,
                                        color: isBanned
                                            ? const Color(0xFFDC2626)
                                            : maritime600,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fishName,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight:
                                              FontWeight.w700,
                                              color: isBanned
                                                  ? const Color(
                                                  0xFFDC2626)
                                                  : textPrimary,
                                            ),
                                          ),
                                          if (isBanned)
                                            const Padding(
                                              padding:
                                              EdgeInsets.only(top: 2),
                                              child: Text(
                                                'BANNED',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: Color(
                                                      0xFFDC2626),
                                                  fontWeight:
                                                  FontWeight.w900,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isAlreadySelected)
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                          const Color(0xFFF1F5F9),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                          border: Border.all(
                                              color: slateBorder),
                                        ),
                                        child: const Text(
                                          'Added',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: textMuted,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ─── Cancel ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: slateBorder),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VALIDATE AND SUBMIT (UNCHANGED)
  // ============================================================

  Future<void> _submitCatch() async {
    for (int i = 0; i < selectedItems.length; i++) {
      final weight = double.tryParse(weightControllers[i].text);
      final quantity = int.tryParse(quantityControllers[i].text);
      final remarks = remarksControllers[i].text;

      selectedItems[i]['weight_kg'] = weight;
      selectedItems[i]['quantity_count'] = quantity;
      selectedItems[i]['remarks'] = remarks;
    }

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
              content:
              Text(response['message'] ?? 'Failed to save catch details'),
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
  // BUILD (NEW UI)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildNewHeader(),
            Expanded(
              child: isPageLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: maritime600),
                    SizedBox(height: 16),
                    Text(
                      'Loading fish species...',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVoyageBannerCard(),
                    const SizedBox(height: 14),
                    ...selectedItems.asMap().entries.map((entry) {
                      return _buildFishItemCard(entry.key, entry.value);
                    }).toList(),
                    const SizedBox(height: 4),
                    _buildAddFishItemButton(),
                    const SizedBox(height: 16),
                    _buildSaveCatchButton(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── New Maritime Header ───
  Widget _buildNewHeader() {
    return Container(
      color: maritime900,
      child: Stack(
        children: [
          // Radar grid pattern (decorative)
          Positioned.fill(
            child: CustomPaint(
              painter: _RadarGridPainter(),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  const Expanded(
                    child: Text(
                      'Add Catch / Fish Data',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  // GPS pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF022C22).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'GPS',
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Voyage Banner (Bathymetric card) ───
  Widget _buildVoyageBannerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B306B), Color(0xFF143C7D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: maritime700.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: maritime900.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Compass decorative ring
          Positioned(
            right: -30, bottom: -30,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.10), width: 1),
              ),
              child: Center(
                child: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.10), width: 1),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.12)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded,
                            color: Color(0xFF67E8F9), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'MARITIME LOG ENTRY',
                          style: TextStyle(
                            color: Color(0xFF67E8F9),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '#LOG-2025',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Add Catch / Fish Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: maritime950.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: maritime600.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_rounded,
                            color: maritime400, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          'Voyage ID: ${widget.voyageId}',
                          style: const TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Deep Sea Sector 4',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Add Fish Item Button ───
  Widget _buildAddFishItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : _addNewItem,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Add Fish Item',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: maritime600.withOpacity(0.5),
            width: 2,
            style: BorderStyle.solid,
          ),
          foregroundColor: maritime700,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ─── Save Catch Button ───
  Widget _buildSaveCatchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitCatch,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [maritime700, maritime600, maritime500],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: maritime600.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: maritime400.withOpacity(0.35)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.4),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_alt_rounded,
                    color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Save Catch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FISH ITEM CARD (NEW UI)
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? maritime600 : slateBorder,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header Row ───
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? maritime50
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFBAE0FD)
                        : slateBorder,
                  ),
                ),
                child: Text(
                  'Item ${index + 1}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? maritime700 : textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? emerald : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              // ⭐ DELETE ICON — properly wired to _removeItem
              if (selectedItems.length > 1)
                GestureDetector(
                  onTap: isLoading ? null : () => _removeItem(index),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFDC2626),
                      size: 17,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ─── Species Selector ───
          InkWell(
            onTap: isLoading ? null : () => _showSpeciesSearchDialog(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? maritime50
                    : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: isSelected ? maritime600 : slateBorder,
                  width: isSelected ? 1.4 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: isSelected
                        ? maritime600
                        : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSelected ? speciesName : 'Select fish species',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isSelected ? maritime800 : textMuted,
                        fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.search_rounded,
                    color: textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Weight & Quantity Row ───
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weight (kg)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: slateBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: weightControllers[index],
                              keyboardType: TextInputType.number,
                              enabled: !isLoading && isSelected,
                              onChanged: (value) {
                                final double? weight =
                                double.tryParse(value);
                                _updateItemField(
                                    index, 'weight_kg', weight);
                              },
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.0',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              'KG',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
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
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: slateBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: slateBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityControllers[index],
                              keyboardType: TextInputType.number,
                              enabled: !isLoading && isSelected,
                              onChanged: (value) {
                                final int? quantity =
                                int.tryParse(value);
                                _updateItemField(
                                    index, 'quantity_count', quantity);
                              },
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              'PCS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: textMuted,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ─── Remarks ───
          Container(
            decoration: BoxDecoration(
              color: slateBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: slateBorder),
            ),
            child: TextField(
              controller: remarksControllers[index],
              enabled: !isLoading && isSelected,
              onChanged: (value) {
                _updateItemField(index, 'remarks', value);
              },
              style: const TextStyle(
                fontSize: 13,
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Remarks (optional)',
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RADAR GRID PAINTER (decorative header texture)
// ══════════════════════════════════════════════════════════════

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;

    const double gridSize = 24;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}