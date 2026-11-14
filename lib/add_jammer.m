function [CSX, port, mesh, bbox, info] = add_jammer(CSX, mesh, J, portnr, excite)
% ADD_JAMMER  The jammer antenna of one stage (see params/jammer_params.m), at J.feed, aimed at -x.
%   bbox : extent of everything that belongs to the jammer (antenna + absorber / reflector)
%   info.zc : height of the horizontal plane for the field map
a = J.ant;  x = J.feed(1); y = J.feed(2); z = J.feed(3);
info.zc = z;
switch a.type
  case 'omni'      % lambda/4 whip on a small square plate (Case 3)
    g = a.plate / 2;  zb = z + a.gap;
    CSX = AddMetal(CSX, 'jam_plate');
    CSX = AddBox(CSX, 'jam_plate', 10, [x-g y-g z], [x+g y+g z]);
    CSX = AddMetal(CSX, 'jam_wire');
    CSX = AddCylinder(CSX, 'jam_wire', 10, [x y zb], [x y zb+a.L], a.radius);
    [CSX, port] = AddLumpedPort(CSX, 5, portnr, J.R, [x y z], [x y zb], [0 0 1], excite);
    mesh.x = [mesh.x x + [-g -a.res 0 a.res g]];
    mesh.y = [mesh.y y + [-g -a.res 0 a.res g]];
    mesh.z = [mesh.z z z+a.gap/2 zb zb+a.L];        % two cells across the feed gap, as for the TX
    bbox = [x-g y-g z; x+g y+g zb+a.L];
    info.zc = z + a.gap + a.L/2;

  case 'whip'      % old Stage A: whip on the JH-HB8 housing (for the reproduction check)
    h = a.housing;  zb = z + a.gap;
    CSX = AddMetal(CSX, 'jam_housing');
    CSX = AddBox(CSX, 'jam_housing', 10, [x-h(1)/2 y-h(2)/2 z-h(3)], [x+h(1)/2 y+h(2)/2 z]);
    CSX = AddMetal(CSX, 'jam_wire');
    CSX = AddCylinder(CSX, 'jam_wire', 10, [x y zb], [x y zb+a.collar(2)], a.collar(1));
    CSX = AddCylinder(CSX, 'jam_wire', 10, [x y zb], [x y zb+a.L], a.radius);
    [CSX, port] = AddLumpedPort(CSX, 5, portnr, J.R, [x y z], [x y zb], [0 0 1], excite);
    mesh.x = [mesh.x x + [-h(1)/2 h(1)/2 -a.collar(1) a.collar(1) -a.res 0 a.res]];
    mesh.y = [mesh.y y + [-h(2)/2 h(2)/2 -a.collar(1) a.collar(1) -a.res 0 a.res]];
    mesh.z = [mesh.z z-h(3) z zb zb+a.collar(2) zb+a.L];
    bbox = [x-h(1)/2 y-h(2)/2 z-h(3); x+h(1)/2 y+h(2)/2 zb+a.L];

  case 'tsa600'    % tapered-slot (Vivaldi) board in the x-z plane (vertical), mouth at x, opening towards -x
    xm = x;  xb = xm + a.Lb;  zc = z;  H = a.Wb/2;
    xt = xm + a.Lt;                          % throat
    xc = xt + a.stub + a.rc;                 % cavity centre
    % exponential taper: half-width h(u) = (w0/2) exp(R u), u = distance from the throat
    R  = log(a.Wm / a.w0) / a.Lt;
    u  = linspace(0, a.Lt, 80);
    hu = a.w0/2 * exp(R * u);
    xs = xt - u;                              % throat -> mouth
    % cavity: upper half circle, from the back (angle 0) over the top to the slot (angle pi - asin)
    a1 = pi - asin(a.w0/2 / a.rc);
    ang = linspace(0, a1, 40);
    xcav = xc + a.rc * cos(ang);  zcav = a.rc * sin(ang);
    % upper metal half (z >= zc), points as offsets from zc
    px = [xm  xb  xb  xc+a.rc  xcav  xt   xs        xm];
    pz = [H   H   0   0        zcav  a.w0/2  hu      H];
    CSX = AddMetal(CSX, 'jam_tsa');
    % for a y-normal polygon CSXCAD takes the points as [z; x]
    CSX = AddPolygon(CSX, 'jam_tsa', 10, 1, y, [zc + pz; px]);
    CSX = AddPolygon(CSX, 'jam_tsa', 10, 1, y, [zc - pz; px]);
    [CSX, port] = AddLumpedPort(CSX, 5, portnr, J.R, [xt y zc-a.w0/2], [xt y zc+a.w0/2], [0 0 1], excite);
    % mesh: a.res over the board, 0.5 mm steps at the throat, lines on the board plane
    mesh.x = add_fill([mesh.x xt + (-4:1:4) xc + [-a.rc a.rc] xm xb], xm:a.res:xb, a.res);
    mesh.z = add_fill([mesh.z zc + (-3:0.5:3) zc + [-a.rc a.rc] zc-H zc+H], zc + (-H:a.res:H), a.res);
    mesh.y = [mesh.y y + [-4 -2 -1 0 1 2 4]];
    bbox = [xm y-1 zc-H; xb y+1 zc+H];

  otherwise
    error('unknown jammer type %s', a.type);
