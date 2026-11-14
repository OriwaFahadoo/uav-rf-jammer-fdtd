# Viewing the geometry

The model of every stage can be built and inspected without running the solver. This is the quickest way to check
antenna sizes, positions and the mesh before a long run. All commands are run from the repository folder.

## 1. Write the geometry files

```bash
./run_geometry.sh                  # TX alone, plus jammer alone and scene (0.1 m) for stages A, B, C, D
./run_geometry.sh C                # one stage only (plus the TX alone)
./run_geometry.sh B scene 500      # one case: stage, tx | jam | scene, distance TX to jammer in mm
./run_geometry.sh D jam            # the Stage D jammer alone
```

or in MATLAB / Octave: `G_geometry('B', 'scene', 500)`.

The files are written to `results/geometry/<case>/`, for example `results/geometry/B_scene_d0500/`. This takes a few
minutes in all. openEMS is run with `--no-simulation --debug-PEC --debug-material`, so it reports an error code at the
end; this is expected and the files are written.

Each case folder contains:

| File | Content |
|---|---|
| `open_scene.py` | Opens the case in ParaView with every part coloured and labelled. Start here. |
| `metal_solid.vtk`, `part_<name>.vtk` | Solid model of all metal parts, and one file per part (`parts.txt` lists them) |
| `ground_plane.vtk` | The PEC ground plane at z = 0 |
| `scene.xml` | The full model for AppCSXCAD |
| `PEC_dump.vtp`, `material_dump.vtr` | The FDTD mesh view: metal on the grid cells, and the cell grid itself |

## 2. ParaView (coloured and labelled)

```bash
paraview --script=results/geometry/D_scene_d0100/open_scene.py
```

or inside ParaView: View > Python Shell > Run Script, and pick the `open_scene.py` of the case.

| Part | Colour |
|---|---|
| TX dipole | blue |
| Jammer whip | red |
| Jammer ground plate | orange |
| Corner reflector | green |
| TSA600 board | purple |
| Ground plane | grey, semi-transparent |

Without the script: File > Open `metal_solid.vtk`, Apply, set Representation to Surface and colour by `part`.
Coordinates are in metres and the antenna feeds are at z = 0.5. The TSA600 board and the plates are zero-thickness
sheets in the model; the reflector plates are 3 mm thick and the wires 2 mm in diameter. Open `PEC_dump.vtp` on top
to see the FDTD cells.

The 3D radiation patterns in `results/stage<X>/patterns3d/` open the same way and can be shown together with the
geometry.

## 3. AppCSXCAD

AppCSXCAD is the geometry viewer installed with openEMS:

```bash
AppCSXCAD results/geometry/B_scene_d0100/scene.xml
```

On macOS with MacPorts it may be `/opt/local/bin/AppCSXCAD.sh`. From MATLAB: `setup_paths; CSXGeomPlot('results/geometry/B_scene_d0100/scene.xml')`.

## 4. Without any viewer

With Python and `vtk` installed (`pip3 install vtk`), a coloured, labelled PNG can be drawn:

```bash
# or: ./open_geometry.sh B_scene_d0100 --png
python3 lib/scene_png.py results/geometry/B_scene_d0100 scene.png
```

Pre-rendered views of every stage are already in `results/stage<X>/geometry_pictures/`, and simple 2D views in
`results/stage<X>/plots/00a_geometry_TX_alone.png`, `00b_geometry_interferer_alone.png` and `00c_geometry_both.png`.

## 5. Changing the geometry

Jammer sizes are set in `params/jammer_params.m` and the TX in `params/tx_params.m`. After a change, run
`./run_geometry.sh` again for the affected stage to check it before running the simulation.
