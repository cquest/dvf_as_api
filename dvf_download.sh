#! /bin/bash

MILLESIME=$1

mkdir -p data
cd data
# Téléchargement des fichiers DVF
for ANNEE in $(seq 2014 2019)
do
  wget -N http://data.cquest.org/dgfip_dvf/$MILLESIME/valeursfoncieres-$ANNEE.txt.gz
  wget -N https://cadastre.data.gouv.fr/data/etalab-dvf/$MILLESIME/csv/$ANNEE/full.csv.gz -O $ANNEE-full.csv.gz
done
