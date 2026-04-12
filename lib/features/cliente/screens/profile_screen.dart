import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/ubicacion_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/ubicacion_service.dart';
import 'package:granos_la_tradicion/features/cliente/widgets/client_base_layout.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  final _totpCodeController = TextEditingController();
  final _disableTotpCodeController = TextEditingController();

  final UbicacionService _ubicacionService = UbicacionService();

  int? _question1Id;
  int? _question2Id;

  int? _paisId;
  int? _provinciaId;
  int? _cantonId;
  int? _distritoId;

  List<UbicacionModel> _paises = [];
  List<UbicacionModel> _provincias = [];
  List<UbicacionModel> _cantones = [];
  List<UbicacionModel> _distritos = [];

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _savingSecurity = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loadingLocations = false;
  bool _loadingProfileData = true;

  bool _loadingTotpStatus = false;
  bool _settingUpTotp = false;
  bool _confirmingTotp = false;
  bool _disablingTotp = false;

  bool _totpEnabled = false;
  bool _totpPendingSetup = false;

  String? _totpQrDataUrl;
  String? _totpManualKey;
  String? _totpMessage;

  List<Map<String, dynamic>> questions = [
    {"id": 1, "question": "¿Nombre de tu primera mascota?"},
    {"id": 2, "question": "¿Ciudad donde naciste?"},
    {"id": 3, "question": "¿Nombre de tu mejor amigo de infancia?"},
    {"id": 4, "question": "¿Nombre de tu primera escuela?"},
    {"id": 5, "question": "¿Comida favorita en tu niñez?"},
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _loadInitialData();
    _loadSecurityQuestions();
    _loadTotpStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    _totpCodeController.dispose();
    _disableTotpCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();

    await auth.refreshProfile();
    final user = auth.currentUser;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';
    _addressController.text = user?.address ?? '';
    _totpEnabled = user?.totpEnabled ?? false;

    await _loadPaises();

    if (user?.ubicacionId != null) {
      await _preloadLocationRoute(user!.ubicacionId!);
    }

    if (!mounted) return;
    setState(() {
      _loadingProfileData = false;
    });
  }

  Future<void> _loadSecurityQuestions() async {
    final auth = context.read<AuthProvider>();
    final result = await auth.getSecurityQuestions();

    if (!mounted) return;

    if (result.isNotEmpty) {
      setState(() {
        questions = result;
      });
    }
  }

  Future<void> _loadTotpStatus() async {
    setState(() {
      _loadingTotpStatus = true;
    });

    final auth = context.read<AuthProvider>();
    final result = await auth.getTotpStatus();

    if (!mounted) return;

    setState(() {
      _loadingTotpStatus = false;

      if (result["success"] == true) {
        _totpEnabled = result["totpEnabled"] == true;
        _totpPendingSetup = result["pendingSetup"] == true;
      } else {
        _totpMessage = result["error"]?.toString();
      }
    });
  }

  Future<void> _loadPaises() async {
    setState(() => _loadingLocations = true);

    final paises = await _ubicacionService.getPaises();

    if (!mounted) return;

    setState(() {
      _paises = paises;
      _loadingLocations = false;
    });
  }

  Future<void> _onPaisChanged(int? value) async {
    setState(() {
      _paisId = value;
      _provinciaId = null;
      _cantonId = null;
      _distritoId = null;
      _provincias = [];
      _cantones = [];
      _distritos = [];
      _loadingLocations = true;
    });

    if (value == null) {
      setState(() => _loadingLocations = false);
      return;
    }

    final provincias = await _ubicacionService.getHijos(value);

    if (!mounted) return;

    setState(() {
      _provincias = provincias;
      _loadingLocations = false;
    });
  }

  Future<void> _onProvinciaChanged(int? value) async {
    setState(() {
      _provinciaId = value;
      _cantonId = null;
      _distritoId = null;
      _cantones = [];
      _distritos = [];
      _loadingLocations = true;
    });

    if (value == null) {
      setState(() => _loadingLocations = false);
      return;
    }

    final cantones = await _ubicacionService.getHijos(value);

    if (!mounted) return;

    setState(() {
      _cantones = cantones;
      _loadingLocations = false;
    });
  }

  Future<void> _onCantonChanged(int? value) async {
    setState(() {
      _cantonId = value;
      _distritoId = null;
      _distritos = [];
      _loadingLocations = true;
    });

    if (value == null) {
      setState(() => _loadingLocations = false);
      return;
    }

    final distritos = await _ubicacionService.getHijos(value);

    if (!mounted) return;

    setState(() {
      _distritos = distritos;
      _loadingLocations = false;
    });
  }

  int? _resolveUbicacionFinal() {
    if (_distritos.isNotEmpty && _distritoId != null) {
      return _distritoId;
    }

    if (_cantonId != null) {
      return _cantonId;
    }

    return null;
  }

  Future<void> _preloadLocationRoute(int ubicacionId) async {
    final path = await _ubicacionService.getRuta(ubicacionId);
    if (path.isEmpty) return;

    final pais = path.isNotEmpty ? path[0] : null;
    final provincia = path.length > 1 ? path[1] : null;
    final canton = path.length > 2 ? path[2] : null;
    final distrito = path.length > 3 ? path[3] : null;

    if (pais != null) {
      final provincias = await _ubicacionService.getHijos(pais.id);
      _paisId = pais.id;
      _provincias = provincias;
    }

    if (provincia != null) {
      final cantones = await _ubicacionService.getHijos(provincia.id);
      _provinciaId = provincia.id;
      _cantones = cantones;
    }

    if (canton != null) {
      final distritos = await _ubicacionService.getHijos(canton.id);
      _cantonId = canton.id;
      _distritos = distritos;
    }

    if (distrito != null) {
      _distritoId = distrito.id;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _saveProfile(AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    if (_paisId == null || _provinciaId == null || _cantonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar país, provincia y cantón/municipio"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_distritos.isNotEmpty && _distritoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar distrito/localidad"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ubicacionFinal = _resolveUbicacionFinal();

    if (ubicacionFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar una ubicación final válida"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingProfile = true);

    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      ubicacionId: ubicacionFinal,
    );

    if (!mounted) return;

    setState(() => _savingProfile = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Perfil actualizado correctamente'
              : (auth.loginError ?? 'Error al actualizar perfil'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _changePassword(AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingPassword = true);

    final result = await auth.changePassword(
      _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _savingPassword = false);

    final success = result["success"] == true;

    if (success) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Contraseña actualizada correctamente'
              : (result["error"] ?? 'Error al cambiar contraseña'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveSecurityAnswers(AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    if (!_securityFormKey.currentState!.validate()) {
      return;
    }

    if (_question1Id == null ||
        _question2Id == null ||
        _answer1Controller.text.trim().isEmpty ||
        _answer2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe completar las preguntas de seguridad"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_question1Id == _question2Id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe seleccionar dos preguntas diferentes"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _savingSecurity = true);

    final result = await auth.updateSecurityAnswers([
      {
        "questionId": _question1Id,
        "answer": _answer1Controller.text.trim(),
      },
      {
        "questionId": _question2Id,
        "answer": _answer2Controller.text.trim(),
      },
    ]);

    if (!mounted) return;

    setState(() => _savingSecurity = false);

    final success = result["success"] == true;

    if (success) {
      _answer1Controller.clear();
      _answer2Controller.clear();
      setState(() {
        _question1Id = null;
        _question2Id = null;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Preguntas de seguridad actualizadas correctamente'
              : (result["error"] ?? 'Error al actualizar preguntas'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _startTotpSetup(AuthProvider auth) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _settingUpTotp = true;
      _totpMessage = null;
    });

    final result = await auth.setupTotp();

    if (!mounted) return;

    setState(() {
      _settingUpTotp = false;

      if (result["success"] == true) {
        _totpQrDataUrl = result["qrDataUrl"]?.toString();
        _totpManualKey = result["manualKey"]?.toString();
        _totpPendingSetup = result["pendingSetup"] == true;
        _totpMessage = result["message"]?.toString();
      } else {
        _totpMessage = result["error"]?.toString();
      }
    });
  }

  Future<void> _confirmTotp(AuthProvider auth) async {
    final code = _totpCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe ingresar el código de Google Authenticator"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _confirmingTotp = true;
      _totpMessage = null;
    });

    final result = await auth.confirmTotp(code);

    if (!mounted) return;

    setState(() {
      _confirmingTotp = false;

      if (result["success"] == true) {
        _totpEnabled = true;
        _totpPendingSetup = false;
        _totpQrDataUrl = null;
        _totpManualKey = null;
        _totpCodeController.clear();
        _totpMessage = result["message"]?.toString();
      } else {
        _totpMessage = result["error"]?.toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result["success"] == true
              ? 'Google Authenticator activado correctamente'
              : (result["error"] ?? 'Error activando Google Authenticator'),
        ),
        backgroundColor:
            result["success"] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _disableTotp(AuthProvider auth) async {
    final code = _disableTotpCodeController.text.trim();

    if (_totpEnabled && code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debe ingresar el código actual de Google Authenticator",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _disablingTotp = true;
      _totpMessage = null;
    });

    final result = await auth.disableTotp(code);

    if (!mounted) return;

    setState(() {
      _disablingTotp = false;

      if (result["success"] == true) {
        _totpEnabled = false;
        _totpPendingSetup = false;
        _totpQrDataUrl = null;
        _totpManualKey = null;
        _totpCodeController.clear();
        _disableTotpCodeController.clear();
        _totpMessage = result["message"]?.toString();
      } else {
        _totpMessage = result["error"]?.toString();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result["success"] == true
              ? 'Google Authenticator desactivado correctamente'
              : (result["error"] ?? 'Error desactivando Google Authenticator'),
        ),
        backgroundColor:
            result["success"] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (_loadingProfileData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no encontrado')),
      );
    }

    return Scaffold(
      body: ClientBaseLayout(
        title: "Mi Perfil",
        showBackButton: true,
        backRoute: '/cliente',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _buildProfileCard(auth, user),
                const SizedBox(height: 20),
                _buildPasswordCard(auth),
                const SizedBox(height: 20),
                _buildSecurityCard(auth),
                const SizedBox(height: 20),
                _buildTotpCard(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AuthProvider auth, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Form(
        key: _profileFormKey,
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _inputField(
              controller: _emailController,
              label: 'Correo electrónico',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese su correo';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Correo inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _nameController,
              label: 'Nombre',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingrese su nombre'
                  : null,
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _phoneController,
              label: 'Teléfono',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese su teléfono';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                  return "Solo números permitidos";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLocationDropdown(
              label: "País",
              value: _paisId,
              items: _paises,
              onChanged: _onPaisChanged,
            ),
            const SizedBox(height: 16),
            _buildLocationDropdown(
              label: "Provincia / Departamento",
              value: _provinciaId,
              items: _provincias,
              onChanged: _paisId == null ? null : _onProvinciaChanged,
            ),
            const SizedBox(height: 16),
            _buildLocationDropdown(
              label: "Cantón / Municipio",
              value: _cantonId,
              items: _cantones,
              onChanged: _provinciaId == null ? null : _onCantonChanged,
            ),
            const SizedBox(height: 16),
            if (_distritos.isNotEmpty)
              _buildLocationDropdown(
                label: "Distrito / Localidad",
                value: _distritoId,
                items: _distritos,
                onChanged: _cantonId == null
                    ? null
                    : (value) {
                        setState(() {
                          _distritoId = value;
                        });
                      },
              ),
            if (_distritos.isNotEmpty) const SizedBox(height: 16),
            _inputField(
              controller: _addressController,
              label: 'Dirección exacta / señas',
              maxLines: 2,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingrese su dirección'
                  : null,
            ),
            if (_loadingLocations) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Colors.white),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _savingProfile ? null : () => _saveProfile(auth),
                child: _savingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar cambios del perfil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Form(
        key: _passwordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cambiar contraseña",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _newPasswordController,
              label: 'Nueva contraseña',
              obscure: _obscurePassword,
              toggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese una nueva contraseña';
                }
                if (value.trim().length < 8) {
                  return 'Mínimo 8 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _passwordField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              obscure: _obscureConfirm,
              toggle: () {
                setState(() {
                  _obscureConfirm = !_obscureConfirm;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Confirme la contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _savingPassword ? null : () => _changePassword(auth),
                child: _savingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Actualizar contraseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
        ),
      ),
      child: Form(
        key: _securityFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Actualizar preguntas de seguridad",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuestionDropdown(
              label: "Pregunta 1",
              value: _question1Id,
              excludedId: _question2Id,
              onChanged: (value) {
                setState(() {
                  _question1Id = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _answer1Controller,
              label: "Respuesta",
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingrese la respuesta'
                  : null,
            ),
            const SizedBox(height: 20),
            _buildQuestionDropdown(
              label: "Pregunta 2",
              value: _question2Id,
              excludedId: _question1Id,
              onChanged: (value) {
                setState(() {
                  _question2Id = value;
                });
              },
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _answer2Controller,
              label: "Respuesta",
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingrese la respuesta'
                  : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    _savingSecurity ? null : () => _saveSecurityAnswers(auth),
                child: _savingSecurity
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar preguntas de seguridad'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotpCard(AuthProvider auth) {
    final hasQr = _totpQrDataUrl != null && _totpQrDataUrl!.isNotEmpty;
    Uint8List? qrBytes;

    if (hasQr) {
      try {
        final base64Part = _totpQrDataUrl!.split(',').last;
        qrBytes = base64Decode(base64Part);
      } catch (_) {
        qrBytes = null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            "Google Authenticator",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingTotpStatus)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: Text(
                _totpEnabled
                    ? "Estado: Activado"
                    : (_totpPendingSetup
                        ? "Estado: Configuración pendiente"
                        : "Estado: Desactivado"),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_totpMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _totpMessage!.toLowerCase().contains("error") ||
                        _totpMessage!.toLowerCase().contains("inválido")
                    ? Colors.red.shade400
                    : Colors.green.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _totpMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (!_totpEnabled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    _settingUpTotp ? null : () => _startTotpSetup(auth),
                child: _settingUpTotp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Activar Google Authenticator"),
              ),
            ),
          ],
          if (hasQr && qrBytes != null) ...[
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Image.memory(
                  qrBytes,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
          if (_totpManualKey != null && _totpManualKey!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "Clave manual",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                ),
              ),
              child: SelectableText(
                _totpManualKey!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ],
          if (_totpPendingSetup && !_totpEnabled) ...[
            const SizedBox(height: 20),
            _inputField(
              controller: _totpCodeController,
              label: "Código de Google Authenticator",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.25),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _confirmingTotp ? null : () => _confirmTotp(auth),
                child: _confirmingTotp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Confirmar activación"),
              ),
            ),
          ],
          if (_totpEnabled) ...[
            const SizedBox(height: 20),
            _inputField(
              controller: _disableTotpCodeController,
              label: "Código actual de Google Authenticator",
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _disablingTotp ? null : () => _disableTotp(auth),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _disablingTotp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Desactivar Google Authenticator",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDropdown({
    required String label,
    required int? value,
    required List<UbicacionModel> items,
    required FutureOr<void> Function(int?)? onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
      ),
      iconEnabledColor: Colors.white70,
      items: items
          .map(
            (item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(
                item.nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged == null
          ? null
          : (value) {
              onChanged(value);
            },
    );
  }

  Widget _buildQuestionDropdown({
    required String label,
    required int? value,
    required int? excludedId,
    required Function(int?) onChanged,
  }) {
    final filteredQuestions = questions.where((q) {
      final id = q["id"] as int;
      return id != excludedId || id == value;
    }).toList();

    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      menuMaxHeight: 300,
      dropdownColor: Colors.black87,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
      ),
      iconEnabledColor: Colors.white70,
      items: filteredQuestions
          .map(
            (q) => DropdownMenuItem<int>(
              value: q["id"] as int,
              child: Text(
                q["question"].toString(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }
}