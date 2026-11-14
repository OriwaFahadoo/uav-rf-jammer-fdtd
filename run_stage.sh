#!/bin/bash
# Run one stage from the terminal, MATLAB in the background (no window).
#   ./run_stage.sh A          everything for Stage A: antenna checks, the 5 scene runs, results
#   ./run_stage.sh A check    only the antenna checks (TX alone, jammer alone)
#   ./run_stage.sh A scene    only the scene runs (0.1, 0.5, 1, 2 m over the ground + 1.01 m free space)
#   ./run_stage.sh A post     only the numbers and the full picture set (no simulation)
# If MATLAB is not found:  MATLAB=/Applications/MATLAB_R2025a.app/bin/matlab ./run_stage.sh A
set -e
cd "$(dirname "$0")"
S=${1:?usage: ./run_stage.sh A|B|C|D [all|check|scene|post]}; WHAT=${2:-all}
if [ -z "$MATLAB" ]; then
  MATLAB=$(ls -d /Applications/MATLAB_R*.app 2>/dev/null | sort | tail -1)/bin/matlab
fi
[ -x "$MATLAB" ] || { echo "MATLAB not found. Run: MATLAB=/Applications/MATLAB_Rxxxx.app/bin/matlab ./run_stage.sh $S"; exit 1; }
run() { echo ">>> $1"; "$MATLAB" -batch "$1"; }
case "$WHAT" in
  check) run "C1_antenna_check('A', true, 'tx'); C1_antenna_check('$S', true); C1_antenna_check('$S', false)";;
  scene) run "C2_run_scene('$S', [100 500 1000 2000]); C2_run_scene('$S', 1010, false)";;
  post)  run "C3_postprocess('$S'); C4_make_report('$S')";;
  all)   run "C1_antenna_check('A', true, 'tx'); C1_antenna_check('$S', true); C1_antenna_check('$S', false)"
         run "C2_run_scene('$S', [100 500 1000 2000]); C2_run_scene('$S', 1010, false)"
         run "C3_postprocess('$S'); C4_make_report('$S')";;
  *) echo "unknown step $WHAT (use all, check, scene or post)"; exit 1;;
esac
echo "Done. Results: $(pwd)/results/stage$S/"
