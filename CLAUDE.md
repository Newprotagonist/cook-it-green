# Cook It Green — contexte projet

App Rails 8 mono-utilisateur (PWA) qui génère un **menu vegan annuel calibré au
gramme** : 16 semaines de rotation, 48 plats, une session de cuisine de 3 h par semaine.

Nom définitif : **Cook It Green** (domaine `cookitgreen.com` acheté). Le module Rails
(`CookItGreen`) et le chemin d'image ghcr.io (`cook-it-green`) sont renommés ; seul le
dossier physique sur disque s'appelle encore `batch_cooking`, à renommer à la main
(`mv`, puis rouvrir l'éditeur et les terminaux ouverts dessus).

Langue du projet : **français**, code compris (noms de recettes, commentaires, UI, commits).

---

## Le principe, en trois phrases

Midi et soir visent **exactement la même cible** de macronutriments, ce qui rend les trois
plats d'une semaine totalement interchangeables. Chaque recette a une base fixe (légumes,
aromates, matière grasse de cuisson) et **trois leviers** — un apport protéique, un apport
glucidique, une matière grasse — dont un solveur détermine le grammage. Rien n'est en dur :
cibles, répartition, constantes de calcul, bornes de grammage et rotation sont des
enregistrements en base, éditables depuis l'interface.

## Convention nutritionnelle — à ne jamais enfreindre

Convention française, celle des étiquettes européennes :

- **les glucides sont donnés HORS fibres** (`carb` = glucides nets) ;
- `kcal = 4·P + 9·L + 4·G + 2·F`.

Toute valeur saisie ou importée doit respecter cette convention. Les tables américaines
(USDA) comptent souvent les fibres dans les glucides : il faut les soustraire à l'import.

Les cibles sont des **minimums**, jamais des objectifs à atteindre pile. Dépasser est
acceptable, passer dessous ne l'est pas — c'est toute la logique du solveur.

---

## Architecture

```
app/services/nutrition/macros.rb            objet-valeur, kcal dérivées
app/services/nutrition/solver.rb            recherche exhaustive bornée
app/services/nutrition/needs_calculator.rb  Mifflin-St Jeor / Katch-McArdle
app/services/menu/resolver.rb               applique le solveur à une recette
app/services/menu/recalculator.rb           48 plats + 24 recettes fixes, persistés
app/services/menu/week.rb                   planning, liste de courses, session de 3 h
app/services/menu/calendar.rb               place une date dans la rotation
```

### Le solveur

Il parcourt **toute** la grille des grammages admissibles au pas de 5 g, plutôt que de
résoudre un système linéaire. Ce n'est pas de la naïveté : l'espace est assez petit
(~800 ms pour les 72 recettes), et l'optimum est garanti même quand un levier sature sa
borne. Une résolution linéaire, elle, produit des solutions absurdes dans ce cas — la
première version dérapait à +46 g de glucides sur un seul plat.

La pénalité sur les écarts **négatifs** est ×40. C'est ce qui fait qu'à 36,3 g de cible et
un pas de 5 g, le solveur choisit 40 et non 35. Ne pas « simplifier » cette asymétrie.

### Le calcul des besoins

`Goal#protein_g_per_kg` stocke une recommandation **omnivore**. La majoration végétale
(`NutritionSetting#plant_protein_multiplier`, ×1,15) s'applique **une seule fois**, dans
`NeedsCalculator`. Stocker des valeurs déjà majorées a produit 2,53 g/kg en perte de gras —
bug corrigé, verrouillé par deux tests de non-régression. Ne pas réintroduire.

### Ce qui est éditable en base

62 bornes de grammage (`ingredients.min_grams` / `max_grams`), 6 lignes de répartition
(`meal_shares`), 7 constantes (`nutrition_settings`), la rotation (`week_patterns`), les
portions par rôle (`role_portions`). **Chacun de ces réglages peut casser l'invariant des
112 journées.** Le contrôle ne tourne qu'au recalcul — d'où la suite de tests.

---

## Commandes

```bash
bin/dev                 # Puma + Tailwind, http://localhost:3000
bin/rails test          # 47 tests, ~3 s
bin/rubocop             # doit rester à zéro offense
bin/rails db:seed       # idempotent, recharge db/seeds/menu_definitions.json
```

Identifiants de développement (`.env`, non versionné) : `batch` / `cooking`.

**Après un `db:reset`, aller sur `/cibles` et cliquer « Recalculer les 16 semaines ».**
Sans ça aucun grammage n'existe et les écrans de semaine redirigent vers les cibles.

---

## Pattern « Rails single-user PWA »

Repris de Move the Spark (mémoire `pattern_rails_single_user_pwa` du projet
`~/code/Newprotagonist/planner`). Les trois points suivants viennent de vrais bugs :
ne pas les « nettoyer ».

- **Pas de modèle `User`, pas de Devise.** Un identifiant partagé protège l'app via
  `http_basic_authenticate_with`, gardé par `ENV["BASIC_AUTH_USER"].present?` et **non**
  par `Rails.env.production?`, pour que le même chemin de code soit exerçable en local.
  Les routes internes à Rails (`/up`, manifeste, service worker) n'héritent pas
  d'`ApplicationController` et doivent rester joignables sans auth.
