#!/usr/bin/env python3
import json
import time
import os
import logging
from datetime import datetime

import requests

DATA_FILE = os.path.expanduser("~/practica/proiect/dimitrie-constantin/sensor-data.jsonl")
STATE_FILE = os.path.expanduser("~/practica/proiect/local-sync/.sync-state")

INFLUX_URL = "http://localhost:8086"
INFLUX_DB = "training"
MEASUREMENT = "sensor"

SYNC_INTERVAL = 10

# logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("sync")

# checkpoint reader
def read_checkpoint():
    try:
        with open(STATE_FILE) as f:
            return int(f.read().strip())
    except (FileNotFoundError, ValueError):
        return 0
    
# checkpoint writer
def write_checkpoint(n):
    with open(STATE_FILE, "w") as f:
        f.write(str(n))

# function that checks the connection to the influxDB
def influx_is_up():
    try:
        r = requests.get(f"{INFLUX_URL}/ping", timeout=3)
        return r.status_code == 204
    except requests.RequestException:
        return False
    
def iso_to_nanos(iso_str):
    dt = datetime.fromisoformat(iso_str.replace("Z", "+00:00"))
    return int(dt.timestamp() * 1_000_000_000)

def to_line_protocol(reading):
    ts = iso_to_nanos(reading["time"])
    device = reading["device"]
    temp = reading["temperature"]
    return f"{MEASUREMENT},device={device} temperature={temp} {ts}"

def send_to_influx(line):
    try:
        r = requests.post(
            f"{INFLUX_URL}/write",
            params={"db": INFLUX_DB, "precision": "ns"},
            data=line,
            timeout=5,
        )
        return r.status_code == 204
    except requests.RequestException:
        return False
    
def sync_once():
    if not influx_is_up():
        log.warning("Influx DB is not reachable")
        return
    
    checkpoint = read_checkpoint()

    try:
        with open(DATA_FILE) as f:
            lines = f.readlines()
    except FileNotFoundError:
        return
    
    sent = checkpoint

    for line in lines[checkpoint:]:
        line = line.strip()
        if not line:
            sent += 1
            continue

        try:
            reading = json.loads(line)
        except json.JSONDecodeError:
            log.error("corrupt line")
            sent += 1
            continue

        if send_to_influx(to_line_protocol(reading)):
            sent += 1
            write_checkpoint(sent)
        else:
            log.warning("Sending the data failed")
            break

    if sent > checkpoint:
        log.info("sinchronised %d readings from %d in total", sent - checkpoint, sent)

def main():
    log.info("Serviciu de sync pornit (interval %ds)", SYNC_INTERVAL)
    while True:
        sync_once()
        time.sleep(SYNC_INTERVAL)

if __name__ == "__main__":
    main()



