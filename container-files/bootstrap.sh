#!/bin/sh

export PATH=$PATH:/usr/local/rvm/rubies/ruby-1.9.3-p551/bin

echo 'snorby: &snorby' > /usr/local/src/snorby/config/database.yml
echo "  adapter: mysql" >> /usr/local/src/snorby/config/database.yml
echo "  username: $DB_USER" >> /usr/local/src/snorby/config/database.yml
echo "  password: \"$DB_PASS\"" >> /usr/local/src/snorby/config/database.yml
echo "  host: $DB_ADDRESS" >> /usr/local/src/snorby/config/database.yml
echo "" >> /usr/local/src/snorby/config/database.yml
echo "production:" >> /usr/local/src/snorby/config/database.yml
echo "  database: $DB_DATABASE" >> /usr/local/src/snorby/config/database.yml
echo '  <<: *snorby' >> /usr/local/src/snorby/config/database.yml
echo "" >> /usr/local/src/snorby/config/database.yml


# Prepare Database if it doesn't exist
export MYSQL_PWD=$DB_PASS
STATUS=$( echo "show databases" | mysql -u $DB_USER -h $DB_ADDRESS | fgrep $DB_DATABASE )
if [[ $STATUS != "snorby" ]]; then
    mysql -u $DB_USER -h $DB_ADDRESS -e "CREATE DATABASE snorby"
    mysql -u $DB_USER -h $DB_ADDRESS -e "GRANT ALL ON snorby.* TO $DB_USER@'%' IDENTIFIED BY '$DB_PASS'"
    mysql -u $DB_USER -h $DB_ADDRESS -e "flush privileges"
    cd /usr/local/src/snorby
    bundle install
    bundle exec rake snorby:setup
fi

# Download latest rules when provided with valid Oinkcode from snort.org
if [ $OINKCODE != "community" ]; then
    wget -O /tmp/rules.tar.gz https://www.snort.org/rules/snortrules-snapshot-2970.tar.gz?oinkcode=$OINKCODE
    rm -rf      /etc/snort/rules
    mkdir -p    /etc/snort/rules
    tar zxvf    /tmp/rules.tar.gz -C /etc/snort/rules --strip-components=1
    rm -f       /tmp/rules.tar.gz
fi

# User params
SNORBY_USER_PARAMS=$@
if [ -z "$SNORBY_USER_PARAMS" ]; then
    SNORBY_USER_PARAMS=" -e production"
fi

SNORBY_CONFIG=${SNORBY_CONFIG:="/usr/local/src/snorby/config/snorby_config.yml"}

# Internal params
SNORBY_CMD="bundle exec rails server ${SNORBY_USER_PARAMS}"

#######################################
# Echo/log function
# Arguments:
#   String: value to log
#######################################
log() {
  if [[ "$@" ]]; then echo "[`date +'%Y-%m-%d %T'`] $@";
  else echo; fi
}

# Launch Snorby
log $SNORBY_CMD
cd /usr/local/src/snorby && $SNORBY_CMD

# Exit immidiately in case of any errors or when we have interactive terminal
if [[ $? != 0 ]] || test -t 0; then exit $?; fi
log "Snorby started with $SNORBY_CONFIG config" && log
