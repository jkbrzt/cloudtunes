import re
from struct import unpack
from tempfile import NamedTemporaryFile

from mutagen.easyid3 import EasyID3
from mutagen.id3 import BitPaddedInt
from mutagen.id3 import error as ID3Error


tracknumber_re = re.compile(r'^0*(?P<pos>\d+)(/0*(?P<set>\d+))?$')


def id3_to_dict(id3, defaults):

    def get(name):
        try:
            return id3[name][0].strip() or None
        except (KeyError, IndexError):
            return defaults.get(name, None)

    year = get('date')
    if year:
        try:
            year = int(year)
        except ValueError:
            year = None

    number_pos = None
    number_set = None
    number = get('tracknumber') or None

    if number is not None:
        match = tracknumber_re.match(number)
        if match:
            number_pos = int(match.group('pos'))
            if match.group('set'):
                number_set = int(match.group('set'))

    return {
        'title': get('title'),
        'artist': get('artist'),
        'album': get('album'),
        'number': number_pos,
        #'set': number_set,
        'year': year
    }


def get_id3(client, path, **defaults):

    logger = client.logger
    logger.info('getting ID3 for %r', path)

    resp = client.get_file(path)
    cl = long(resp.getheader('Content-Length'))

    logger.info('got resp status=%s; len=%d', resp.status, cl)

    # Possibly ID3v2 header
    data = resp.read(10)
    id3, vmaj, vrev, flags, size = unpack('>3sBBB4s', data)

    if id3 == 'ID3':
        extra = 100  # HACK to avoid ocasional EOF
        size = BitPaddedInt(size)

        logger.info('trying ID3v2.x; fetching additional'
                    ' %s bytes + %s extra', size, extra)

        body = resp.read(size + extra)

        logger.info('got %s bytes' % len(body))

        data += body
        resp.close()
    else:
        logger.info('trying ID3v1.x')

        resp.close()
        data = client.get_byte_range(path, cl - 128, cl)

        if not data.startswith('TAG'):

            logger.warning('no ID3 tags found')

            return None

    with NamedTemporaryFile('wb') as f:
        f.write(data)
        f.flush()
        try:
            tags = EasyID3(f.name)
        except ID3Error:

            logger.exception('exception from mutagen')

            return None

    logger.debug('extracted ID3 %r', tags)

    return id3_to_dict(tags, defaults)
