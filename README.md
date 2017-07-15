Python Wheelhouse (Python 3.5)
==============================

This repository contains a sample implementation of a [Source-to-Image (S2I)](https://github.com/openshift/source-to-image) builder image for generating Python wheels.

Using the Builder Image with OpenShift
--------------------------------------

If using OpenShift, to directly import the S2I builder image run:

```
oc import-image openshiftkatacoda/python35-wheelhouse --confirm
```

To generate Python wheels for the packages required by an application, then run:

```
oc new-build --name <application-name>-wheelhouse \
  --image-stream python35-wheelhouse \
  --code <source-files>
```

The source files for the application should include a ``requirements.txt`` file listing the required Python packages.

For a working example, try:

```
oc new-build --name blog-wheelhouse \
  --image-stream python35-wheelhouse \
  --code https://github.com/openshift-katacoda/blog-django-py
```

The resulting wheelhouse image is then used as an image source in the build configuration for an application.

```
oc new-app --name <application-name> \
  --image-stream python:3.5 \
  --code <source-files> \
  --source-image <application-name>-wheelhouse \
  --source-image-path /opt/app-root/cache/wheelhouse/.:.s2i/wheelhouse
```

The ``assemble`` script for the application must be setup to configure ``pip`` to use the wheelhouse directory.

For a working example, try:

```
oc new-app --name blog \
  --image-stream python:3.5 \
  --code https://github.com/openshift-katacoda/blog-django-py \
  --source-image <application-name>-wheelhouse \
  --source-image-path /opt/app-root/cache/wheelhouse/.:.s2i/wheelhouse
```

Whenever the ``requirements.txt`` file is changed to add more Python packages, trigger a rebuild of the wheelhouse. Subsequent builds of the application will then be quicker as they will reuse the Python wheels from the wheelhouse image.
