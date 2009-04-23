#!/bin/sh
zip -r textorizer12.windows.zip application.windows
zip -r textorizer12.macosx.zip application.macosx
zip -r textorizer12.linux.zip application.linux

scp *.zip lapin-bl.eu/textorizer12