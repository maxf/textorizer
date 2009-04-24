#!/bin/sh
DATESTRING=`date "+%Y%m%d"`
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources/sketch.icns
zip -r textorizer-windows-${DATESTRING}.zip application.windows
zip -r textorizer-macosx--${DATESTRING}.zip application.macosx
zip -r textorizer-linux-${DATESTRING}.zip application.linux

scp *.zip *.png dreamhost:lapin-bleu.net/software/textorizer
