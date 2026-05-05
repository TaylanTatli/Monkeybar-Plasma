#!/bin/bash
ID=$(jq -r '.KPlugin.Id' ../metadata.json)

echo "Parsing strings..."
find ../contents -name "*.qml" -o -name "*.js" | xgettext \
    --from-code=UTF-8 -L JavaScript \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 \
    -o template.pot -f -

for po in *.po; do
    if [ -f "$po" ]; then
        echo "Updating: $po"
        msgmerge -U "$po" template.pot
    fi
done

echo "Done!"
