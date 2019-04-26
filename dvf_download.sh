#! /bin/bash

mkdir -p data
cd data
# Téléchargement des fichiers DVF
for ANNEE in $(seq 2014 2018)
do
  wget -nc http://data.cquest.org/dgfip_dvf/valeursfoncieres-$ANNEE.txt.gz
  wget -nc https://cadastre.data.gouv.fr/data/hackathon-dgfip-dvf/contrib/etalab-csv/$ANNEE/full.csv.gz -O $ANNEE-full.csv.gz
done
