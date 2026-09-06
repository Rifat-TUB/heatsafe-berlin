-- HeatSafe Berlin - database schema and pilot data
-- Runs automatically on first container start.

CREATE EXTENSION IF NOT EXISTS postgis;

-- ---------------------------------------------------------------
-- Table 1: cooling_places  (points)
-- ---------------------------------------------------------------
CREATE TABLE cooling_places (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    place_type  TEXT NOT NULL
                CHECK (place_type IN ('fountain','park','shade','indoor','water')),
    description TEXT,
    -- Where this row came from. Lets the map and the reader tell
    -- official open data apart from pilot points and user entries.
    data_source TEXT NOT NULL DEFAULT 'pilot_seed'
                CHECK (data_source IN ('pilot_seed','berlin_open_data','user_submitted')),
    geom        geometry(Point, 4326) NOT NULL
);

CREATE INDEX cooling_places_geom_idx ON cooling_places USING GIST (geom);

-- ---------------------------------------------------------------
-- Table 2: heat_zones  (polygons)
-- ---------------------------------------------------------------
CREATE TABLE heat_zones (
    id             SERIAL PRIMARY KEY,
    name           TEXT NOT NULL,
    risk_level     TEXT NOT NULL CHECK (risk_level IN ('high','medium','low')),
    temp_indicator NUMERIC(4,1),
    surface_type   TEXT,
    data_source    TEXT NOT NULL DEFAULT 'self_digitized',
    geom           geometry(Polygon, 4326) NOT NULL
);

CREATE INDEX heat_zones_geom_idx ON heat_zones USING GIST (geom);

-- ---------------------------------------------------------------
-- Table 3: emergency_services  (points)
--
-- Hospitals near the pilot area. Every row here comes from the
-- official Berlin hospital register, so no coordinate in this table
-- was placed by hand. That matters more here than anywhere else in
-- the project: a wrong hospital position is the one error in this
-- application that could actually put someone at risk.
-- ---------------------------------------------------------------
CREATE TABLE emergency_services (
    id           SERIAL PRIMARY KEY,
    name         TEXT NOT NULL,
    service_type TEXT NOT NULL
                 CHECK (service_type IN ('hospital')),
    address      TEXT,
    operator     TEXT,
    beds         INTEGER,
    data_source  TEXT NOT NULL DEFAULT 'berlin_open_data'
                 CHECK (data_source IN ('berlin_open_data')),
    geom         geometry(Point, 4326) NOT NULL
);

CREATE INDEX emergency_services_geom_idx ON emergency_services USING GIST (geom);

-- ---------------------------------------------------------------
-- Data set 1: pilot cooling places
-- The places themselves are real, but the coordinates were placed
-- by hand for this pilot and are approximate.
-- data_source falls back to its default value 'pilot_seed'.
-- ---------------------------------------------------------------
INSERT INTO cooling_places (name, place_type, description, geom) VALUES
    ('Neptunbrunnen', 'fountain', 'Grosser Brunnen am Rathaus mit Wasserflaeche und Sitzstufen',
     ST_SetSRID(ST_MakePoint(13.4064, 52.5195), 4326)),
    ('Weltzeituhr Brunnen', 'fountain', 'Wasserspiel am Alexanderplatz',
     ST_SetSRID(ST_MakePoint(13.4133, 52.5215), 4326)),
    ('Volkspark Friedrichshain', 'park', 'Grosser Park mit dichtem Baumbestand',
     ST_SetSRID(ST_MakePoint(13.4325, 52.5275), 4326)),
    ('Monbijoupark', 'park', 'Park an der Spree mit Schatten und Wasser',
     ST_SetSRID(ST_MakePoint(13.3960, 52.5235), 4326)),
    ('Lustgarten', 'park', 'Rasenflaeche mit Springbrunnen an der Museumsinsel',
     ST_SetSRID(ST_MakePoint(13.3985, 52.5185), 4326)),
    ('James-Simon-Park', 'park', 'Uferpark an der Spree',
     ST_SetSRID(ST_MakePoint(13.4020, 52.5225), 4326)),
    ('Alexanderplatz Trinkbrunnen', 'fountain', 'Oeffentlicher Trinkwasserbrunnen der Berliner Wasserbetriebe',
     ST_SetSRID(ST_MakePoint(13.4118, 52.5222), 4326)),
    ('Karl-Marx-Allee Baumallee', 'shade', 'Beschattete Allee mit Baumreihen',
     ST_SetSRID(ST_MakePoint(13.4270, 52.5205), 4326)),
    ('Rotes Rathaus Innenhof', 'shade', 'Beschatteter Innenhof',
     ST_SetSRID(ST_MakePoint(13.4085, 52.5175), 4326)),
    ('Berliner Dom Umgebung', 'shade', 'Schattenbereiche am Lustgarten',
     ST_SetSRID(ST_MakePoint(13.4010, 52.5190), 4326)),
    ('Bibliothek am Alexanderplatz', 'indoor', 'Oeffentlich zugaenglicher Innenraum',
     ST_SetSRID(ST_MakePoint(13.4145, 52.5238), 4326)),
    ('Galeria Kaufhof', 'indoor', 'Klimatisiertes Kaufhaus am Alexanderplatz',
     ST_SetSRID(ST_MakePoint(13.4128, 52.5205), 4326)),
    ('Spreeufer Jannowitzbruecke', 'water', 'Uferbereich an der Spree',
     ST_SetSRID(ST_MakePoint(13.4185, 52.5145), 4326)),
    ('Koppenplatz', 'park', 'Kleiner Nachbarschaftspark mit Baeumen',
     ST_SetSRID(ST_MakePoint(13.3985, 52.5285), 4326)),
    ('Hackescher Markt Gruenflaeche', 'shade', 'Kleine beschattete Flaeche',
     ST_SetSRID(ST_MakePoint(13.4025, 52.5245), 4326));

