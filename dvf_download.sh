#! /bin/bash

# Téléchargement des fichiers DVF
for ANNEE in $(seq 2014 2018)
do
  wget -nc http://data.cquest.org/dgfip_dvf/valeursfoncieres-$ANNEE.txt.gz
done
