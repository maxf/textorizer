#!/bin/sh
DATESTRING=`date "+%Y%m%d"`
rm textorizer-*.zip
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources/sketch.icns
zip -r textorizer-windows-${DATESTRING}.zip application.windows
zip -r textorizer-macosx-${DATESTRING}.zip application.macosx
zip -r textorizer-linux-${DATESTRING}.zip application.linux
ln -s  textorizer-linux-${DATESTRING}.zip textorizer-linux.zip
ln -s  textorizer-macosx-${DATESTRING}.zip textorizer-macosx.zip
ln -s  textorizer-windows-${DATESTRING}.zip textorizer-windows.zip

rsync -va *.zip *.png dreamhost:lapin-bleu.net/software/textorizer
