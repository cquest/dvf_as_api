#! /bin/bash

MILLESIME=$1

psql -c "create table dvf_tmp (
    code_service_ch text,
    reference_document text,
    articles_1 text,
    articles_2 text,
    articles_3 text,
    articles_4 text,
    articles_5 text,
    numero_disposition text,
    date_mutation text,
    nature_mutation text,
    valeur_fonciere float,
    numero_voie text,
    suffixe_numero text,
    type_voie text,
    code_voie text,
    voie text,
    code_postal text,
    Commune text,
    code_departement text,
    code_commune text,
    prefixe_section text,
    Section text,
    numero_plan text,
    numero_volume text,
    lot_1 text,
    surface_lot_1 float,
    lot_2 text,
    surface_lot_2 float,
    lot_3 text,
    surface_lot_3 float,
    lot_4 text,
    surface_lot_4 float,
    lot_5 text,
    surface_lot_51 float,
    nombre_lots text,
    code_type_local text,
    type_local text,
    identifiant_local text,
    surface_relle_bati float,
    nombre_pieces_principales int,
    Nature_culture text,
    Nature_culture_speciale text,
    Surface_terrain float
);"

# import des données DVF (fichiers dgfip)
for f in data/valeursfoncieres-*.gz
do
    echo "Import $f"
    zcat $f | sed 's/,\([0-9]\)/.\1/g' | psql -c "copy dvf_tmp from stdin with (format csv, delimiter '|', header true)"
done

psql -c "
-- remise en forme des code_commune, code_postal, et numero_plan
update dvf_tmp set (code_commune, code_postal, numero_plan) =
   ( code_departement || right('000'||code_commune,3),
     lpad(code_postal,5,'0'),
     code_departement || right('000'||code_commune,3) || lpad(coalesce(prefixe_section,''),3,'0')  || lpad(section,2,'0') || lpad(numero_plan,4,'0'))
where code_departement<'970';

update dvf_tmp set (code_commune, code_postal, numero_plan) =
   ( code_departement || right('000'||code_commune,2),
     lpad(code_postal,5,'0'),
     code_departement || right('000'||code_commune,2) || lpad(coalesce(prefixe_section,''),3,'0')  || lpad(section,2,'0') || lpad(numero_plan,4,'0'))
where code_departement>'970';

-- remise en forme des dates au format ISO (AAAA-MM-JJ)
update dvf_tmp set date_mutation = regexp_replace(date_mutation, '(..)/(..)/(....)','\3-\2-\1' ) where date_mutation ~ '../../....';
"

# import des localisations de parcelles (fichiers etalab)
psql -c "CREATE TABLE dvf_parcelles_tmp (id text, lon float, lat float)"
for f in data/*-full.csv.gz
do
    zcat $f | csvcut -c id_parcelle,longitude,latitude | psql -c "COPY dvf_parcelles_tmp FROM stdin WITH (FORMAT csv, header true)"
done

# dédoublonnage parcelles
psql -c "
CREATE TABLE dvf_parcelles_$MILLESIME AS SELECT id, lon, lat FROM dvf_parcelles_tmp GROUP BY 1,2,3 ORDER BY id;
DROP TABLE dvf_parcelles_tmp;
CREATE INDEX ON dvf_parcelles_$MILLESIME USING brin(id); -- index BRIN car table trié sur id de parcelle
-- ajout géométrie postgis et index
ALTER TABLE dvf_parcelles_$MILLESIME ADD geom geometry(point);
UPDATE dvf_parcelles_$MILLESIME SET geom = ST_MakePoint(lon,lat);
CREATE INDEX ON dvf_parcelles_$MILLESIME USING spgist (geom);

-- table dvf_geo
CREATE TABLE dvf_geo_$MILLESIME AS SELECT d.*, lat, lon FROM dvf_tmp d LEFT JOIN dvf_parcelles_$MILLESIME p ON (id=numero_plan) order by numero_plan;
DROP TABLE dvf_tmp;

create index on dvf_geo_$MILLESIME using spgist (numero_plan);
create index on dvf_geo_$MILLESIME using spgist (code_postal);

-- vues pour le millésime courant
CREATE OR REPLACE VIEW dvf_geo AS SELECT * FROM dvf_geo_$MILLESIME;
CREATE OR REPLACE VIEW dvf_parcelles AS SELECT * FROM dvf_parcelles_$MILLESIME;

"
