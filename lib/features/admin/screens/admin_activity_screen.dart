import 'package:flutter/material.dart';

import 'package:granos_la_tradicion/features/admin/widgets/admin_base_layout.dart';
import 'package:granos_la_tradicion/features/admin/services/admin_audit_service.dart';
import 'package:granos_la_tradicion/features/admin/models/audit_log_model.dart';

class AdminActivityScreen extends StatefulWidget {

  final String token;

  const AdminActivityScreen({
    super.key,
    required this.token,
  });

  @override
  State<AdminActivityScreen> createState() =>
      _AdminActivityScreenState();
}

class _AdminActivityScreenState
    extends State<AdminActivityScreen> {

  List<AuditLog> logs = [];
  List<AuditLog> filteredLogs = [];

  bool loading = true;

  String searchQuery = "";
  String selectedAction = "Todos";
  String selectedUser = "Todos";

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  Future<void> loadLogs() async {

    try {

      final result =
          await AdminAuditService.getAuditLogs(widget.token);

      setState(() {
        logs = result;
        filteredLogs = result;
        loading = false;
      });

    } catch (e) {

      setState(() {
        loading = false;
      });

    }
  }

  void applyFilters() {

    List<AuditLog> result = logs;

    /// BUSQUEDA
    if (searchQuery.isNotEmpty) {

      result = result.where((log) {

        final text =
            "${log.email} ${log.action} ${log.details}"
                .toLowerCase();

        return text.contains(searchQuery.toLowerCase());

      }).toList();
    }

    /// FILTRO ACCION
    if (selectedAction != "Todos") {

      result = result.where((log) {
        return log.action == selectedAction;
      }).toList();
    }

    /// FILTRO USUARIO
    if (selectedUser != "Todos") {

      result = result.where((log) {
        return log.email == selectedUser;
      }).toList();
    }

    /// FILTRO FECHA
    if (selectedDate != null) {

      result = result.where((log) {

        final logDate = DateTime.parse(log.createdAt);

        return logDate.year == selectedDate!.year &&
            logDate.month == selectedDate!.month &&
            logDate.day == selectedDate!.day;

      }).toList();
    }

    setState(() {
      filteredLogs = result;
    });
  }

  List<String> get actions {

    final set = logs.map((e) => e.action).toSet().toList();
    set.insert(0, "Todos");

    return set;
  }

  List<String> get users {

    final set = logs.map((e) => e.email).toSet().toList();
    set.insert(0, "Todos");

    return set;
  }

  @override
  Widget build(BuildContext context) {

    return AdminBaseLayout(
      title: "Actividad del Sistema",
      showBackButton: true,

      child: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [

                  _searchBox(),

                  const SizedBox(height: 20),

                  _filters(),

                  const SizedBox(height: 20),

                  ...filteredLogs.map((log) {
                    return _glassLogCard(log);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _searchBox() {

    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Buscar actividad...",
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {

        searchQuery = value;
        applyFilters();

      },
    );
  }

  /// FILTROS
  Widget _filters() {

    return LayoutBuilder(
      builder: (context, constraints) {

        double width = constraints.maxWidth;
        bool mobile = width < 500;

        return Column(
          children: [

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [

                /// FILTRO ACCION
                SizedBox(
                  width: mobile ? width : 220,
                  child: DropdownMenu<String>(
                    width: mobile ? width : 220,
                    initialSelection: selectedAction,
                    label: const Text("Acción"),
                    dropdownMenuEntries: actions.map((action) {
                      return DropdownMenuEntry(
                        value: action,
                        label: action,
                      );
                    }).toList(),
                    onSelected: (value) {

                      selectedAction = value!;
                      applyFilters();

                    },
                  ),
                ),

                /// FILTRO USUARIO
                SizedBox(
                  width: mobile ? width : 220,
                  child: DropdownMenu<String>(
                    width: mobile ? width : 220,
                    initialSelection: selectedUser,
                    label: const Text("Usuario"),
                    dropdownMenuEntries: users.map((user) {
                      return DropdownMenuEntry(
                        value: user,
                        label: user,
                      );
                    }).toList(),
                    onSelected: (value) {

                      selectedUser = value!;
                      applyFilters();

                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [

                ElevatedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    selectedDate == null
                        ? "Filtrar por fecha"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                  ),
                  onPressed: () async {

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {

                      selectedDate = picked;
                      applyFilters();

                    }
                  },
                ),

                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text("Limpiar"),
                  onPressed: () {

                    selectedDate = null;
                    selectedUser = "Todos";
                    selectedAction = "Todos";
                    searchQuery = "";

                    filteredLogs = logs;

                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _glassLogCard(AuditLog log) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              log.action,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              log.email,
              style: const TextStyle(color: Colors.white70),
            ),

            Text(
              log.details,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 6),

            Text(
              log.createdAt,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            )
          ],
        ),
      ),
    );
  }
}