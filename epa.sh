#!/bin/bash

parse_yaml() {
    local prefix=$2
    local s
    local w
    local fs
    s='[[:space:]]*'
    w='[a-zA-Z0-9_]*'
    fs="$(echo @|tr @ '\034')"
    sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
    awk -F"$fs" '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
        if (length($3) > 0) {
            vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
            printf("%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, $3);
        }
    }' | sed 's/_=/+=/g'
}

epa-create-environment(){
  local env="${1}"

  virtualenv -p $(which "${env}") .epa/"${env}"
  source .epa/"${env}"/bin/activate

  pip install --upgrade pip
  pip install numpy
  pip install scipy

  [ -e requirements.txt ] && pip install -r requirements.txt
  [ -e requirements-test.txt ] && pip install -r requirements-test.txt
  [ -e requirements-doc ] && pip install -r requirements-doc.txt

  deactivate
}

epa-create(){
  # parse the config file and extract the variables
  eval $(parse_yaml epa.cfg __epa_)
  local variables=$(compgen -A variable | grep __epa_)

  if [ -n "${__epa_environments}" ]; then
    for env in "${__epa_environments[@]}"; do
      epa-create-environment "${env}"
    done
  fi

  for v in "${variables}"; do
    unset $v
  done
}

epa-update(){
  if [ -z "${EPA_ENV}" ]; then
    echo You need to be in an epa shell to update
    return
  fi

  pip install --upgrade pip
  pip install numpy
  pip install scipy

  [ -e requirements.txt ] && pip install -r requirements.txt
  [ -e requirements-test.txt ] && pip install -r requirements-test.txt
  [ -e requirements-doc.txt ] && pip install -r requirements-doc.txt
}

epa-list(){
  for f in $(ls .epa/); do
    echo "${f}"
  done
}

epa-enter(){
  local env
  local filename

  env="${1}"
  filename=$(mktemp)

  cat ~/.bashrc > "${filename}"
  echo export EPA_ENV=$(pwd)/.epa/"${env}" >> "${filename}"
  echo source .epa/"${env}"/bin/activate >> "${filename}"
  echo unset deactivate >> "${filename}"
  echo rm -f "${filename}" >> "${filename}"

  if [ -n "${EPA_ENV}" ]; then
    exec /bin/bash --rcfile "${filename}"
  else
    (/bin/bash --rcfile "${filename}")
  fi
}

epa-exit(){
  if [ -z "${EPA_ENV}" ]; then
    echo You need to be in an epa shell to exit from it
    return
  fi
  exit $*
}

epa(){
  while [ $# -gt 0 ]; do
    case "${1}" in
      enter)
        shift
        epa-enter $@
        ;;
      create)
        shift
        epa-create $@
        ;;
      update)
        shift
        epa-update $@
        ;;
      exit)
        shift
        epa-exit $@
        ;;
      list)
        shift
        epa-list $@
        ;;
      *)
        ;;
    esac
    shift
  done
}
