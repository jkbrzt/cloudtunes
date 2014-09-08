"""Asynchronous MongoDB and Redis connections."""
from functools import partial

import motor
import tornadoredis

from cloudtunes import settings


RedisClient = partial(tornadoredis.Client, **settings.REDIS)


mongo = motor.MotorClient(**settings.MONGODB).cloudtunes
redis = RedisClient()
