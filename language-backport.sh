#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <repo> <target-branch> <source-branch>"
    echo "Example: $0 core stable10 master"
    exit 1
fi

set -e

REPO=$1
TARGET=$2
SOURCE=$3

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORKING_DIR=language-backport-$REPO-$TARGET-$SOURCE
BACKPORT_BRANCH=backport/translations-$TARGET-$SOURCE

# Prepate directories
if [ -d "$WORKING_DIR" ]; then
    cd $WORKING_DIR
    git fetch origin -p
    git branch -D $SOURCE || true
    git branch -D $TARGET || true
    git branch -D $BACKPORT_BRANCH || true
else
    git clone -b $SOURCE git@github.com:owncloud/$REPO.git $WORKING_DIR
    cd $WORKING_DIR
fi

# Generate language difference
$SCRIPT_DIR/language-differ.sh $TARGET $SOURCE
php $SCRIPT_DIR/find.php

# Create backport
git checkout $TARGET
git checkout -b $BACKPORT_BRANCH

php $SCRIPT_DIR/find.php start

git commit -am "Backport of languages from $SOURCE"
git push origin $BACKPORT_BRANCH

# open pull request on GitHub
xdg-open https://github.com/owncloud/$REPO/compare/$TARGET...$BACKPORT_BRANCH
