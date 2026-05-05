#!/bin/bash
ID=$(jq -r '.KPlugin.Id' ../metadata.json)

for po in *.po; do
    if [ -f "$po" ]; then
        LANG_CODE=$(basename "$po" .po)
        DEST="../contents/locale/$LANG_CODE/LC_MESSAGES/plasma_applet_$ID.mo"
        
        echo "Compiling: $LANG_CODE"
        mkdir -p $(dirname "$DEST")
        msgfmt "$po" -o "$DEST"
    fi
done

echo "Done!"
