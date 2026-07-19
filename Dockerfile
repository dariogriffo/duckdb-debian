ARG DEBIAN_DIST=bookworm
FROM debian:bookworm

ARG DEBIAN_DIST
ARG duckdb_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG DUCKDB_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/share/doc/duckdb
RUN mkdir -p /output/DEBIAN

COPY ${DUCKDB_RELEASE} /output/usr/bin/duckdb
RUN chmod 755 /output/usr/bin/duckdb
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/duckdb/
COPY output/changelog.Debian /output/usr/share/doc/duckdb/
COPY output/README.md /output/usr/share/doc/duckdb/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/duckdb/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/duckdb/changelog.Debian
RUN gzip -9n /output/usr/share/doc/duckdb/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/duckdb_VERSION/$duckdb_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

RUN dpkg-deb --build /output /duckdb_${FULL_VERSION}.deb
