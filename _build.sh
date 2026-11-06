#!/bin/bash

set -e

# Variables
dlurl="https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
publisher_jar="publisher.jar"
input_cache_path="$(pwd)/input-cache/"
publisher_home="${FHIR_PUBLISHER_HOME:-$HOME/.fhir/tools/publisher}"
skipPrompts=false
upper_path="../"
scriptdlroot="https://raw.githubusercontent.com/HL7/ig-publisher-scripts/main"
build_bat_url="${scriptdlroot}/_build.bat"
build_sh_url="${scriptdlroot}/_build.sh"

function check_jar_location() {
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    jar_location="${input_cache_path}${publisher_jar}"
    echo "Found publisher.jar in input-cache"
  elif [ -f "${upper_path}${publisher_jar}" ]; then
    jar_location="${upper_path}${publisher_jar}"
    echo "Found publisher.jar in parent folder"
  elif [ -f "${publisher_home}/${publisher_jar}" ]; then
    jar_location="${publisher_home}/${publisher_jar}"
    echo "Found publisher.jar in FHIR publisher home"
  else
    jar_location="not_found"
    echo "publisher.jar not found in input-cache, parent folder, or FHIR publisher home"
  fi
}

function check_internet_connection() {
  local target="tx.fhir.org"
  local reachable=false

  if command -v ping > /dev/null 2>&1; then
    if ping -c 1 -W 5 "$target" > /dev/null 2>&1 \
    || ping -c 1 -w 5 "$target" > /dev/null 2>&1; then
      reachable=true
    fi
  elif command -v curl > /dev/null 2>&1; then
    if curl --silent --max-time 5 --output /dev/null "https://$target"; then
      reachable=true
    fi
  else
    echo "WARNING: Neither ping nor curl available — assuming offline."
  fi

  if [ "$reachable" = "true" ]; then
    online=true
    echo "We're online and $target is available."
    latest_version=$(curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest | grep tag_name | cut -d'"' -f4)
  else
    online=false
    echo ""
    echo "⚠️  WARNING: Working offline — this is not the normal mode."
    echo "   Some features (e.g. terminology rendering) will not work."
    echo ""
  fi
}



function update_publisher() {
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    update_location="${input_cache_path}${publisher_jar}"
    update_location_name="input-cache"
  else
    update_location="${publisher_home}/${publisher_jar}"
    update_location_name="FHIR publisher home"
  fi
  echo "Publisher jar location: ${update_location}"
  if [ "$skipPrompts" = "true" ]; then
    confirm="Y"
  else
    read -p "Download or update publisher.jar? (Y/N): " confirm
  fi
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "Downloading latest publisher.jar (~200 MB)..."
    mkdir -p "$(dirname "$update_location")"
    curl -L "$dlurl" -o "$update_location"
    echo "Publisher updated in ${update_location_name}"
  else
    echo "Skipped downloading publisher.jar"
  fi

  update_scripts_prompt
}


function update_scripts_prompt() {
  if [ "$skipPrompts" = "true" ]; then
    update_confirm="Y"
  else
    read -p "Update scripts (_build.bat and _build.sh)? (Y/N): " update_confirm
  fi
  if [[ "$update_confirm" =~ ^[Yy]$ ]]; then
    echo "Updating scripts..."
    curl -L "$build_bat_url" -o "_build.new.bat" && mv "_build.new.bat" "_build.bat"
    curl -L "$build_sh_url" -o "_build.new.sh" && mv "_build.new.sh" "_build.sh"
    chmod +x _build.sh
    echo "Scripts updated."
  else
    echo "Skipped updating scripts."
  fi
}


function run_publisher() {
  local extra_flags=("$@")
  if [ "$jar_location" != "not_found" ]; then
    echo "jar_location is: $jar_location"
    if [[ "$JAVA_TOOL_OPTIONS" != *"-Dfile.encoding=UTF-8"* ]]; then
      export JAVA_TOOL_OPTIONS+=" -Dfile.encoding=UTF-8"
    fi
    java $JAVA_OPTS -jar "$jar_location" -ig . "${extra_flags[@]}"
  else
    echo "IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home. Please run update. Aborting..."
  fi
}

function build_ig() {
  local args=()
  if [ "$online" = "false" ]; then
    args+=("-tx" "n/a")
  fi
  run_publisher "${args[@]}" "$@"
}

function build_nosushi() {
  run_publisher -no-sushi "$@"
}

function build_notx() {
  run_publisher -tx n/a "$@"
}

function build_continuous() {
  run_publisher -watch "$@"
}

function jekyll_build() {
  echo "Running Jekyll build..."
  jekyll build -s temp/pages -d output
}

function cleanup() {
  echo "Cleaning up temp directories..."
  if [ -f "${input_cache_path}${publisher_jar}" ]; then
    mv "${input_cache_path}${publisher_jar}" ./
    rm -rf "${input_cache_path}"*
    mkdir -p "$input_cache_path"
    mv "$publisher_jar" "$input_cache_path"
  fi
  rm -rf ./output ./template ./temp
  echo "Cleanup complete."
}

check_jar_location

# Handle command-line arguments
# Known first arguments select a menu option; anything else is passed through to the publisher
extraArgs=()
if [ $# -gt 0 ]; then
  case "$1" in
    update)  shift; extraArgs=("$@"); update_publisher; exit 0 ;;
    build)   shift; extraArgs=("$@"); check_internet_connection; build_ig "${extraArgs[@]}"; exit 0 ;;
    nosushi) shift; extraArgs=("$@"); check_internet_connection; build_nosushi "${extraArgs[@]}"; exit 0 ;;
    notx)    shift; extraArgs=("$@"); build_notx "${extraArgs[@]}"; exit 0 ;;
    jekyll)  jekyll_build; exit 0 ;;
    clean)   cleanup; exit 0 ;;
    exit)    exit 0 ;;
    *)
      # Unknown first arg - default to build, pass all args through
      extraArgs=("$@")
      run_publisher "${extraArgs[@]}"
      exit 0
      ;;
  esac
fi

# Interactive menu
check_internet_connection

# Compute default choice and reason
default_choice=2
default_reason="publisher is up to date"

if [ "$jar_location" = "not_found" ]; then
  default_choice=1
  default_reason="publisher not found"
elif [ "$online" = "false" ]; then
  default_choice=4
  default_reason="working offline"
elif [ -n "$latest_version" ]; then
  current_version=$(java -jar "$jar_location" -v 2>/dev/null | tr -d '\r')
  if [ "$current_version" != "$latest_version" ]; then
    default_choice=1
    default_reason="newer version available"
  fi
fi

echo "---------------------------------------------"
echo "Publisher: ${current_version:-unknown}; Latest: ${latest_version:-unknown}"
echo "Publisher location: $jar_location"
echo "Online: $online"
echo "---------------------------------------------"
echo
echo "Please select an option:"
echo "1) Download or update publisher"
echo "2) Build IG"
echo "3) Build IG without Sushi"
echo "4) Build IG without TX server"
echo "5) Jekyll build"
echo "6) Cleanup temp directories"
echo "0) Exit"
echo

# Read with timeout, but default if nothing entered
echo -n "Choose an option [default: $default_choice - $default_reason]: "
read -t 5 choice || choice="$default_choice"
choice="${choice:-$default_choice}"
echo "You selected: $choice"

case "$choice" in
  1) update_publisher ;;
  2) build_ig ;;
  3) build_nosushi ;;
  4) build_notx ;;
  5) jekyll_build ;;
  6) cleanup ;;
  0) exit 0 ;;
  *) echo "Invalid option." ;;
esac
