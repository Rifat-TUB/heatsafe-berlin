# HeatSafe Berlin

A small Web-GIS application that shows heat-risk zones and cooling places
around Alexanderplatz in Berlin-Mitte.

This is a pilot. It covers Alexanderplatz and about 1-2 km around it, not the
whole city. The point was to build a complete working chain from a spatial
database through a REST API to an interactive map, and to keep it small enough
that it actually runs.

## How to run it

You need Docker Desktop. Nothing else - no Python, no PostgreSQL, no Node.

Open a terminal in this folder and run:

```
docker compose up --build
```

The first run downloads the images and takes a few minutes. When all three
containers are up, open:

- http://localhost:8080 for the map
- http://localhost:8000/docs for the API documentation

To stop it: `docker compose down`

## What it does

The map opens on Alexanderplatz and you can zoom and pan as usual.

**Heat-risk zones** are the coloured polygons - red for high, orange for
medium, green for low. Clicking one shows its risk level, heat indicator,
surface type and where the polygon came from.

**Cooling places** are the small symbols: fountains, parks, shaded streets,
indoor spaces and waterfronts. The *shape* of the symbol tells you where the
point came from - see "About the data" below. Clicking one shows its name,
type, description and source.

There are four buttons in the top right corner.

**Find nearest.** Press it, then click anywhere on the map. The nearest
cooling place is highlighted, a dashed line is drawn to it, and the distance
in metres is shown. The distance is calculated by PostGIS in the database -
the browser only sends the coordinates and displays the answer.

**Within 500 m.** Press it, then click anywhere. A 500 m circle is drawn and
every cooling place inside it is highlighted, with a count. This uses a
different PostGIS function from "Find nearest": `ST_DWithin` answers "which
ones are inside this distance", while `ST_Distance` answers "how far is it".

**Add place.** Press it, then click anywhere. A small form opens where you can
enter a name, pick a type and save. The new place is written to the database
through the API and appears on the map immediately. Coordinates outside the
pilot area are rejected by the API with a clear message.

**Where am I.** Uses the browser's geolocation to find your position and then
runs the nearest search from there. If you refuse the permission, the app says
so instead of hanging.

There is also a **type filter** ("Show type") and a **layer control**. The
filter is applied by SQL in the database, not in the browser - it changes what
the API returns, and it also narrows the "Find nearest" and "Within 500 m"
searches, so "nearest drinking fountain" and "nearest park" give different
answers.

The layout adapts to small screens.

## How it is put together

```
Browser (Leaflet)
    |
FastAPI (port 8000)
    |
PostgreSQL + PostGIS (port 5432)
```

Three Docker services:

- `web` - nginx serving the Leaflet client on port 8080
- `api` - FastAPI, talks to the database and returns GeoJSON
- `db` - PostgreSQL 16 with PostGIS 3.4

The tables and the pilot data are created automatically the first time the
database container starts, from `database/01_init.sql`.

## API endpoints

| Method | Endpoint | What it does |
|---|---|---|
| GET | `/api/health` | Service status and PostGIS version |
| GET | `/api/cooling-places?place_type=` | All cooling places as GeoJSON, optionally filtered by type |
| POST | `/api/cooling-places` | Creates a new cooling place |
| GET | `/api/heat-zones` | All heat zones as GeoJSON |
| GET | `/api/cooling-places/nearest?lat=&lon=&limit=&place_type=` | Nearest cooling place(s) with distance in metres |
| GET | `/api/cooling-places/within?lat=&lon=&radius_m=&place_type=` | Every cooling place inside a radius, with a count |

Examples:

```
http://localhost:8000/api/cooling-places/nearest?lat=52.5219&lon=13.4132&limit=3
http://localhost:8000/api/cooling-places/within?lat=52.5219&lon=13.4132&radius_m=500
http://localhost:8000/api/cooling-places?place_type=fountain
```

All endpoints can also be tried directly in the browser at
http://localhost:8000/docs

Input is validated before it reaches the database. `place_type` only accepts
the five values the database allows, and latitude and longitude have to fall
inside the pilot area. Invalid input gets a 422 response explaining what was
wrong. All SQL uses parameters, never string concatenation.

## Database

Two tables, both with PostGIS geometry columns in EPSG:4326 and GiST spatial
indexes:

- `cooling_places` - 20 points
- `heat_zones` - 8 polygons

Both tables have a `data_source` column, so every row says where it came from.

To look inside the database yourself:

```
docker compose exec db psql -U heatsafe -d heatsafe
```

```sql
SELECT name, place_type, data_source, ST_AsText(geom)
FROM cooling_places LIMIT 5;

SELECT data_source, COUNT(*) FROM cooling_places GROUP BY data_source;

SELECT name, ST_IsValid(geom) FROM heat_zones;
```

