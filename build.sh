#!/usr/bin/bash

FOXHOUND_VERSION="main" # or main for current
#FOXHOUND_VERSION="v118.0.1" # or main for current
FOXHOUND_OBJ_DIR="obj-tf-release" 
PLAYWRIGHT_VERSION="release-1.41"

CURRENT_DIR=$(dirname "$(readlink -f "$0" || exit 1)")
BASEDIR=$(realpath "${CURRENT_DIR}/..")

RED=$(tput setaf 1)
POWDER_BLUE=$(tput setaf 153)
NORMAL=$(tput sgr0)

_die() {
    [[ -n $1 ]] || {
        printf >&2 -- 'Usage:\n\t_die <message> [return code]\n'
        [[ $- == *i* ]] && return 1 || exit 1
    }

    printf >&2 -- '%s\n' "${RED}$1${NORMAL}"
    exit "${2:-1}"
}

_status() {
  echo -e "${POWDER_BLUE}${1}${NORMAL}"
}

_checkout_foxhound() {
  FOXHOUND_DIR="$1"
  _status "Cloning foxhound into ${FOXHOUND_DIR}"
  git clone https://github.com/SAP/project-foxhound.git "${FOXHOUND_DIR}"
}

_checkout_playwright() {
  PLAYWRIGHT_DIR="$1"
  _status "Cloning playwright into ${PLAYWRIGHT_DIR}"
  git clone https://github.com/microsoft/playwright.git "${PLAYWRIGHT_DIR}"

}

_prepare_playwright() {
  PLAYWRIGHT_DIR="$1"
  _status "Resetting Playwright (${PLAYWRIGHT_DIR}) to clean state"
  if [ ! -d "${PLAYWRIGHT_DIR}" ]; then
    _die "Playwright should reside in ${PLAYWRIGHT_DIR}, but this directory does not exist.."
  fi
  pushd "${PLAYWRIGHT_DIR}" > /dev/null || exit 1
  git fetch origin
  git reset --hard HEAD
  git checkout "$PLAYWRIGHT_VERSION"
  popd > /dev/null || exit 1
}

_prepare_foxhound() {
  FOXHOUND_DIR="$1"
  _status "Resetting Foxhound (${FOXHOUND_DIR}) to clean state"
  if [ ! -d "${FOXHOUND_DIR}" ]; then
    _die "Foxhound should reside in ${FOXHOUND_DIR}, but this directory does not exist"
    exit 1
  fi
  pushd "${FOXHOUND_DIR}" > /dev/null || exit 1
  git fetch origin
  git reset --hard HEAD
  _status "Checking out Foxhound version: ${FOXHOUND_VERSION}"
  git checkout "${FOXHOUND_VERSION}"
  if [ -d "${FOXHOUND_DIR}/juggler" ]; then
    _status "Deleting stale juggler"
    rm -rf "${FOXHOUND_DIR}/juggler"
  fi
  if [ ! -f "${FOXHOUND_DIR}/.mozconfig" ]; then
    _status "Setting default mozconfig from Ubuntu profile"
    cp "${FOXHOUND_DIR}/taintfox_mozconfig_ubuntu" "${FOXHOUND_DIR}/.mozconfig"	
  fi
  ./mach --no-interactive clobber
  ./mach --no-interactive bootstrap --no-system-changes --application-choice=browser
  if [ ! -d "${FOXHOUND_OBJ_DIR}" ]; then
    OBJ_DIR="$(grep -v -e "^#" "${FOXHOUND_DIR}/.mozconfig" | grep "MOZ_OBJDIR=@TOPSRCDIR@" | cut -d "/" -f 2 || _die "Unable to determine MOZ_OBJDIR and FOXHOUND_OBJ_DIR not set")"
    _die "FOXHOUND_OBJ_DIR not set, suggesting to set it to: ${OBJ_DIR}" 1
  fi
}

_build_foxhound() {
  FOXHOUND_DIR="$1"
  PLAYWRIGHT_DIR="$2"
  cp -r "${PLAYWRIGHT_DIR}/browser_patches/firefox/juggler" "juggler"
  git apply --index --whitespace=nowarn "${PLAYWRIGHT_DIR}/browser_patches/firefox/patches"/*
  ./mach build
}

_package_foxhound() {
  FOXHOUND_DIR="$1"
  PLAYWRIGHT_DIR="$2"
  _status "Packaging foxhound.."
  ./mach package
  mkdir -p "${FOXHOUND_OBJ_DIR}/dist/firefox/defaults/pref"
  cp "${PLAYWRIGHT_DIR}/browser_patches/firefox/preferences/playwright.cfg" "${FOXHOUND_OBJ_DIR}/dist/foxhound/"
  cp "${PLAYWRIGHT_DIR}/browser_patches/firefox/preferences/00-playwright-prefs.js" "${FOXHOUND_OBJ_DIR}/dist/foxhound/defaults/pref/"
  pushd "${FOXHOUND_OBJ_DIR}/dist" || exit 1
  zip -r foxhound_linux.zip foxhound
  _status "Zip located at '$(pwd  || true)/foxhound_linux.zip', done!"
}


_main() {
  echo "Working inside ${BASEDIR}"

  FOXHOUND_DIR="${BASEDIR}/project-foxhound"
  PLAYWRIGHT_DIR="${BASEDIR}/playwright"
  if [ ! -d "${FOXHOUND_DIR}" ]; then
    _checkout_foxhound "${FOXHOUND_DIR}"
  fi
  _prepare_foxhound "${FOXHOUND_DIR}"
  if [ ! -d "${PLAYWRIGHT_DIR}" ]; then
    _checkout_playwright "${PLAYWRIGHT_DIR}"
  fi
  _prepare_playwright "${PLAYWRIGHT_DIR}"
  #_status "Current dir: $(pwd || true)"
  _build_foxhound "${FOXHOUND_DIR}" "${PLAYWRIGHT_DIR}"
  _package_foxhound "${FOXHOUND_DIR}" "${PLAYWRIGHT_DIR}"
  
}

_main
