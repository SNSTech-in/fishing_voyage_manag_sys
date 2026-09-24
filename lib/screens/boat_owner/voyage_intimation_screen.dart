import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../services/api_services/api_service.dart';
import 'add_crew_screen.dart';

class VoyageIntimationScreen extends StatefulWidget {
  const VoyageIntimationScreen({super.key});

  @override
  State<VoyageIntimationScreen> createState() =>
      _VoyageIntimationScreenState();
}

class _VoyageIntimationScreenState extends State<VoyageIntimationScreen> {
  final _formKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // ================================================================
  // CONTROLLERS
  // ================================================================

  final TextEditingController freshWaterController = TextEditingController();
  final TextEditingController dieselController = TextEditingController();
  final TextEditingController lifeJacketController = TextEditingController();
  final TextEditingController lifeBuoysController = TextEditingController();
  final TextEditingController communicationController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyMobileController = TextEditingController();

  // ================================================================
  // DATA
  // ================================================================

  List<Map<String, dynamic>> crewMembers = [];
  List<Map<String, dynamic>> ports = [];
  List<Map<String, dynamic>> boats = [];

  final Set<int> selectedCrewIds = {};
  final List<Map<String, dynamic>> selectedDestinationPorts = [];

  // ================================================================
  // SELECTIONS
  // ================================================================

  int? selectedBoatId;
  String? selectedBoatName;

  String? selectedPrimaryPortId;
  String? selectedPrimaryPortName;

  DateTime? startDate;
  DateTime? returnDate;
  TimeOfDay? startTime;
  TimeOfDay? returnTime;

  String? selectedCrewType = 'ALL';

  // ================================================================
  // UI STATES
  // ================================================================

  bool isLoading = false;
  bool isSaving = false;

  bool isCrewSectionExpanded = true;
  bool isPortSectionExpanded = true;

  // ================================================================
  // INIT
  // ================================================================

// ================================================================
// INIT
// ================================================================

  @override
  void initState() {
    super.initState();
    _loadData();

    // Set default time to current time + 1 hour
    final now = DateTime.now();
    final startDateTime = now.add(const Duration(hours: 1));
    startTime = TimeOfDay.fromDateTime(startDateTime);
    // Set return time to start time + 2 hours
    final returnDateTime = startDateTime.add(const Duration(hours: 2));
    returnTime = TimeOfDay.fromDateTime(returnDateTime);
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _apiService.dispose();

    freshWaterController.dispose();
    dieselController.dispose();
    lifeJacketController.dispose();
    lifeBuoysController.dispose();
    communicationController.dispose();

    emergencyNameController.dispose();
    emergencyMobileController.dispose();

    super.dispose();
  }

