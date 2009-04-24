#!/bin/sh
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources
cp Textorizer.icns application.macosx/textorizer.app/Contents/Resources/sketch.icns
zip -r textorizer.windows.zip application.windows
zip -r textorizer.macosx.zip application.macosx
zip -r textorizer.linux.zip application.linux

scp *.zip *.png dreamhost:lapin-bleu.net/software/textorizer
