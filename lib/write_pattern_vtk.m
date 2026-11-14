function write_pattern_vtk(fname, F, off, tag)
% WRITE_PATTERN_VTK  Free-space radiation pattern as a closed 3D surface for ParaView (legacy ASCII VTK, PolyData).
%   Radius = realized gain (linear, so the shape is the true pattern), colour array 'gain_dBi'.
%   F is the farfield struct (F.th, F.ph, F.Greal_fs); off = [x y z] shift of the surface; tag = antenna number
%   (0 TX, 1 INT) written as the array 'antenna'. A cell array fname/F/off/tag writes ONE file with several patterns.
if ~iscell(F), F = {F}; off = {off}; tag = {tag}; end
P = zeros(0, 3);  S = zeros(0, 1);  A = zeros(0, 1);  T = zeros(0, 3);
for q = 1:numel(F)
  th = F{q}.th(:);  ph = [F{q}.ph(:); F{q}.ph(1) + 2*pi];  G = F{q}.Greal_fs;
  G = [G G(:, 1)];  nt = numel(th);  np = numel(ph);
  [PH, TH] = meshgrid(ph, th);
  R = max(G, 1e-3);
  X = R .* sin(TH) .* cos(PH) + off{q}(1);  Y = R .* sin(TH) .* sin(PH) + off{q}(2);  Z = R .* cos(TH) + off{q}(3);
  base = size(P, 1);
  P = [P; X(:) Y(:) Z(:)];  S = [S; 10*log10(R(:))];  A = [A; tag{q} * ones(nt*np, 1)];
  idx = reshape(1:nt*np, nt, np) + base - 1;
  a = idx(1:nt-1, 1:np-1);  b = idx(2:nt, 1:np-1);  c = idx(2:nt, 2:np);  d = idx(1:nt-1, 2:np);
  T = [T; a(:) b(:) c(:); a(:) c(:) d(:)];
end
fid = fopen(fname, 'w');
fprintf(fid, '# vtk DataFile Version 3.0\nRadiation pattern (free space, realized gain)\nASCII\nDATASET POLYDATA\n');
fprintf(fid, 'POINTS %d float\n', size(P, 1));  fprintf(fid, '%.6g %.6g %.6g\n', P');
fprintf(fid, 'POLYGONS %d %d\n', size(T, 1), 4*size(T, 1));  fprintf(fid, '3 %d %d %d\n', (T - 1)');
fprintf(fid, 'POINT_DATA %d\nSCALARS gain_dBi float 1\nLOOKUP_TABLE default\n', size(P, 1));  fprintf(fid, '%.4g\n', S);
fprintf(fid, 'SCALARS antenna float 1\nLOOKUP_TABLE default\n');  fprintf(fid, '%d\n', A);
fclose(fid);
end
