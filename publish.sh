#!/usr/bin/env bash

shopt -s extglob
set -o errtrace
set +o noclobber

export NOOP=
ASSUMEYES=0
VERBOSE=1

DEST=$1
BASE_URL=$2

# Pre-requisites {{{
function install-prereq() # {{{2
{
  if [[ -n $(brew info bar | grep '^Not installed$') ]]; then
    $NOOP brew install bar
  fi

  if [[ -n $(brew info jq | grep '^Not installed$') ]]; then
    $NOOP brew install jq
  fi
} # }}}2
# }}}

function main() # {{{2
{
  install-prereq

  for box_path in boxes/* ; do
    box=${box_path##*/}
    echo "Processing box ${box}"

    if [[ -f "$DEST/$box/metadata.json" && "$DEST/$box/metadata.json" -nt "$box_path/metadata.json" ]]; then
      echo "  Downloading Metadata"
      cp -f "$DEST/$box/metadata.json" "$box_path"
      chmod 644 "$box_path/metadata.json"
    fi
    metadata=$(cat  "$box_path/metadata.json")

    for provider_path in $box_path/* ; do
      [[ ! -d "$provider_path" ]] && continue
      provider=${provider_path##*/}
      echo "  Processing provider ${provider}"

      for box_filepath in $provider_path/*.box ; do
        box_file=${box_filepath##*/}
        echo "    Box file: ${box_file}"

        if [[ ! -f "${box_filepath}.md5" || "${box_filepath}.md5" -ot "${box_filepath}" ]]; then
          printf "    Calculating checksum..."
	  box_checksum=$(bar -n "${box_filepath}" | md5)
	  echo $box_checksum > "${box_filepath}.md5"
          echo '.'
        else
          box_checksum=$(cat "${box_filepath}.md5")
        fi
        echo "    Checksum: ${box_checksum}"

	metadata_version=$(echo "$metadata" | jq '.versions[] | select(.version=="0.1.0")')
	if [[ -z "$metadata_version" ]]; then
	  echo "    ERROR: Cannot find the box version in the metadata"
	  continue
	fi

	metadata_provider=$(echo "$metadata_version" | jq ".providers[] | select(.name==\"$provider\")")
	if [[ -z "$metadata_provider" ]]; then
	  echo "    Adding provider"
          echo "      Copying box file"
	  mkdir -p "$DEST/$box/$provider"
          bar -o "$DEST/$box/$provider/$box_file" "$box_filepath"
          #cp "$box_filepath" "$DEST/$box/$provider/$box_file" 

	  echo "$metadata" | jq "(.versions[] | select(.version==\"0.1.0\") | .providers) |= . + [{name: \"$provider\", url: \"$BASE_URL/$box/$provider/$box_file\", checksum_type: \"md5\", checksum: \"$box_checksum\"}]" > "$box_path/metadata.$$.json" && mv "$box_path/metadata.$$.json" "$box_path/metadata.json"
	  cp "$box_path/metadata.json" "$DEST/$box/metadata.json"
	  continue
	fi

	metadata_checksum=$(echo "$metadata_provider" | jq --raw-output '.checksum')
        echo "    Destination Checksum: ${metadata_checksum}"
	if [[ $box_checksum == $metadata_checksum ]]; then
          echo "    Destination box is already uploaded"
          continue
        else
          echo "    Copying box file"
          bar -o "$DEST/$box/$provider/$box_file" "$box_filepath"
          #cp "$box_filepath" "$DEST/$box/$provider/$box_file" 
          chmod 644 "$DEST/$box/$provider/$box_file" 

	  echo "$metadata" | jq "(.versions[] | select(.version==\"0.1.0\") | .providers[] | select(.name==\"$provider\") | .checksum) |= \"$box_checksum\"" > "$box_path/metadata.$$.json" && mv "$box_path/metadata.$$.json" "$box_path/metadata.json"
	  cp "$box_path/metadata.json" "$DEST/$box/metadata.json"
          chmod 644 "$box_path/metadata.json"
	fi
      done
    done
  done
} # }}}2

main $@
