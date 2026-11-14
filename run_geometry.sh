#!/bin/bash
# Write the geometry files (scene.xml for AppCSXCAD, PEC/material VTK for ParaView). No simulation, a few minutes in all.
#   ./run_geometry.sh            TX alone + jammer alone + scene (0.1 m) for stages A, B, C, D
#   ./run_geometry.sh B          the same for Stage B only (plus the TX alone)
#   ./run_geometry.sh B scene 500   one case: stage, tx|jam|scene, distance in mm (scene only)
# If MATLAB is not found:  MATLAB=/Applications/MATLAB_R2025a.app/bin/matlab ./run_geometry.sh
set -e
cd "$(dirname "$0")"
if [ -z "$MATLAB" ]; then
  MATLAB=$(ls -d /Applications/MATLAB_R*.app 2>/dev/null | sort | tail -1)/bin/matlab
fi
[ -x "$MATLAB" ] || { echo "MATLAB not found. Run: MATLAB=/Applications/MATLAB_Rxxxx.app/bin/matlab ./run_geometry.sh"; exit 1; }
run() { echo ">>> $1"; "$MATLAB" -batch "$1"; }
S=${1:-ABCD}
if [ -n "$2" ]; then
  run "G_geometry('$S', '$2', ${3:-100})"
else
  run "G_geometry('A', 'tx'); for s = '$S', G_geometry(s, 'jam'); G_geometry(s, 'scene', 100); end"
fi
echo "Done. Geometry: $(pwd)/results/geometry/"