-- ---------------------------------------------------------------
-- Data: heat zones
--
-- SELF-DIGITIZED DATA. Every polygon below was drawn by hand in
-- geojson.io on top of satellite imagery for this pilot.
--
-- risk_level and temp_indicator are VISUAL ESTIMATES based on the
-- land cover that is visible from the air (sealed surface, tree
-- cover, water). They are NOT measured temperatures and NOT taken
-- from any official climate model or sensor network. They are meant
-- for relative comparison inside this pilot area only.
--
-- surface_type records what the dominant surface actually is, read
-- from the same imagery.
-- ---------------------------------------------------------------
INSERT INTO heat_zones (name, risk_level, temp_indicator, surface_type, data_source, geom) VALUES
    ('Rathausforum', 'high', 37.2, 'sealed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.407043 52.519206, 13.409455 52.519206, 13.409455 52.517687, 13.40665 52.517548, 13.406663 52.518442, 13.407043 52.519206))', 4326)),

    ('Alt Berlin', 'medium', 32.5, 'mixed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.408078 52.520317, 13.407502 52.51958, 13.40842 52.518632, 13.410507 52.518538, 13.410846 52.519481, 13.409619 52.519971, 13.408078 52.520317))', 4326)),

    ('Alexanderplatz Zentrum', 'high', 38.2, 'sealed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.409326 52.523281, 13.407775 52.522072, 13.412598 52.518991, 13.416349 52.52051, 13.413218 52.522295, 13.409326 52.523281))', 4326)),

    ('Spandauer Vorstadt', 'medium', 33.5, 'mixed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.395071 52.526287, 13.398504 52.526751, 13.402548 52.526024, 13.401505 52.523177, 13.394638 52.523734, 13.395071 52.526287))', 4326)),

    ('Spreeinsel Museumsinsel', 'high', 38.2, 'sealed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.391353 52.519817, 13.391091 52.515641, 13.399314 52.515737, 13.399995 52.520072, 13.395229 52.521124, 13.391353 52.519817))', 4326)),

    ('Volkspark Friedrichshain', 'low', 29.0, 'vegetated', 'self_digitized',
     ST_GeomFromText('POLYGON((13.425871 52.528677, 13.422676 52.525299, 13.431685 52.523769, 13.437551 52.524247, 13.442842 52.526796, 13.440118 52.529792, 13.433413 52.530525, 13.425871 52.528677))', 4326)),

    ('Strausberger Platz', 'medium', 33.8, 'mixed', 'self_digitized',
     ST_GeomFromText('POLYGON((13.425019 52.520512, 13.434883 52.51986, 13.43863 52.51544, 13.428919 52.513206, 13.421808 52.518162, 13.425019 52.520512))', 4326)),

    ('Neu-Coelln am Wasser', 'low', 30.7, 'water_adjacent', 'self_digitized',
     ST_GeomFromText('POLYGON((13.406873 52.513004, 13.415799 52.514701, 13.426151 52.511212, 13.412326 52.507968, 13.40705 52.508782, 13.406873 52.513004))', 4326));

