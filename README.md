# CloudTunes

**Open source, web-based music player for the cloud.**   [[hn](https://news.ycombinator.com/item?id=8284785 "Hacker News discussion")]


![screenshot](screenshots/Collection.png)


CloudTunes provides a unified interface 
for music stored in the cloud (YouTube, Dropbox, etc.) and integrates with 
[Last.fm](http://www.last.fm/api), Facebook, 
and [Musicbrainz](https://musicbrainz.org/) for metadata, discovery, 
and social experience. It is similar to services like Spotify, 
except instead of local tracks and the fixed Spotify catalog, 
CloudTunes uses your files stored in Dropbox and music videos on YouTube.


![screenshot](screenshots/Explore.png)
![screenshot](screenshots/Settings-Social.png)



## The Story

CloudTunes is a side project of 
[@jakubroztocil](https://twitter.com/jakubroztocil) who is a bit of a 
[music nerd](http://last.fm/user/oswaldcz) and who likes to 
[build stuff](https://github.com/jakubroztocil).  In 2012 he decided 
to create an iTunes-like webapp to **make music stored all over the cloud 
easily discoverable and accessible:** hence *CloudTunes*. 

One of the goals was to experiment with a bunch of new technologies as well.
Later the side-project has been largely abandoned due to other more pressing 
projects. In the autumn of 2014 CloudTunes has been open-sourced *"as is"* 
(i.e. alpha quality, lack of polish, tests and docs).


## Technology

The architecture consist of a server and client component. Those two are 
decoupled and communicate via a JSON REST API and a WebSocket connection:


### [`cloudtunes-server`](cloudtunes-server)

**Web and WebSocket server, worker processes.**
Written in **Python,** uses Tornado, Celery, Mongo DB, MongoEngine, Redis.


### [`cloudtunes-webapp`](cloudtunes-webapp) 
**Single-page app.** Written in **CoffeeScript and Sass,** uses Brunch, 
Backbone.js, SocketIO, Handlebars, Compass, SoundManager.



## Features

### Discographies & Entire Albums

Find and stream entire albums from YouTube.

![screenshot](screenshots/Artist-Discography.png)
![screenshot](screenshots/Artist-Top-Videos.png)
![screenshot](screenshots/Artist-Related.png)
![screenshot](screenshots/Search.png)

Any album or track you like can be added to your collection or any of your playlists.

![screenshot](screenshots/DnD-Album.png)


### Dropbox Integration

Access and stream **music that you already have in Dropbox** from any computer.
Fast indexing and realtime updates.
 
![screenshot](screenshots/Dropbox.png)


![screenshot](screenshots/Dropbox-Sync.png)


### Playlists

Organise your collection with playlists. Drag and drop tracks and 
albums on a playlist to add them. You can create playlists containing both tracks from your Dropbox and music videos from YouTube.

![screenshot](screenshots/DnD.png)
![screenshot](screenshots/Playlist.png)


### Last.fm Support

Scrobble and play your personalised recommendations. 

![screenshot](screenshots/Scrobbling.png)
![screenshot](screenshots/Explore-Trending.png)


### Notifications

![Notifications](screenshots/Settings-Notifications.png)
![Notifications](screenshots/Notification.png)
![Notifications](screenshots/Notification-Confirm.png)

### Settings

![Notifications](screenshots/Settings.png)


### Miscellaneous

* Drag and drop
* Keyboard shortcuts
* Browse view
* Sorting, resizing
* Support for 10s of 1000s of tracks in collection


## Installation

Clone this repo and follow instructions in:

* [`cloudtunes-server/README`](cloudtunes-server)
* [`cloudtunes-webapp/README`](cloudtunes-webapp)


## Licence

BSD. See [LICENCE](LICENCE) for more details.


## Contact 

Jakub Roztočil

* http://github.com/jakubroztocil
* http://twitter.com/jakubroztocil
