# How to run and modify the simulation

This guide covers what to install, how to run a stage, what each step does, where the results go, and how to change
the antennas, power or distances. For what the simulation is and what it found, see [README.md](README.md).

## 1. What you need

| Software | Needed for | Required |
|---|---|---|
| [openEMS](https://openems.de) with CSXCAD | The electromagnetic solver | Yes |
| MATLAB (any recent release) or GNU Octave 8.x | Building the models, running openEMS, post-processing | Yes |
| ParaView 5.x | Viewing the geometry and 3D patterns | No |
| AppCSXCAD (installed with openEMS) | Quick geometry viewer | No |
| Python 3 with NumPy and Matplotlib | `plot_cases.py` and `tools/compare_stages.py` | No |
| Python 3 with `vtk` (`pip3 install vtk`) | PNG pictures of the geometry without ParaView | No |

Installing openEMS:

- **macOS:** `sudo port install openEMS` (MacPorts) installs it in `/opt/local`.
- **Linux:** build from source, see https://docs.openems.de/install.html.
- **Windows:** download the release from https://github.com/thliebig/openEMS-Project/releases and unpack it to
  `C:\openEMS`.

The code looks for openEMS in `/opt/local`, `/opt/openEMS`, `~/opt/openEMS` and `C:\openEMS`. If yours is elsewhere,
set it once before running:

```bash
export OPENEMS_DIR=/path/to/openEMS
```

or edit `OPENEMS_DIR` at the top of `setup_paths.m`. To check that MATLAB can find it:

```matlab
setup_paths; which InitFDTD
```

### Computer

| Stage | Largest model | Approximate time for the whole stage |
|---|---|---|
| A, B | a few million cells | 10 to 30 minutes |
| C | about 10 to 25 million cells | 30 to 60 minutes |
| D | up to about 49 million cells (2 m scene) | several hours |

Times are for a laptop running openEMS on four threads. Stage D at full resolution needs an estimated 5 to 7 GB of
memory. Each stage writes several GB of raw data to `results/`.

## 2. Run a stage

### From Terminal (macOS or Linux)

```bash
cd uav-rf-jammer-fdtd
chmod +x run_stage.sh run_geometry.sh open_geometry.sh    # once
./run_stage.sh A
```

Replace `A` with `B`, `C` or `D`. To run only one part:

```bash
./run_stage.sh A check      # step 1 only: each antenna alone
./run_stage.sh A scene      # step 2 only: the five scene runs
./run_stage.sh A post       # steps 3 and 4 only: numbers and figures, no simulation
```

`run_stage.sh` looks for MATLAB in `/Applications`. If it is not found, give its path:

```bash
MATLAB=/Applications/MATLAB_R2025a.app/bin/matlab ./run_stage.sh A
```

If a run is interrupted, run the same command again. Finished runs are skipped, and it continues from the first
unfinished one.

### From the MATLAB or Octave Command Window

```matlab
cd('/path/to/uav-rf-jammer-fdtd')
C1_antenna_check('A', true, 'tx')          % TX alone over the ground
C1_antenna_check('A', true)                % jammer alone over the ground
C1_antenna_check('A', false)               % jammer alone in free space
C2_run_scene('A', [100 500 1000 2000])     % jammer + TX at 0.1, 0.5, 1 and 2 m (the long step)
C2_run_scene('A', 1010, false)             % jammer + TX at 1.01 m in free space
C3_postprocess('A')                        % coupling, J/S, report, tables
C4_make_report('A')                        % all figures and results/stageA/index.html
```

## 3. What each step does

| Step | Script | What it computes | Output |
|---|---|---|---|
| 1 | `C1_antenna_check.m` | Each antenna simulated alone: resonance, S11, input impedance, realized gain, radiation pattern | `results/check_<antenna>_<pec or free>/` |
| 2 | `C2_run_scene.m` | Jammer driven, TX connected to a 50 Ω receiver, at each distance | `results/stage<X>_d<mm>_<pec or free>/` |
| 3 | `C3_postprocess.m` | Coupling, jamming power J, J/S, TX power needed to reach J/S = 10 dB | `results/stage<X>/report_stage<X>.txt`, `.csv` tables |
| 4 | `C4_make_report.m` | Standard figure set, 3D pattern files, summary page | `results/stage<X>/plots/`, `patterns3d/`, `index.html` |

Steps 1 and 2 run openEMS and take almost all of the time. Steps 3 and 4 only read the stored results and take a few
minutes.

After running one or more stages, update the plots that compare all stages:

```bash
python3 tools/compare_stages.py results results/compare
```

## 4. View the geometry before running

The geometry can be built and checked without running the solver, in a few minutes:

```bash
./run_geometry.sh                  # TX alone, plus jammer alone and scene for stages A to D
./run_geometry.sh C                # one stage
./run_geometry.sh B scene 500      # one case: stage, tx | jam | scene, distance in mm
```

Files go to `results/geometry/<case>/`. Open a case in ParaView with each part coloured and labelled:

```bash
paraview --script=results/geometry/B_scene_d0100/open_scene.py
```

or in AppCSXCAD:

```bash
AppCSXCAD results/geometry/B_scene_d0100/scene.xml
```

openEMS reports an error code in geometry-only mode. This is expected; the files are still written.
More options are in [docs/HOW_TO_RUN_GEOMETRY.md](docs/HOW_TO_RUN_GEOMETRY.md).

## 5. How to modify the simulation

All inputs are in `params/`. The code in `lib/` does not need to change for ordinary modifications.

| To change | Edit | Setting |
|---|---|---|
| Jammer power | `params/jammer_params.m` | `J.P_dBm` (30 dBm) |
| Jammer antenna dimensions | `params/jammer_params.m` | the block for that stage, for example `case 'B'` |
| Corner reflector size, Stage B | `params/jammer_params.m` | `J.corner.S`, `.L`, `.H` (mm) |
| Corner reflector size, Stage D | `params/jammer_params.m` | the `V` table (variants `D1`, `D2`, `D3`) and which one `'D'` uses |
| TSA600 board shape | `params/jammer_params.m` | `t.Lb`, `t.Wb`, `t.Lt`, `t.Wm`, ... |
| TX length, height, power | `params/tx_params.m` | `A.L` (52.2 mm), `A.height` (500 mm), `A.P_dBm` (20 dBm) |
| Receiver bandwidth, noise figure, cable loss | `params/rx_params.m` | `A.BW_Hz`, `A.NF_dB`, `A.cable_loss_dB` |
| Frequency, mesh size, run length, J/S target | `params/case_params.m` | `P.f0`, `P.max_res`, `P.EndCriteria`, `P.JS_target_dB` |
| Distances | command line | `C2_run_scene('A', [100 250 500])`, in mm |
| With or without ground | command line | third argument of `C2_run_scene`: `true` or `false` |

### Changes that need no new simulation

The model is linear, so power levels only shift the results. After changing `J.P_dBm`, `A.P_dBm`, the receiver
settings or the J/S target, re-run only the post-processing:

```bash
./run_stage.sh A post
```

### Changes that need a new simulation

Any change to a size, position, the frequency or the mesh changes the model. Delete the affected raw runs first,
because finished runs are skipped:

- **A jammer change** (for example the Stage D reflector): delete `results/check_jamD_*` and `results/stageD_d*`,
  then run `./run_stage.sh D`.
- **A TX change:** delete `results/check_tx_pec` and re-run all four stages, so that they stay comparable.
- **A mesh or frequency change:** delete everything in `results/` except the summary folders you want to keep, and
  re-run all stages.

### Faster Stage D runs

The corner reflector of Stage D is meshed at 2 mm by default. A coarser mesh roughly halves the model size:

```bash
D_RES=4 ./run_stage.sh D
```

Use the same `D_RES` for every step of a run, and delete the Stage D raw runs if you change it.

### Adding a new jammer design

Add a new `case` block to `params/jammer_params.m` with a new stage letter or name, using an existing block as the
template (`'omni'` whip, `'tsa600'` board, optional `J.corner` reflector). Then run it like any other stage, for
example `./run_stage.sh E`. A completely new antenna type also needs a builder in `lib/add_jammer.m`.

## 6. Keeping the repository clean

The raw run folders (`results/check_*`, `results/stage*_d*`, `results/geometry/`) are several GB and are excluded by
`.gitignore`. After a re-run, commit only the summary:

```bash
git add params/ results/stageD/ results/compare/
git commit -m "Re-run Stage D with the new reflector"
```

## 7. Troubleshooting

| Problem | Fix |
|---|---|
| `openEMS / CSXCAD MATLAB files not found` | Set `OPENEMS_DIR` (section 1). |
| `MATLAB not found` from `run_stage.sh` | Pass the path: `MATLAB=/Applications/MATLAB_Rxxxx.app/bin/matlab ./run_stage.sh A`. |
| A run is skipped though you changed something | Delete that run's folder in `results/` (section 5). |
| Out of memory on Stage D | Use `D_RES=4` or `D_RES=6`, and close other large applications. |
| Paths with spaces fail in Terminal | Put the path in quotes: `cd "/Users/name/EMS MAIN/uav-rf-jammer-fdtd"`. |
| Recursion limit error in MATLAB on fine meshes | Already raised in `setup_paths.m`; make sure it runs first (the step scripts call it). |
