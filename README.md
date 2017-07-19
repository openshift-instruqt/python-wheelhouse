Python Wheelhouse
=================

This repository contains a sample implementation of a [Source-to-Image (S2I)](https://github.com/openshift/source-to-image) builder image for generating Python wheels.

Two different ways are provided for building the S2I builder image. The first uses a ``Dockerfile`` to build the image from a generic S2I base image. The second uses a Python S2I builder to generate a new custom S2I image which overrides the existing behaviour of the Python S2I builder image.

The ``s2i`` command line tool mentioned in these instructions can be downloaded from:

* https://github.com/openshift/source-to-image/releases

Building the Image from the Dockerfile
--------------------------------------

To build the image from the ``Dockerfile``, checkout this source code repository and run ``docker build``.

```
docker build -t python-wheelhouse .
```

If wishing to build the image in OpenShift, you can use:

```
oc new-build --strategy=docker --name python-wheelhouse \
  --code https://github.com/openshift-katacoda/python-wheelhouse
```

Note that when building from the ``Dockerfile``, the resulting image will be for Python 3.5.

Building the Image Using Python S2I
-----------------------------------

To build the image using the Python S2I builder, checkout this source code repository and run ``s2i build``. You can use the builder for the version of Python you want to use.

For Python 3.5 you would use:

```
s2i build . centos/python-35-centos7 python35-wheelhouse
```

For Python 2.7 you would use:

```
s2i build . centos/python-27-centos7 python27-wheelhouse
```

If wishing to build the image in OpenShift, for Python 3.5 you would use:

```
oc new-build --strategy=source --name python35-wheelhouse \
  --code https://github.com/openshift-katacoda/python-wheelhouse \
  --image-stream centos/python-35-centos7
```

For Python 2.7 you would use:

```
oc new-build --strategy=source --name python27-wheelhouse \
  --code https://github.com/openshift-katacoda/python-wheelhouse \
  --image-stream centos/python-35-centos7
```

Using the ``s2i`` Command Line Tool
-----------------------------------

To use the S2I builder image created locally with the ``s2i`` command line tool run:

```
s2i build <source-files> python35-wheelhouse <image-name>
```

Replace ``<source-files>`` with a local file system path, or a URL for a hosted Git repository which contains the requirements file describing the packages you want to turn into wheels. Replace ``<image-name>`` with the name you wish to use for the container image created.

Use whatever technique is appropriate for your situation to copy the wheels created from the image. The wheels are located in the directory ``/opt/app-root/wheelhouse``.

Using the Builder Image with OpenShift
--------------------------------------

If using OpenShift, to generate Python wheels for the packages required by an application, run:

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
  --source-image-path /opt/app-root/wheelhouse/.:.s2i/wheelhouse
```

The ``assemble`` script for the application must be setup to configure ``pip`` to use the wheelhouse directory.

For a working example, try:

```
oc new-app --name blog \
  --image-stream python:3.5 \
  --code https://github.com/openshift-katacoda/blog-django-py \
  --source-image <application-name>-wheelhouse \
  --source-image-path /opt/app-root/wheelhouse/.:.s2i/wheelhouse
```

Whenever the ``requirements.txt`` file is changed to add more Python packages, trigger a rebuild of the wheelhouse. Subsequent builds of the application will then be quicker as they will reuse the Python wheels from the wheelhouse image.
