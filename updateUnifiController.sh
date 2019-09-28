#!/bin/sh
  
#Create the working directory
WORKING_DIR = "/home/kloughnan/unifi"
mkdir $WORKING_DIR
cd $WORKING_DIR
wget http://dl.ubnt.com/unifi/debian/dists/stable/ubiquiti/binary-armhf/Packages.gz -O Packages.gz

FILEURL=$(zcat Packages.gz | grep Filename | awk '{print $2}')
FILENAME=$(basename $FILEURL)

wget "http://dl.ubnt.com/unifi/debian/${FILEURL}" -O ${FILENAME}

#Compare the output of the package with the value from the SHA256 field in the Packages.gz file
if [ "$(sha256sum $FILENAME | cut -d " " -f 1)" != "$(zcat Packages.gz | grep SHA256 | awk '{print $2}')"  ]; then
        echo "Unifi SHA256 hash doesn't match SHA256 field in the Packages.gz"
        exit 0
fi

#Remove the tmp directory if it already exists
if [ -d "tmp" ]; then
        rm -rf tmp
fi

mkdir tmp
echo "Unpacking $FILENAME"
dpkg-deb -R $FILENAME tmp

CONTROL_FILE="tmp/DEBIAN/control"
FIXED_PACKAGE="fixed-${FILENAME}"

sed -i '/mongodb-server/d' $CONTROL_FILE
echo "Removed mongodb-server dependancies from ${CONTROL_FILE}"

#Repackage the Unifi controller package
dpkg-deb -b tmp $FIXED_PACKAGE

#Install Unifi Controller
dpkg -i $FIXED_PACKAGE

echo "Removing all created files"

#Remove all created files
cd ..
rm -rf $WORKING_DIR