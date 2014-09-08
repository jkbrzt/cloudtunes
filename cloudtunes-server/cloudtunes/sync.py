"""Synchronous MongoDB and Redis connections."""
import pymongo
import redis

from cloudtunes import settings


mongo = pymongo.Connection(**settings.MONGODB).cloudtunes
redis = redis.Redis(**settings.REDIS)