  // ================================================================
  // LOAD ALL DATA
  // ================================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadBoats(),
        _loadCrew(),
        _loadPorts(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');

      if (mounted) {
        _showError('Unable to load required data.');
      }
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  // ================================================================
  // LOAD BOATS
  // ================================================================

  Future<void> _loadBoats() async {
    try {
      final response = await _apiService.getBoats(
        page: 1,
        pageSize: 20,
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List?;

        if (items != null) {
          boats = List<Map<String, dynamic>>.from(items);

          boats = boats.map((boat) {
            final copy = Map<String, dynamic>.from(boat);
            copy['id'] = copy['boat_id'];
            return copy;
          }).toList();

          debugPrint('Loaded ${boats.length} boats');
        }
      }
    } catch (e) {
      debugPrint('Error loading boats: $e');
    }
  }

  // ================================================================
  // LOAD CREW
  // ================================================================

  Future<void> _loadCrew() async {
    try {
      final response = await _apiService.getCrewList(
        page: 1,
        pageSize: 50,
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List?;

        if (items != null) {
          crewMembers = List<Map<String, dynamic>>.from(items);

          crewMembers = crewMembers.map((crew) {
            final copy = Map<String, dynamic>.from(crew);
            copy['id'] = copy['crew_id'];
            return copy;
          }).toList();

          debugPrint(
            'Loaded ${crewMembers.length} crew members',
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading crew: $e');
    }
  }

  // ================================================================
  // LOAD PORTS
  // ================================================================

  Future<void> _loadPorts() async {
    try {
      final response = await _apiService.getPorts();

      if (response['success'] == true) {
        final items = response['data']['items'] as List?;

        if (items != null) {
          ports = List<Map<String, dynamic>>.from(items);

          debugPrint('Loaded ${ports.length} ports');
        }
      }
    } catch (e) {
      debugPrint('Error loading ports: $e');
    }
  }

  // ================================================================
  // CHECK CAPTAIN
  // ================================================================

  bool _isCaptain(Map<String, dynamic> crew) {
    final value = crew['is_captain'];

    if (value == true) return true;
    if (value == 1) return true;
    if (value.toString().toLowerCase() == 'true') {
      return true;
    }

    return false;
  }

  // ================================================================
  // GET CREW ID
  // ================================================================

  int? _getCrewId(Map<String, dynamic> crew) {
    final value = crew['id'] ?? crew['crew_id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  // ================================================================
  // GET BOAT ID
  // ================================================================

  int? _getBoatId(Map<String, dynamic> boat) {
    final value = boat['id'] ?? boat['boat_id'];

    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }

  // ================================================================
  // GET SELECTED CAPTAIN
  // ================================================================

  Map<String, dynamic>? _getSelectedCaptain() {
    for (final crew in crewMembers) {
      final id = _getCrewId(crew);

      if (id != null && selectedCrewIds.contains(id) && _isCaptain(crew)) {
        return crew;
      }
    }

    return null;
  }

  // ================================================================
  // GET SELECTED CREW
  // ================================================================

  List<Map<String, dynamic>> _getSelectedCrew() {
    return crewMembers.where((crew) {
      final id = _getCrewId(crew);

      return id != null && selectedCrewIds.contains(id);
    }).toList();
  }

  // ================================================================
  // FILTER SELECTED CREW
  // ================================================================

  List<Map<String, dynamic>> _getFilteredSelectedCrew() {
    final selected = _getSelectedCrew();

    if (selectedCrewType == null || selectedCrewType == 'ALL') {
      return selected;
    }

    if (selectedCrewType == 'CAPTAIN') {
      return selected.where(_isCaptain).toList();
    }

    return selected.where((crew) => !_isCaptain(crew)).toList();
  }

  // ================================================================
  // CREW SELECTION
  // ================================================================

  void _toggleCrewSelection(Map<String, dynamic> crew) {
    final crewId = _getCrewId(crew);

    if (crewId == null) {
      _showAlert(
        title: 'Invalid Crew',
        message: 'This crew member does not have a valid ID.',
      );
      return;
    }

    final isSelected = selectedCrewIds.contains(crewId);

    if (isSelected) {
      setState(() {
        selectedCrewIds.remove(crewId);
      });

      return;
    }

    if (_isCaptain(crew)) {
      final existingCaptain = _getSelectedCaptain();

      if (existingCaptain != null) {
        _showAlert(
          title: 'Captain Already Selected',
          message:
          '${existingCaptain['crew_name'] ?? 'Captain'} '
              'is already selected as captain.\n\n'
              'Only one captain can be selected for a voyage.',
        );

        return;
      }
    }

    setState(() {
      selectedCrewIds.add(crewId);
    });
  }

  // ================================================================
  // REMOVE SELECTED CREW
  // ================================================================

  void _removeSelectedCrew(Map<String, dynamic> crew) {
    final id = _getCrewId(crew);

    if (id == null) return;

    setState(() {
      selectedCrewIds.remove(id);
    });
  }

  // ================================================================
  // ADD CREW SCREEN
  // ================================================================
// ================================================================
// ADD CREW SCREEN
// ================================================================

  Future<void> _navigateToAddCrew() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCrewScreen(),
      ),
    );

    if (!mounted) return;

    // Always reload crew when coming back from AddCrewScreen
    // This handles both successful addition and back button navigation
    await _loadCrew();

    // Show success message only if a crew was actually added
    if (result == true) {
      _showSuccess('Crew member added successfully.');
    }

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // CAPTAIN SELECTION DIALOG
  // ================================================================

  Future<void> _showCaptainSelectionDialog() async {
    final captains = crewMembers.where(_isCaptain).toList();

    if (captains.isEmpty) {
      _showAlert(
        title: 'No Captains Available',
        message:
        'No captain is available.\n\n'
            'Please use the "Add" button to add a new crew member.',
      );
      return;
    }

    String search = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final result = captains.where((crew) {
              if (search.isEmpty) {
                return true;
              }

              final name = crew['crew_name']?.toString().toLowerCase() ?? '';
              final mobile = crew['mobile_no']?.toString().toLowerCase() ?? '';

              return name.contains(search) || mobile.contains(search);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1257C7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFF1257C7),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Select Captain',
                      style: TextStyle(
                        color: Color(0xFF07347F),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          search = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search captain...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: result.isEmpty
                          ? const Center(
                        child: Text('No captains found'),
                      )
                          : ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final crew = result[index];

                          final id = _getCrewId(crew);

                          final selected =
                              id != null && selectedCrewIds.contains(id);

                          return _buildDialogCrewItem(
                            crew: crew,
                            selected: selected,
                            isCaptain: true,
                            onTap: () {
                              if (id == null) {
                                return;
                              }

                              final existing = _getSelectedCaptain();

                              if (existing != null &&
                                  !selectedCrewIds.contains(id)) {
                                _showAlert(
                                  title: 'Captain Already Selected',
                                  message:
                                  '${existing['crew_name'] ?? 'Captain'} '
                                      'is already selected as captain.\n\n'
                                      'Only one captain can be selected.',
                                );
                                return;
                              }

                              setState(() {
                                if (selected) {
                                  selectedCrewIds.remove(id);
                                } else {
                                  selectedCrewIds.add(id);
                                }
                              });

                              setDialogState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1257C7),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // MEMBER SELECTION DIALOG
  // ================================================================

  Future<void> _showMemberSelectionDialog() async {
    final members = crewMembers.where((crew) => !_isCaptain(crew)).toList();

    if (members.isEmpty) {
      _showAlert(
        title: 'No Members Available',
        message:
        'No crew members are available.\n\n'
            'Please use the "Add" button to add a new crew member.',
      );
      return;
    }

    final temporarySelection = selectedCrewIds.toSet();

    String search = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final result = members.where((crew) {
              if (search.isEmpty) {
                return true;
              }

              final name = crew['crew_name']?.toString().toLowerCase() ?? '';
              final mobile = crew['mobile_no']?.toString().toLowerCase() ?? '';

              return name.contains(search) || mobile.contains(search);
            }).toList();

            final visibleIds =
            result.map(_getCrewId).whereType<int>().toList();

            final allVisibleSelected =
                visibleIds.isNotEmpty && visibleIds.every(temporarySelection.contains);

            final selectedMemberCount = temporarySelection
                .where((id) => members.any((m) => _getCrewId(m) == id))
                .length;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E8B57).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Color(0xFF2E8B57),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Select Crew Members',
                      style: TextStyle(
                        color: Color(0xFF07347F),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$selectedMemberCount',
                    style: const TextStyle(
                      color: Color(0xFF2E8B57),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 470,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          search = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search crew member...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: result.isEmpty
                              ? null
                              : () {
                            setDialogState(() {
                              for (final crew in result) {
                                final id = _getCrewId(crew);

                                if (id != null) {
                                  temporarySelection.add(id);
                                }
                              }
                            });
                          },
                          icon: const Icon(
                            Icons.done_all_rounded,
                            size: 16,
                          ),
                          label: Text(
                            allVisibleSelected ? 'Selected' : 'Select Visible',
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: result.isEmpty
                              ? null
                              : () {
                            setDialogState(() {
                              for (final crew in result) {
                                final id = _getCrewId(crew);

                                if (id != null) {
                                  temporarySelection.remove(id);
                                }
                              }
                            });
                          },
                          child: const Text(
                            'Clear Visible',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: result.isEmpty
                          ? const Center(
                        child: Text('No crew members found'),
                      )
                          : ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final crew = result[index];

                          final id = _getCrewId(crew);

                          final selected =
                              id != null && temporarySelection.contains(id);

                          return _buildDialogCrewItem(
                            crew: crew,
                            selected: selected,
                            isCaptain: false,
                            onTap: () {
                              if (id == null) {
                                return;
                              }

                              setDialogState(() {
                                if (temporarySelection.contains(id)) {
                                  temporarySelection.remove(id);
                                } else {
                                  temporarySelection.add(id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedCrewIds.removeWhere(
                            (id) => members.any((member) => _getCrewId(member) == id),
                      );

                      selectedCrewIds.addAll(
                        temporarySelection.where(
                              (id) => members.any((member) => _getCrewId(member) == id),
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ================================================================
  // DIALOG CREW ITEM
  // ================================================================

  Widget _buildDialogCrewItem({
    required Map<String, dynamic> crew,
    required bool selected,
    required bool isCaptain,
    required VoidCallback onTap,
  }) {
    final name = crew['crew_name']?.toString().trim().isNotEmpty == true
        ? crew['crew_name'].toString()
        : 'Unknown';

    final mobile = crew['mobile_no']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1257C7) : const Color(0xFFE1E7F0),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              activeColor: const Color(0xFF1257C7),
              visualDensity: VisualDensity.compact,
              onChanged: (_) => onTap(),
            ),
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isCaptain
                    ? const Color(0xFF1257C7).withOpacity(0.1)
                    : const Color(0xFF2E8B57).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCaptain
                    ? Icons.workspace_premium_outlined
                    : Icons.person_outline,
                size: 19,
                color: isCaptain
                    ? const Color(0xFF1257C7)
                    : const Color(0xFF2E8B57),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: const Color(0xFF07347F),
                    ),
                  ),
                  if (mobile.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        mobile,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? const Color(0xFF1257C7) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PRIMARY PORT
  // ================================================================

  void _selectPrimaryPort(Map<String, dynamic> port) {
    final portId = port['port_id']?.toString();

    if (portId == null) return;

    setState(() {
      selectedPrimaryPortId = portId;

      selectedPrimaryPortName = port['port_name']?.toString();

      final exists = selectedDestinationPorts.any(
            (p) => p['port_id']?.toString() == portId,
      );

      if (!exists) {
        selectedDestinationPorts.add(port);
      }
    });
  }

  // ================================================================
  // PRIMARY PORT DIALOG
  // ================================================================

  Future<void> _showPrimaryPortDialog() async {
    if (ports.isEmpty) {
      _showAlert(
        title: 'No Ports',
        message: 'No ports are available.',
      );
      return;
    }

    String search = '';

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final result = ports.where((port) {
              if (search.isEmpty) {
                return true;
              }

              final name = port['port_name']?.toString().toLowerCase() ?? '';
              final code = port['port_code']?.toString().toLowerCase() ?? '';
              final district = port['district']?.toString().toLowerCase() ?? '';

              return name.contains(search) ||
                  code.contains(search) ||
                  district.contains(search);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Select Primary Port',
                style: TextStyle(
                  color: Color(0xFF07347F),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 430,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          search = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search port...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: result.isEmpty
                          ? const Center(
                        child: Text('No ports found'),
                      )
                          : ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final port = result[index];

                          final id = port['port_id']?.toString();

                          final isSelected = id == selectedPrimaryPortId;

                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            leading: Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? const Color(0xFF1257C7)
                                  : Colors.grey,
                            ),
                            title: Text(
                              port['port_name']?.toString() ?? '',
                            ),
                            subtitle: Text(
                              port['district']?.toString() ??
                                  port['port_code']?.toString() ??
                                  '',
                            ),
                            onTap: () {
                              Navigator.pop(
                                dialogContext,
                                port,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      _selectPrimaryPort(selected);
    }
  }

  // ================================================================
  // DESTINATION PORT DIALOG
  // ================================================================

  Future<void> _showDestinationPortDialog() async {
    if (ports.isEmpty) {
      _showAlert(
        title: 'No Ports',
        message: 'No ports are available.',
      );
      return;
    }

    final temporarySelection =
    selectedDestinationPorts.map((p) => p['port_id']?.toString()).whereType<String>().toSet();

    String search = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final result = ports.where((port) {
              if (search.isEmpty) {
                return true;
              }

              final name = port['port_name']?.toString().toLowerCase() ?? '';
              final code = port['port_code']?.toString().toLowerCase() ?? '';
              final district = port['district']?.toString().toLowerCase() ?? '';

              return name.contains(search) ||
                  code.contains(search) ||
                  district.contains(search);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Destination Ports',
                      style: TextStyle(
                        color: Color(0xFF07347F),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${temporarySelection.length}',
                    style: const TextStyle(
                      color: Color(0xFF1257C7),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 470,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          search = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search port...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (final port in result) {
                                final id = port['port_id'];

                                if (id != null) {
                                  temporarySelection.add(id.toString());
                                }
                              }
                            });
                          },
                          child: const Text('Select Visible'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              for (final port in result) {
                                temporarySelection.remove(
                                  port['port_id']?.toString(),
                                );
                              }
                            });
                          },
                          child: const Text('Clear Visible'),
                        ),
                      ],
                    ),
                    Expanded(
                      child: result.isEmpty
                          ? const Center(
                        child: Text('No ports found'),
                      )
                          : ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final port = result[index];

                          final id = port['port_id']?.toString();

                          final selected =
                              id != null && temporarySelection.contains(id);

                          return Container(
                            margin: const EdgeInsets.only(
                              bottom: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFE8F0FE)
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CheckboxListTile(
                              dense: true,
                              value: selected,
                              activeColor: const Color(0xFF1257C7),
                              controlAffinity:
                              ListTileControlAffinity.leading,
                              title: Text(
                                port['port_name']?.toString() ?? '',
                              ),
                              subtitle: Text(
                                port['district']?.toString() ??
                                    port['port_code']?.toString() ??
                                    '',
                              ),
                              onChanged: (_) {
                                if (id == null) {
                                  return;
                                }

                                setDialogState(() {
                                  if (temporarySelection.contains(id)) {
                                    temporarySelection.remove(id);
                                  } else {
                                    temporarySelection.add(id);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selected = ports.where((port) {
                      final id = port['port_id']?.toString();

                      return id != null && temporarySelection.contains(id);
                    }).toList();

                    setState(() {
                      selectedDestinationPorts
                        ..clear()
                        ..addAll(selected);

                      if (selectedPrimaryPortId != null) {
                        final primaryExists = selectedDestinationPorts.any(
                              (port) =>
                          port['port_id']?.toString() ==
                              selectedPrimaryPortId,
                        );

                        if (!primaryExists) {
                          final primary = ports.firstWhere(
                                (port) =>
                            port['port_id']?.toString() ==
                                selectedPrimaryPortId,
                            orElse: () => {},
                          );

                          if (primary.isNotEmpty) {
                            selectedDestinationPorts.add(primary);
                          }
                        }
                      }
                    });

                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1257C7),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
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

  // ================================================================
  // DATE
  // ================================================================

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();

    DateTime initialDate = isStart
        ? (startDate ?? now)
        : (returnDate ?? startDate ?? now);

    final firstDate = isStart
        ? DateTime(now.year, now.month, now.day)
        : (startDate ?? DateTime(now.year, now.month, now.day));

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;

        if (returnDate != null && returnDate!.isBefore(picked)) {
          returnDate = null;
        }
      } else {
        returnDate = picked;
      }
    });
  }

  // ================================================================
  // TIME SELECTION
  // ================================================================

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);

    // For start time, minimum is current time + 15 minutes
    final minTime = TimeOfDay(
      hour: currentTime.hour,
      minute: currentTime.minute + 15,
    ).replacing(hour: currentTime.hour + (currentTime.minute + 15 >= 60 ? 1 : 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (startTime ?? currentTime.replacing(hour: currentTime.hour + 1))
          : (returnTime ?? currentTime.replacing(hour: currentTime.hour + 3)),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startTime = picked;

        // If return time is before start time, adjust it
        if (returnTime != null &&
            (returnDate == startDate || returnDate == null) &&
            _isTimeBefore(returnTime!, picked)) {
          returnTime = picked.replacing(
            hour: picked.hour + 2,
            minute: picked.minute,
          );
        }
      } else {
        // Validate return time is after start time
        if (startTime != null &&
            (returnDate == startDate || returnDate == null) &&
            _isTimeBefore(picked, startTime!)) {
          _showAlert(
            title: 'Invalid Time',
            message: 'Return time cannot be before start time on the same day.',
          );
          return;
        }
        returnTime = picked;
      }
    });
  }

  bool _isTimeBefore(TimeOfDay a, TimeOfDay b) {
    return a.hour < b.hour || (a.hour == b.hour && a.minute < b.minute);
  }

  // ================================================================
  // VALIDATION
  // ================================================================

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(value.trim())) {
      return 'Enter valid number';
    }

    return null;
  }

  String? _validateEmergencyMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter emergency mobile number';
    }

    final cleanNumber = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.length != 10) {
      return 'Enter valid 10-digit mobile number';
    }

    return null;
  }

  // ================================================================
  // API DATE/TIME FORMAT
  // ================================================================

  String _formatApiDateTime(DateTime date, TimeOfDay time) {
    final combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
      0,
    );

    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(combined) + '+05:30';
  }

  // ================================================================
  // SAVE VOYAGE
  // ================================================================

  Future<void> _saveVoyage() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedBoatId == null) {
      _showAlert(
        title: 'Boat Required',
        message: 'Please select a boat before saving the voyage.',
      );
      return;
    }

    if (selectedPrimaryPortId == null) {
      _showAlert(
        title: 'Primary Port Required',
        message: 'Please select the primary port.',
      );
      return;
    }

    if (selectedDestinationPorts.isEmpty) {
      _showAlert(
        title: 'Destination Required',
        message: 'Please select at least one destination port.',
      );
      return;
    }

    if (startDate == null) {
      _showAlert(
        title: 'Start Date Required',
        message: 'Please select the voyage start date.',
      );
      return;
    }

    if (startTime == null) {
      _showAlert(
        title: 'Start Time Required',
        message: 'Please select the voyage start time.',
      );
      return;
    }

    if (returnDate == null) {
      _showAlert(
        title: 'Return Date Required',
        message: 'Please select the voyage return date.',
      );
      return;
    }

    if (returnTime == null) {
      _showAlert(
        title: 'Return Time Required',
        message: 'Please select the voyage return time.',
      );
      return;
    }

    // Validate dates
    final startDateTime = DateTime(
      startDate!.year,
      startDate!.month,
      startDate!.day,
      startTime!.hour,
      startTime!.minute,
    );

    final returnDateTime = DateTime(
      returnDate!.year,
      returnDate!.month,
      returnDate!.day,
      returnTime!.hour,
      returnTime!.minute,
    );

    // Check if start time is in the past
    final now = DateTime.now();
    if (startDateTime.isBefore(now)) {
      _showAlert(
        title: 'Invalid Start Time',
        message: 'Voyage start time cannot be in the past.\n\nPlease select a future time.',
      );
      return;
    }

    if (returnDateTime.isBefore(startDateTime)) {
      _showAlert(
        title: 'Invalid Dates',
        message: 'Return date/time cannot be before the voyage start date/time.',
      );
      return;
    }

    final selectedCaptain = _getSelectedCaptain();

    if (selectedCaptain == null) {
      _showAlert(
        title: 'Captain Required',
        message: 'Please select one captain for this voyage.\n\n'
            'You can use the "Add Captain" button to select one.',
      );
      return;
    }

    if (selectedCrewIds.isEmpty) {
      _showAlert(
        title: 'Crew Required',
        message: 'Please select at least one crew member.',
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      isSaving = true;
    });

    try {
      // ============================================================
      // API DATE FORMAT
      // ============================================================

      final voyageStartDate = _formatApiDateTime(startDate!, startTime!);
      final voyageReturnDate = _formatApiDateTime(returnDate!, returnTime!);

      // ============================================================
      // CREW IDS
      // ============================================================

      final crewIds = selectedCrewIds.map((id) => id.toString()).toList();

      // ============================================================
      // DESTINATION PORT IDS
      // ============================================================

      final destinationPortIds =
      selectedDestinationPorts.map((port) => port['port_id'].toString()).toList();

      // ============================================================
      // REQUEST BODY
      // ============================================================

      final requestBody = {
        'boat_id': selectedBoatId.toString(),
        'voyage_start_date': voyageStartDate,
        'voyage_return_date': voyageReturnDate,
        'fresh_water_ltr':
        double.tryParse(freshWaterController.text.trim()) ?? 0.0,
        'diesel_ltr':
        double.tryParse(dieselController.text.trim()) ?? 0.0,
        'life_jackets':
        int.tryParse(lifeJacketController.text.trim()) ?? 0,
        'life_buoys':
        int.tryParse(lifeBuoysController.text.trim()) ?? 0,
        'communication_devices':
        int.tryParse(communicationController.text.trim()) ?? 0,
        'emergency_name': emergencyNameController.text.trim(),
        'emergency_contact': emergencyMobileController.text.trim(),
        'primary_port_id': int.parse(selectedPrimaryPortId!),
        'destination_port_ids': destinationPortIds,
        'crew_ids': crewIds,
        'status': 'SUBMITTED',
      };

      // ============================================================
      // REQUEST LOG
      // ============================================================

      debugPrint('===========================================================');
      debugPrint('VOYAGE API REQUEST');
      debugPrint('===========================================================');
      debugPrint('voyage_start_date : $voyageStartDate');
      debugPrint('voyage_return_date: $voyageReturnDate');
      debugPrint('requestBody       : $requestBody');
      debugPrint('===========================================================');

      // ============================================================
      // API CALL
      // ============================================================

      final response = await _apiService.createIntimation(requestBody);

      debugPrint('Voyage Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];

        _showSuccess(
          'Voyage intimation saved successfully!\n'
              'Reference: ${data?['reference_no'] ?? '-'}',
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorDialog(
          response['message'],
          response['error_code'],
          response['errors'],
        );
      }
    } catch (e) {
      debugPrint('Error saving voyage: $e');

      if (mounted) {
        _showErrorDialog(
          'Error saving voyage',
          null,
          [e.toString()],
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ================================================================
  // ALERT
  // ================================================================

  Future<void> _showAlert({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1257C7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1257C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF07347F),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // ERROR SNACKBAR
  // ================================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ================================================================
  // SUCCESS SNACKBAR
  // ================================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ================================================================
  // ERROR DIALOG
  // ================================================================

  void _showErrorDialog(String? message, String? errorCode, dynamic errors) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF07347F),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message ?? 'Something went wrong.',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (errorCode != null && errorCode.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Error Code: $errorCode',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
                if (errors is List && errors.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF07347F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...errors.map(
                        (error) {
                      String text;

                      if (error is Map) {
                        text = error['message']?.toString() ?? error.toString();
                      } else {
                        text = error.toString();
                      }

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(
                          bottom: 6,
                        ),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: _buildAppBar(),
      body: isLoading ? _buildLoading() : _buildBody(),
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF1257C7),
          ),
          SizedBox(height: 14),
          Text(
            'Loading data...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF24365B),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BODY
  // ================================================================

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.directions_boat_rounded,
                title: 'Voyage Details',
              ),
              const SizedBox(height: 10),
              _buildBoatSelector(),
              const SizedBox(height: 10),
              _buildPortsSection(),
              const SizedBox(height: 10),
              _buildDateAndTimeSection(),
              const SizedBox(height: 16),
              _buildSectionHeader(
                icon: Icons.inventory_2_outlined,
                title: 'Voyage Resources',
              ),
              const SizedBox(height: 10),
              _buildResourceFields(),
              const SizedBox(height: 16),
              _buildSectionHeader(
                icon: Icons.contact_phone_outlined,
                title: 'Emergency Contact',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: emergencyNameController,
                label: 'Emergency Contact Name',
                hint: 'Enter name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter emergency contact name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: emergencyMobileController,
                label: 'Emergency Contact No.',
                hint: '10-digit mobile number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: _validateEmergencyMobile,
              ),
              const SizedBox(height: 16),
              _buildCrewSection(),
              const SizedBox(height: 18),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // APP BAR
  // ================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF06358D),
      elevation: 0,
      toolbarHeight: 54,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context, false),
        tooltip: 'Back',
      ),
      titleSpacing: 0,
      title: const Text(
        'Voyage Intimation',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================================================================
  // SECTION HEADER
  // ================================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1257C7).withOpacity(0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF1257C7),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1257C7),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // BOAT SELECTOR
  // ================================================================

  Widget _buildBoatSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: _showBoatSelectionDialog,
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Boat',
          hint: 'Select boat',
          icon: Icons.directions_boat_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedBoatName ?? 'Select boat',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedBoatName != null
                      ? const Color(0xFF07347F)
                      : Colors.grey[500],
                  fontWeight: selectedBoatName != null
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF07347F),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // BOAT SELECTION DIALOG
  // ================================================================

  Future<void> _showBoatSelectionDialog() async {
    if (boats.isEmpty) {
      _showAlert(
        title: 'No Boats',
        message: 'No boats are available.',
      );
      return;
    }

    String search = '';

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final result = boats.where((boat) {
              if (search.isEmpty) {
                return true;
              }

              final name = boat['boat_name']?.toString().toLowerCase() ?? '';
              final reg = boat['boat_reg_no']?.toString().toLowerCase() ?? '';

              return name.contains(search) || reg.contains(search);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1257C7).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_boat_outlined,
                      color: Color(0xFF1257C7),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      'Select Boat',
                      style: TextStyle(
                        color: Color(0xFF07347F),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          search = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search boat...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: result.isEmpty
                          ? const Center(
                        child: Text('No boats found'),
                      )
                          : ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final boat = result[index];

                          final id = _getBoatId(boat);

                          final selected = id != null && id == selectedBoatId;

                          final name = boat['boat_name']?.toString() ?? 'Boat';
                          final reg = boat['boat_reg_no']?.toString() ?? '';

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              Navigator.pop(
                                dialogContext,
                                boat,
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: 6,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE8F0FE)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1257C7)
                                      : const Color(0xFFE1E7F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1257C7)
                                          .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.directions_boat_outlined,
                                      size: 20,
                                      color: Color(0xFF1257C7),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF07347F),
                                          ),
                                        ),
                                        if (reg.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Text(
                                              reg,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? const Color(0xFF1257C7)
                                        : Colors.grey[400],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      final id = _getBoatId(selected);

      if (id != null) {
        setState(() {
          selectedBoatId = id;
          selectedBoatName = selected['boat_name']?.toString();
        });
      }
    }
  }

  // ================================================================
  // PORT SECTION
  // ================================================================

  Widget _buildPortsSection() {
    final selectedCount = selectedDestinationPorts.length;

    return _buildExpandableCard(
      title: 'Port Details',
      icon: Icons.location_on_outlined,
      expanded: isPortSectionExpanded,
      trailing: '$selectedCount selected',
      onTap: () {
        setState(() {
          isPortSectionExpanded = !isPortSectionExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPrimaryPortSelector(),
          const SizedBox(height: 10),
          _buildDestinationSelector(),
        ],
      ),
    );
  }

  // ================================================================
  // PRIMARY PORT SELECTOR
  // ================================================================

  Widget _buildPrimaryPortSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _showPrimaryPortDialog,
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Primary Port',
          hint: 'Select primary port',
          icon: Icons.flag_outlined,
        ),
        child: Text(
          selectedPrimaryPortName ?? 'Select primary port',
          style: TextStyle(
            fontSize: 14,
            color: selectedPrimaryPortName != null
                ? const Color(0xFF07347F)
                : Colors.grey[500],
            fontWeight: selectedPrimaryPortName != null
                ? FontWeight.w500
                : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // DESTINATION PORT SELECTOR
  // ================================================================

  Widget _buildDestinationSelector() {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _showDestinationPortDialog,
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Destination Ports',
          hint: 'Select destination ports',
          icon: Icons.location_on_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedDestinationPorts.isEmpty
                    ? 'Select destination ports'
                    : '${selectedDestinationPorts.length} port(s) selected',
                style: TextStyle(
                  fontSize: 14,
                  color: selectedDestinationPorts.isEmpty
                      ? Colors.grey[500]
                      : const Color(0xFF07347F),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF07347F),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DATE AND TIME SECTION
  // ================================================================

  Widget _buildDateAndTimeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Start Date',
                date: startDate,
                icon: Icons.calendar_today_outlined,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimePicker(
                label: 'Start Time',
                time: startTime,
                icon: Icons.access_time_outlined,
                onTap: () => _selectTime(context, true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDatePicker(
                label: 'Return Date',
                date: returnDate,
                icon: Icons.event_available_outlined,
                onTap: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimePicker(
                label: 'Return Time',
                time: returnTime,
                icon: Icons.access_time_outlined,
                onTap: () => _selectTime(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // RESOURCE FIELDS
  // ================================================================

  Widget _buildResourceFields() {
    return Column(
      children: [
        _buildTextField(
          controller: freshWaterController,
          label: 'Fresh Water',
          hint: 'Enter litres',
          icon: Icons.water_drop_outlined,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: _validateNumber,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: dieselController,
          label: 'Diesel',
          hint: 'Enter litres',
          icon: Icons.local_gas_station_outlined,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          validator: _validateNumber,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: lifeJacketController,
          label: 'Life Jackets',
          hint: 'Enter quantity',
          icon: Icons.health_and_safety_outlined,
          keyboardType: TextInputType.number,
          validator: _validateNumber,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: lifeBuoysController,
          label: 'Life Buoys',
          hint: 'Enter quantity',
          icon: Icons.circle_outlined,
          keyboardType: TextInputType.number,
          validator: _validateNumber,
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: communicationController,
          label: 'Communication Devices',
          hint: 'Enter quantity',
          icon: Icons.radio_outlined,
          keyboardType: TextInputType.number,
          validator: _validateNumber,
        ),
      ],
    );
  }

  // ================================================================
  // CREW SECTION
  // ================================================================

  Widget _buildCrewSection() {
    final selectedCrew = _getFilteredSelectedCrew();
    final totalSelected = selectedCrewIds.length;

    return _buildExpandableCard(
      title: 'Crew Members',
      icon: Icons.groups_outlined,
      expanded: isCrewSectionExpanded,
      trailing: '$totalSelected selected',
      onTap: () {
        setState(() {
          isCrewSectionExpanded = !isCrewSectionExpanded;
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Add Captain',
                  color: const Color(0xFF1257C7),
                  onPressed: _showCaptainSelectionDialog,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _actionButton(
                  icon: Icons.person_outline,
                  label: 'Add Member',
                  color: const Color(0xFF2E8B57),
                  onPressed: _showMemberSelectionDialog,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _actionButton(
                  icon: Icons.add_rounded,
                  label: 'Add',
                  color: const Color(0xFFE67E22),
                  onPressed: _navigateToAddCrew,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFD4DFEE),
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCrewType,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF07347F),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text(
                      'All Selected Crew',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'CAPTAIN',
                    child: Text(
                      'Selected Captain',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'MEMBER',
                    child: Text(
                      'Selected Members',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedCrewType = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (selectedCrew.isEmpty)
            _buildNoSelectedCrew()
          else
            Column(
              children: selectedCrew.map((crew) {
                return _buildSelectedCrewItem(crew);
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // SELECTED CREW ITEM
  // ================================================================

  Widget _buildSelectedCrewItem(Map<String, dynamic> crew) {
    final captain = _isCaptain(crew);

    final name = crew['crew_name']?.toString().trim().isNotEmpty == true
        ? crew['crew_name'].toString()
        : 'Unknown';

    final mobile = crew['mobile_no']?.toString() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: captain ? const Color(0xFFE8F0FE) : const Color(0xFFF1FAF5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: captain ? const Color(0xFFBBD0F5) : const Color(0xFFC5E5D2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: captain
                  ? const Color(0xFF1257C7).withOpacity(0.1)
                  : const Color(0xFF2E8B57).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              captain
                  ? Icons.workspace_premium_outlined
                  : Icons.person_outline,
              size: 20,
              color: captain ? const Color(0xFF1257C7) : const Color(0xFF2E8B57),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF07347F),
                        ),
                      ),
                    ),
                    if (captain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1257C7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'CAPTAIN',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1257C7),
                          ),
                        ),
                      ),
                  ],
                ),
                if (mobile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 3,
                    ),
                    child: Text(
                      mobile,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            tooltip: 'Remove crew',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(5),
            constraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
            onPressed: () => _removeSelectedCrew(crew),
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFFD32F2F),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // NO SELECTED CREW
  // ================================================================

  Widget _buildNoSelectedCrew() {
    String message;

    if (selectedCrewType == 'CAPTAIN') {
      message = 'No captain selected.';
    } else if (selectedCrewType == 'MEMBER') {
      message = 'No crew members selected.';
    } else {
      message = 'No crew selected yet.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE1E7F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.groups_outlined,
            size: 38,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 7),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use Add Captain or Add Member above.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ACTION BUTTON
  // ================================================================

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 17,
        color: color,
      ),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 42),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ),
        side: BorderSide(
          color: color.withOpacity(0.35),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        backgroundColor: color.withOpacity(0.05),
      ),
    );
  }

  // ================================================================
  // EXPANDABLE CARD
  // ================================================================

  Widget _buildExpandableCard({
    required String title,
    required IconData icon,
    required bool expanded,
    required String trailing,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E6EF),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: const Color(0xFF1257C7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF07347F),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trailing,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 21,
                    color: const Color(0xFF1257C7),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                10,
              ),
              child: child,
            ),
        ],
      ),
    );
  }

  // ================================================================
  // TEXT FIELD
  // ================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      style: const TextStyle(
        fontSize: 13,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
      ).copyWith(
        counterText: maxLength != null ? null : '',
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF53627A),
      ),
      hintStyle: TextStyle(
        fontSize: 13,
        color: Colors.grey[400],
      ),
      prefixIcon: icon != null
          ? Icon(
        icon,
        size: 19,
        color: Colors.grey[600],
      )
          : null,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 11,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD4DFEE),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFD4DFEE),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF1257C7),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  // ================================================================
  // DATE PICKER
  // ================================================================

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: 'Select date',
          icon: icon,
        ),
        child: Text(
          date == null
              ? 'Select date'
              : DateFormat('dd MMM yyyy').format(date),
          style: TextStyle(
            fontSize: 13,
            color: date == null ? Colors.grey[500] : const Color(0xFF07347F),
            fontWeight: date == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // TIME PICKER
  // ================================================================

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: label,
          hint: 'Select time',
          icon: icon,
        ),
        child: Text(
          time == null
              ? 'Select time'
              : time.format(context),
          style: TextStyle(
            fontSize: 13,
            color: time == null ? Colors.grey[500] : const Color(0xFF07347F),
            fontWeight: time == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SAVE BUTTON
  // ================================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveVoyage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1257C7),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isSaving
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_outlined,
              size: 19,
            ),
            SizedBox(width: 8),
            Text(
              'Save Intimation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}