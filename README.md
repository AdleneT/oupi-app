# Oupi · appli Flutter

Prototype de l’appli éducative Oupi pour les 3-5 ans (iOS et Android). Le design de référence est le GDD du 4 nov. 2026 et le dashboard du projet : https://claude.ai/artifact/MPjhKJcUmb2bVg5JeqAoaa

## Lancer

```sh
flutter pub get
flutter test          # règles, catalogue, contrôle parental, parcours d’accueil
flutter run           # sur l’émulateur Android ou un appareil branché
```

Outils installés sur ce PC : Flutter dans `C:\dev\flutter`, Java 17 dans `C:\dev\jdk-17`, SDK Android dans `%LOCALAPPDATA%\Android\Sdk`. Le projet est dans un chemin sans espace ni accent, car Gradle plante souvent sinon sous Windows.

## Ce que fait le prototype

| Écran (GDD §9) | Fichier | État |
|---|---|---|
| Onboarding parent | `lib/screens/onboarding_screen.dart` | Philosophie, visionnage accompagné, limite par jour et heure du dodo |
| Accueil | `lib/screens/home_screen.dart` | Oupi qui respire, 3 gros boutons sans texte, accès parents discret |
| Épisodes | `lib/screens/episodes_screen.dart` | Vignettes rangées par couleur de thème, pousse sur les vus, cadenas doux |
| Lecteur | `lib/screens/player_screen.dart` | Plein écran, un bouton pause, pas de barre de progression, pauses tactiles |
| Écran de repos | `lib/screens/rest_screen.dart` | Ciel étoilé, aucun autre épisode, bouton maison discret |
| Musique | `lib/screens/music_screen.dart` | Juke-box pour les abonnés, cadenas en gratuit |
| Galerie souvenirs | `lib/screens/gallery_screen.dart` | État vide pour l’instant |
| Contrôle parental | `lib/screens/parent_gate_screen.dart` | « Écris en chiffres : quarante-sept » |
| Espace parents | `lib/screens/parent_space_screen.dart` | Temps d’écran, activités, repères, abonnement, réglages |
| Il fait dodo | `lib/screens/sleep_screen.dart` | Limite atteinte ou heure du dodo |

**Règles appliquées** (`lib/state/app_state.dart`, couvertes par les tests) :
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
