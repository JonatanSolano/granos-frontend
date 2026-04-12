class UbicacionModel {
  final int id;
  final String nombre;
  final int nivel;
  final String tipoSistema;
  final String tipoReal;
  final int? idPadre;
  final String? paisCodigo;
  final String? codigoOficial;
  final bool activo;

  UbicacionModel({
    required this.id,
    required this.nombre,
    required this.nivel,
    required this.tipoSistema,
    required this.tipoReal,
    this.idPadre,
    this.paisCodigo,
    this.codigoOficial,
    required this.activo,
  });

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'activo' ||
          normalized == 'yes';
    }
    return false;
  }

  factory UbicacionModel.fromJson(Map<String, dynamic> json) {
    return UbicacionModel(
      id: _toInt(json['id']),
      nombre: (json['nombre'] ?? '').toString(),
      nivel: _toInt(json['nivel']),
      tipoSistema: (json['tipoSistema'] ?? json['tipo_sistema'] ?? '')
          .toString(),
      tipoReal: (json['tipoReal'] ?? json['tipo_real'] ?? '').toString(),
      idPadre: _toNullableInt(json['idPadre'] ?? json['id_padre']),
      paisCodigo:
          (json['paisCodigo'] ?? json['pais_codigo'])?.toString(),
      codigoOficial:
          (json['codigoOficial'] ?? json['codigo_oficial'])?.toString(),
      activo: _toBool(json['activo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'nivel': nivel,
      'tipoSistema': tipoSistema,
      'tipoReal': tipoReal,
      'idPadre': idPadre,
      'paisCodigo': paisCodigo,
      'codigoOficial': codigoOficial,
      'activo': activo,
    };
  }

  UbicacionModel copyWith({
    int? id,
    String? nombre,
    int? nivel,
    String? tipoSistema,
    String? tipoReal,
    int? idPadre,
    String? paisCodigo,
    String? codigoOficial,
    bool? activo,
  }) {
    return UbicacionModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      nivel: nivel ?? this.nivel,
      tipoSistema: tipoSistema ?? this.tipoSistema,
      tipoReal: tipoReal ?? this.tipoReal,
      idPadre: idPadre ?? this.idPadre,
      paisCodigo: paisCodigo ?? this.paisCodigo,
      codigoOficial: codigoOficial ?? this.codigoOficial,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() {
    return 'UbicacionModel('
        'id: $id, '
        'nombre: $nombre, '
        'nivel: $nivel, '
        'tipoSistema: $tipoSistema, '
        'tipoReal: $tipoReal, '
        'idPadre: $idPadre, '
        'paisCodigo: $paisCodigo, '
        'codigoOficial: $codigoOficial, '
        'activo: $activo'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UbicacionModel &&
        other.id == id &&
        other.nombre == nombre &&
        other.nivel == nivel &&
        other.tipoSistema == tipoSistema &&
        other.tipoReal == tipoReal &&
        other.idPadre == idPadre &&
        other.paisCodigo == paisCodigo &&
        other.codigoOficial == codigoOficial &&
        other.activo == activo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        nivel.hashCode ^
        tipoSistema.hashCode ^
        tipoReal.hashCode ^
        idPadre.hashCode ^
        paisCodigo.hashCode ^
        codigoOficial.hashCode ^
        activo.hashCode;
  }
}