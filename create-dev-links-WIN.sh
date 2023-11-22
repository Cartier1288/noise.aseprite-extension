# use this to replace an existing install of the package with links to the dev resources / scripts
# in the base directory of this repo.
#
# run this in the git bash console, CD'd inside the base directory of the repository
# you may need to run the terminal as administrator.
#
# CAREFUL, `__info.json` records the files that were installed, and aseprite removes them
# _individually_ when reinstalling/updating a package. therefore, it will remove the linked dev 
# files inadvertently if you try and reinstall while the links exist. before installing a 
# release, delete the dev-linked extension folder first.

LINKDIR="$APPDATA/Aseprite/extensions/noise-scripts"
FROMDIR="$PWD"

FILES="bin scripts noise-plugin.lua noise-keys.aseprite-keys package.json"

export MSYS=winsymlinks:nativestrict

echo "linking files from \"$FROMDIR\" to \"$LINKDIR\""; echo

for FILE in $FILES; do
    FROM="$FROMDIR/$FILE"
    TO="$LINKDIR/$FILE"

    echo "creating link from \"$FROM\" to \"$TO\""

    if [ -L $TO ]; then
        echo "a symlink already exists, overwriting"
        rm $TO
    elif [ -e $TO ]; then
        read -p "deleting existing file/folder at $TO, proceed? y/[n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf $TO
        fi
    fi
    
    ln -s $FROM $TO

    echo
done