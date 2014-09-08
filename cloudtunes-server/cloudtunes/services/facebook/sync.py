from __future__ import absolute_import
import logging

import facebook
from celery.utils.log import get_task_logger

from cloudtunes.worker import celery
from cloudtunes.users.models import User
from .models import FacebookUser


logger = get_task_logger(__name__)
logger.setLevel(logging.DEBUG)


@celery.task
def sync_account(fbid_to_sync):
    """Update Facebook accounts for ``fbid_to_sync`` and friends."""

    logger.info('syncing account %s', fbid_to_sync)

    try:
        user = User.objects.get(facebook__id=fbid_to_sync)
        logger.info('user => %s', user.id)
    except User.DoesNotExist:
        logger.warning('User with facebook.id %s does not exist', fbid_to_sync)
        return

    # Fetch the user's and his friends facebook data.
    graph = facebook.GraphAPI(user.facebook.access_token)
    fb_users = [graph.get_object('me')]
    url = '/me/friends'
    while True:
        logger.debug('getting page')
        resp = graph.request(url)
        try:
            fb_users.extend(resp['data'])
            url = resp['paging']['next']
        except KeyError:
            break

    # FB IDs as `fbid` and `int`s.
    current = {int(data['id']): data for data in fb_users}
    for fbid, data in current.items():
        data['fbid'] = fbid
        del data['id']

    previous = {
        fb_user.fbid: fb_user for fb_user in
        FacebookUser.objects.filter(fbid__in=current.keys())
    }

    logger.debug('data collected: previous=%d, current=%d',
                 len(previous), len(current))

    # Update current.
    fb_users = {}
    for fbid, data in current.items():
        if fbid in previous:
            fb_user = previous[fbid]
        else:
            fb_user = FacebookUser()
        fb_user.update_fields(**data)
        fb_user.save()
        fb_users[fbid] = fb_user

    # Save friends.
    fb_user = fb_users[fbid_to_sync]
    del fb_users[fbid_to_sync]
    fb_user.friends = fb_users.values()
    fb_user.save()

    logger.info('done syncing %d', fbid_to_sync)
