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
    data_source    TEXT NOT NULL DEFAULT 'demonstration',
    geom           geometry(Polygon, 4326) NOT NULL
);

CREATE INDEX heat_zones_geom_idx ON heat_zones USING GIST (geom);

-- ---------------------------------------------------------------
-- Data: cooling places (real locations around Alexanderplatz,
-- coordinates approximate)
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
-- DEMONSTRATION DATA. Polygons drawn by hand for this pilot.
-- risk_level and temp_indicator are illustrative estimates based on
-- visible land cover, NOT measured or modelled official values.
-- ---------------------------------------------------------------
INSERT INTO heat_zones (name, risk_level, temp_indicator, surface_type, data_source, geom) VALUES
    ('Alexanderplatz Zentrum', 'high', 38.5, 'sealed', 'demonstration',
     ST_GeomFromText('POLYGON((13.4085 52.5235, 13.4175 52.5235, 13.418 52.5195, 13.409 52.5192, 13.4085 52.5235))', 4326)),
    ('Rathausforum', 'high', 37.2, 'sealed', 'demonstration',
     ST_GeomFromText('POLYGON((13.404 52.5205, 13.4105 52.5208, 13.4108 52.5168, 13.4045 52.5165, 13.404 52.5205))', 4326)),
    ('Karl-Marx-Allee West', 'medium', 34.0, 'mixed', 'demonstration',
     ST_GeomFromText('POLYGON((13.418 52.5215, 13.43 52.522, 13.4302 52.5185, 13.4182 52.518, 13.418 52.5215))', 4326)),
    ('Spandauer Vorstadt', 'medium', 33.5, 'mixed', 'demonstration',
     ST_GeomFromText('POLYGON((13.395 52.529, 13.406 52.5292, 13.4062 52.5245, 13.3952 52.5242, 13.395 52.529))', 4326)),
    ('Volkspark Friedrichshain', 'low', 29.0, 'vegetated', 'demonstration',
     ST_GeomFromText('POLYGON((13.427 52.53, 13.439 52.5305, 13.4392 52.525, 13.4272 52.5245, 13.427 52.53))', 4326)),
    ('Spreeinsel Museumsinsel', 'low', 30.5, 'water_adjacent', 'demonstration',
     ST_GeomFromText('POLYGON((13.3945 52.5215, 13.403 52.5218, 13.4032 52.517, 13.3947 52.5168, 13.3945 52.5215))', 4326));
