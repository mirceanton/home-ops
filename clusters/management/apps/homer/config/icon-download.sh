#!/bin/bash

# =================================================================================================
# HOMER ICONS GIT REPO
# =================================================================================================
apk add git
git clone https://github.com/NX211/homer-icons
mv homer-icons/png/* /icons/
# mv homer-icons/svg/* /icons/svg/

# =================================================================================================
# Custom Icons
# =================================================================================================
wget "https://icon-icons.com/downloadimage.php?id=169399&root=2699/PNG/512/&file=cisco_logo_icon_169399.png" -O /icons/cisco.png
