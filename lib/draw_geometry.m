function draw_geometry(P, which)
% DRAW_GEOMETRY  3D drawing of the TX and this stage's jammer (no ParaView needed).
%   which: 'tx', 'jam' or 'both'. Rods are drawn thicker than their true 2 mm so they can be seen.
%   Left: perspective; right: front view (x-z). The ground plane z = 0 is far below (feeds at 500 mm).
tx = P.tx;  J = P.jam;
[jl, jh] = jam_extent(J);
for k = 1:2
  subplot(1, 2, k); hold on; grid on;
  switch which
    case 'tx', xl = tx.feed(1) + [-60 60];  yl = [-60 60];  zl = tx.feed(3) + [-60 60];
    case 'jam', xl = [jl(1) jh(1)] + [-40 40]; yl = [jl(2) jh(2)] + [-40 40]; zl = [jl(3) jh(3)] + [-40 40];
    otherwise
      xl = [min(tx.feed(1), jl(1)) - 50, max(tx.feed(1), jh(1)) + 50];
      yl = [min(-60, jl(2)) - 20, max(60, jh(2)) + 20];  zl = [min(tx.feed(3) - 60, jl(3)) - 20, max(tx.feed(3) + 60, jh(3)) + 20];
  end
  is3d = (k == 1);
  if any(strcmp(which, {'tx', 'both'})), draw_tx(tx, is3d); end
  if any(strcmp(which, {'jam', 'both'})), draw_jam(J, is3d); end
  if is3d
    xlabel('x / mm'); ylabel('y / mm'); zlabel('z / mm (up)'); axis([xl yl zl]); view(35, 20); title('perspective');
  else
    xlabel('x / mm'); ylabel('z / mm (up)'); axis equal; axis([xl zl]);
    title('front view (x-z), the ground plane z = 0 is far below');
  end
end
end

function [lo, hi] = jam_extent(J)
a = J.ant;  x = J.feed(1);  z = J.feed(3);
switch a.type
  case 'omni',   lo = [x - a.plate/2, -a.plate/2, z];  hi = [x + a.plate/2, a.plate/2, z + a.gap + a.L];
  case 'tsa600', lo = [x, -1, z - a.Wb/2];  hi = [x + a.Lb, 1, z + a.Wb/2];
  case 'whip',   lo = [x - a.housing(1)/2, -a.housing(2)/2, z - a.housing(3)]; hi = [x + a.housing(1)/2, a.housing(2)/2, z + a.gap + a.L];
end
if isfield(J, 'corner')
  C = J.corner;  c = cos(pi/4);
  if isfield(C, 'ref') && strcmp(C.ref, 'back'), xa = hi(1) + C.S; else, xa = x + C.S; end
  zc = mean([lo(3) hi(3)]);
  lo = min(lo, [xa - C.L*c, -C.L*c, zc - C.H/2]);  hi = max(hi, [xa, C.L*c, zc + C.H/2]);
end
end

function draw_tx(a, is3d)
z0 = a.feed(3);  g = a.gap;  arm = (a.L - g) / 2;  x = a.feed(1);
P1 = [z0 + g/2, z0 + g/2 + arm];  P2 = [z0 - g/2, z0 - g/2 - arm];
if is3d
  plot3([x x], [0 0], P1, 'b-', 'LineWidth', 5);  plot3([x x], [0 0], P2, 'b-', 'LineWidth', 5);
  plot3(x, 0, z0, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 6);
  text(x + 6, 0, z0 + g/2 + arm + 8, sprintf('TX dipole %.1f mm, feed z %g', a.L, z0), 'Color', 'b');
else
  plot([x x], P1, 'b-', 'LineWidth', 5);  plot([x x], P2, 'b-', 'LineWidth', 5);
  plot(x, z0, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 6);
  text(x + 6, z0 + g/2 + arm + 8, sprintf('TX dipole %.1f mm', a.L), 'Color', 'b');
end
end

