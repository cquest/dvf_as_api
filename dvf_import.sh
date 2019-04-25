TABLE=dvf

psql -c "create table $TABLE (
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
)"

for f in valeursfoncieres-*.gz
do
    echo $f
    zcat $f | sed 's/,\([0-9]\)/.\1/g' | psql -c "copy $TABLE from stdin with (format csv, delimiter '|', header true)"
done

psql -c "
-- remise en forme du code INSEE de la commune
update $TABLE set code_commune = code_departement || right('000'||code_commune,3) where code_departement<'970';
update $TABLE set code_commune = code_departement || right('00'||code_commune,2) where code_departement>'970';

-- remise en forme du code postal
update $TABLE set code_postal = lpad(code_postal,5,'0');

-- remise en forme du code parcelle
update $TABLE set numero_plan = code_commune || lpad(coalesce(prefixe_section,''),3,'0')  || lpad(section,2,'0') || lpad(numero_plan,4,'0');

-- remise en forme des dates au format ISO (AAAA-MM-JJ)
update $TABLE set date_mutation = regexp_replace(date_mutation, '(..)/(..)/(....)','\3-\2-\1' ) where date_mutation ~ '../../....';

create index on $TABLE (numero_plan);
create index on $TABLE (code_postal);
create index on $TABLE (code_commune);

"
