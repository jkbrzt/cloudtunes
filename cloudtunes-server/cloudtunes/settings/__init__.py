import sys


try:
    from .local import *
except ImportError:
    sys.stderr.write("""

!!!Cannot import local settings!!!

You need to copy cloudtunes/settings/local.example.py
to cloudtunes/settings/local.py and fill in the None's.

https://github.com/jakubroztocil/cloudtunes#installation


""")
    raise
