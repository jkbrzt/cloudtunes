CloudTunes Server
=================

Built with Python, Mongo DB, MongoEngine, Redis, Tornado, Celery, SocketIO, tornadio2.



## Setup


* Copy [`cloudtunes/settings/local.example.py`](cloudtunes/settings/local.example.py)
  to `cloudtunes/settings/local.py` and fill in the `None`'s.
* Install and start Mongo DB and Redis.


### Development


```bash
# Install cloudtunes-server
$ pip install -r requirements.txt
$ pip install -e .

# Run
$ cloudtunes-worker worker --loglevel=INFO -c 4 &
$ cloudtunes-server

# Go to http://localhost:8001/

```


### Production

Take a look at [`./fabfile.py`](./fabfile.py)
and [`./production/*`](./production) for inspiration.
