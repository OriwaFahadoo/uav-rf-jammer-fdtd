function [CSX, FDTD, port, nf2ff, info] = build_scene(P, active, include)
% BUILD_SCENE  openEMS model: frozen Stage A TX (port 1) and this stage's jammer (port 2).
%   active  : 'tx' or 'jam' (the driven antenna; the other is a matched 50 ohm load)
%   include : {'tx','jam'} (default) or one of them alone (antenna check, adds the far-field box)
if nargin < 3, include = {'tx', 'jam'}; end

FDTD = InitFDTD('NrTS', P.NrTS, 'EndCriteria', P.EndCriteria);
FDTD = SetGaussExcite(FDTD, P.f0, P.fc);
BC = {'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8' 'PML_8'};
if P.ground, BC{5} = 'PEC'; end
FDTD = SetBoundaryCond(FDTD, BC);
CSX  = InitCSX();
mesh = struct('x', [], 'y', [], 'z', []);
port = cell(1, 2);  bbox = cell(1, 2);  zc = P.tx.feed(3);
if any(strcmp(include, 'tx'))
  [CSX, port{1}, mesh, bbox{1}] = add_tx(CSX, mesh, P.tx, 1, strcmp(active, 'tx'));
end
if any(strcmp(include, 'jam'))
  [CSX, port{2}, mesh, bbox{2}, ji] = add_jammer(CSX, mesh, P.jam, 2, strcmp(active, 'jam'));
  if strcmp(active, 'jam'), zc = ji.zc; end
end
used = ~cellfun(@isempty, bbox);
allb = cat(1, bbox{used});
lo = min(allb, [], 1) - P.pml_margin;
hi = max(allb, [], 1) + P.pml_margin;
if P.ground, lo(3) = 0; end
mesh.x = [mesh.x lo(1) hi(1)];  mesh.y = [mesh.y lo(2) hi(2)];  mesh.z = [mesh.z lo(3) hi(3)];
mesh.x = thin_lines(mesh.x, 0.4);  mesh.y = thin_lines(mesh.y, 0.4);  mesh.z = thin_lines(mesh.z, 0.4);
if isfield(P.jam, 'mesher') && strcmp(P.jam.mesher, 'grade')
  mesh.x = grade_mesh(mesh.x, P.max_res, P.mesh_ratio);
  mesh.y = grade_mesh(mesh.y, P.max_res, P.mesh_ratio);
  mesh.z = grade_mesh(mesh.z, P.max_res, P.mesh_ratio);
else
  mesh = SmoothMesh(mesh, P.max_res, P.mesh_ratio);   % as in the settled Stage A
end
CSX  = DefineRectGrid(CSX, P.unit, mesh);

a = find(strcmp({'tx', 'jam'}, active));
nf2ff = [];
scene_ff = isfield(P, 'scene_ff') && P.scene_ff && sum(used) > 1;   % pattern of the whole scene (box around both)
if sum(used) == 1 || scene_ff                      % antenna alone (or whole scene): far-field box
  if scene_ff, nb = [min(allb, [], 1) - P.nf2ff_margin; max(allb, [], 1) + P.nf2ff_margin];
  else,        nb = [bbox{a}(1,:) - P.nf2ff_margin; bbox{a}(2,:) + P.nf2ff_margin]; end
  dirs = [1 1 1 1 1 1];
  if P.ground && nb(1,3) <= P.max_res, nb(1,3) = 0; dirs(5) = 0; end
  [CSX, nf2ff] = CreateNF2FFBox(CSX, 'nf2ff', nb(1,:), nb(2,:), 'Directions', dirs);
end
if P.dump_fd_h5
  CSX = AddDump(CSX, 'Ef_plane', 'DumpType', 10, 'FileType', 1, 'Frequency', P.f0);
  CSX = AddBox(CSX, 'Ef_plane', 0, [lo(1) lo(2) zc], [hi(1) hi(2) zc]);
end
info.mesh   = mesh;
info.ncells = (numel(mesh.x)-1) * (numel(mesh.y)-1) * (numel(mesh.z)-1);
if a == 1, info.center = P.tx.feed; else, info.center = P.jam.feed; end
if scene_ff, info.center = [(P.tx.feed(1) + P.jam.feed(1))/2, 0, P.tx.feed(3)]; end   % midpoint of the two
info.scene_ff = scene_ff;
info.domain = [lo; hi];
info.active = a;
info.bbox   = bbox;
end

function v = thin_lines(v, dmin)
% drop mesh lines closer than dmin (mm) to the previous kept one (SmoothMesh fails on near-duplicates)
v = sort(v(:)');  keep = true(size(v));  last = v(1);
for k = 2:numel(v)
  if v(k) - last < dmin, keep(k) = false; else, last = v(k); end
end
v = v(keep);
end
