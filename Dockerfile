#
# This will install Apache drill on the ipython/scipystack image
# It's based on:
#    https://github.com/mkieboom/apache-drill-docker/blob/master/Dockerfile
#
FROM ipython/scipystack

MAINTAINER "odewahn@oreilly.com"


#
# You need to apt-get update the first time you run this
# So, if this is your first build, comment this line out!
#
# RUN apt-get update

#
# Prerequisite: Install Java, tar and create Drill folders
# http://doc.mapr.com/display/MapR/Preparing+Each+Node#PreparingEachNode-java
#

RUN apt-get update && \
    apt-get install -yq openjdk-7-jre && \
    mkdir -p /opt/drill && \
    mkdir -p /drill-scripts

#
# Download and Install Apache Drill
# https://drill.apache.org/docs/installing-drill-on-linux-and-mac-os-x/
#
RUN curl -o apache-drill-1.1.0.tar.gz http://getdrill.org/drill/download/apache-drill-1.1.0.tar.gz && \
    tar zxpf apache-drill-1.1.0.tar.gz -C /opt/drill

#
# The default drill env file sucks up 3GB, which is a little large for
# our little containers.  So, this config file sets it to a smaller size
#
ADD drill-env.sh /opt/drill/apache-drill-1.1.0/conf/drill-env.sh

#
# Install MAPR ODBC driver
#    https://drill.apache.org/docs/installing-the-driver-on-linux/
#
# Does the ODBC driver have a Debian package? It comes as an RPM, but I need it as a Debian package.
# I use alien to convert it, but it would be simpler to just have it as a .deb to begin with.
#
RUN apt-get install -y alien dpkg-dev debhelper build-essential wget unixodbc-dev screen unzip nginx

RUN pip3 install pyodbc ipymd

WORKDIR /tmp

RUN wget http://package.mapr.com/tools/MapR-ODBC/MapR_Drill/MapRDrill_odbc_v1.1.0.1000/MapRDrillODBC-1.1.0.x86_64.rpm

RUN alien MapRDrillODBC-1.1.0.x86_64.rpm

RUN dpkg -i maprdrillodbc_1.1.0-2_amd64.deb


ENV LD_LIBRARY_PATH=/usr/local/lib:/opt/mapr/drillodbc/lib/64

RUN mkdir /usr/data

#
# Configure NGINX
#
ADD nginx-site /etc/nginx/sites-available
RUN /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/mapr .



#
# Install the USDA data source
#
RUN mkdir -p /tmp/sr27asc
WORKDIR /tmp/sr27asc
RUN wget https://www.ars.usda.gov/SP2UserFiles/Place/12354500/Data/SR27/dnload/sr27asc.zip && \
    unzip sr27asc.zip && \
    rm sr27asc.zip


# Set up the PYTHONPATH info
RUN ipython profile create
RUN echo "c.NotebookApp.contents_manager_class = 'ipymd.IPymdContentsManager'" >> /root/.ipython/profile_default/ipython_notebook_config.py
RUN echo "c.IPymdContentsManager.format = 'markdown'" >> /root/.ipython/profile_default/ipython_notebook_config.py


#
# Now add the codebase as the home directory
#
ADD . /usr/home

WORKDIR /usr/home
RUN chmod +x start.sh