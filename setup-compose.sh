#!/bin/bash
set -e

check_mandatory_flags() {
  if [ -z "$PORTUS_FQDN" ]; then
    echo "External FQDN for portus not set. Provide it using the -p flag." >&2
    echo "Example: ./setupCompose.sh -p portus.example.com" >&2
    exit 1
  fi
  if [ -z "$REGISTRY_FQDN" ]; then
    echo "External FQDN for portus not set. Provide it using the -r flag." >&2
    echo "Example: ./setupCompose.sh -r registry.example.com" >&2
    exit 1
  fi
}

fill_inherited_values() {
  SERVER_NAME=PORTUS_FQDN
}

fill_optional_values() {
  if [ -z "$MARIADB_PASSWORD" ]; then
    echo "Mysql password not providing. Generating..."
    MARIADB_PASSWORD=$(openssl rand -hex 64)
    MYSQL_ROOT_PASSWORD=$MARIADB_PASSWORD
  fi

  if [ -z "$PORTUS_SECRET_KEY_BASE" ]; then
    echo "Portus secret key base not provided. Generating..."
    PORTUS_SECRET_KEY_BASE=$(openssl rand -hex 64)
  fi

  if [ -z "$PORTUS_PORTUS_PASSWORD" ]; then
    echo "Portus password not provided. Generating..."
    PORTUS_PORTUS_PASSWORD=$(openssl rand -hex 64)
  fi
}

print_all_arguments() {
  echo "#########################################################################################"
  echo "Using these parametes for further processing: "
  echo "PORTUS_FQDN            = " $PORTUS_FQDN
  echo "REGISTRY_FQDN          = " $REGISTRY_FQDN
  echo "MARIADB_PASSWORD       = " $MARIADB_PASSWORD
  echo "PORTUS_SECRET_KEY_BASE = " $PORTUS_SECRET_KEY_BASE
  echo "PORTUS_PORTUS_PASSWORD = "$PORTUS_PORTUS_PASSWORD
  echo "#########################################################################################"
}

display_help() {
cat << EOM

Parameters:
  -a       FQDN of the docker registry that will be deployed using this script.
  -b       FQDN of the portus webinterface that will be deployed using the script.
  [-c]     MariadDB root password (if not provided a random string will be generated).
  [-d]     Portus Secret Key Base (if not provided a random string will be generated).
  [-e]     Portus Password (if not provided a random string will be generated).

Example command: ./setupCompose.sh  -a registry.example.com -b portus.example.com

EOM
}

# script entrypoint

while getopts "a:b:" opt; do
  case $opt in
    a)
      REGISTRY_FQDN=$OPTARG
      ;;
    b)
      PORTUS_FQDN=$OPTARG
      ;;
    c)
      MARIADB_PASSWORD=$OPTARG
      MYSQL_ROOT_PASSWORD=$OPTARG
      ;;
    d)
      PORTUS_SECRET_KEY_BASE=$OPTARG
      ;;
    e)
      PORTUS_PORTUS_PASSWORD=$OPTARG
      ;;
    h)
      display_help
      exit 0
      ;;

    \?)
      display_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

check_mandatory_flags
fill_optional_values
fill_inherited_values
print_all_arguments

#web
cp ./certs/portus.key ./web/portus.key
sed -e "s|PORTUS_FQDN|$PORTUS_FQDN|g" docker-compose.yml.template > docker-compose.yml

#proxy
cp -r ./certs/ ./proxy/
sed -e "s|PORTUS_FQDN|$PORTUS_FQDN|g" ./proxy/vhosts/portus.conf.template > ./proxy/vhosts/portus.conf
sed -e "s|REGISTRY_FQDN|$REGISTRY_FQDN|g" ./proxy/vhosts/registry.conf.template > ./proxy/vhosts/registry.conf

#registry
cp ./certs/portus.crt ./registry/portus.crt
sed -e "s|PORTUS_FQDN|$PORTUS_FQDN|g" ./registry/config.yml.template > ./registry/config.yml.intermediate
sed -e "s|REGISTRY_FQDN|$REGISTRY_FQDN|g" ./registry/config.yml.intermediate > ./registry/config.yml
rm -f ./registry/config.yml.intermediate


# Asking to continue

echo "This script will now delete all previous containers that may have been started."
echo "Normally this should not cause any data lost, as the data is stored inside the ./data/ directory."
echo "Please type y to continue or anything else to abort."

read -n 1 answer

if [[ "$answer" != "y" ]]; then
  echo "Aborting..."
  exit 1
fi


echo "Cleaning up..."
docker-compose kill
docker-compose rm -f

echo "Exporting variables..."

export MYSQL_ROOT_PASSWORD
export MARIADB_PASSWORD
export PORTUS_SECRET_KEY_BASE
export PORTUS_PORTUS_PASSWORD
export SERVER_NAME

echo "Starting compose unit..."
docker-compose up -d --build --force-recreate


cat << EOM
#######################################
System Ready!

Remember to save the generated passwords!
EOM