-- ---------------------------------------------------------------
-- Data set 2: official drinking fountains (Trinkbrunnen)
--
-- Source : Berlin Open Data portal, daten.berlin.de
--          "Public drinking fountains in Friedrichshain-Kreuzberg"
--          Provider: District Office Friedrichshain-Kreuzberg of
--          Berlin - Surveying
-- License: Data License Germany - Attribution - Version 2.0
--          (dl-de-by-2.0)
-- Attribution text required by the license:
--          "Public drinking fountains in Friedrichshain-Kreuzberg"
--
-- The published file uses EPSG:25833 (ETRS89 / UTM zone 33N), where
-- coordinates are metres, not degrees. The numbers below are copied
-- unchanged from that file. PostGIS converts them to EPSG:4326 with
-- ST_Transform, so no coordinate was edited by hand.
--
-- Only fountains near the Alexanderplatz pilot area are loaded.
-- The dataset covers Friedrichshain-Kreuzberg, while Alexanderplatz
-- lies in Mitte, so most of its fountains fall outside this pilot.
-- ---------------------------------------------------------------
INSERT INTO cooling_places (name, place_type, description, data_source, geom) VALUES
    ('Trinkbrunnen Strausberger Platz', 'fountain',
     'Oeffentlicher Trinkbrunnen, Betriebszeit Mai bis Oktober',
     'berlin_open_data',
     ST_Transform(ST_SetSRID(ST_MakePoint(393432.806, 5819892.440), 25833), 4326)),

    ('Trinkbrunnen Volkspark Friedrichshain West', 'fountain',
     'Oeffentlicher Trinkbrunnen, Betriebszeit Mai bis Oktober',
     'berlin_open_data',
     ST_Transform(ST_SetSRID(ST_MakePoint(393695.211, 5820980.256), 25833), 4326)),

    ('Trinkbrunnen Karl-Marx-Allee', 'fountain',
     'Oeffentlicher Trinkbrunnen, Betriebszeit Mai bis Oktober',
     'berlin_open_data',
     ST_Transform(ST_SetSRID(ST_MakePoint(393969.336, 5819785.539), 25833), 4326)),

    ('Trinkbrunnen Bahnhof Berlin Ostbahnhof', 'fountain',
     'Oeffentlicher Trinkbrunnen, Betriebszeit Mai bis Oktober',
     'berlin_open_data',
     ST_Transform(ST_SetSRID(ST_MakePoint(393723.958, 5819102.658), 25833), 4326)),

    ('Trinkbrunnen Volkspark Friedrichshain Ost', 'fountain',
     'Oeffentlicher Trinkbrunnen, Betriebszeit Mai bis Oktober',
     'berlin_open_data',
     ST_Transform(ST_SetSRID(ST_MakePoint(394110.594, 5820902.686), 25833), 4326));

-- ---------------------------------------------------------------
-- Data set 3: hospitals near the pilot area
--
-- Source : Berlin Open Data portal, daten.berlin.de
--          "Krankenhaeuser", layer Plankrankenhaeuser
--          Provider: Senatsverwaltung fuer Wissenschaft,
--          Gesundheit, Pflege und Gleichstellung
-- License: Datenlizenz Deutschland - Zero - Version 2.0
--          (dl-de-zero-2.0). Attribution is not required by this
--          licence, but is given here anyway.
--
-- Downloaded straight from the WFS endpoint as GeoJSON in EPSG:4326,
-- so the coordinates below are copied unchanged and need no
-- ST_Transform. The WFS-Explorer export of the same layer returned
-- broken coordinates, which is why the raw service was used instead.
--
-- Plankrankenhaeuser are the hospitals in the Berlin state hospital
-- plan. The other layer of the same service holds specialist and
-- rehabilitation clinics, which are not useful in a heat emergency.
--
-- Selection rule, applied with no hand-picking: every hospital in
-- that layer within 3 km of Alexanderplatz (52.5219, 13.4132).
-- Three qualify. 3 km is twice the radius of the pilot area, which
-- is a reasonable allowance for an emergency.
--
-- Umlauts are written in ASCII (ae, oe, ue, ss) to match the rest of
-- this file and to avoid encoding problems on load.
-- ---------------------------------------------------------------
INSERT INTO emergency_services
    (name, service_type, address, operator, beds, geom) VALUES

    ('St. Hedwig-Krankenhaus', 'hospital',
     'Grosse Hamburger Strasse 5-11, 10115 Berlin',
     'Alexianer St. Hedwig-Kliniken Berlin', 415,
     ST_SetSRID(ST_MakePoint(13.39839853, 52.52591281), 4326)),

    ('Vivantes Klinikum im Friedrichshain', 'hospital',
     'Landsberger Allee 49, 10249 Berlin',
     'Vivantes - Klinikum im Friedrichshain', 955,
     ST_SetSRID(ST_MakePoint(13.43890404, 52.52448727), 4326)),

    ('Campus Charite Mitte', 'hospital',
     'Chariteplatz 1, 10117 Berlin',
     'Charite', 893,
     ST_SetSRID(ST_MakePoint(13.37819437, 52.52363436), 4326));
