# Helper functions for getting badges.

# Get code quality color.
# ${1}:   Amount of bugs actually found.
# ${2}:   Maximum number of bugs above which color will be red. Defaults to 20.
# ${3}:   Maximum number of bugs above which color will be yellow. Defaults to
#         $1 / 2.
# Output: 24-bit hexadecimal representation of the color (xxxxxx).
get_code_quality_color() {
  local bugs=$1 ; shift  # shift will fail if there is no argument
  local max_bugs=${1:-20}
  local yellow_threshold=${2:-$(( max_bugs / 2 ))}

  local red=255
  local green=255
  local blue=0

  bugs=$(( bugs < max_bugs ? bugs : max_bugs))
  if test $bugs -ge $yellow_threshold ; then
    green=$(( 255 - 255 * (bugs - yellow_threshold) / yellow_threshold ))
  else
    red=$(( 255 * bugs / yellow_threshold ))
  fi

  printf "%02x%02x%02x" $red $green $blue
}

# Get code quality badge.
# ${1}:   Amount of bugs actually found.
# ${2}:   Badge text.
# ${3}:   Directory where to save badge to.
# ${3}:   Maximum number of bugs above which color will be red. Defaults to 20.
# ${4}:   Maximum number of bugs above which color will be yellow. Defaults to
#         $1 / 2.
# Output: 24-bit hexadecimal representation of the color (xxxxxx).
download_badge() {
  local bugs=$1 ; shift
  local badge_text="$1" ; shift
  local reports_dir="$1" ; shift
  local max_bugs=${1:-20}
  local yellow_threshold=${2:-$(( max_bugs / 2 ))}

  local code_quality_color="$(
    get_code_quality_color $bugs $max_bugs $yellow_threshold)"
  local badge="${badge_text}-${bugs}-${code_quality_color}"
  local response="$(
    curl --tlsv1 https://img.shields.io/badge/${badge}.svg \
      -o"$reports_dir/badge.svg" 2>&1
  )" || rm -f "$reports_dir/badge.svg"
  if ! cat "$reports_dir/badge.svg" \
     | grep -F 'xmlns="http://www.w3.org/2000/svg"' ; then
    echo "Failed to download badge to $reports_dir: $response"
    rm "$reports_dir/badge.svg"
  fi
}