`ST_AsText` prints the geometry as text, which shows that the coordinates are
stored as real spatial objects and not just as two numbers.

## About the data

There are three kinds of data in this project and the map keeps them apart on
purpose, both in the `data_source` column and in the symbol used to draw them.

| Source | Symbol | What it is |
|---|---|---|
| `berlin_open_data` | square | Official survey data |
| `pilot_seed` | circle | Places I positioned by hand |
| `user_submitted` | orange triangle | Added through the app |

### Official drinking fountains (`berlin_open_data`, 5 points)

From the Berlin Open Data portal, daten.berlin.de:
**"Public drinking fountains in Friedrichshain-Kreuzberg"**, published by the
District Office Friedrichshain-Kreuzberg of Berlin - Surveying.

License: **Data License Germany - Attribution - Version 2.0 (dl-de-by-2.0)**.
This license requires attribution, so the source is named in the popup on the
map, in `database/01_init.sql` and here.

The published file uses **EPSG:25833** (ETRS89 / UTM zone 33N), where
coordinates are metres rather than degrees. The numbers in `01_init.sql` are
copied unchanged from that file and converted by PostGIS with `ST_Transform`,
so no coordinate was edited by hand.

Only fountains near the pilot area are loaded. The dataset covers
Friedrichshain-Kreuzberg while Alexanderplatz is in Mitte, which is why the
squares on the map all sit east and south of the centre.

### Pilot cooling places (`pilot_seed`, 15 points)

Real places - the Neptunbrunnen, Volkspark Friedrichshain, Monbijoupark and so
on - but I positioned the coordinates by hand, so they are approximate. That
is what the circle symbol means.

### Heat zones (`self_digitized`, 8 polygons)

**These are not measured data.** I digitized every polygon myself in
geojson.io on top of satellite imagery.

The risk levels and heat indicators are my own visual estimates based on what
the land cover looks like from the air: sealed squares and wide roads are hot,
parks and waterfronts are cooler. `surface_type` records what the dominant
surface actually is. The numbers are meant for relative comparison inside this
pilot area only. **They are not measured temperatures and they do not come
from any official climate model or sensor network.**

This is written in four places so it cannot be missed: in
`data/heat_zones.geojson`, in the comment block in `database/01_init.sql`, in
the `data_source` column, and in the popup on the map itself.

Real modelled data does exist - the Umweltatlas Berlin publishes
Klimaanalysekarten. Replacing my estimates with those would not require any
code changes, only a different `01_init.sql`.

### Basemap

Tiles from OpenStreetMap ((c) OpenStreetMap contributors, ODbL).

## Limitations

Things this version does not do, or does not do well:

- **The heat zones are self-digitized estimates**, as explained above. This is
  the biggest limitation and the reason the app is a demonstration rather than
  a tool anyone should act on in real heat.
- **"Where am I" only works on `localhost` or over HTTPS.** Browsers block
  geolocation on plain HTTP. If you open the app from another device using the
  machine's IP address, that one button will fail while everything else works.
- **The official fountain dataset does not cover Mitte.** Alexanderplatz
  itself has no official points, only hand-placed ones.
- **There is no login.** Anyone who can reach the API can read it and add
  cooling places to it. There is no moderation of what gets submitted.
- **Nothing can be edited or deleted** once it is added.
- **Data added through the app lives in the Docker volume.** Running
  `docker compose down -v` deletes it and restores the seed data.
- **The pilot area is small.** The architecture would extend to the rest of
  Berlin, but nothing has been tested at that size.

## Folder structure

```
heatsafe-berlin/
  backend/            FastAPI app
    main.py
    requirements.txt
    Dockerfile
  database/
    01_init.sql       Schema and data, runs on first start
  data/               Source data files
    cooling_places.csv
    heat_zones.geojson
    trinkbrunnen_friedrichshain_kreuzberg.geojson
  frontend/           Leaflet client
    index.html
    nginx.conf
    Dockerfile
  docker-compose.yml
  README.md
```

## Built with

Leaflet, OpenStreetMap, FastAPI, psycopg 3, PostgreSQL 16, PostGIS 3.4, nginx
and Docker Compose. All free and open source, no API keys and no hosting
needed.

## If something goes wrong

**A port is already in use.** Something else on the machine is using 8080,
8000 or 5432. Change the left-hand number in `docker-compose.yml`, for example
`"8081:80"`.

**The map is empty.** Check that all three containers are running with
`docker ps`, then open http://localhost:8000/api/health to see whether the API
can reach the database.

**Changing `01_init.sql` does nothing.** That script only runs when the
database is empty. Run `docker compose down -v` first to delete the volume,
then `docker compose up --build`. Without the `-v` the old data stays.

**A new place does not appear after saving.** Check the type filter. If it is
set to one type and the new place is another, the map hides it. The app says
so in a message when this happens.