end

%% 'BABS': graded absorber block behind the jammer (+x side)
if isfield(J, 'absorber')
  A = J.absorber;  f = bbox(2,1) + A.gap;  yy = y + [-1 1]*A.size(1)/2;  zz = info.zc + [-1 1]*A.size(2)/2;
  for k = 1:numel(A.t)
    nm = sprintf('absorber_%d', k);
    CSX = AddMaterial(CSX, nm);
    CSX = SetMaterialProperty(CSX, nm, 'Epsilon', A.epsR(k), 'Kappa', A.kappa(k));
    CSX = AddBox(CSX, nm, 1, [f yy(1) zz(1)], [f+A.t(k) yy(2) zz(2)]);
    mesh.x = [mesh.x f f+A.t(k)];
    f = f + A.t(k);
  end
  mesh.y = [mesh.y yy];  mesh.z = [mesh.z zz];
  bbox = [min(bbox(1,:), [bbox(1,1) yy(1) zz(1)]); max(bbox(2,:), [f yy(2) zz(2)])];
end

%% Stage B / D: 90 degree corner reflector, apex behind the whip or the board (+x), opening towards -x
if isfield(J, 'corner')
  C = J.corner;  zz = info.zc + [-1 1]*C.H/2;
  if isfield(C, 'ref') && strcmp(C.ref, 'back'), xa = bbox(2,1) + C.S; else, xa = x + C.S; end
  c45 = cos(pi/4);
  CSX = AddMetal(CSX, 'jam_reflector');
  for s = [-1 1]
    % thin plate from the apex to (xa - L c45, s L c45); thickness C.t, offset away from the whip
    p0 = [xa y];  p1 = [xa - C.L*c45, y + s*C.L*c45];
    nrm = [c45, s*c45] * 1;                  % unit normal pointing away from the whip (towards +x / outward)
    q = [p0; p1; p1 + C.t*nrm; p0 + C.t*nrm];
    CSX = AddLinPoly(CSX, 'jam_reflector', 10, 2, zz(1), q', C.H);
  end
  xr = [xa - C.L*c45, xa + C.t];  yr = y + [-1 1]*(C.L*c45 + C.t);
  mesh.x = add_fill([mesh.x xr], xr(1):C.res:xr(2), C.res);
  mesh.y = add_fill([mesh.y yr], yr(1):C.res:yr(2), C.res);
  mesh.z = [mesh.z zz];
  bbox = [min(bbox(1,:), [xr(1) yr(1) zz(1)]); max(bbox(2,:), [xr(2) yr(2) zz(2)])];
end
end
