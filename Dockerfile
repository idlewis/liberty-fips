FROM icr.io/appcafe/open-liberty:kernel-slim-java17-openj9-ubi

# Add Liberty server configuration including all necessary features
COPY --chown=1001:0  server.xml /config/

# This script will add the requested XML snippets to enable Liberty features and grow image to be fit-for-purpose using featureUtility.
# Only available in 'kernel-slim'. The 'full' tag already includes all features for convenience.
RUN features.sh

# This script will add the requested server configurations, apply any interim fixes and populate caches to optimize runtime
RUN configure.sh

COPY tls.crt tls.key /config/
COPY --chown=1001:0 pkcs11cfg.cfg /config/
COPY --chown=1001:0 jvm.options /config/

USER 0

RUN yum install -y -q nss nss-tools; \
    openssl pkcs12 -export -name "default" -inkey "/config/tls.key" -in "/config/tls.crt" -out "/tmp/key.p12" -password pass:notverysecure; \
    mkdir -p /.pki/nssdb; \
    pk12util -i /tmp/key.p12 -W notverysecure -K "" -d /.pki/nssdb; \
    find /.pki -type d | xargs chmod ugo+rx; \
    find /.pki -type f | xargs chmod ugo+r; \
    rm /config/tls.key /config/tls.crt /tmp/key.p12

USER 1001:0
ENV HOME=/