function quad(V, col, is3d)
% one flat quadrilateral (4 x 3 vertices) as two triangles (Octave's gnuplot only draws triangles)
if is3d
  patch('Vertices', V, 'Faces', [1 2 3; 1 3 4], 'FaceColor', col, 'FaceAlpha', 0.8, 'EdgeColor', [0.2 0.2 0.2]);
else
  fill(V(:, 1), V(:, 3), col, 'EdgeColor', [0.2 0.2 0.2]);
end
end

function draw_jam(J, is3d)
a = J.ant;  x = J.feed(1);  y = J.feed(2);  z = J.feed(3);
switch a.type
  case 'omni'
    g = a.plate/2;
    quad([x-g y-g z; x+g y-g z; x+g y+g z; x-g y+g z], [0.6 0.6 0.65], is3d);
    zz = [z + a.gap, z + a.gap + a.L];
    if is3d, plot3([x x], [y y], zz, 'r-', 'LineWidth', 5); plot3(x, y, z, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 6);
             text(x + 10, y, zz(2) + 8, sprintf('jammer whip %.1f mm on a %g mm plate', a.L, a.plate), 'Color', 'r');
    else,    plot([x x], zz, 'r-', 'LineWidth', 5); plot([x-g x+g], [z z], 'k-', 'LineWidth', 3);
             text(x + 10, zz(2) + 8, sprintf('whip %.1f mm', a.L), 'Color', 'r'); end
  case 'tsa600'
    xm = x; xb = x + a.Lb; xt = x + a.Lt; H = a.Wb/2;
    R = log(a.Wm / a.w0) / a.Lt; u = linspace(0, a.Lt, 40); hu = a.w0/2 * exp(R*u);
    for s = [-1 1]   % upper and lower metal halves (outline only along the slot)
      px = [xm xb xb xt - u(1) xt - u]; pz = z + s*[H H 0 a.w0/2 hu];
      if is3d, plot3([px px(1)], zeros(1, numel(px) + 1), [pz pz(1)], '-', 'Color', [0.1 0.45 0.2], 'LineWidth', 2);   % outline (gnuplot 3D can't fill polygons)
      else,    fill(px, pz, [0.2 0.55 0.3], 'EdgeColor', [0.1 0.3 0.1]); end
    end
    if is3d, text(xm, 0, z + H + 15, sprintf('TSA600 %g x %g mm, mouth towards the TX', a.Lb, a.Wb), 'Color', [0 0.4 0]);
    else,    text(xm, z + H + 15, sprintf('TSA600 %g x %g mm', a.Lb, a.Wb), 'Color', [0 0.4 0]); end
  case 'whip'
    h = a.housing;
    quad([x-h(1)/2 0 z-h(3); x+h(1)/2 0 z-h(3); x+h(1)/2 0 z; x-h(1)/2 0 z], [0.55 0.55 0.6], is3d);
    if is3d, plot3([x x], [0 0], z + [a.gap a.gap + a.L], 'r-', 'LineWidth', 5);
    else, plot([x x], z + [a.gap a.gap + a.L], 'r-', 'LineWidth', 5); end
end
if isfield(J, 'corner')
  C = J.corner;  c = cos(pi/4);  [lo, hi] = jam_extent(rmfield(J, 'corner'));
  if isfield(C, 'ref') && strcmp(C.ref, 'back'), xa = hi(1) + C.S; else, xa = x + C.S; end
  zc = mean([lo(3) hi(3)]);  z1 = zc - C.H/2;  z2 = zc + C.H/2;
  for s = [-1 1]
    xe = xa - C.L*c;  ye = s*C.L*c;
    % plates drawn as outlines with vertical hatching, so the element inside stays visible
    t = linspace(0, 1, 9);  xs = xa + (xe - xa) * t;  ys = ye * t;
    if is3d
      plot3([xa xe xe xa xa], [0 ye ye 0 0], [z1 z1 z2 z2 z1], 'k-', 'LineWidth', 1.5);
      for q = 2:numel(t) - 1, plot3([xs(q) xs(q)], [ys(q) ys(q)], [z1 z2], '-', 'Color', [0.6 0.6 0.6]); end
    else
      plot([xa xe xe xa xa], [z1 z1 z2 z2 z1], 'k-', 'LineWidth', 1.5);
    end
  end
  if is3d, text(xa, 0, z2 + 15, sprintf('90 deg corner reflector S %g, L %g, H %g mm', C.S, C.L, C.H), 'Color', [0.3 0.3 0.3]); end
end
end
