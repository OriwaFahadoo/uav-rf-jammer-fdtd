function out = G_geometry(stage, what, d_mm)
% G_GEOMETRY  Write the geometry of one case for AppCSXCAD / ParaView, without running the simulation.
%   G_geometry('B', 'jam')          the Stage B jammer alone
%   G_geometry('A', 'tx')           the frozen TX alone (same for every stage)
%   G_geometry('C', 'scene', 100)   TX + jammer, 100 mm apart (any distance in mm)
% Writes results/geometry/<stage>_<what>[_d<mm>]/ with
%   scene.xml            the openEMS/CSXCAD geometry: open it in AppCSXCAD
%   open_scene.py        opens the scene in ParaView with fixed colours and labels (see HOW_TO_RUN_GEOMETRY.md)
%   part_<name>.vtk      one file per metal part (used by open_scene.py)
%   metal_solid.vtk      the metal as filled surfaces: open in ParaView (colour by 'part', names in parts.txt)
%   ground_plane.vtk     the PEC ground plane z = 0
%   PEC_dump.vtp         the metal as wireframe on the FDTD mesh (the mesh view)
%   material_dump.vtr    the materials / cell grid: open in ParaView
% openEMS is called with --no-simulation, so this takes seconds to a minute, not hours.
if nargin < 1, stage = 'A'; end
if nargin < 2, what = 'scene'; end
if nargin < 3, d_mm = 100; end
stage = upper(stage);
setup_paths;
switch what
  case 'tx',    act = 'tx';  inc = {'tx'};
  case 'jam',   act = 'jam'; inc = {'jam'};
  case 'scene', act = 'jam'; inc = {'tx', 'jam'};
  otherwise, error('what must be tx, jam or scene');
end
P = case_params(stage, d_mm, true);
P.scene_ff = false;
name = [stage '_' what];  if strcmp(what, 'scene'), name = sprintf('%s_d%04d', name, d_mm); end
if strcmp(what, 'tx'), name = 'TX_alone'; end
root = fullfile(P.root, 'geometry');
if ~exist(root, 'dir'), mkdir(root); end
out = fullfile(root, name);
if exist(out, 'dir'), rmdir(out, 's'); end
mkdir(out);
[CSX, FDTD, ~, ~, info] = build_scene(P, act, inc);
WriteOpenEMS(fullfile(out, 'scene.xml'), FDTD, CSX);
parts = export_solids(CSX, fullfile(out, 'metal_solid.vtk'), P.unit);     % filled metal surfaces for ParaView
export_ground(fullfile(out, 'ground_plane.vtk'), CSX, P);
fid = fopen(fullfile(out, 'parts.txt'), 'w');
for i = 1:numel(parts), fprintf(fid, 'part %d = %s\n', i, parts{i}); end
fclose(fid);
copyfile(fullfile(fileparts(mfilename('fullpath')), 'lib', 'open_scene.py'), fullfile(out, 'open_scene.py'));   % ParaView: colours + labels
fprintf('%s: %.2f M cells, writing VTK ...\n', name, info.ncells/1e6);
try   % openEMS returns exit code 1 after --no-simulation although it wrote the files
  RunOpenEMS(out, 'scene.xml', '--no-simulation --debug-PEC --debug-material');
catch
end
if ~exist(fullfile(out, 'PEC_dump.vtp'), 'file'), warning('no PEC_dump.vtp written: only scene.xml is available'); end
fprintf('Geometry in %s\n', out);
end

function export_ground(file, CSX, P)
% the z = 0 PEC ground plane as a flat sheet over the model, in metres
m = CSX.RectilinearGrid;  x = grid_lines(m.XLines) * P.unit;  y = grid_lines(m.YLines) * P.unit;
c = [min(x) min(y) 0; max(x) min(y) 0; max(x) max(y) 0; min(x) max(y) 0];
fid = fopen(file, 'w');
fprintf(fid, '# vtk DataFile Version 3.0\nground plane (m)\nASCII\nDATASET POLYDATA\nPOINTS 4 float\n');
fprintf(fid, '%.6g %.6g %.6g\n', c');
fprintf(fid, 'POLYGONS 1 5\n4 0 1 2 3\n');
fclose(fid);
end

function v = grid_lines(c)
if iscell(c), c = c{1}; end
if isstruct(c), c = c.ATTRIBUTE; end
if ischar(c), v = sscanf(strrep(c, ',', ' '), '%f')'; else, v = double(c(:))'; end
end
