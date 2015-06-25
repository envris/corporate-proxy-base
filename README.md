### Corporate Proxy Base
The corporate-proxy-base is a lowest level container image used to contain
corporate proxy settings that can be then inherited (via FROM) for use in
subsequent application container builds.

#### Building the container
To build the container image, simply substitute the `Cproxy___C` strings within
the Dockerfile with your correct settings. Then build like any other container:

```
docker build --rm=true -t your-registry/my-base:latest .
```

#### Using apply-config.sh
The apply-config script is copied into /usr/local/bin/, and so is available
to applications during their installation process. The script will substitute
configuration values into designated config files that have place-holder
values.

The script will either pull in config items from environment variables supplied
in the docker run command, or pull in config items from a defined etcd host
for a given application. In both instances, these values are then substituted
into files (or folders recursively) where placeholders are present.

Usage:

An install script should invoke apply-config, as it need only be run once
per container instance. However, the script could also be invoked within the
actual Dockerfile for distributing environment you want baked into a layer.

If the docker run command is given ETCD_HOST and ETCD_DIR environment variables,
as well as --volumes-from etcd_conf (where etcd_conf is a data-only container
containing the appropriate certificates for the etcd host), then the script
will load in configuration items located at /$ETCD_DIR/ and, for any provided
configuration file, substitute those values into any string prefixed with '@@'
that matches the key.

```
docker run -d -p 8002:80 --volumes-from etcd_conf \
       -e ETCD_HOST="my-etcd-server.example.com" -e ETCD_DIR="someapp" \
       my-registry/someapp:latest
```

If neither of these environment variables are supplied, the script will look
for key/value pairs in env that start with double-underscore, and substitute
those values into any string prefixed with '@@' that match.
