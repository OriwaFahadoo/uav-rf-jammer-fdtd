# StageB V2: V2 changes (read first)

This is the complete, self-contained FDTD package of the stage, made from the original stage folder with exactly **two changes**
(everything else, including the geometry, is byte-identical to the original; compare with `diff`):
1. **Jammer port power 30 dBm** (`params/jammer_params.m`, `J.P_dBm = 30`; was 27). J/S ceiling is now 30 - 20 = +10 dB.
2. **Perfect impedance match** (`C3_postprocess.m`): the mismatch loss of the jammer port and of the TX port is removed from S21,
   coupling = S21 - 10log10(1-|S11_jam|^2) - 10log10(1-|S11_TX|^2). The raw value stays in `coup_raw` inside the script.
   The numbers it writes (`results/stageB/stageB_table.csv`, report, plots) are therefore the V2 numbers.

Geometry: the real omni + 90 deg corner reflector (S 60, L 200, H 150 mm).
Antenna (original run, free space): 12.19 dBi towards the TX, HPBW E 48 / H 34 deg, F/B 28.4 dB in the original run.
The antenna checks and scene runs are unchanged, so a finished run of this folder reproduces the original antenna results; the
tables change by the +3 dB power and the 0.1 to 0.5 dB match correction.
Some numbers quoted further down in this file (J/S values, "what to compare with") are the ORIGINAL 27 dBm / with-mismatch values; add 3 dB plus the small match correction.
Run: `cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageB V2" && chmod +x run_stage.sh && ./run_stage.sh B` (same steps as before: `check`, `scene`, `post`).

---

# Stage B (Case 2): how to run on your Mac

This folder is self-contained: `EMS MAIN/Stages V2/StageB V2`. Everything Stage B needs is inside it, and the results are
written to `Stage B/results/` (`results/stageB/` is the one to open). My cloud results for comparison are in `results_from_cloud/stageB/`.

The TX is the settled Stage A dipole (52.2 mm, 0.5 m above the metal ground, 20 dBm), unchanged.
The jammer is the Stage A omni (24.1 mm whip on a 50 mm plate) inside a 90° corner reflector:
S 6 cm (apex to whip), L 20 cm (each side), H 15 cm, opening towards the TX. Jammer 30 dBm.

## What you need
The same MATLAB and openEMS that ran Stage A. Nothing else, and no folder to create: the script makes
`results/` and everything in it. (The TX-alone check is run for you, or reused if Stage A already made it.)

## Run Stage B (about 20 to 30 min)
In Terminal:
```bash
cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageB V2"
./run_stage.sh B               # checks, 5 scene runs, results
open  results/stageB/index.html # the report and every picture on one page
```
Keep the quotes: "EMS MAIN" has a space.

Or step by step in the MATLAB Command Window:
```matlab
cd('/Users/fahado/Documents/EMS MAIN/Stages V2/StageB V2')
C1_antenna_check('B', true)         % jammer + reflector alone over the ground
C1_antenna_check('B', false)        % jammer + reflector alone in free space
C2_run_scene('B', [100 500 1000 2000])   % the scene at 0.1, 0.5, 1 and 2 m (the long step)
C2_run_scene('B', 1010, false)      % free space at 1.01 m: the check against the Case 2 figure
C3_postprocess('B')                 % numbers + report
C4_make_report('B')                 % the full Stage A picture set +  results/stageB/index.html
```
Finished scene runs are skipped if you run C2 again. To redo one, delete its folder in `results/`.
To remake only the numbers and pictures (no simulation): `./run_stage.sh B post`.

## What you get (results/stageB/)
* `index.html`: the report and every picture on one page
* `report_stageB.txt`: S11, coupling, J, J/S, the TX power needed for +10 dB, compared with the settled Stage A
* `plots/`: the same picture set as Stage A, same names (00a to 10, Efield_map, JS_vs_frequency,
  match_coupling, pattern_horizontal, pattern_elevation, JS_vs_distance, coupling_vs_distance)
* `patterns3d/*.vtk`: 3D patterns for ParaView
* `results/compare/`: Stage A and B (and C, D once run) on one plot: coupling vs distance, J/S vs distance,
  coupling vs frequency
* `stageB_table.csv`, `stageB_spectra.csv`: the numbers for Excel

## Expected (simulated here)
| | value |
|---|---|
| jammer + reflector alone, free space | 12.2 dBi towards the TX, S11 -13.9 dB, front-to-back 28 dB |

| Distance | Coupling | J/S (TX 20 dBm) | TX power for +10 dB |
|---|---|---|---|
| 0.1 m | -11.7 dB | -4.7 dB | +5.3 dBm |
| 0.5 m | -20.1 dB | -13.1 dB | -3.1 dBm |
| 1 m | -26.5 dB | -19.5 dB | -9.5 dBm |
| 2 m | -28.7 dB | -21.7 dB | -11.7 dBm |

Free space at 1.01 m: -26.1 dB (Case 2 figure: -27.1 dB). Your numbers should match to about 0.1 dB.

## Where Stage B is set
`params/jammer_params.m`, block `case 'B'`: the reflector size (`J.corner.S`, `.L`, `.H`). Nothing else changes
between stages.
