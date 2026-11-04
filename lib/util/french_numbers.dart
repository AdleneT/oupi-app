const _units = [
  'zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf',
  'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize',
];

const _tens = {20: 'vingt', 30: 'trente', 40: 'quarante', 50: 'cinquante', 60: 'soixante'};

/// Écrit un nombre de 0 à 99 en toutes lettres, en français de France
/// (« soixante et onze », « quatre-vingts », « quatre-vingt-un »).
/// Sert au contrôle parental : « Écris en chiffres : quarante-sept ».
String frenchNumber(int n) {
  if (n < 0 || n > 99) throw RangeError.range(n, 0, 99, 'n');
  if (n <= 16) return _units[n];
  if (n < 20) return 'dix-${_units[n - 10]}';
  if (n < 70) {
    final base = _tens[n ~/ 10 * 10]!;
    final unit = n % 10;
    if (unit == 0) return base;
    if (unit == 1) return '$base et un';
    return '$base-${_units[unit]}';
  }
  if (n < 80) {
    final rest = n - 60;
    return rest == 11 ? 'soixante et onze' : 'soixante-${frenchNumber(rest)}';
  }
  final rest = n - 80;
  return rest == 0 ? 'quatre-vingts' : 'quatre-vingt-${frenchNumber(rest)}';
}
