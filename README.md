# micro-API DVF

Ce projet implémente une API minimale pour requêter les données DVF de la DGFiP stockées dans une base locale postgresql.

## Installation

`pip install -r requirements.txt`

## Lancement du serveur

`gunicorn dvf_as_api:app -b 0.0.0.0:8888`

## Paramètres reconnus par l'API

Sélection des transactions par commune, section, parcelle:
- code_commune: http://localhost:8888/dvf?code_commune=89304
- section: http://localhost:8888/dvf?section=94038000CQ
- numero_plan: http://localhost:8888/dvf?section=94038000CQ0110

Le résultat est au format JSON.

Sélection par proximité géographique:
- distance de 100m: http://localhost:8888/dvf?lat=48.85&lon=2.35&dist=100
- distance par défaut de 500m: http://localhost:8888/dvf?lat=48.85&lon=2.35

Filtres possibles:
- nature_mutation: Vente, Expropriation, etc...
- type_local: Maison, Appartement, Local, Dépendance

Exemple de ventes de maisons sur une commune:

http://localhost:8888/dvf?code_commune=89304&nature_mutation=Vente&type_local=Maison

