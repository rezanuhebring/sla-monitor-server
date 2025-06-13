import os
from fastapi import FastAPI, Request, HTTPException
from influxdb_client import InfluxDBClient, Point, WriteOptions
from influxdb_client.client.write_api import SYNCHRONOUS
from dotenv import load_dotenv

load_dotenv()

INFLUX_URL = os.environ.get("INFLUX_URL")
INFLUX_TOKEN = os.environ.get("INFLUX_TOKEN")
INFLUX_ORG = os.environ.get("INFLUX_ORG")
INFLUX_BUCKET = os.environ.get("INFLUX_BUCKET")

app = FastAPI(title="SLA Monitor API")

try:
    influx_client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
    write_api = influx_client.write_api(write_options=SYNCHRONOUS)
    print("Successfully connected to InfluxDB.")
except Exception as e:
    print(f"Error connecting to InfluxDB: {e}")
    influx_client = None

@app.post("/api/submit")
async def submit_metric_data(request: Request):
    if not influx_client:
        raise HTTPException(status_code=503, detail="InfluxDB connection not available.")
    try:
        data = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON data.")
    agent_id = data.get("agent_id")
    if not agent_id:
        raise HTTPException(status_code=400, detail="Missing 'agent_id' in payload.")
    point = Point("internet_metrics") \
        .tag("agent", agent_id) \
        .field("download_mbps", float(data.get("download", 0.0))) \
        .field("upload_mbps", float(data.get("upload", 0.0))) \
        .field("ping_latency", float(data.get("ping_latency", 0.0))) \
        .field("jitter", float(data.get("jitter", 0.0))) \
        .field("packet_loss", float(data.get("packet_loss", 0.0)))
    try:
        write_api.write(bucket=INFLUX_BUCKET, org=INFLUX_ORG, record=point)
        return {"status": "success", "agent": agent_id, "data_received": data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to write to database: {e}")

@app.get("/")
def read_root():
    return {"message": "SLA Monitoring API is running."}