import os
import json
import psycopg
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="HeatSafe Berlin API",
    description="Heat risk and cooling places around Alexanderplatz",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://heatsafe:heatsafe_dev@db:5432/heatsafe",
)


def query(sql, params=None):
    with psycopg.connect(DB_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            return cur.fetchall()


@app.get("/")
def root():
    return {"message": "HeatSafe Berlin API", "docs": "/docs"}


@app.get("/api/health")
def health():
    rows = query("SELECT PostGIS_Version();")
    return {"status": "ok", "postgis": rows[0][0]}


@app.get("/api/cooling-places")
def cooling_places():
    rows = query("""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(
                json_build_object(
                    'type', 'Feature',
                    'geometry', ST_AsGeoJSON(geom)::json,
                    'properties', json_build_object(
                        'id', id,
                        'name', name,
                        'place_type', place_type,
                        'description', description
                    )
                )
            ), '[]'::json)
        )
        FROM cooling_places;
    """)
    return rows[0][0]
@app.get("/api/heat-zones")
def heat_zones():
    rows = query("""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(
                json_build_object(
                    'type', 'Feature',
                    'geometry', ST_AsGeoJSON(geom)::json,
                    'properties', json_build_object(
                        'id', id,
                        'name', name,
                        'risk_level', risk_level,
                        'temp_indicator', temp_indicator,
                        'surface_type', surface_type,
                        'data_source', data_source
                    )
                )
            ), '[]'::json)
        )
        FROM heat_zones;
    """)
    return rows[0][0]


@app.get("/api/cooling-places/nearest")
def nearest_cooling_place(lat: float, lon: float, limit: int = 1):
    rows = query("""
        SELECT
            id,
            name,
            place_type,
            description,
            ST_Y(geom) AS lat,
            ST_X(geom) AS lon,
            ROUND(ST_Distance(
                geom::geography,
                ST_SetSRID(ST_MakePoint(%s, %s), 4326)::geography
            )) AS distance_m
        FROM cooling_places
        ORDER BY geom <-> ST_SetSRID(ST_MakePoint(%s, %s), 4326)
        LIMIT %s;
    """, (lon, lat, lon, lat, limit))

    return {
        "query_point": {"lat": lat, "lon": lon},
        "results": [
            {
                "id": r[0],
                "name": r[1],
                "place_type": r[2],
                "description": r[3],
                "lat": r[4],
                "lon": r[5],
                "distance_m": int(r[6]),
            }
            for r in rows
        ],
    }