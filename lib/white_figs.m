function white_figs()
% WHITE_FIGS  Force a white background and black text/axes on every new figure (also when MATLAB runs in its dark theme).
try, s = settings; s.matlab.appearance.figure.GraphicsTheme.TemporaryValue = 'light'; catch, end
r = groot;
d = {'defaultFigureColor', 'w'; 'defaultAxesColor', 'w'; 'defaultAxesXColor', 'k'; 'defaultAxesYColor', 'k'; ...
     'defaultAxesZColor', 'k'; 'defaultTextColor', 'k'; 'defaultLegendColor', 'w'; 'defaultLegendTextColor', 'k'; ...
     'defaultLegendEdgeColor', 'k'; 'defaultAxesGridColor', 'k'; 'defaultAxesMinorGridColor', 'k'; 'defaultColorbarColor', 'k'};
for k = 1:size(d, 1)
  try, set(r, d{k, 1}, d{k, 2}); catch, end
end
end
