from celery.utils.log import get_task_logger

from cloudtunes.users.models import User
from cloudtunes.library.models import Track
from cloudtunes.worker import celery
from . import client
from .models import YoutubeTrack


@celery.task
def add_video_by_url(user_id, url):

    log = get_task_logger(__name__)
    log.info('start user_id=%s url=%s', user_id, url)

    user = User.objects.get(id=user_id)
    video_id = client.get_video_id(url)

    log.debug('video_id=%s', video_id)

    video = client.get_video(video_id)['data']

    log.debug('video=%s', video)

    try:
        track = Track.objects.get(user=user, youtube__id=video_id)
    except Track.DoesNotExist:
        track = Track()

    log.debug('existing track=%s', track)

    track.update_fields(**{
        'user': user,
        'title': video['title'],
        'artist': None,
        'album': None,
        'source': 'youtube',
        'youtube': YoutubeTrack(**video)
    })

    log.debug('saving track=%s', track)

    track.save()

    log.info('done track.id=%s', track.id)

    user.emit('sync', 'track:add', track.to_json())

