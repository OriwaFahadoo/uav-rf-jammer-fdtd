# StageD V2: V2 changes (read first)

This is the complete, self-contained FDTD package of the stage, made from the original stage folder with exactly **two changes**
(everything else, including the geometry, is byte-identical to the original; compare with `diff`):
1. **Jammer port power 30 dBm** (`params/jammer_params.m`, `J.P_dBm = 30`; was 27). J/S ceiling is now 30 - 20 = +10 dB.
2. **Perfect impedance match** (`C3_postprocess.m`): the mismatch loss of the jammer port and of the TX port is removed from S21,
   coupling = S21 - 10log10(1-|S11_jam|^2) - 10log10(1-|S11_TX|^2). The raw value stays in `coup_raw` inside the script.
   The numbers it writes (`results/stageD/stageD_table.csv`, report, plots) are therefore the V2 numbers.

Geometry: the real TSA600 + the current corner reflector (variant D3: S 120, L 400, H 300 mm).
Antenna (original run, free space): 11.95 dBi towards the TX, HPBW E 20 / H 54 deg, F/B 22.5 dB in the original run.
The antenna checks and scene runs are unchanged, so a finished run of this folder reproduces the original antenna results; the
tables change by the +3 dB power and the 0.1 to 0.5 dB match correction.
Some numbers quoted further down in this file (J/S values, "what to compare with") are the ORIGINAL 27 dBm / with-mismatch values; add 3 dB plus the small match correction.
Run: `cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageD V2" && chmod +x run_stage.sh && ./run_stage.sh D` (same steps as before: `check`, `scene`, `post`).

---

# Stage D (Case 4 TSA600 + corner reflector): how to run on your Mac

This folder is self-contained: `EMS MAIN/Stages V2/StageD V2`. Everything Stage D needs is inside it, and the results are
written to `Stage D/results/` (`results/stageD/` is the one to open).

The TX is the settled Stage A dipole (52.2 mm, 0.5 m above the metal ground, 20 dBm), unchanged.
The jammer is the Stage C TSA600 (330 x 240 mm Vivaldi, 125 ohm port, 30 dBm) with a 90° corner reflector behind
its back edge, opening towards the TX: **S 120 mm, L 400 mm, H 300 mm** (variant D3).

## What you need
The same MATLAB and openEMS that ran Stage C. Nothing else, and no folder to create.

## Run Stage D
In Terminal:
```bash
cd "/Users/fahado/Documents/EMS MAIN/Stages V2/StageD V2"
chmod +x run_stage.sh
./run_stage.sh D               # checks, 5 scene runs, results
open results/stageD/index.html # the report and every picture on one page
```
Keep the quotes: "EMS MAIN" has a space.

**If it is interrupted, just run the same command again.** Finished antenna checks and finished scene runs
are skipped, so it carries on with the first unfinished run (a run that was cut in the middle starts again from its beginning).
One step at a time: `./run_stage.sh D check`, `./run_stage.sh D scene`, `./run_stage.sh D post` (numbers and pictures only).

## Mesh on the reflector: full resolution by default
The reflector plates are meshed at 2 mm (full resolution). That makes the model big. Cell counts (computed, not run on your Mac):

| Mesh on the reflector | Jammer alone (free / over ground) | Scene 0.1 m | Scene 2 m |
|---|---|---|---|
| **2 mm (default, full)** | 20.1 M / 23.2 M | 25.0 M | 49.1 M |
| 4 mm | | 13.2 M | 27.5 M |
| 6 mm (what the cloud run used) | 7.8 M / 9.0 M | 9.8 M | 20.8 M |

Memory is my estimate, not a measurement: openEMS needs roughly 100 to 150 bytes per cell, so the biggest run (49 M cells)
should need about 5 to 7 GB, which fits a 16 GB Mac, but close other big apps first. At your ~200 MC/s the 2 m scene
at 2 mm is probably 1 hour or more, so allow several hours for the whole Stage D (my estimate). For a quicker run:
```bash
D_RES=4 ./run_stage.sh D       # 4 mm reflector mesh, about half the cells
```
(Use the same D_RES value for every step of one run, and delete `results/` first if you change it.)

## What you get (results/stageD/)
* `index.html`: the report and every picture on one page
* `report_stageD.txt`: S11, coupling, J, J/S, the TX power needed for +10 dB
* `plots/`: the same picture set as Stage A, same names
* `patterns3d/*.vtk`: 3D patterns for ParaView
* `stageD_table.csv`, `stageD_spectra.csv`: the numbers for Excel
The all-stage compare plots (coupling and J/S vs distance) draw whichever stages have results in `results/`; this folder
only has Stage D, so copy the other stages' `results/stageX` folders in if you want them on one plot.

## What to compare with
* Jammer alone in free space, towards the TX: the D3 size test gave **11.95 dBi** (about 12.0 dBi). Your `check_jamD_free`
  line should be close to that. Stage C (TSA600 alone) gave 10.6 dBi towards the TX, so the reflector adds about 1.4 dB.
* Stage C, for reference (coupling): -18.2 / -24.4 / -27.3 / -35.9 dB at 0.1 / 0.5 / 1 / 2 m, and -29.0 dB in free space at 1.01 m.
  Stage D coupling is expected to be a little better than these; I have no finished Stage D numbers yet.
* J/S can not exceed 10 dB (30 dBm - 20 dBm).

## Where Stage D is set
`params/jammer_params.m`, block `case {'C','D',...}`: `V.D3 = [120 400 300]` is the reflector size (S, L, H in mm).
