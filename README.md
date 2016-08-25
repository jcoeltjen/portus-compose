# Portus + Docker Registry Compose Deployment

## Prerequisites

To run this script the following requirements must be fulfilled:
- DNS routed hostname for Portus
- DNS routed hostname for the Docker Registry
- Valid or Self-Signed-Certificate for Portus
- Valid or Self-Signed-Certificate for Registry

Note: Only valid certificates were tested. Self-signed ones may break the script at some point.

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
iptables -A IN_public_allow -p tcp -m tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT
```

Note that the Portus webinterface was already reachable from public chain. I can't explain why this workaround seems to work but it does. At least for now.
