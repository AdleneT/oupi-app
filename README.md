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
| Accueil | `lib/screens/home_screen.dart` | Toute la bande au parc en vidéo qui boucle (Oupi fait coucou et danse, Lala se balance, Totu sur le toboggan, Ibou salue), badges sans texte posés autour des personnages, accès parents discret |
| Épisodes | `lib/screens/episodes_screen.dart` | Cartes bonbons dans le parc, rangées par couleur de thème, pousse sur les vus, cadenas doux |
| Lecteur | `lib/screens/player_screen.dart` | Plein écran, un badge pause discret, pas de barre de progression, pauses tactiles |
| Écran de repos | `lib/screens/rest_screen.dart` | Parc de nuit, Oupi (et Lala) dorment sur un nuage, badge maison de nuit |
| Musique | `lib/screens/music_screen.dart` | Juke-box pour les abonnés, cadenas en gratuit. une vignette par chanson (carte blanche, personnage qui sort du cadre, titre, durée, badge lecture). « Les couleurs » (épisode 1) se joue d’un toucher ; les autres sont « Bientôt » |
| Exercices | `lib/screens/exercises_screen.dart` | Place réservée, « Bientôt, des jeux avec Oupi ! » |
| Galerie souvenirs | `lib/screens/gallery_screen.dart` | État vide pour l’instant |
| Contrôle parental | `lib/screens/parent_gate_screen.dart` | « Écris en chiffres : quarante-sept » |
| Espace parents | `lib/screens/parent_space_screen.dart` | Une couleur et un bandeau illustré par rubrique (temps d’écran, activités, mur des trésors, repères, pourquoi Oupi, abonnement, réglages) ; carte « Mode dodo » de nuit pour réveiller Oupi |
| Il fait dodo | `lib/screens/sleep_screen.dart` | Parc de nuit, Oupi dort sur un nuage qui flotte ; on n’en sort qu’avec le code parent |

**Design** : tous les écrans de l’enfant se passent dans le même parc en feutrine, de jour ou de nuit (`lib/widgets/scenery.dart`). Les boutons sont des badges illustrés qui flottent et rebondissent (`BadgeButton`, `lib/widgets/premium.dart`) ; les cartes ont la même finition (`CandyFace`, `lib/widgets/candy.dart`). Les visuels viennent de Higgsfield, à partir des planches validées ; les détourages se font avec `tool/Cutout.cs` (personnages sur fond clair), `tool/KeyCutout.cs` (fond uni) et `tool/DiffCutout.cs` (par différence avec le même décor sans personnages). Les vignettes de chansons (`lib/widgets/song_art.dart`) suivent la maquette de l’utilisateur : carte blanche, décor dans la fenêtre, personnage détouré qui sort par le haut et danse pendant la chanson, titre, durée et badge lecture ; `test/render_song_art_test.dart` en tire un PNG. Les images générées que l’appli n’utilise plus sont rangées dans `design/assets-hors-appli/`, hors de l’appli.

Les écrans parents (onboarding, espace parents) suivent la charte du dashboard : fond crème, abricot, sauge et bleu des yeux d’Oupi, titres en Fredoka, texte en Nunito, cartes à ombre chaude et couture en pointillés de la feutrine. Leurs briques sont dans `lib/widgets/parent_ui.dart` (cartes, pastilles de choix, interrupteurs, tuiles de chiffres, avatar d’Oupi). Dans l’espace parents, chaque rubrique teinte tout l’écran de sa couleur et s’ouvre sur un bandeau en feutrine où Oupi (et parfois Lala) joue le thème (`assets/images/parent_*.jpg`, Seedream 5.0 Pro) ; à gauche, les couleurs relevées sur l’image prolongent le bandeau sous le titre.

**Règles appliquées** (`lib/state/app_state.dart`, couvertes par les tests) :
- 1 épisode par jour par défaut (réglable de 1 à 3), compté au lancement.
- L’appli dort de 19 h (réglable de 17 h à 21 h) jusqu’à 7 h, et aussi quand la limite du jour est atteinte. Pendant le dodo, l’enfant n’a plus accès aux menus ; le parent peut réveiller Oupi pour 30 min, 1 h ou 2 h depuis l’espace parents.
- Un épisode abonné ouvre « Oups ! Demande à papa ou maman », puis le contrôle parental, jamais un écran d’achat.
- Aucune lecture automatique : après un épisode, Oupi dort.

## Ce qui est simulé

- **Les épisodes :** aucune vidéo n’existe encore. Sans vidéo (`"video": null` dans le catalogue), le lecteur affiche une maquette minutée qui suit la structure du GDD. L’épisode 4 déclenche la vraie pause tactile de son fichier d’interactions (à 2:13). L’espace parents propose une lecture ×10 pour tester vite.
- **L’abonnement :** l’écran est réel, le paiement non. « Commencer l’essai » simule l’abonnement. Les achats intégrés (`in_app_purchase`) restent à brancher.
- **Les voix et chansons d’Oupi :** la voix est à venir. Première chanson : « Les couleurs » (Suno, fichier « Quelle est ta couleur », `assets/audio/`), jouée dans le juke-box et pendant la séquence Chanson de la maquette de l’épisode 1. La boucle vidéo de l’accueil existe (`assets/videos/home_bande.mp4`, 10 s, 2208 × 936) ; si l’appareil ne la lit pas, une scène animée dans l’appli prend le relais.

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
