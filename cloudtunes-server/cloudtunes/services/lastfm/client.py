import lastfmclient
import lastfmclient.async

from cloudtunes.settings import LASTFM_API_KEY, LASTFM_API_SECRET


class LastfmClient(lastfmclient.LastfmClient):
    api_key = LASTFM_API_KEY
    api_secret = LASTFM_API_SECRET


class AsyncLastfmClient(lastfmclient.async.AsyncLastfmClient):
    api_key = LASTFM_API_KEY
    api_secret = LASTFM_API_SECRET
