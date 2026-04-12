import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/ubicacion_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/admin_service.dart';
import '../../../core/services/ubicacion_service.dart';
import '../widgets/admin_base_layout.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final AdminService adminService = AdminService();
  final UbicacionService ubicacionService = UbicacionService();

  String search = "";
  String filter = "todos";

  int? actionUserId;
  String? actionType;

  int refreshKey = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final token = auth.token;

    if (token == null || token.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("Sesión inválida"),
        ),
      );
    }

    return AdminBaseLayout(
      title: "Gestión de Clientes",
      showBackButton: true,
      child: FutureBuilder<List<dynamic>>(
        key: ValueKey(refreshKey),
        future: adminService.getUsers(token),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error cargando usuarios: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<dynamic> users = snapshot.data ?? [];

          users = users.where((u) {
            final name = (u["name"] ?? "").toString().toLowerCase();
            final email = (u["email"] ?? "").toString().toLowerCase();
            final username = (u["username"] ?? "").toString().toLowerCase();
            final phone = (u["phone"] ?? "").toString().toLowerCase();

            final q = search.toLowerCase();

            return name.contains(q) ||
                email.contains(q) ||
                username.contains(q) ||
                phone.contains(q);
          }).toList();

          if (filter != "todos") {
            users = users.where((u) => u["status"] == filter).toList();
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar cliente...",
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.90),
                    hintStyle: const TextStyle(color: Color(0xFF6B5B52)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(color: Color(0xFF4B3A2F)),
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filterButton("todos", "Todos"),
                    _filterButton("activo", "Activos"),
                    _filterButton("bloqueado", "Bloqueados"),
                  ],
                ),
                const SizedBox(height: 20),
                if (users.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: const Text(
                      "No se encontraron clientes.",
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Column(
                  children: users.map((user) {
                    final int userId = user["id"] as int;
                    final name = user["name"] ?? "Sin nombre";
                    final email = user["email"] ?? "Sin email";
                    final phone = user["phone"] ?? "";
                    final username = user["username"] ?? "";
                    final address = user["address"] ?? "";
                    final status = user["status"] ?? "activo";
                    final role = user["role"] ?? "cliente";
                    final ubicacionId =
                        user["ubicacionId"] ?? user["ubicacion_id"];
                    final totpEnabled =
                        user["totpEnabled"] == true || user["totp_enabled"] == 1;
                    final createdAt = user["created_at"]?.toString() ?? "";

                    final bool isBlockingThisUser =
                        actionUserId == userId && actionType == "block";
                    final bool isDeletingThisUser =
                        actionUserId == userId && actionType == "delete";
                    final bool isUpdatingThisUser =
                        actionUserId == userId && actionType == "update";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
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
                            name.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (username.toString().trim().isNotEmpty)
                            Text(
                              "Usuario: $username",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          Text(
                            email.toString(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (phone.toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                phone.toString(),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          if (address.toString().trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Dirección: $address",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            "Estado: $status",
                            style: TextStyle(
                              color: status == "bloqueado"
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rol: $role",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "Ubicación ID: ${ubicacionId ?? 'No asignada'}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "TOTP: ${totpEnabled ? 'Activo' : 'No activo'}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (createdAt.isNotEmpty)
                            Text(
                              "Creado: $createdAt",
                              style: const TextStyle(color: Colors.white54),
                            ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF6A4BBE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                icon: Icon(
                                  isUpdatingThisUser
                                      ? Icons.hourglass_top
                                      : Icons.edit,
                                ),
                                label: Text(
                                  isUpdatingThisUser
                                      ? "Guardando..."
                                      : "Editar",
                                ),
                                onPressed: isUpdatingThisUser
                                    ? null
                                    : () => _editUser(user, token),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.grey.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.block),
                                label: Text(
                                  isBlockingThisUser
                                      ? "Procesando..."
                                      : (status == "bloqueado"
                                          ? "Desbloquear"
                                          : "Bloquear"),
                                ),
                                onPressed: isBlockingThisUser
                                    ? null
                                    : () async {
                                        try {
                                          setState(() {
                                            actionUserId = userId;
                                            actionType = "block";
                                          });

                                          final newStatus =
                                              status == "bloqueado"
                                                  ? "activo"
                                                  : "bloqueado";

                                          await adminService.blockUser(
                                            token,
                                            userId,
                                            newStatus,
                                          );

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                newStatus == "bloqueado"
                                                    ? "Cliente bloqueado correctamente"
                                                    : "Cliente desbloqueado correctamente",
                                              ),
                                            ),
                                          );

                                          setState(() {
                                            refreshKey++;
                                          });
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Error al cambiar estado: $e",
                                              ),
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              actionUserId = null;
                                              actionType = null;
                                            });
                                          }
                                        }
                                      },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.delete),
                                label: Text(
                                  isDeletingThisUser
                                      ? "Eliminando..."
                                      : "Eliminar",
                                ),
                                onPressed: isDeletingThisUser
                                    ? null
                                    : () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text("Confirmar eliminación"),
                                            content: Text(
                                              "¿Deseas eliminar a ${user["name"] ?? "este cliente"}?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text("Cancelar"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text("Eliminar"),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm != true) return;

                                        try {
                                          setState(() {
                                            actionUserId = userId;
                                            actionType = "delete";
                                          });

                                          await adminService.deleteUser(
                                            token,
                                            userId,
                                          );

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Cliente eliminado correctamente",
                                              ),
                                            ),
                                          );

                                          setState(() {
                                            refreshKey++;
                                          });
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Error al eliminar: $e",
                                              ),
                                            ),
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              actionUserId = null;
                                              actionType = null;
                                            });
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterButton(String value, String label) {
    final bool selected = filter == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.green : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : const Color(0xFF6A4BBE),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      onPressed: () {
        setState(() {
          filter = value;
        });
      },
      child: Text(label),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white70),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _dialogInputDecoration(label),
    );
  }

  void _editUser(Map user, String token) async {
    final nameController =
        TextEditingController(text: (user["name"] ?? "").toString());
    final emailController =
        TextEditingController(text: (user["email"] ?? "").toString());
    final phoneController =
        TextEditingController(text: (user["phone"] ?? "").toString());
    final addressController =
        TextEditingController(text: (user["address"] ?? "").toString());
    final usernameController =
        TextEditingController(text: (user["username"] ?? "").toString());

    String selectedStatus = (user["status"] ?? "activo").toString();
    final int userId = user["id"] as int;

    List<UbicacionModel> paises = [];
    List<UbicacionModel> nivel2List = [];
    List<UbicacionModel> nivel3List = [];
    List<UbicacionModel> nivel4List = [];

    int? selectedPaisId;
    int? selectedNivel2Id;
    int? selectedNivel3Id;
    int? selectedNivel4Id;

    final dynamic ubicacionRaw = user["ubicacionId"] ?? user["ubicacion_id"];
    final int? ubicacionFinal = ubicacionRaw is int
        ? ubicacionRaw
        : int.tryParse(ubicacionRaw?.toString() ?? "");

    try {
      paises = await ubicacionService.getPaises();

      if (ubicacionFinal != null) {
        final List<UbicacionModel> ruta =
            await ubicacionService.getRuta(ubicacionFinal);

        if (ruta.isNotEmpty) {
          if (ruta.length >= 1) {
            selectedPaisId = ruta[0].id;
            nivel2List = await ubicacionService.getHijos(selectedPaisId!);
          }

          if (ruta.length >= 2) {
            selectedNivel2Id = ruta[1].id;
            nivel3List = await ubicacionService.getHijos(selectedNivel2Id!);
          }

          if (ruta.length >= 3) {
            selectedNivel3Id = ruta[2].id;
            nivel4List = await ubicacionService.getHijos(selectedNivel3Id!);
          }

          if (ruta.length >= 4) {
            selectedNivel4Id = ruta[3].id;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo cargar la ubicación actual: $e"),
        ),
      );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasNivel4 = nivel4List.isNotEmpty;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4A3F).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Editar Cliente",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Actualiza la información general y la ubicación del cliente.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildEditField(
                        controller: usernameController,
                        label: "Usuario",
                        enabled: false,
                      ),
                      const SizedBox(height: 12),
                      _buildEditField(
                        controller: nameController,
                        label: "Nombre completo",
                      ),
                      const SizedBox(height: 12),
                      _buildEditField(
                        controller: emailController,
                        label: "Correo electrónico",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      _buildEditField(
                        controller: phoneController,
                        label: "Teléfono",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildEditField(
                        controller: addressController,
                        label: "Dirección exacta / señas",
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        dropdownColor: const Color(0xFF5B4A3F),
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration("Estado"),
                        items: const [
                          DropdownMenuItem(
                            value: "activo",
                            child: Text("Activo"),
                          ),
                          DropdownMenuItem(
                            value: "bloqueado",
                            child: Text("Bloqueado"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Ubicación",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedPaisId,
                        dropdownColor: const Color(0xFF5B4A3F),
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration("País"),
                        items: paises.map<DropdownMenuItem<int>>((pais) {
                          return DropdownMenuItem<int>(
                            value: pais.id,
                            child: Text(pais.nombre),
                          );
                        }).toList(),
                        onChanged: (value) async {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPaisId = value;
                            selectedNivel2Id = null;
                            selectedNivel3Id = null;
                            selectedNivel4Id = null;
                            nivel2List = [];
                            nivel3List = [];
                            nivel4List = [];
                          });

                          try {
                            final hijos = await ubicacionService.getHijos(value);
                            setDialogState(() {
                              nivel2List = hijos;
                            });
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error cargando provincias: $e"),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedNivel2Id,
                        dropdownColor: const Color(0xFF5B4A3F),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _dialogInputDecoration("Provincia / Departamento"),
                        items: nivel2List.map<DropdownMenuItem<int>>((item) {
                          return DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.nombre),
                          );
                        }).toList(),
                        onChanged: selectedPaisId == null
                            ? null
                            : (value) async {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedNivel2Id = value;
                                  selectedNivel3Id = null;
                                  selectedNivel4Id = null;
                                  nivel3List = [];
                                  nivel4List = [];
                                });

                                try {
                                  final hijos =
                                      await ubicacionService.getHijos(value);
                                  setDialogState(() {
                                    nivel3List = hijos;
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error cargando cantones: $e",
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedNivel3Id,
                        dropdownColor: const Color(0xFF5B4A3F),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _dialogInputDecoration("Cantón / Municipio"),
                        items: nivel3List.map<DropdownMenuItem<int>>((item) {
                          return DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.nombre),
                          );
                        }).toList(),
                        onChanged: selectedNivel2Id == null
                            ? null
                            : (value) async {
                                if (value == null) return;

                                setDialogState(() {
                                  selectedNivel3Id = value;
                                  selectedNivel4Id = null;
                                  nivel4List = [];
                                });

                                try {
                                  final hijos =
                                      await ubicacionService.getHijos(value);
                                  setDialogState(() {
                                    nivel4List = hijos;
                                  });
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error cargando distritos: $e",
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedNivel4Id,
                        dropdownColor: const Color(0xFF5B4A3F),
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _dialogInputDecoration("Distrito / Localidad"),
                        items: nivel4List.map<DropdownMenuItem<int>>((item) {
                          return DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(item.nombre),
                          );
                        }).toList(),
                        onChanged: nivel4List.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedNivel4Id = value;
                                });
                              },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasNivel4
                            ? "Selecciona el distrito o localidad final."
                            : "Si no existe nivel 4, se usará el cantón o municipio como ubicación final.",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text("Cancelar"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final name = nameController.text.trim();
                                      final email = emailController.text.trim();
                                      final phone = phoneController.text.trim();
                                      final address = addressController.text.trim();

                                      if (name.isEmpty ||
                                          email.isEmpty ||
                                          phone.isEmpty ||
                                          address.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Todos los campos son obligatorios",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (selectedPaisId == null ||
                                          selectedNivel2Id == null ||
                                          selectedNivel3Id == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Debes seleccionar la ubicación completa",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final int ubicacionIdFinal =
                                          selectedNivel4Id ?? selectedNivel3Id!;

                                      try {
                                        setDialogState(() {
                                          saving = true;
                                        });

                                        setState(() {
                                          actionUserId = userId;
                                          actionType = "update";
                                        });

                                        await adminService.updateUser(
                                          token: token,
                                          id: userId,
                                          name: name,
                                          email: email,
                                          phone: phone,
                                          address: address,
                                          status: selectedStatus,
                                          ubicacionId: ubicacionIdFinal,
                                        );

                                        if (!mounted) return;

                                        Navigator.pop(dialogContext);

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Cliente actualizado correctamente",
                                            ),
                                          ),
                                        );

                                        setState(() {
                                          refreshKey++;
                                        });
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Error al actualizar: $e",
                                            ),
                                          ),
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() {
                                            actionUserId = null;
                                            actionType = null;
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD1A054),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                saving ? "Guardando..." : "Guardar",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}  