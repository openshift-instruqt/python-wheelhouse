FROM centos/python-35-centos7:latest

LABEL io.k8s.description="Python Wheelhouse (Python 3.5)" \
      io.k8s.display-name="Python Wheelhouse (Python 3.5)" \
      io.openshift.tags="builder,python,python35,wheelhouse"

ENV CACHE_DIR="/opt/app-root/cache" \
    PIP_CACHE_DIR="/opt/app-root/cache/pip" \
    PIP_WHEEL_DIR="/opt/app-root/cache/wheelhouse" \
    PIP_NO_CACHE_DIR=""

RUN mkdir -p $PIP_CACHE_DIR $PIP_WHEEL_DIR && \
    echo "Python Wheelhouse (Python 3.5)" > $CACHE_DIR/README.txt

COPY assemble /usr/libexec/s2i/
COPY run /usr/libexec/s2i/
COPY save-artifacts /usr/libexec/s2i/
COPY usage /usr/libexec/s2i/
