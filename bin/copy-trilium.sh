#!/usr/bin/env bash

shopt -s globstar

if [[ $# -eq 0 ]] ; then
    echo "Missing argument of target directory"
    exit 1
fi
if ! [[ $(which npm) ]]; then
    echo "Missing npm"
    exit 1
fi

# Trigger the TypeScript build
echo TypeScript build start
npx tsc
echo TypeScript build finished

# Copy the TypeScript artifacts
DIR="$1"
rm -rf "$DIR"
mkdir -pv "$DIR"

echo Webpack start
npm run webpack
echo Webpack finish

echo "Copying Trilium to build directory $DIR"

for d in 'images' 'libraries' 'src' 'db'; do
    cp -r "$d" "$DIR"/
done

for f in 'package.json' 'package-lock.json' 'README.md' 'LICENSE' 'config-sample.ini'; do
    cp "$f" "$DIR"/
done

script_dir=$(realpath $(dirname $0))
cp -Rv "$script_dir/../build/src" "$DIR"
cp "$script_dir/../build/electron.js" "$DIR"

# run in subshell (so we return to original dir)
(cd $DIR && npm install --only=prod)

if [[ -d "$DIR"/node_modules ]]; then
# cleanup of useless files in dependencies
    for d in 'image-q/demo' 'better-sqlite3/Release' 'better-sqlite3/deps/sqlite3.tar.gz' '@jimp/plugin-print/fonts' 'jimp/browser' 'jimp/fonts'; do
        [[ -e "$DIR"/node_modules/"$d" ]] && rm -rv "$DIR"/node_modules/"$d"
    done

# delete all tests (there are often large images as test file for jimp etc.)
    for d in 'test' 'docs' 'demo'; do
        find "$DIR"/node_modules -name "$d" -exec rm -rf {} \;
    done
fi

find $DIR/libraries -name "*.map" -type f -delete

d="$DIR"/src/public
[[ -d "$d"/app-dist ]] || mkdir -pv "$d"/app-dist
cp "$d"/app/share.js "$d"/app-dist/
cp -r "$d"/app/doc_notes "$d"/app-dist/

rm -rf "$d"/app
unset f d DIR
