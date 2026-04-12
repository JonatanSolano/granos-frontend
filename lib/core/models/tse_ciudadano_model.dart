class TseCiudadanoModel {
  final String cedula;
  final String nombreCompleto;
  final String? fechaNacimiento;
  final String provincia;
  final String canton;
  final String distrito;
  final String domicilioElectoral;
  final String centroVotacion;

  const TseCiudadanoModel({
    required this.cedula,
    required this.nombreCompleto,
    required this.fechaNacimiento,
    required this.provincia,
    required this.canton,
    required this.distrito,
    required this.domicilioElectoral,
    required this.centroVotacion,
  });

  factory TseCiudadanoModel.fromJson(Map<String, dynamic> json) {
    return TseCiudadanoModel(
      cedula: (json["cedula"] ?? "").toString(),
      nombreCompleto: (json["nombreCompleto"] ?? json["nombre_completo"] ?? "")
          .toString(),
      fechaNacimiento:
          json["fechaNacimiento"]?.toString() ??
          json["fecha_nacimiento"]?.toString(),
      provincia: (json["provincia"] ?? "").toString(),
      canton: (json["canton"] ?? "").toString(),
      distrito: (json["distrito"] ?? "").toString(),
      domicilioElectoral:
          (json["domicilioElectoral"] ?? json["domicilio_electoral"] ?? "")
              .toString(),
      centroVotacion:
          (json["centroVotacion"] ?? json["centro_votacion"] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "cedula": cedula,
      "nombreCompleto": nombreCompleto,
      "fechaNacimiento": fechaNacimiento,
      "provincia": provincia,
      "canton": canton,
      "distrito": distrito,
      "domicilioElectoral": domicilioElectoral,
      "centroVotacion": centroVotacion,
    };
  }

  TseCiudadanoModel copyWith({
    String? cedula,
    String? nombreCompleto,
    String? fechaNacimiento,
    String? provincia,
    String? canton,
    String? distrito,
    String? domicilioElectoral,
    String? centroVotacion,
  }) {
    return TseCiudadanoModel(
      cedula: cedula ?? this.cedula,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      provincia: provincia ?? this.provincia,
      canton: canton ?? this.canton,
      distrito: distrito ?? this.distrito,
      domicilioElectoral: domicilioElectoral ?? this.domicilioElectoral,
      centroVotacion: centroVotacion ?? this.centroVotacion,
    );
  }

  @override
  String toString() {
    return '''
TseCiudadanoModel(
  cedula: $cedula,
  nombreCompleto: $nombreCompleto,
  fechaNacimiento: $fechaNacimiento,
  provincia: $provincia,
  canton: $canton,
  distrito: $distrito,
  domicilioElectoral: $domicilioElectoral,
  centroVotacion: $centroVotacion
)
''';
  }
}