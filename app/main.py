import os
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app import models, schemas
from app.db import Base, engine, get_db

APP_VERSION = os.getenv("APP_VERSION", "dev")


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="LogiFlow Tracking", version=APP_VERSION, lifespan=lifespan)


@app.get("/health")
def health(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return {"status": "ok"}


@app.get("/version")
def version():
    return {"version": APP_VERSION}


@app.post("/deliveries", response_model=schemas.DeliveryOut, status_code=201)
def create_delivery(payload: schemas.DeliveryCreate, db: Session = Depends(get_db)):
    exists = db.scalar(select(models.Delivery).where(models.Delivery.tracking_code == payload.tracking_code))
    if exists:
        raise HTTPException(status_code=409, detail="El código de seguimiento ya existe")
    delivery = models.Delivery(**payload.model_dump())
    db.add(delivery)
    db.commit()
    return delivery


@app.get("/deliveries", response_model=list[schemas.DeliveryOut])
def list_deliveries(db: Session = Depends(get_db)):
    return db.scalars(select(models.Delivery).order_by(models.Delivery.id)).all()


def _get_or_404(db: Session, tracking_code: str) -> models.Delivery:
    delivery = db.scalar(select(models.Delivery).where(models.Delivery.tracking_code == tracking_code))
    if not delivery:
        raise HTTPException(status_code=404, detail="Entrega no encontrada")
    return delivery


@app.get("/deliveries/{tracking_code}", response_model=schemas.DeliveryOut)
def get_delivery(tracking_code: str, db: Session = Depends(get_db)):
    return _get_or_404(db, tracking_code)


@app.post(
    "/deliveries/{tracking_code}/events",
    response_model=schemas.EventOut,
    status_code=201,
)
def add_event(tracking_code: str, payload: schemas.EventCreate, db: Session = Depends(get_db)):
    delivery = _get_or_404(db, tracking_code)
    event = models.TrackingEvent(delivery_id=delivery.id, **payload.model_dump())
    delivery.status = payload.status
    db.add(event)
    db.commit()
    return event


@app.get("/deliveries/{tracking_code}/events", response_model=list[schemas.EventOut])
def list_events(tracking_code: str, db: Session = Depends(get_db)):
    return _get_or_404(db, tracking_code).events
