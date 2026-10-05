from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

Status = Literal["created", "in_transit", "delivered", "failed"]


class DeliveryCreate(BaseModel):
    tracking_code: str = Field(min_length=3, max_length=40)
    destination: str = Field(min_length=3, max_length=200)


class DeliveryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    tracking_code: str
    destination: str
    status: Status
    created_at: datetime


class EventCreate(BaseModel):
    status: Status
    lat: float | None = Field(default=None, ge=-90, le=90)
    lng: float | None = Field(default=None, ge=-180, le=180)
    note: str | None = Field(default=None, max_length=200)


class EventOut(EventCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
