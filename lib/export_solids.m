function parts = export_solids(CSX, file, unit)
% EXPORT_SOLIDS  Write the metal of a CSX model as filled surfaces (triangles) in a legacy VTK file, for ParaView.
% Boxes, cylinders, polygon sheets and extruded polygons are written as closed surfaces / flat sheets (metres).
% Cell data "part" is the index of the metal property (see the returned names).
if nargin < 3, unit = 1e-3; end
T = zeros(0, 9);  id = zeros(0, 1);  parts = {};
M = CSX.Properties.Metal;
for i = 1:numel(M)
  parts{i} = M{i}.ATTRIBUTE.Name; %#ok<AGROW>
  pr = M{i}.Primitives;
  for f = fieldnames(pr)'
    q = pr.(f{1});  if ~iscell(q), q = {q}; end
    for k = 1:numel(q)
      switch f{1}
        case 'Box',      t = tri_box(q{k});
        case 'Cylinder', t = tri_cyl(q{k});
        case 'Polygon',  t = tri_poly(q{k}, false);
        case 'LinPoly',  t = tri_poly(q{k}, true);
        otherwise, t = zeros(0, 9);
      end
      T = [T; t]; id = [id; i * ones(size(t, 1), 1)]; %#ok<AGROW>
    end
  end
end
T = T * unit;
write_vtk(file, T, id);
[d, ~] = fileparts(file);                       % one file per metal part: ParaView colours and labels each
for i = 1:numel(parts)
  k = id == i;
  if any(k), write_vtk(fullfile(d, ['part_' parts{i} '.vtk']), T(k, :), id(k)); end
end
end

