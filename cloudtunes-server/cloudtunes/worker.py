"""
Main script for Celery worker.

"""
from __future__ import absolute_import

from celery.app import Celery

from cloudtunes import settings


celery = Celery(
    'tasks',
    broker='redis://{host}:6379/1'.format(**settings.REDIS)
)

celery.conf.CELERY_DISABLE_RATE_LIMITS = True
celery.conf.CELERY_IMPORTS = [
    'cloudtunes.services.dropbox.sync',
    'cloudtunes.services.youtube.sync',
    'cloudtunes.services.facebook.sync',
    'cloudtunes.mail',
]


def main():
    celery.start()


if __name__ == '__main__':
    main()
