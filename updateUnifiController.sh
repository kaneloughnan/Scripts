#!/bin/sh
  
#Create the working directory
WORKING_DIR="/root/unifi"

#Remove the working directory if it already exists
if [ -d $WORKING_DIR ]; then
        rm -rf $WORKING_DIR
fi

#Create a new clean working directory
mkdir $WORKING_DIR
cd $WORKING_DIR
echo "Changed working directory to: ${WORKING_DIR}"

#Download the package info
wget http://dl.ubnt.com/unifi/debian/dists/stable/ubiquiti/binary-armhf/Packages.gz

#Get the package filenames
FILEURL=$(zcat Packages.gz | grep Filename | awk '{print $2}')
FILENAME=$(basename $FILEURL)

#Download the most up-to-date package
wget "http://dl.ubnt.com/unifi/debian/${FILEURL}"

#Compare the output of the package with the value from the SHA256 field in the Packages.gz file
if [ $(sha256sum $FILENAME | cut -d " " -f 1) != $(zcat Packages.gz | grep SHA256 | awk '{print $2}')  ]; then
        echo "Unifi SHA256 hash doesn't match SHA256 field in the Packages.gz"
        exit 0
fi

#Remove the tmp directory if it already exists
if [ -d "unpackaged" ]; then
        rm -rf unpackaged
fi

#Unpack the package so it can be editted
echo "Unpacking $FILENAME"
mkdir unpackaged
dpkg-deb -R $FILENAME tmp

CONTROL_FILE="tmp/DEBIAN/control"
FIXED_PACKAGE="fixed-${FILENAME}"

#Remove all mongodb dependancies as the package will work with the current mongodb
sed -i '/mongodb-server/d' $CONTROL_FILE
echo "Removed mongodb-server dependancies from ${CONTROL_FILE}"

#Repackage the Unifi controller package
dpkg-deb -b tmp $FIXED_PACKAGE

#Install Unifi Controller
dpkg -i $FIXED_PACKAGE

#Remove all created files
echo "Removing all created files"
cd ..
rm -rf $WORKING_DIR

echo "Unifi Controller successfully installed/updated"