- **Exclusions `/up`** sur `force_ssl` et `host_authorization` : Kamal interroge la sonde
  en HTTP simple depuis le réseau Docker privé, un 301 casse le déploiement sans coupure.
- **`ApplicationHelper::ICON_VERSION`** ajouté en `?v=N` à chaque URL d'icône. Sans lui,
  les icônes mises à jour n'atteignent jamais les caches navigateur, OS et notifications.

**Écart assumé :** le pattern prescrit la gem `webpush`. Elle n'est plus maintenue et sa
génération de clés VAPID échoue sur OpenSSL 3 (`pkeys are immutable`). Ce projet utilise
`web-push`, le successeur maintenu — namespace `WebPush`.

---

## Pièges rencontrés

- `frozen` est un nom de colonne **interdit** par Active Record (`DangerousAttributeError`).
  D'où `week_patterns.from_freezer`.
- Les bases SQLite vivent dans `storage/` en Rails 8, pas dans `db/`.
- Kamal ne charge pas `.env` : les secrets doivent être exportés dans le shell à chaque
  invocation.

---

## État au 3 septembre 2026

*Section transitoire — à élaguer au fur et à mesure.*

Commit initial `c187327` (170 fichiers). L'app tourne en local, 112 journées validées,
0 sous un minimum, résolution en ~800 ms. Suite de 47 tests verte, rubocop clean.

**Non committé :** les 6 fichiers de test et la modification de `test/test_helper.rb`.
C'est la première chose à faire.

### Corrigé — semaine 12 (état « plat d'assemblage »)

La salade niçoise (`E12C`) était programmée jusqu'au dimanche (J+7) alors qu'elle n'était
garantie que 3 jours au frais et marquée non congelable — l'été comptait 5 plats non
congelables pour 4 semaines, donc une semaine en portait forcément deux.

Correction : `dishes.storage_mode` (`congelable` / `frais` / `assemblage`) remplace
l'ancien booléen `freezable`. E12C passe en `assemblage` — tout le plat se congèle sauf
l'avocat (`dish_components.assembled_fresh`), ajouté frais à chaque service. `Dish#freezable?`
reste vrai pour ce mode, donc `Menu::Week#roles` la traite comme congelable sans changement
de logique. `Menu::InvariantTest::KNOWN_STORAGE_VIOLATIONS` est repassé à `[]`.

### Fils ouverts

1. **UI mobile**, étroitement : les deux seuls écrans utilisés loin d'un bureau sont la
   liste de courses (au magasin) et le planning (dans la cuisine). Ce sont aujourd'hui des
   tableaux larges pensés pour un ordinateur. Plus l'installation sur l'écran d'accueil.
2. **Corriger la mémoire du pattern** (`webpush` → `web-push`) dans le projet `planner`,
   sinon la prochaine app retombe dans le même mur OpenSSL 3.
3. **Plage calorique.** Le menu couvre environ 1 600–2 600 kcal. Au-delà, les bornes de
   grammage ne suivent plus (un homme de 85 kg en prise de masse demande 516 g de glucides).
   À trancher : élargir les bornes — c'est un changement de **données**, pas de code — ou
   ajouter une 5ᵉ prise au-delà d'un seuil.
4. **Nom acquis : « Cook It Green »**, domaine `cookitgreen.com` acheté (2026-09-04).
   Module Rails et image ghcr.io renommés (2026-09-05). Reste seulement le dossier
   physique sur disque (`batch_cooking`), à renommer à la main.
5. **Sauvegarde hors serveur** du volume SQLite, à régler *avant* toute mise en ligne.
   Ce point a été reporté puis oublié sur Move the Spark.
6. **Deux modes, à terme : batch cooking et daily cooking.** Aujourd'hui toute l'app
   suppose une session unique de 3 h par semaine et une rotation figée sur 16 semaines —
   la notion même de rôles F/A/B (`Menu::Week#roles`) n'a de sens qu'en batch. Chantier
   de fond, pas encore cadré : reste à décider si les deux modes partagent les mêmes
   recettes et la même cible nutritionnelle, ou si le quotidien a sa propre rotation.
   Implique `Nutrition::Solver`, `Menu::Recalculator` et `Menu::Week` a minima.

### Déploiement — en cours de préparation

Le blocage « pas de domaine » est levé (`cookitgreen.com` acheté). `service` et `image`
de `config/deploy.yml` sont renommés ; `<ip-du-serveur>` et `<utilisateur-github>`
restent à remplir (l'utilisateur a un serveur Docker déjà prêt). Ne pas lancer `kamal`
sans accord explicite à chaque fois — consigne qui reste valable même le gabarit rempli.

**Décision du 2026-09-05 :** la sauvegarde SQLite hors serveur (fils ouverts, point 5)
sera réglée *après* le premier déploiement, pas avant — écart assumé à la recommandation
du gabarit lui-même, qui rappelle que ce report a été oublié sur Move the Spark. À ne
pas oublier une deuxième fois.

---

## Conventions de travail

- Lancer `bin/rails test` et `bin/rubocop` avant tout commit.
- Toute modification du solveur, des bornes ou de la répartition doit laisser
  `Menu::InvariantTest` vert : c'est la seule garantie qui compte.
- Messages de commit en français, corps explicatif sur le *pourquoi*.
