From alpine:latest

# Defining packages to install
ENV ESSENTIAL_PACKAGES="python3 postfix opendkim opendkim-utils" \
    UTILITY_PACKAGES="busybox mlocate vim" \
    BUILDER_PACKAGES="g++ gdbm-dev make openssl-dev"

# Installing packages
RUN apk update && \
    apk --no-cache --progress add $ESSENTIAL_PACKAGES $UTILITY_PACKAGES $BUILDER_PACKAGES

# building cyrus-sasl because alpine package give error
RUN wget https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.28/cyrus-sasl-2.1.28.tar.gz && \
    tar -xvzf cyrus-sasl-2.1.28.tar.gz && \
    cd cyrus-sasl-2.1.28 && \
    ./configure --enable-plain --enable-login --enable-cram --enable-digest --enable-ntlm && \
    make && \
    make install

# Removing non needed builder packages
RUN apk del $BUILDER_PACKAGES

# touch log file
RUN mkdir -p /var/log && touch /var/log/postfix.log

# setup user
RUN addgroup --gid 1000 app-user \
    && adduser --disabled-password --no-create-home --gecos "" --home /root --ingroup opendkim --ingroup postfix --ingroup root --uid 1000 app-user

USER app-user

WORKDIR /root
