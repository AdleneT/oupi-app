import '../domain/ports/clock.dart';

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// Horloge réglable, pour les tests et les démonstrations.
class FakeClock implements Clock {
  FakeClock(this.current);
  DateTime current;
  @override
  DateTime now() => current;
}
