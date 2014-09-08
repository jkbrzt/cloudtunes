"""

developers.google.com/youtube/2.0/developers_guide_protocol_video_entries

"""
import urlparse

import requests


VIDEO_URL = 'https://gdata.youtube.com/feeds/api/videos/%s?v=2&alt=jsonc'


def get_video_id(url):
    url = urlparse.urlparse(url)
    if 'youtube.com' not in url.netloc:
        raise ValueError('Not a youtube.com URL: %s' % url)
    params = urlparse.parse_qs(url.query)
    if 'v' not in params:
        raise ValueError('Missing video ID: %s' % url)
    return params['v'][0]


def get_video(id):
    return requests.get(VIDEO_URL % id).json
