from fastapi import FastAPI
import os

app = FastAPI(title="ENA API", version="1.0.0")

PROJECT_ID = os.getenv("PROJECT_ID", "affable-elf-472819-k2")
DATASET_ID = os.getenv("DATASET_ID", "ena_data")

@app.get("/")
async def root():
    return {
        "message": "ENA API - Projeto Sauter Hydro Forecast",
        "project": PROJECT_ID,
        "dataset": DATASET_ID,
        "status": "running"
    }

@app.get("/health")
async def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)