#!/usr/bin/env python3

import logging
from flask import Flask, jsonify
import requests

INFLUX_URL = "http://localhost:8086"
INFLUX_DB = "training"
PROVIDER_PORT = 5001

logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s",
                    datefmt="%H:%M:%S")
log = logging.getLogger("provider")

app = Flask(__name__)

def get_last_reading():
    # interogheaza InfluxDB pentru ultima citire din "sensor"
    query = "SELECT last(temperature) FROM sensor"
    r = requests.get(f"{INFLUX_URL}/query",
                     params={"db": INFLUX_DB, "q": query},
                     timeout=5)
    r.raise_for_status()
    data = r.json()

    # extrage valoarea din structura InfluxDB
    series = data["results"][0].get("series")
    if not series:
        return None
    columns = series[0]["columns"]   # ["time", "last"]
    values = series[0]["values"][0]  # [timestamp, valoare]
    return {
        "time": values[columns.index("time")],
        "temperature": values[columns.index("last")],
    }

@app.route("/temperature", methods=["GET"])
def temperature():
    reading = get_last_reading()
    if reading is None:
        return jsonify({"error": "no data"}), 404
    log.info("Servesc: %s", reading)
    return jsonify(reading)

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    log.info("Provider pornit pe portul %d", PROVIDER_PORT)
    app.run(host="0.0.0.0", port=PROVIDER_PORT)