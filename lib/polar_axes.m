function polar_axes(rmin, rmax, step, ang0, ang1)
% POLAR_AXES  Draw rings and spokes (radius = dBi mapped to rmin..rmax) for a pattern plot made with plot().
%   Portable (MATLAB and Octave): no polarplot needed. ang0..ang1 in degrees, measured from the +x axis.
hold on; axis equal off;
a = linspace(ang0, ang1, 181) * pi/180;
for v = rmin:step:rmax
  r = (v - rmin) / (rmax - rmin);
  plot(r*cos(a), r*sin(a), '-', 'Color', [0.8 0.8 0.8]);
  text(r*cos(a(end)), r*sin(a(end)), sprintf(' %g', v), 'FontSize', 8, 'Color', [0.4 0.4 0.4]);
end
for ad = ang0:30:ang1
  plot([0 cos(ad*pi/180)], [0 sin(ad*pi/180)], '-', 'Color', [0.88 0.88 0.88]);
end
end
