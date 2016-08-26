# Portus + Docker Registry Compose Deployment

## Prerequisites

To run this script the following requirements must be fulfilled:

- Prebuild Portus Docker Image with image name `portus-git`
- DNS routed hostname for Portus
- DNS routed hostname for the Docker Registry
- Valid or Self-Signed-Certificate for Portus
- Valid or Self-Signed-Certificate for Registry

Note: Only valid certificates were tested. Self-signed ones may break the script at some point.


### Build Portus Docker Image

To build the image needed by this script, clone the official openSUSE docker-containers repo

```
$ git clone https://github.com/openSUSE/docker-containers
```

Get into the right directory and trigger the build

```
$ cd docker-containers/derived_images/portus/docker
$ docker build -t portus-git .
```

If the process fails in step 4, replace the RUN command with this one and try again.
This skips the gpg-key install and therefore also skips the gpg-checks for the artefacts provided by the open build service.

```
RUN zypper --non-interactive --no-gpg-checks ar -f obs://Virtualization:containers:Portus/openSUSE_Leap_42.1 portus-head && \
    zypper --non-interactive --no-gpg-checks ref && \
    zypper -n in portus sudo && \
    zypper clean -a
```

After you did this, rerun the docker build command:
```
$ docker build -t portus-git .
```

## Usage

### Place your certificate files

Put all your certificate files into the `./certs/` directory.
If you use LetsEncrypt certificates, use the fullchain certificate!

|      File          |   Meaning                                   |
|--------------------|---------------------------------------------|
|./certs/portus.crt  | Certificate for the Portus webinterface     |
|./certs/portus.key  | Corresponding private key                   |
|./certs/registry.crt| Certificate for the Registry HTTPS endpoint |
|./certs/registry.key| Corresponding private key                   |

### Execute the setup script

Execute the setup compose file `setup-compose.sh`. You habe to provide at least the hostnames for Portus and the Docker Registry.

Valid arguments are:

|Flag| Meaning                         |optional|
|----|---------------------------------|--------|
| -a | FQDN of the Docker Registry     | no     |
| -b | FQDN of the Portus webinterface | no     |
| -c | MariaDB Root password           | yes    |
| -d | Portus Secret Key Base          | yes    |
| -e | Portus Password                 | yes    |

If any of the optional flags are not provided, to populate the corresponding environment variables, random values are generated using the command `openssl rand -hex 64`.

### Data storage
All data is stored within the `./data/` directory which will be created on the first run. You customize this by editing `./docker-compose.yml.template`.

## Troubleshooting

### Registry cannot connect to authenticator endpoint

If the internal registry container cannot reach the external endpoint of the Portus instance pushings images will fail.
In my case the problem was the firewall an my host machine. For CentOS 7 there is an example rule below that fixed the problem for me.

```
$ iptables -A IN_public_allow -p tcp -m tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
```

Note that the Portus webinterface was already reachable from public chain. I can't explain why this workaround seems to work but it does. At least for now.
