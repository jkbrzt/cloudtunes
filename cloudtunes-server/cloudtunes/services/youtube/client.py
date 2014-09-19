"""

developers.google.com/youtube/2.0/developers_guide_protocol_video_entries

"""
import urlparse

import requests


VIDEO_URL = 'https://gdata.youtube.com/feeds/api/videos/%s?v=2&alt=jsonc'


def get_video_id(url):
    url = urlparse.urlparse(url)

    if 'youtube.com' in url.netloc:
        params = urlparse.parse_qs(url.query)
        if 'v' in params:
            return params['v'][0]
        else:
            raise ValueError('Missing video ID: %s' % url)

    elif 'youtu.be' in url.netloc:
        if len(url[2]) > 1:
           return url[2].split('/')[1]
        else:
            raise ValueError('Missing video ID: %s' % url)

    else:
        raise ValueError('Not a youtube.com or youtu.be URL: %s' % url)





def get_video(id):
    return requests.get(VIDEO_URL % id).json
