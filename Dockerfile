FROM centos/python-35-centos7:latest

LABEL io.k8s.description="Wheelhouse (Python 3.5)" \
      io.k8s.display-name="Wheelhouse (Python 3.5)" \
      io.openshift.tags="builder,python,python35,wheelhouse"

COPY assemble /usr/libexec/s2i/
COPY run /usr/libexec/s2i/
COPY save-artifacts /usr/libexec/s2i/
COPY usage /usr/libexec/s2i/
