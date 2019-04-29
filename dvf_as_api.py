#! /usr/bin/python3

# modules additionnels
import falcon
import psycopg2

class dgfip_dvf(object):
    def getDVF(self, req, resp):
        ## connexion à la base PG locale
        db = psycopg2.connect("")
        cur = db.cursor()

        where = ''
        where2 = b''

        code_postal = req.params.get('code_postal', None)
        if code_postal and len(code_postal) == 5:
            where = cur.mogrify(' AND code_postal = %s ', (code_postal,))

        code_commune = req.params.get('code_commune', None)
        if code_commune and len(code_commune) == 5:
            where = cur.mogrify(' AND numero_plan LIKE %s ', (code_commune+'%',))

        section = req.params.get('section', None)
        if section and len(section) >= 10:
            where = cur.mogrify(' AND numero_plan LIKE %s ', (section+'%',))

        numero_plan = req.params.get('numero_plan', None)
        # on veut à minima le code commune (5 caractères)
        if numero_plan and len(numero_plan) >= 5:
            if len(numero_plan) == 14:  ## id parcelle complet
                where = cur.mogrify(
                    ' AND numero_plan = %s ', (numero_plan,))
            else:
                where = cur.mogrify(
                    ' AND numero_plan LIKE %s ', (numero_plan+'%',))

        nature_mutation = req.params.get('nature_mutation', None)
        if nature_mutation:
            where2 = where2 + \
                cur.mogrify(' AND nature_mutation = %s ', (nature_mutation,))

        type_local = req.params.get('type_local', None)
        if type_local and type_local != '':
            where2 = where2 + \
                cur.mogrify(' AND type_local like %s ', (type_local+'%',))

        lat = req.params.get('lat', None)
        lon = req.params.get('lon', None)
        dist = int(req.params.get('dist',500))
        if dist > 1000:
            dist = 1000

        if lat and lon:
            query = cur.mogrify("""select
                json_build_object('source', 'DGFIP / Demande de Valeurs Foncières',
                    'derniere_maj', '2019-04',
                    'licence', 'http://data.cquest.org/dgfip_dvf/conditions-generales-dutilisation.pdf',
                    'type','Featurecollection',
                    'features', case when count(*)=0 then array[]::json[] else array_agg(json_build_object('type','Feature',
                                                           'properties',json_strip_nulls(row_to_json(d)),
                                                           'geometry',st_asgeojson(geom,6,0)::json)) end )::text
                from dvf_parcelles p
                join dvf_geo d on (id=numero_plan)
                where st_buffer(st_setsrid(st_makepoint(%s, %s),4326)::geography, %s)::geometry && geom
                    and ST_DWithin(st_setsrid(st_makepoint(%s, %s),4326)::geography, geom::geography, %s)
                
             """, (lon, lat, dist, lon, lat, dist)) + where2
        else:
            query = None

        if query or where != '':
            if not query:
                query = """select json_build_object('source', 'DGFIP / Demande de Valeurs Foncières',
    'derniere_maj', '2019-04',
    'licence', 'http://data.cquest.org/dgfip_dvf/conditions-generales-dutilisation.pdf',
    'nb_resultats', count(r),
    'resultats',array_to_json(array_agg(r)))::text
from (select *
    from
        dvf_geo
    where true """ + where.decode('utf8') + where2.decode('utf8') + """ ) r
"""
            print(query)
            cur.execute(query)
            dvf = cur.fetchone()

            resp.status = falcon.HTTP_200
            resp.set_header('X-Powered-By', 'dvf_as_api')
            resp.set_header('Access-Control-Allow-Origin', '*')
            resp.set_header("Access-Control-Expose-Headers","Access-Control-Allow-Origin")
            resp.set_header('Access-Control-Allow-Headers','Origin, X-Requested-With, Content-Type, Accept')
            resp.set_header('X-Robots-Tag', 'noindex, nofollow')
            resp.body = dvf[0]
        else:
            resp.status = falcon.HTTP_413
            resp.body = '{"erreur": "aucun critère de recherche indiqué"}'

        db.close()

    def on_get(self, req, resp):
        self.getDVF(req, resp);



# instance WSGI
app = falcon.API()

# route vers notre API
app.add_route('/dvf', dgfip_dvf())
