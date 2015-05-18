# CloudTunes Single-Page Web App


Built with CoffeeScript, Brunch, Backbone.js, SocketIO,
SoundManager, Handlebars, Sass, Compass.


## Development Setup

```bash
$ npm install .
```

You'll also need to install [Compass](http://compass-style.org/install/).

### Compilation

The `.coffee`, `.sass`, and `.hbs`  files need to be compiled 
before serving them to clients. We use [Brunch](http://brunch.io/) for that.


#### Production

Compiled & mified production code is included in the repo in 
`build/production`. To update it after making changes to any of 
the source files, run:

```bash
$ brunch build --env config-dist.coffee
```


Take a look at [`./fabfile.py`](./fabfile.py) 
for some deployment automation inspiration.

#### Development

Non-minified, debug-friendly compilation. Output goes to `build/development`. 
Start a watcher for on-the-fly compilation for changed files:

```bash
$ brunch watch
```

**Note:** Please make sure to configure `WEB_APP_DIR` path 
in your local settings for `cloudtunes-server`, which by default 
points to the production build directory.

