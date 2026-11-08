# Oupi · appli Flutter

Prototype de l’appli éducative Oupi pour les 3-5 ans (iOS et Android). Le design de référence est le GDD du 4 nov. 2026 et le dashboard du projet : https://claude.ai/artifact/MPjhKJcUmb2bVg5JeqAoaa

## Lancer

```sh
flutter pub get
flutter test          # règles, catalogue, contrôle parental, parcours d’accueil
flutter run           # sur l’émulateur Android ou un appareil branché
```

Outils installés sur ce PC : Flutter dans `C:\dev\flutter`, Java 17 dans `C:\dev\jdk-17`, SDK Android dans `%LOCALAPPDATA%\Android\Sdk`. Le projet est dans un chemin sans espace ni accent, car Gradle plante souvent sinon sous Windows.

Sur le Mac : Flutter stable dans `~/development/flutter` (ajouter `export PATH="$HOME/development/flutter/bin:$PATH"` au `~/.zshrc`), Xcode 26 et le simulateur iPhone. Pas de CocoaPods : les plugins iOS passent par Swift Package Manager (`flutter config --enable-swift-package-manager`). Le SDK Android n'est pas encore installé sur le Mac.

## Architecture hexagonale

Le domaine ne dépend ni de Flutter ni du stockage. Les écrans ne parlent qu'à `AppState`, qui appelle des cas d'usage, qui parlent à des ports. Les adaptateurs ne sont branchés qu'au démarrage, dans `main.dart`.

```
lib/
├── domain/                      Dart pur, testable sans Flutter
│   ├── entities/                Episode, Catalog, ParentalSettings, ViewingHistory, Interactions
│   ├── rules/                   ViewingRules (verrou > dodo > limite), ParentGateChallenge
│   ├── ports/                   CatalogRepository, SettingsRepository, HistoryRepository, Clock
│   └── usecases/                BootstrapApp, StartEpisode, FinishEpisode, UpdateSettings, ResetApp, ScreenTimeReport
├── application/                 AppState (façade ChangeNotifier pour les widgets), AppScope
├── infrastructure/              adaptateurs des ports
│   ├── assets/                  AssetCatalogRepository + mapping JSON
│   ├── persistence/             SharedPrefs{Settings,History}Repository (mêmes clés que le prototype)
│   ├── memory/                  dépôts en mémoire pour les tests
│   └── clock.dart               SystemClock, FakeClock
├── presentation/                écrans, widgets, thème, navigation, responsive.dart
└── main.dart                    racine de composition
```

Règles de dépendance : `presentation → application → domain ← infrastructure`. Rien dans `domain/` n'importe `package:flutter`. Pour changer de stockage (fichier, base locale, nuage) ou de source de catalogue (en ligne), on écrit un nouvel adaptateur et on le branche dans `main.dart` : les écrans et les règles ne bougent pas.

## Responsive

Chaque écran se construit à partir de `Layout` (`lib/presentation/responsive.dart`) et d'un `LayoutBuilder` : tailles en proportion de la hauteur et de la largeur, jamais en pixels fixes.

- `Layout.screenClass` (compact, medium, expanded) selon le côté le plus court, `isPortrait`, `isNarrow`.
- `Layout.scale` met les tailles à l'échelle (1 sur un iPhone à l'horizontale, jusqu'à 1,5 sur grand écran) ; `textScale` agrandit doucement les textes sur tablette en respectant le réglage d'accessibilité.
- `characterHeight()` borne un personnage par la hauteur **et** la largeur disponibles.
- Les rangées deviennent des colonnes quand l'écran est étroit (`AdaptiveFlex`) ; les listes horizontales deviennent des grilles en portrait ; le rail de l'espace parents devient une rangée d'onglets.
- `test/responsive_test.dart` monte chaque écran sur huit tailles d'écran (téléphones, tablettes, portrait, grand écran) et échoue au moindre débordement.


## Ce que fait le prototype

| Écran (GDD §9) | Fichier | État |
|---|---|---|
| Onboarding parent | `lib/presentation/screens/onboarding_screen.dart` | Philosophie, visionnage accompagné, limite par jour et heure du dodo |
| Accueil | `lib/presentation/screens/home_screen.dart` | Oupi qui respire, 3 gros boutons sans texte, accès parents discret |
| Épisodes | `lib/presentation/screens/episodes_screen.dart` | Vignettes rangées par couleur de thème, pousse sur les vus, cadenas doux |
| Lecteur | `lib/presentation/screens/player_screen.dart` | Plein écran, un bouton pause, pas de barre de progression, pauses tactiles |
| Écran de repos | `lib/presentation/screens/rest_screen.dart` | Ciel étoilé, aucun autre épisode, bouton maison discret |
| Musique | `lib/presentation/screens/music_screen.dart` | Juke-box pour les abonnés, cadenas en gratuit |
| Galerie souvenirs | `lib/presentation/screens/gallery_screen.dart` | État vide pour l’instant |
| Contrôle parental | `lib/presentation/screens/parent_gate_screen.dart` | « Écris en chiffres : quarante-sept » |
| Espace parents | `lib/presentation/screens/parent_space_screen.dart` | Temps d’écran, activités, repères, abonnement, réglages |
| Il fait dodo | `lib/presentation/screens/sleep_screen.dart` | Limite atteinte ou heure du dodo |

**Règles appliquées** (`lib/domain/rules/viewing_rules.dart`, couvertes par les tests) :
- 1 épisode par jour par défaut (réglable de 1 à 3), compté au lancement.
- L’appli dort de 19 h (réglable de 17 h à 21 h) jusqu’à 7 h.
- Un épisode abonné ouvre « Oups ! Demande à papa ou maman », puis le contrôle parental, jamais un écran d’achat.
- Aucune lecture automatique : après un épisode, Oupi dort.

## Ce qui est simulé

- **Les épisodes :** aucune vidéo n’existe encore. Sans vidéo (`"video": null` dans le catalogue), le lecteur affiche une maquette minutée qui suit la structure du GDD. L’épisode 4 déclenche la vraie pause tactile de son fichier d’interactions (à 2:13). L’espace parents propose une lecture ×10 pour tester vite.
- **L’abonnement :** l’écran est réel, le paiement non. « Commencer l’essai » simule l’abonnement. Les achats intégrés (`in_app_purchase`) restent à brancher.
- **Les voix, chansons et boucles vidéo d’Oupi :** à venir. L’accueil utilise l’image de la planche.

## Données

- `assets/data/catalog.json` : les 10 épisodes. Il sera aussi publié en ligne pour ajouter des épisodes sans mettre à jour l’appli.
- `assets/data/interactions/ep04.json` : pauses tactiles et zones à toucher de l’épisode 4.
- Tout l’état reste sur l’appareil (`shared_preferences`) : aucun compte, aucun SDK de mesure ou de publicité.
- Polices Fredoka et Nunito embarquées (licence SIL OFL, `assets/fonts/`) : aucune requête vers un serveur tiers.

## Prochaines étapes

1. Brancher une vraie vidéo d’épisode, dès que le pilote existe.
2. Ajout des photos au mur des trésors (appareil photo, stockage local).
3. Achats intégrés et restauration.
4. Catalogue en ligne et téléchargement des épisodes pour le hors ligne.
5. Voix d’Oupi sur les écrans (« Oups ! Demande à papa ou maman », « Il fait dodo »).
