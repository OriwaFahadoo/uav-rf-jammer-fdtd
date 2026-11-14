# StageA V2: V2 changes (read first)

This is the complete, self-contained FDTD package of the stage, made from the original stage folder with exactly **two changes**
(everything else, including the geometry, is byte-identical to the original; compare with `diff`):
1. **Jammer port power 30 dBm** (`params/jammer_params.m`, `J.P_dBm = 30`; was 27). J/S ceiling is now 30 - 20 = +10 dB.
2. **Perfect impedance match** (`C3_postprocess.m`): the mismatch loss of the jammer port and of the TX port is removed from S21,
   coupling = S21 - 10log10(1-|S11_jam|^2) - 10log10(1-|S11_TX|^2). The raw value stays in `coup_raw` inside the script.
   The numbers it writes (`results/stageA/stageA_table.csv`, report, plots) are therefore the V2 numbers.

Geometry: the real lambda/4 whip on a 50 mm plate (bare omni).
Antenna (original run, free space): 0.72 dBi towards the TX (realized, 0.75 dBi peak in free space), omnidirectional.
The antenna checks and scene runs are unchanged, so a finished run of this folder reproduces the original antenna results; the
tables change by the +3 dB power and the 0.1 to 0.5 dB match correction.
Some numbers quoted further down in this file (J/S values, "what to compare with") are the ORIGINAL 27 dBm / with-mismatch values; add 3 dB plus the small match correction.
Run: `cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageA V2" && chmod +x run_stage.sh && ./run_stage.sh A` (same steps as before: `check`, `scene`, `post`).

---

## The VERT2450 option (documented offset, NOT part of the FDTD run)
The FDTD run of this folder is the real lambda/4 whip (0.72 dBi towards the TX, S11 -7.3 dB). Its EIRP is therefore only about
**30 dBm + 1.6 dBi = 31.6 dBm** (matched directivity 1.61 dBi), not 33 dBm. The "33 dBm EIRP / 3 dBi VERT2450" figure reported earlier is an **analytic
element swap**: the VERT2450 reference antenna (3 dBi, perfectly matched) is assumed, which raises the coupling by 3 - 1.61 = **+1.39 dB**
(not +2.28 dB, that would count the whip's 0.89 dB mismatch twice) and gives EIRP = 30 + 3 = 33 dBm. To apply it, add 1.39 dB to the coupling
(and to J, J/S) from this folder's table. It is an assumption (same pattern towards the horizon, coupling scaling with gain), not a simulation.

---

# Stages rebuilt on the four cases: how to run on your Mac

The TX is the settled Stage A dipole in every stage (52.2 mm, 0.5 m above the metal ground, 20 dBm).
Only the jammer changes:

| Stage | Jammer | Case |
|---|---|---|
| A | bare omni: 24.1 mm whip on a 50 mm plate | Case 3 |
| B | the same omni in a 90° corner reflector (S 6 cm, L 20 cm, H 15 cm) | Case 2 |
| C | RFSPACE TSA600 Vivaldi, board vertical, aimed at the TX | Case 4 |
| D | TSA600 + a corner reflector behind it | C + reflector |

## What you need
MATLAB and openEMS, the same ones that ran Stage A. Nothing else.
If openEMS is not in `/opt/local` (MacPorts), open `setup_paths.m` and set `OPENEMS_DIR` (or run `export OPENEMS_DIR=...` first).

## Run Stage A (about 10 to 20 min)
In Terminal:
```bash
cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageA V2"
chmod +x run_stage.sh          # once
./run_stage.sh A               # checks, 5 scene runs, results
open results/stageA            # the pictures and report
```
Keep the quotes: "EMS MAIN" has a space.

Or step by step in the MATLAB Command Window:
```matlab
cd('/Users/fahado/Documents/EMS MAIN/Stages V2/StageA V2')
C1_antenna_check('A', true, 'tx')   % TX alone (should give S11 -16.0 dB, 8.14 dBi, as in Stage A)
C1_antenna_check('A', true)         % jammer alone over the ground
C1_antenna_check('A', false)        % jammer alone in free space
C2_run_scene('A', [100 500 1000 2000])   % the scene at 0.1, 0.5, 1 and 2 m (the long step)
C2_run_scene('A', 1010, false)      % free space at 1.01 m: the check against the Case 3 figure
C3_postprocess('A')                 % numbers + quick plots
C4_make_report('A')                 % the full Stage A picture set + results/stageA/index.html
```
Finished scene runs are skipped if you run C2 again. To redo one, delete its folder in `results/`.

## What you get (results/stageA/)
* `index.html`: every picture on one page (`open results/stageA/index.html`)
* `report_stageA.txt`: S11, coupling, J, J/S, the TX power needed for +10 dB, compared with the settled Stage A
* `plots/`: the same picture set as the settled Stage A, same names:
  `00a/00b/00c_geometry_*`, `01_S11_and_impedance`, `01b_VSWR`, `02*_pattern_*_tx`, `03*_pattern_*_jam`,
  `04/05_pattern_3d_*`, `06_received_power_vs_frequency`, `07_coupling_S21_vs_frequency`,
  `08_pattern_polar_scene`, `09_pattern_3d_scene`, `10_receiver_power_vs_distance`, `Efield_map`,
  `JS_vs_frequency`, `match_coupling`, `pattern_horizontal`, `pattern_elevation`, `JS_vs_distance`,
  `coupling_vs_distance`, and `pattern_tx.csv`, `pattern_jam.csv`
* `patterns3d/*.vtk`: 3D patterns for ParaView
* `results/compare/`: all stages run so far on one plot: `compare_coupling_vs_distance`, `compare_JS_vs_distance`,
  `compare_coupling_vs_frequency`
* `stageA_table.csv`, `stageA_spectra.csv`: the numbers for Excel

Expected (simulated here): coupling -18.2 dB at 0.1 m, J/S -11.2 dB with the TX at 20 dBm,
TX power for J/S = +10 dB: -1.2 dBm. Free space at 1.01 m: -37.8 dB (Case 3 figure: -36.1 dB).

## Other stages
Same commands with B, C or D instead of A, e.g. `./run_stage.sh B`. (C and D take longer: fine mesh on the
330 x 240 mm board, roughly 30 to 60 min each.)

## Files
| File | What it does |
|---|---|
| `params/tx_params.m` | the TX, frozen at the settled Stage A design. Don't change it per stage |
| `params/jammer_params.m` | the jammer of each stage: the only file that changes between stages |
| `params/case_params.m` | frequency, mesh, ground, distance |
| `C1_antenna_check.m`, `C2_run_scene.m`, `C3_postprocess.m` | the three steps |
| `lib/` | model builder and helpers |
