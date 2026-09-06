/// CurrencyFormatter
/// -----------------
/// Formateador único de moneda para toda la app (pesos colombianos).
/// Centralizado aquí para que Flights, Booking y cualquier módulo
/// futuro (Reservations, Profile) muestren el mismo formato exacto,
/// sin repetir la lógica de separadores de miles en cada widget.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formatea un valor numérico como pesos colombianos: 414000 -> "COP 414.000".
  static String cop(num value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i != 0 && remaining % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'COP $buffer';
  }
}
