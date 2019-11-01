# micro-API DVF

Ce projet implémente une API minimale pour requêter les données DVF de la DGFiP stockées dans une base locale postgresql.

## Installation

`pip install -r requirements.txt`

## Chargement des données

Téléchargement des données :

`./dvf_download.sh`

Import des données dans postgresql :

`./dvf_import.sh`

## Lancement du serveur

`gunicorn dvf_as_api:app -b 0.0.0.0:8888`

## Paramètres reconnus par l'API

*(les liens interrogent une version publique de l'API sur api.cquest.org, sans garantie de disponibilité)*

Sélection des transactions par commune, section, parcelle:
- code_commune: http://api.cquest.org/dvf?code_commune=89304
- section: http://api.cquest.org/dvf?section=89304000ZB
- numero_plan: http://api.cquest.org/dvf?section=89304000ZB0134

Le résultat est au format JSON.

Sélection par proximité géographique:
- distance de 100m: http://api.cquest.org/dvf?lat=48.85&lon=2.35&dist=100
- distance par défaut de 500m: http://api.cquest.org/dvf?lat=48.85&lon=2.35

Filtres possibles:
- nature_mutation: Vente, Expropriation, etc...
- type_local: Maison, Appartement, Local, Dépendance

Exemple de ventes de maisons sur une commune:

http://api.cquest.org/dvf?code_commune=89304&nature_mutation=Vente&type_local=Maison

