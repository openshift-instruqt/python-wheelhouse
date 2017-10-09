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
  --image-stream python:3.5
```

For Python 2.7 you would use:

```
oc new-build --strategy=source --name python27-wheelhouse \
  --code https://github.com/openshift-katacoda/python-wheelhouse \
  --image-stream python:2.7
```

Using the ``s2i`` Command Line Tool
-----------------------------------

To use the S2I builder image created locally with the ``s2i`` command line tool run:

```
s2i build <source-files> python35-wheelhouse <image-name>
```

Replace ``<source-files>`` with a local file system path, or a URL for a hosted Git repository which contains the ``requirements.txt`` file describing the packages you want to turn into wheels. Replace ``<image-name>`` with the name you wish to use for the container image created.

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
oc new-build --name <application-name> \
  --image-stream python:3.5 \
  --code <source-files> \
  --source-image <application-name>-wheelhouse \
  --source-image-path /opt/app-root/wheelhouse/.:.s2i/wheelhouse \
  --env PIP_FIND_LINKS=.s2i/wheelhouse
```

The ``PIP_FIND_LINKS`` could also be set in a ``.s2i/environment`` file, or in a custom ``assemble`` script.

For a working example which automatically detects the presence of the wheelhouse directory via a custom ``assemble`` script and sets ``PIP_FIND_LINKS``, try:

```
oc new-build --name blog \
  --image-stream python:3.5 \
  --code https://github.com/openshift-katacoda/blog-django-py \
  --source-image blog-wheelhouse \
  --source-image-path /opt/app-root/wheelhouse/.:.s2i/wheelhouse
```

When the build has finished, then deploy the image:

```
oc new-app --image-stream blog
oc expose svc/blog
```

Whenever the ``requirements.txt`` file is changed to add more Python packages, trigger a rebuild of the wheelhouse. Subsequent builds of the application will then be quicker as they will reuse the Python wheels from the wheelhouse image.

How to Run a Disconnected Build
-------------------------------

The examples above rely on you still having access to PyPi to download the Python packages when building the wheelhouse. When building the application using the wheelhouse, it acts a local repository to speed up installs. If a version of a package isn't in the wheelhouse, or the version of the package is not pinned and a newer version is available on PyPi, then the package will still be downloaded and installed from PyPi.

To create a Python wheelhouse and use it for builds in a totally disconnected environment where no Internet access is available, some additional steps and configuration are required.

For a disconnected build you first need to download all the Python packages you want to be able to later install when the application is being built and deployed in OpenShift. Obviously for this step you will need to have Internet access available.

Create an empty directory to contain all the packages you want to pull down and populate the Python wheelhouse with. Add to this directory the ``requirements.txt`` file listing the packages. Run the command:

```
pip download -r requirements.txt --dest packages
```

This will populate the ``packages`` subdirectory with everything which is downloaded.

Because the Python S2I builders bundled with OpenShift do not always have the latest versions of the ``pip``, ``setuptools`` and ``wheel`` packages, the wheelhouse when being built will first attempt to update them to the latest version. If this is not done, various Python packages may not install correctly due to bugs in the older versions of these packages.

You should also therefore run the following command to pull down latest versions of these packages.

```
pip download pip setuptools wheel --dest packages
```

Note that the above commands only download packages, they do not attempt to compile packages which have C extension components.

Next we create the wheelhouse image from this directory. We are going to use a binary input build so the first create the build configuration.

```
oc new-build --name <application-name>-wheelhouse --binary \
  --image-stream python35-wheelhouse \
  --env PIP_FIND_LINKS=packages \
  --env PIP_NO_INDEX=true
```

The ``PIP_NO_INDEX`` environment variable ensures that ``pip`` does not try and pull down packages from PyPi. The ``PIP_FIND_LINKS`` environment variable tells ``pip`` to instead look in the ``packages`` subdirectory where all the downloaded packages are installed.

Trigger the build, uploading the contents of the current directory as the input for the build.

```
oc start-build <application-name>-wheelhouse --from-dir=.
```

The wheelhouse has now been created which contains all required packages, compiled into Python wheels.

A build configuration for the application is created similar to before, but with the ``PIP_NO_INDEX`` environment variable also being set so ``pip`` doesn't attempt to download packages from PyPi.

```
oc new-build --name <application-name> \
  --image-stream python:3.5 \
  --code <source-files> \
  --source-image <application-name>-wheelhouse \
  --source-image-path /opt/app-root/wheelhouse/.:.s2i/wheelhouse \
  --env PIP_FIND_LINKS=.s2i/wheelhouse \
  --env PIP_NO_INDEX=true
```
