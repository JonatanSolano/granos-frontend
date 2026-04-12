import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/tse_ciudadano_model.dart';
import '../../../core/models/ubicacion_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/tse_service.dart';
import '../../../core/services/ubicacion_service.dart';
import '../../../core/widgets/app_layout.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _cedulaController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _answer1Controller = TextEditingController();
  final _answer2Controller = TextEditingController();

  final UbicacionService _ubicacionService = UbicacionService();
  final TseService _tseService = TseService();

  int? _question1Id;
  int? _question2Id;

  int? _paisId;
  int? _provinciaId;
  int? _cantonId;
  int? _distritoId;

  bool _isLoading = false;
  bool _loadingLocations = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _consultandoTse = false;
  bool _tseConsultaRealizada = false;
  bool _tseEncontrado = false;
  String? _tseMessage;

  List<UbicacionModel> _paises = [];
  List<UbicacionModel> _provincias = [];
  List<UbicacionModel> _cantones = [];
  List<UbicacionModel> _distritos = [];

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
    _loadSecurityQuestions();
    _loadPaises();
  }

  @override
  void dispose() {
    _cedulaController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _answer1Controller.dispose();
    _answer2Controller.dispose();
    super.dispose();
  }

  String _limpiarCedula(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '').trim();
  }

  String _normalizeText(String value) {
    const from = 'ÁÀÂÄÃáàâäãÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñ';
    const to = 'AAAAAaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNn';

    var result = value.trim().toLowerCase();

    for (int i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i].toLowerCase(), to[i].toLowerCase());
    }

    result = result.replaceAll(RegExp(r'\s+'), ' ');
    return result;
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

  void _resetUbicacionSeleccionada() {
    setState(() {
      _paisId = null;
      _provinciaId = null;
      _cantonId = null;
      _distritoId = null;
      _provincias = [];
      _cantones = [];
      _distritos = [];
    });
  }

  Future<void> _consultarCedulaTse() async {
    final cedula = _limpiarCedula(_cedulaController.text);

    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe ingresar la cédula antes de consultar"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cedula.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cédula ingresada no es válida"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _consultandoTse = true;
      _tseConsultaRealizada = false;
      _tseEncontrado = false;
      _tseMessage = null;
    });

    final result = await _tseService.consultarCedula(cedula);

    if (!mounted) return;

    if (result.success && result.ciudadano != null) {
      final TseCiudadanoModel ciudadano = result.ciudadano!;

      _nameController.text = ciudadano.nombreCompleto;
      _addressController.text = ciudadano.domicilioElectoral;

      await _aplicarUbicacionDesdeTse(
        provincia: ciudadano.provincia,
        canton: ciudadano.canton,
        distrito: ciudadano.distrito,
      );

      setState(() {
        _tseConsultaRealizada = true;
        _tseEncontrado = true;
        _tseMessage = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _nameController.clear();
      _addressController.clear();
      _resetUbicacionSeleccionada();

      setState(() {
        _tseConsultaRealizada = true;
        _tseEncontrado = false;
        _tseMessage = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.orange,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _consultandoTse = false;
    });
  }

  Future<void> _aplicarUbicacionDesdeTse({
    required String provincia,
    required String canton,
    required String distrito,
  }) async {
    if (_paises.isEmpty) {
      await _loadPaises();
    }

    final paisCostaRica = _paises.cast<UbicacionModel?>().firstWhere(
          (p) =>
              p != null &&
              _normalizeText(p.nombre) == _normalizeText("Costa Rica"),
          orElse: () => null,
        );

    if (paisCostaRica == null) {
      return;
    }

    await _onPaisChanged(paisCostaRica.id);

    final provinciaMatch = _provincias.cast<UbicacionModel?>().firstWhere(
          (p) =>
              p != null &&
              _normalizeText(p.nombre) == _normalizeText(provincia),
          orElse: () => null,
        );

    if (provinciaMatch == null) {
      if (mounted) {
        setState(() {
          _paisId = paisCostaRica.id;
        });
      }
      return;
    }

    await _onProvinciaChanged(provinciaMatch.id);

    final cantonMatch = _cantones.cast<UbicacionModel?>().firstWhere(
          (c) =>
              c != null && _normalizeText(c.nombre) == _normalizeText(canton),
          orElse: () => null,
        );

    if (cantonMatch == null) {
      if (mounted) {
        setState(() {
          _paisId = paisCostaRica.id;
          _provinciaId = provinciaMatch.id;
        });
      }
      return;
    }

    await _onCantonChanged(cantonMatch.id);

    if (_distritos.isNotEmpty) {
      final distritoMatch = _distritos.cast<UbicacionModel?>().firstWhere(
            (d) =>
                d != null &&
                _normalizeText(d.nombre) == _normalizeText(distrito),
            orElse: () => null,
          );

      if (mounted) {
        setState(() {
          _paisId = paisCostaRica.id;
          _provinciaId = provinciaMatch.id;
          _cantonId = cantonMatch.id;
          _distritoId = distritoMatch?.id;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _paisId = paisCostaRica.id;
          _provinciaId = provinciaMatch.id;
          _cantonId = cantonMatch.id;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final cedula = _limpiarCedula(_cedulaController.text);

    if (cedula.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe ingresar la cédula"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cedula.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("La cédula ingresada no es válida"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_tseConsultaRealizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe consultar la cédula en TSE antes de registrarse"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe completar todos los campos"),
          backgroundColor: Colors.red,
        ),
      );
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

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_question1Id == null ||
        _question2Id == null ||
        _answer1Controller.text.trim().isEmpty ||
        _answer2Controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debe completar las 2 preguntas de seguridad"),
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

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      cedula: cedula,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      password: _passwordController.text.trim(),
      ubicacionId: ubicacionFinal,
      tseConsultado: _tseConsultaRealizada,
      tseEncontrado: _tseEncontrado,
      securityQuestions: [
        {
          "id": _question1Id,
          "answer": _answer1Controller.text.trim(),
        },
        {
          "id": _question2Id,
          "answer": _answer2Controller.text.trim(),
        }
      ],
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      final errorMessage = auth.loginError ?? "Error al crear la cuenta";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tseEncontrado
              ? "Cuenta creada correctamente con validación TSE"
              : "Cuenta creada correctamente con datos ingresados manualmente",
        ),
        backgroundColor: Colors.green,
      ),
    );

    context.go('/login');
  }

  Widget _buildTseStatusCard() {
    if (!_tseConsultaRealizada) return const SizedBox.shrink();

    final bool ok = _tseEncontrado;
    final Color bgColor = ok
        ? Colors.green.withOpacity(0.18)
        : Colors.orange.withOpacity(0.18);
    final Color borderColor = ok
        ? Colors.green.withOpacity(0.45)
        : Colors.orange.withOpacity(0.45);
    final IconData icon = ok ? Icons.verified_user : Icons.edit_note;
    final String title = ok
        ? "Datos encontrados en TSE"
        : "No se encontró la cédula en TSE";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$title\n${_tseMessage ?? ''}${ok ? '' : '\nPuede continuar llenando el formulario manualmente.'}",
              style: const TextStyle(
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? screenWidth * 0.30 : 24.0;

    return AppLayout(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Registrarse",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      AuthTextField(
                        controller: _cedulaController,
                        label: "Cédula",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (_consultandoTse || _isLoading)
                              ? null
                              : _consultarCedulaTse,
                          icon: _consultandoTse
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.search,
                                  color: Colors.white,
                                ),
                          label: Text(
                            _consultandoTse
                                ? "Consultando TSE..."
                                : "Consultar cédula en TSE",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTseStatusCard(),
                      if (_tseConsultaRealizada) const SizedBox(height: 20),
                      AuthTextField(
                        controller: _nameController,
                        label: "Nombre completo",
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _emailController,
                        label: "Correo electrónico",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _phoneController,
                        label: "Teléfono",
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
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
                        onChanged:
                            _provinciaId == null ? null : _onCantonChanged,
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
                      if (_distritos.isNotEmpty) const SizedBox(height: 20),
                      AuthTextField(
                        controller: _addressController,
                        label: "Dirección exacta / señas",
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _passwordController,
                        label: "Contraseña",
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: _confirmController,
                        label: "Confirmar contraseña",
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Preguntas de seguridad",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
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
                      AuthTextField(
                        controller: _answer1Controller,
                        label: "Respuesta 1",
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
                      AuthTextField(
                        controller: _answer2Controller,
                        label: "Respuesta 2",
                      ),
                      const SizedBox(height: 28),
                      if (_loadingLocations)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Crear cuenta"),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      "¿Ya tienes cuenta? Iniciar Sesión",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.go('/login');
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Volver a Iniciar Sesión",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.7),
          ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.7),
          ),
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
}