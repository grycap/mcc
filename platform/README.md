# Architecture

In the initial version a single *platform* file implements all the functions for lxd.

## Idea (in case of further development)
The underlying idea it to have an *empty platform file* that simply loads the functions from the plugins directory, 
according to con configuration variables.

i.e.

NETWORK_PLUGIN=lxd.d
for FILE in "./plugin/network/$NETWORK_PLUGIN/*"; do
    source "$FILE"
done

The files contained in that folder will implement the expected *_NETWORK__* functions.

The same for the underlying container techonology

CONTAINER_ENGINE=lxd.d
for FILE in "./plugin/container/$CONTAINER_ENGINE/*"; do
    source "$FILE"
done

The files in that folder will implement the expected *_PLATFORM__* functions.