function write_vtk(file, T, id)
n = size(T, 1);
fid = fopen(file, 'w');
fprintf(fid, '# vtk DataFile Version 3.0\nmetal surfaces (m)\nASCII\nDATASET POLYDATA\nPOINTS %d float\n', 3*n);
fprintf(fid, '%.6g %.6g %.6g\n', reshape(T', 3, []));
fprintf(fid, 'POLYGONS %d %d\n', n, 4*n);
fprintf(fid, '3 %d %d %d\n', [0:3:3*n-3; 1:3:3*n-2; 2:3:3*n-1]);
fprintf(fid, 'CELL_DATA %d\nSCALARS part int 1\nLOOKUP_TABLE default\n', n);
fprintf(fid, '%d\n', id);
fclose(fid);
end

function t = tri_box(b)
p1 = [b.P1.ATTRIBUTE.X b.P1.ATTRIBUTE.Y b.P1.ATTRIBUTE.Z];  p2 = [b.P2.ATTRIBUTE.X b.P2.ATTRIBUTE.Y b.P2.ATTRIBUTE.Z];
lo = min(p1, p2);  hi = max(p1, p2);
c = [lo(1) lo(2) lo(3); hi(1) lo(2) lo(3); hi(1) hi(2) lo(3); lo(1) hi(2) lo(3);
     lo(1) lo(2) hi(3); hi(1) lo(2) hi(3); hi(1) hi(2) hi(3); lo(1) hi(2) hi(3)];
F = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
t = quads(c, F);
end

function t = tri_cyl(c)
p1 = [c.P1.ATTRIBUTE.X c.P1.ATTRIBUTE.Y c.P1.ATTRIBUTE.Z];  p2 = [c.P2.ATTRIBUTE.X c.P2.ATTRIBUTE.Y c.P2.ATTRIBUTE.Z];
r = c.ATTRIBUTE.Radius;  ax = p2 - p1;  L = norm(ax);  ax = ax / L;
[~, m] = min(abs(ax));  e = zeros(1, 3);  e(m) = 1;
u = cross(ax, e);  u = u / norm(u);  v = cross(ax, u);
N = 16;  a = (0:N-1)' * 2*pi/N;
ring = r * (cos(a) * u + sin(a) * v);
A = ring + p1;  B = ring + p2;
V = [A; B; p1; p2];  t = zeros(0, 9);
for j = 1:N
  j2 = mod(j, N) + 1;
  t = [t; tri(V, j, j2, N+j2); tri(V, j, N+j2, N+j); tri(V, 2*N+1, j2, j); tri(V, 2*N+2, N+j, N+j2)]; %#ok<AGROW>
end
end

function t = tri_poly(q, extrude)
nd = q.ATTRIBUTE.NormDir;  el = q.ATTRIBUTE.Elevation;
vx = q.Vertex;  if ~iscell(vx), vx = {vx}; end
P = zeros(numel(vx), 2);
for k = 1:numel(vx), P(k, :) = [vx{k}.ATTRIBUTE.X1 vx{k}.ATTRIBUTE.X2]; end
keep = [true; any(abs(diff(P, 1, 1)) > 1e-9, 2)];  P = P(keep, :);
if norm(P(1, :) - P(end, :)) < 1e-9, P(end, :) = []; end
tr = ear_clip(P);
ia = mod(nd + 1, 3) + 1;  ib = mod(nd + 2, 3) + 1;  in = nd + 1;     % X1 -> axis nd+1, X2 -> axis nd+2 (cyclic)
to3 = @(p, h) set3(p, ia, ib, in, h);
t = zeros(0, 9);
if extrude, hs = [el, el + q.ATTRIBUTE.Length]; else, hs = el; end
for h = hs
  for k = 1:size(tr, 1)
    t = [t; reshape(to3(P(tr(k, :), :), h)', 1, 9)]; %#ok<AGROW>
  end
end
if extrude
  n = size(P, 1);
  for k = 1:n
    k2 = mod(k, n) + 1;
    a = to3(P([k k2], :), hs(1));  b = to3(P([k k2], :), hs(2));
    t = [t; reshape([a(1, :); a(2, :); b(2, :)]', 1, 9); reshape([a(1, :); b(2, :); b(1, :)]', 1, 9)]; %#ok<AGROW>
  end
end
end

function X = set3(p, ia, ib, in, h)
X = zeros(size(p, 1), 3);  X(:, ia) = p(:, 1);  X(:, ib) = p(:, 2);  X(:, in) = h;
end

function tr = ear_clip(P)
n = size(P, 1);  idx = 1:n;  tr = zeros(0, 3);
A = 0.5 * sum(P(:, 1) .* P([2:n 1], 2) - P([2:n 1], 1) .* P(:, 2));
if A < 0, idx = fliplr(idx); end
guard = 0;
while numel(idx) > 3 && guard < 10*n
  guard = guard + 1;  m = numel(idx);  found = false;
  for k = 1:m
    i0 = idx(mod(k - 2, m) + 1);  i1 = idx(k);  i2 = idx(mod(k, m) + 1);
    a = P(i0, :);  b = P(i1, :);  c = P(i2, :);
    if (b(1)-a(1))*(c(2)-a(2)) - (b(2)-a(2))*(c(1)-a(1)) <= 1e-12, continue; end   % reflex or flat
    ok = true;
    for j = idx
      if j == i0 || j == i1 || j == i2, continue; end
      if in_tri(P(j, :), a, b, c), ok = false; break; end
    end
    if ok, tr(end+1, :) = [i0 i1 i2]; idx(k) = []; found = true; break; end %#ok<AGROW>
  end
  if ~found, idx(1) = []; end      % degenerate: drop a point and go on
end
if numel(idx) == 3, tr(end+1, :) = idx; end
end

function r = in_tri(p, a, b, c)
d1 = (p(1)-b(1))*(a(2)-b(2)) - (a(1)-b(1))*(p(2)-b(2));
d2 = (p(1)-c(1))*(b(2)-c(2)) - (b(1)-c(1))*(p(2)-c(2));
d3 = (p(1)-a(1))*(c(2)-a(2)) - (c(1)-a(1))*(p(2)-a(2));
r = ~((d1 < 0 || d2 < 0 || d3 < 0) && (d1 > 0 || d2 > 0 || d3 > 0)) && all(abs(p - a) + abs(p - b) + abs(p - c) > 0) ...
    && ~(abs(d1) < 1e-12 && abs(d2) < 1e-12);
end

function t = quads(c, F)
t = zeros(0, 9);
for k = 1:size(F, 1)
  t = [t; tri(c, F(k, 1), F(k, 2), F(k, 3)); tri(c, F(k, 1), F(k, 3), F(k, 4))]; %#ok<AGROW>
end
end

function t = tri(V, a, b, c)
t = reshape(V([a b c], :)', 1, 9);
end
