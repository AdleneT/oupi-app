/// Réglages choisis par le parent (GDD §10). Objet-valeur immuable.
class ParentalSettings {
  const ParentalSettings({
    this.onboardingDone = false,
    int dailyLimit = defaultDailyLimit,
    this.sleepHour = defaultSleepHour,
    this.premium = false,
    this.sound = true,
    this.fastPlayback = false,
  }) : dailyLimit = dailyLimit < minDailyLimit
            ? minDailyLimit
            : dailyLimit > maxDailyLimit
                ? maxDailyLimit
                : dailyLimit;

  static const minDailyLimit = 1;
  static const maxDailyLimit = 3;
  static const defaultDailyLimit = 1;
  static const defaultSleepHour = 19;
  static const sleepHourChoices = [17, 18, 19, 20, 21];

  /// Heure du réveil : l'appli dort entre l'heure du dodo et 7 h.
  static const wakeHour = 7;

  static const defaults = ParentalSettings();

  final bool onboardingDone;

  /// Épisodes par jour, toujours entre [minDailyLimit] et [maxDailyLimit].
  final int dailyLimit;
  final int sleepHour;

  /// Prototype : simule l'abonnement. Les vrais achats intégrés viendront avec `in_app_purchase`.
  final bool premium;
  final bool sound;

  /// Mode test du prototype : la maquette d'épisode défile dix fois plus vite.
  final bool fastPlayback;

  /// L'appli dort de l'heure du dodo jusqu'à [wakeHour].
  bool isSleepTime(DateTime at) => at.hour >= sleepHour || at.hour < wakeHour;

  ParentalSettings copyWith({
    bool? onboardingDone,
    int? dailyLimit,
    int? sleepHour,
    bool? premium,
    bool? sound,
    bool? fastPlayback,
  }) =>
      ParentalSettings(
        onboardingDone: onboardingDone ?? this.onboardingDone,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        sleepHour: sleepHour ?? this.sleepHour,
        premium: premium ?? this.premium,
        sound: sound ?? this.sound,
        fastPlayback: fastPlayback ?? this.fastPlayback,
      );

  @override
  bool operator ==(Object other) =>
      other is ParentalSettings &&
      other.onboardingDone == onboardingDone &&
      other.dailyLimit == dailyLimit &&
      other.sleepHour == sleepHour &&
      other.premium == premium &&
      other.sound == sound &&
      other.fastPlayback == fastPlayback;

  @override
  int get hashCode => Object.hash(onboardingDone, dailyLimit, sleepHour, premium, sound, fastPlayback);
}
