/// Port : l'heure courante. Les règles (dodo, limite du jour) ne lisent jamais `DateTime.now()` directement.
abstract interface class Clock {
  DateTime now();
}
