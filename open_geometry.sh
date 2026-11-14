#!/bin/bash
# Open a geometry case in ParaView, coloured and labelled, from Terminal.
#   ./open_geometry.sh               the scene of this folder (0.1 m apart)
#   ./open_geometry.sh jam           the jammer alone      (tx = the TX alone)
#   ./open_geometry.sh B_scene_d0100 any folder name inside results/geometry/
#   ./open_geometry.sh --png         no ParaView: draw scene.png with python + vtk instead
#   ./open_geometry.sh jam --png
# ParaView is searched in /Applications, ~/Applications, Homebrew/MacPorts and by Spotlight.
cd "$(dirname "$0")"
PNG=0; ARG=""
for a in "$@"; do [ "$a" = "--png" ] && PNG=1 || ARG="$a"; done
SCENE=$(ls results/geometry | grep "_scene_" | head -1)
S=${SCENE%%_*}
case "$ARG" in
  "")    CASE="$SCENE";;
  scene) CASE="$SCENE";;
  jam)   CASE="${S}_jam";;
  tx)    CASE="TX_alone";;
  *)     CASE="$ARG";;
esac
DIR="$PWD/results/geometry/$CASE"
[ -f "$DIR/open_scene.py" ] || { echo "No such case: $DIR"; echo "Available:"; ls results/geometry; exit 1; }

find_paraview() {
  for p in /Applications/ParaView*.app/Contents/MacOS/paraview "$HOME"/Applications/ParaView*.app/Contents/MacOS/paraview \
           /opt/homebrew/bin/paraview /usr/local/bin/paraview /opt/local/bin/paraview; do
    [ -x "$p" ] && { echo "$p"; return; }
  done
  if command -v paraview >/dev/null 2>&1; then command -v paraview; return; fi
  app=$(mdfind "kMDItemCFBundleIdentifier == 'org.paraview.ParaView'" 2>/dev/null | head -1)
  [ -n "$app" ] && [ -x "$app/Contents/MacOS/paraview" ] && echo "$app/Contents/MacOS/paraview"
}

if [ "$PNG" = 0 ]; then
  PV=$(find_paraview)
  if [ -n "$PV" ]; then
    echo "ParaView: $PV"
    echo "Case:     $CASE"
    exec "$PV" --script="$DIR/open_scene.py"
  fi
  cat <<'M'
ParaView was not found on this Mac.
  Install it with Homebrew:  brew install --cask paraview
  or download it:            https://www.paraview.org/download/  (macOS, drag ParaView to Applications)
Then run this command again.

Without ParaView you can get a picture of the scene instead (needs python3 and the vtk package):
  pip3 install vtk
  ./open_geometry.sh --png
M
  exit 1
fi

PY=$(command -v python3 || command -v python)
[ -n "$PY" ] || { echo "python3 not found: install ParaView instead (brew install --cask paraview)"; exit 1; }
"$PY" -c "import vtk" 2>/dev/null || { echo "The python package vtk is missing. Run:  pip3 install vtk   (or install ParaView)"; exit 1; }
"$PY" "$PWD/lib/scene_png.py" "$DIR" "$DIR/scene.png" && { echo "Wrote $DIR/scene.png"; open "$DIR/scene.png"; }
