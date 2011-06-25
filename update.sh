#/bin/bash

if [ $# -lt 1 ]; then
  echo 'Usage '`basename "$0"`' qpid-dir'
  exit 1
fi

SELF=`realpath $0`
OWN_DIR=`dirname "$SELF"`
QPID_DIR=`realpath $1`

# Remove all destination files the cqpid_php repository.
find "$OWN_DIR" -type f | grep -v '\.svn' | grep -v 'update.sh' | xargs rm -f

cd "$QPID_DIR"
# Copy all changed files from the Qpid source to the qpid_php repository.
svn status | grep -v '^?' | cut -b9- | xargs -I{} cp "{}" "../cqpid_php/{}" 2>&1 | grep -v 'omitting directory'
# Re-create the cqpid_php diff file.
svn diff > "$OWN_DIR/cqpid_php.diff"

# Copy any other dependencies to the cqpid_php checkout.
cp '/usr/share/cmake-2.8/Modules/FindPHPDev.cmake' "$OWN_DIR"
