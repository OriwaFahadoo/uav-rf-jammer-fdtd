# StageC V2: V2 changes (read first)

This is the complete, self-contained FDTD package of the stage, made from the original stage folder with exactly **two changes**
(everything else, including the geometry, is byte-identical to the original; compare with `diff`):
1. **Jammer port power 30 dBm** (`params/jammer_params.m`, `J.P_dBm = 30`; was 27). J/S ceiling is now 30 - 20 = +10 dB.
2. **Perfect impedance match** (`C3_postprocess.m`): the mismatch loss of the jammer port and of the TX port is removed from S21,
   coupling = S21 - 10log10(1-|S11_jam|^2) - 10log10(1-|S11_TX|^2). The raw value stays in `coup_raw` inside the script.
   The numbers it writes (`results/stageC/stageC_table.csv`, report, plots) are therefore the V2 numbers.

Geometry: the real TSA600 Vivaldi alone (330 x 240 mm, 125 ohm port), no reflector.
Antenna (original run, free space): 10.61 dBi towards the TX, HPBW E 31 / H 60 deg, F/B 16.3 dB in the original run.
The antenna checks and scene runs are unchanged, so a finished run of this folder reproduces the original antenna results; the
tables change by the +3 dB power and the 0.1 to 0.5 dB match correction.
Some numbers quoted further down in this file (J/S values, "what to compare with") are the ORIGINAL 27 dBm / with-mismatch values; add 3 dB plus the small match correction.
Run: `cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageC V2" && chmod +x run_stage.sh && ./run_stage.sh C` (same steps as before: `check`, `scene`, `post`).

---

# Stage C (Case 4, TSA600): how to run on your Mac

This folder is self-contained: `EMS MAIN/Stages V2/StageC V2`. Everything Stage C needs is inside it, and the results are
written to `Stage C/results/` (`results/stageC/` is the one to open). My cloud results for comparison are in `results_from_cloud/stageC/`.

The TX is the settled Stage A dipole (52.2 mm, 0.5 m above the metal ground, 20 dBm), unchanged.
The jammer is the RFSPACE TSA600 directional Vivaldi antenna (330 x 240 mm board, 11 dBi at 2.4 GHz in the
datasheet), aimed at the TX, 30 dBm, fed through a 125 ohm port (ideal transformer balun).

## What you need
The same MATLAB and openEMS that ran Stage A. Nothing else, and no folder to create: the script makes
`results/` and everything in it. (The TX-alone check is run for you.)

## Run Stage C (allow up to about an hour; the scene runs are the long step)
In Terminal:
```bash
cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageC V2"
chmod +x run_stage.sh
./run_stage.sh C               # checks, 5 scene runs, results
open results/stageC/index.html # the report and every picture on one page
```
Keep the quotes: "EMS MAIN" has a space.

Or step by step in the MATLAB Command Window:
```matlab
cd('/Users/fahado/Documents/EMS MAIN/Stages V2/StageC V2')
C1_antenna_check('C', true)         % TSA600 alone over the ground
C1_antenna_check('C', false)        % TSA600 alone in free space
C2_run_scene('C', [100 500 1000 2000])   % the scene at 0.1, 0.5, 1 and 2 m (the long step)
C2_run_scene('C', 1010, false)      % free space at 1.01 m: the check against the Case 4 figure
C3_postprocess('C')                 % numbers + report
C4_make_report('C')                 % the full Stage A picture set + results/stageC/index.html
```
Finished scene runs are skipped if you run C2 again. To redo one, delete its folder in `results/`.
To remake only the numbers and pictures (no simulation): `./run_stage.sh C post`.

## What you get (results/stageC/)
* `index.html`: the report and every picture on one page
* `report_stageC.txt`: S11, coupling, J, J/S, the TX power needed for +10 dB
* `plots/`: the same picture set as Stage A, same names
* `patterns3d/*.vtk`: 3D patterns for ParaView
* `stageC_table.csv`, `stageC_spectra.csv`: the numbers for Excel

## Expected (simulated in the cloud)
| | value |
|---|---|
| TSA600 alone, free space | 10.6 dBi towards the TX, S11 -29.3 dB, resonance 2.433 GHz |
| TX alone (PEC) | S11 -16.0 dB, 8.14 dBi |

| Distance | Coupling | J/S (TX 20 dBm) | TX power for +10 dB |
|---|---|---|---|
| 0.1 m | -18.2 dB | -11.2 dB | -1.2 dBm |
| 0.5 m | -24.4 dB | -17.4 dB | -7.4 dBm |
| 1 m | -27.3 dB | -20.3 dB | -10.3 dBm |
| 2 m | -35.9 dB | -28.9 dB | -18.9 dBm |

Free space at 1.01 m: -29.0 dB (Case 4 figure: -27.1 dB). J/S can not exceed 10 dB (30 dBm - 20 dBm).
Your numbers should match to about 0.1 dB.

## Where Stage C is set
`params/jammer_params.m`, block `case 'C'`: the TSA600 model. Nothing else changes between stages.
