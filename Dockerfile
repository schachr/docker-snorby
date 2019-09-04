FROM centos:7
LABEL maintainer=schachr@github.com

RUN \
    # Clean everything
    yum clean all && \
    # Install needed packages
    yum update -y && \
    yum install -y epel-release && \
    yum install -y tar wget git libxml2-devel libxslt-devel mariadb mariadb-devel postgresql-devel wkhtmltopdf && \
    yum clean all && \
    # Prepare ruby for Snorby
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -sSL https://get.rvm.io | bash -s -- --version 1.29.7 && \
    source /etc/profile.d/rvm.sh && \
    export PATH=$PATH:/usr/local/rvm/bin/ && \
    rvm reload && \
    rvm install 1.9.3 && \
    source /usr/local/rvm/scripts/rvm && \
    export PATH=$PATH:/usr/local/rvm/rubies/ruby-1.9.3-p551/bin && \
    # Install DAQ and Snort
    yum install -y daq && \
    yum install -y https://snort.org/downloads/snort/snort-2.9.14.1-1.centos7.x86_64.rpm && \
    # Install Community rules
    wget -O /tmp/community-rules.tar.gz https://www.snort.org/downloads/community/community-rules.tar.gz && \
    mkdir -p /etc/snort/rules && \
    tar zxvf /tmp/community-rules.tar.gz -C /etc/snort/rules --strip-components=1 && \
    rm -f /tmp/community-rules.tar.gz && \
    # Install Snorby
    source /usr/local/rvm/scripts/rvm && \
    source /etc/profile.d/rvm.sh && \
    export PATH=$PATH:/usr/local/rvm/rubies/ruby-1.9.3-p551/bin && \
    git clone git://github.com/Snorby/snorby.git /usr/local/src/snorby && \
    sed -i "s/gem 'byebug'/gem 'pry-byebug', platform: [:ruby_20]/g" /usr/local/src/snorby/Gemfile && \
    cd /usr/local/src/snorby && \
    ( gem install --user-install executable-hooks bundler ; bundle install ; bundle update do_mysql ; bundle update dm-mysql-adapter )

    # Try to fix wkhtmltopdf
RUN \
    yum install -y https://bitbucket.org/wkhtmltopdf/wkhtmltopdf/downloads/wkhtmltox-0.13.0-alpha-7b36694_linux-centos7-amd64.rpm

COPY container-files /

ENV \
    DB_ADDRESS=127.0.0.1 \
    DB_USER=user \
    DB_PASS=password \
    DB_DATABASE=snorby \
    SNORBY_CONFIG=/usr/local/src/snorby/config/snorby_config.yml \
    OINKCODE=community \
    TIMEZONE=UTC

ENTRYPOINT ["/bootstrap.sh"]
