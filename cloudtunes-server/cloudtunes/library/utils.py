from functools import partial
from collections import defaultdict

from .models import UNTITLED_ARTIST, UNTITLED_ALBUM


FIELDS_ORDER = [
    'id',
    'source',
    'source_id',
    'title',
    'number',
    'mbid',
    'artist_mbid',
    'album_mbid'
]


def compress_tracks_to_json(tracks):
    """
    Serialize tracks to a list with fields as defined in `FIELDS_ORDER`.

    """
    collection = defaultdict(partial(defaultdict, list))
    for track in tracks:
        source = track['source'][0]  # [dy]
        source_id = None
        if source == 'y':
            source_id = track['youtube']['id']

        artist = track.get('artist') or UNTITLED_ARTIST
        album = track.get('album') or UNTITLED_ALBUM

        collection[artist][album].append((
            str(track['_id']),
            source,
            source_id,
            track['title'],
            track.get('number') or 0,
            track.get('mbid'),
            track.get('artist_mbid'),
            track.get('album_mbid')
        ))

    return collection
