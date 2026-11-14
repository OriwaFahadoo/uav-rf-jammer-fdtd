function vline(x)
% VLINE  dotted vertical line (xline is missing in Octave)
yl = ylim; plot([x x], yl, 'k:'); ylim(yl);
end
