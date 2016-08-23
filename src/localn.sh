#!/usr/bin/env bash
set -e

root=$PWD

if [ "$1" == "init" ]; then
    echo export PATH="$root/.localn/bin/:$PATH"
    exit
fi
abort(){
    echo "$@"
    exit 1
}
check_command(){
    which "$1" >/dev/null ||  abort command "$1" not found...

}

check_command wget
check_command realpath
check_command egrep
check_command grep
check_command fgrep
check_command sort
check_command tail
check_command head
check_command tr

WGET_PARAMS=( "--no-check-certificate"
              "-q"
              "-O-")
GET="wget ${WGET_PARAMS[*]}"
MIRROR=https://nodejs.org/dist/


display_latest_stable_version() {
  $GET 2> /dev/null ${MIRROR} \
    | egrep "</a>" \
    | egrep -o '[0-9]+\.[0-9]*[02468]\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tail -n1
}
display_latest_lts_version() {

  local folder_name=$($GET 2> /dev/null ${MIRROR} \
    | egrep "</a>" \
    | egrep -o 'latest-[a-z]{2,}' \
    | sort \
    | tail -n1)

  $GET 2> /dev/null "${MIRROR}/$folder_name/" \
    | egrep "</a>" \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | head -n1
}

display_latest_version() {
  $GET 2> /dev/null ${MIRROR} \
    | egrep "</a>" \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | egrep -v '^0\.[0-7]\.' \
    | egrep -v '^0\.8\.[0-5]$' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tail -n1
}
display_remote_versions() {
  $GET 2> /dev/null ${MIRROR} \
    | egrep "</a>" \
    | egrep -o '[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -u -k 1,1n -k 2,2n -k 3,3n -t . \
    | tr " " "\n"

}

#display_latest_stable_version
#display_latest_lts_version
#display_latest_version

#display_remote_versions

check_version_availible(){
    display_remote_versions | grep  . | grep -q -- "$1"
}

install_node(){
    check_version_availible "$1" || abort version \""$1"\" not availible
    url="http://nodejs.org/dist/v$1/node-v$1-${os}-${arch}.tar.gz"
    cd ./.localn/
    echo -n "Downloading node version (if not cached): $1..."
    wget -cq "$url"
    echo -e '\b\b\b Done'
    test -d "$(basename "$url" .tar.gz)" || (
        echo -n "Unpackingnode version: $1..."
        tar -xf "$(basename "$url")"
        echo -e '\b\b\b Done'
    )


    rm -rf "$root/.localn/bin/"
    mkdir -p "$root/.localn/bin/"
    cd "$(basename "$url" .tar.gz)/bin"
    ln -s "$(realpath node)" "$root/.localn/bin/node"
    ln -s "$(realpath npm*)" "$root/.localn/bin/npm"

    echo
    echo
    echo -n "node version: "
    node -v
    echo -n "npm  version: "
    npm -v
}

install_module(){
    npm i -g "$1"
    nodepath="$root/.localn/node-$(node -v)-${os}-${arch}"
    for bin in ${nodepath}/bin/* ; do
    bn="$(basename "$bin")"
    if [ "$bn" == "node" ]; then
        continue
    fi
    if [ "$bn" == "npm" ]; then
        continue
    fi
    targetpath="$root/.localn/bin/${bn}"
    test -e "$targetpath" && rm "$targetpath"
    ln -s "$(realpath "$bin")" "$targetpath"
    done

}

    os=$(uname -s)
    os=$(echo "$os" | tr '[:upper:]' '[:lower:]' )
    arch=$(uname -m | sed 's/x86_64/x64/' | sed 's/i.86/x86/')

echo "$PATH" | fgrep -q "$root/.localn/bin" || abort localn is not in path, you should run \$\("$0" init\)

mkdir -p ./.localn/bin/
which wget >/dev/null || abort wget required


case $1 in
    "")
        echo "HELP"
        ;;
    "stable")
        install_node "$(display_latest_stable_version)"
        ;;
    "lts")
        install_node "$(display_latest_lts_version)"
        ;;
    "latest")
        install_node "$(display_latest_version)"
        ;;
    "module")
        install_module "$2"
        ;;
    *)
        install_node "$1"
esac
