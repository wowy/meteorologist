#!/bin/bash
set -e 

TEMPLATE_DMG=dist/template.dmg

# "working copy" names for the intermediate dmgs
WC_DMG=wc.dmg
WC_DIR=wc
VERSION=`cat VERSION`
SOURCE_FILES="build/Deployment/Meteorologist.app dist/Readme.rtf"
MASTER_DMG="build/Meteorologist-${VERSION}.dmg"
echo ""
echo "------------------------ Building Project -----------------------"
echo ""
xcodebuild -configuration Deployment

if [ ! -f "${TEMPLATE_DMG}" ]
then
    bunzip2 --keep ${TEMPLATE_DMG}.bz2
fi
cp ${TEMPLATE_DMG} ${WC_DMG}

echo ""
echo "------------------------ Copying to Disk Image -----------------------"
echo ""
echo "unpacking dmg template"
mkdir -p "${WC_DIR}"
hdiutil attach "${WC_DMG}" -noautoopen -quiet -mountpoint "${WC_DIR}"
for i in ${SOURCE_FILES}; do
    echo "copying $i"
	rm -rf "${WC_DIR}/$i";
	cp -pr $i ${WC_DIR}/;
done

echo ""
echo "------------------------ Compressing disk image -----------------------"
echo ""
WC_DEV=`hdiutil info | grep "${WC_DIR}" | grep "/dev/disk" | awk '{print $1}'` && \
hdiutil detach ${WC_DEV} -quiet -force
rm -f "${MASTER_DMG}"
hdiutil convert "${WC_DMG}" -quiet -format UDZO -imagekey zlib-level=9 -o "${MASTER_DMG}"
rm -rf ${WC_DIR}
rm -f ${WC_DMG}

echo ""
echo "Disk Image Built: ${MASTER_DMG}"
echo ""
