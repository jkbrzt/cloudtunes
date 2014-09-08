import os
import datetime
from operator import itemgetter
from itertools import groupby

from celery.utils.log import get_task_logger

from cloudtunes.users.models import User
from cloudtunes.library.models import Track
from cloudtunes.worker import celery
from .id3 import get_id3
from .client import Client
from .models import DropboxTrack


logger = get_task_logger(__name__)


@celery.task
def sync_account(account_id):
    """

    https://www.dropbox.com/developers/reference/api#delta

    """
    try:
        user = User.objects.get(dropbox__id=account_id)
    except User.DoesNotExist:
        logger.warning('Dropbox account not found: %s', account_id)
        return

    client = Client.for_account(user.dropbox)

    while True:

        logger.info('getting delta for cursor=%s', user.dropbox.delta_cursor)

        delta = client.delta(cursor=user.dropbox.delta_cursor)
        entries = []

        logger.info(
            'got delta: reset=%r; has_more=%r; len(entries)=%d; cursor=%r',
            delta['reset'], delta['has_more'],
            len(delta['entries']), delta['cursor']
        )

        if delta['reset']:
            Track.objects.filter(user=user.pk, source='dropbox').delete()
            user.emit('sync', 'dropbox:reset')

        for path, meta in delta['entries']:
            if meta and meta.get('mime_type', None) != 'audio/mpeg':
                logger.info('not a song, skipping: %s', meta)
                continue
            do_delete = not meta
            entries.append((path, do_delete))

        user.dropbox.delta_cursor = delta['cursor']

        entries.sort(key=itemgetter(0))
        folders = groupby(entries, lambda entry: os.path.dirname(entry[0]))
        for folder, entries in folders:
            for path, do_delete in entries:
                sync_track.delay(account_id, path, do_delete)

        if not delta['has_more']:
            break

    user.dropbox.synced = datetime.datetime.utcnow()
    user.save()
    user.emit_change()


@celery.task(ack_late=True, retry=3)
def sync_track(account_id, path, do_delete):

    logger.info('updating path=%r; do_delete=%r', path, do_delete)

    try:
        user = User.objects.get(dropbox__id=account_id)
    except User.DoesNotExist:
        logger.warning('dropbox account not found: %s; bailing out', account_id)
        return

    client = Client.for_account(user.dropbox)

    try:
        id3 = get_id3(client, path, title=os.path.basename(path))
    except Exception:
        logger.exception('could not get tags')
        return

    logger.debug('id3 dict=%r', id3)

    if not id3:
        return

    try:
        track = Track.objects.get(user=user.pk, dropbox__path=path)
    except Track.DoesNotExist:
        if do_delete:
            logger.warning('track %s already deleted', path)
            return
        track = Track()
        action = 'add'
    else:
        if do_delete:
            logger.info('deleting track %s @ %s', track.id, path)
            track.delete()
            user.emit('sync', 'track:remove', str(track.id))
            return
        else:
            action = 'update'

    track.update_fields(
        user=user,
        source='dropbox',
        dropbox=DropboxTrack(path=path),
        **id3
    )
    track.save()
    user.emit('sync', 'track:' + action, track.to_json())
    logger.info('track %s @ %s saved', track.id, path)
