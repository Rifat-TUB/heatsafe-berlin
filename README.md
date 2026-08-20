# HeatSafe Berlin

A small Web-GIS application that shows heat-risk zones and cooling places
around Alexanderplatz in Berlin-Mitte.

This is a pilot. It covers Alexanderplatz and about 1-1.5 km around it, not
the whole city. The point was to build a complete working chain from a spatial
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

Heat-risk zones are drawn as coloured polygons - red for high, orange for
medium, green for low. Clicking one shows its risk level, heat indicator and
surface type.

Cooling places are the blue circles: fountains, parks, shaded streets, indoor
spaces and waterfronts. Clicking one shows its name, type and description.

The "Find nearest" button is the main spatial feature. Press it, then click
anywhere on the map. The nearest cooling place is highlighted, a dashed line
is drawn to it, and the distance in metres is shown. The distance is
calculated by PostGIS in the database - the browser only sends the coordinates
and displays the answer.

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

| Endpoint | What it returns |
|---|---|
| `/api/health` | Service status and PostGIS version |
| `/api/cooling-places` | All cooling places as GeoJSON |
| `/api/heat-zones` | All heat zones as GeoJSON |
| `/api/cooling-places/nearest?lat=&lon=&limit=` | Nearest cooling place(s) with distance in metres |

Example:

```
http://localhost:8000/api/cooling-places/nearest?lat=52.5219&lon=13.4132&limit=3
```

All endpoints can also be tried directly in the browser at
http://localhost:8000/docs

## Database

Two tables, both with PostGIS geometry columns in EPSG:4326 and GiST spatial
indexes:

- `cooling_places` - 15 points
- `heat_zones` - 6 polygons

To look inside the database yourself:

```
docker compose exec db psql -U heatsafe -d heatsafe
```

```sql
SELECT name, place_type, ST_AsText(geom) FROM cooling_places LIMIT 5;
```

`ST_AsText` prints the geometry as text, which shows that the coordinates are
stored as real spatial objects and not just as two numbers.

## About the data

The cooling places are real locations around Alexanderplatz - the
Neptunbrunnen, Volkspark Friedrichshain, Monbijoupark and so on. I placed the
coordinates manually, so they are approximate.

**The heat zones are demonstration data.** I drew the polygons by hand for
this pilot. The risk levels and temperatures are my own estimates based on
what the land cover looks like - sealed squares are hot, parks and water are
cooler. They are not measured values and they do not come from any official
climate model.

This is written in three places so it is not missed: in
`data/heat_zones.geojson`, in the `data_source` column of the `heat_zones`
table, and in the popup on the map itself.

Real data does exist for both layers. The Umweltatlas Berlin publishes
modelled heat maps (Klimaanalysekarten) and the Berlin Open Data portal has
the real drinking fountain locations under Datenlizenz Deutschland Zero 2.0.
Replacing my demonstration data with those would not require any code changes,
only a different `01_init.sql`.

Basemap tiles are from OpenStreetMap ((c) OpenStreetMap contributors, ODbL).

## Limitations and possible next steps

Things this version does not do:

- The API only reads data. There is no way to add or edit a cooling place
  from the map yet.
- There is no login. Anyone who can reach the API can query it.
- The heat zones are demonstration polygons, as explained above.
- There is no GPS. You have to click your location on the map instead of the
  browser finding it.
- The layout is not optimised for phones.

The most useful next steps would probably be a POST endpoint so users can
report a cooling place they know about, and browser geolocation so the app is
usable while actually standing outside in the heat.

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
