function [CSX, port, mesh, bbox] = add_tx(CSX, mesh, a, portnr, excite)
% ADD_TX  The settled Stage A TX: vertical centre-fed dipole of round rods (radius a.radius).
x = a.feed(1); y = a.feed(2); z = a.feed(3);
CSX = AddMetal(CSX, 'tx_wire');
CSX = AddCylinder(CSX, 'tx_wire', 10, [x y z+a.gap/2], [x y z+a.L/2], a.radius);
CSX = AddCylinder(CSX, 'tx_wire', 10, [x y z-a.gap/2], [x y z-a.L/2], a.radius);
[CSX, port] = AddLumpedPort(CSX, 5, portnr, a.R, [x y z-a.gap/2], [x y z+a.gap/2], [0 0 1], excite);
mesh.x = [mesh.x x + [-a.res 0 a.res]];
mesh.y = [mesh.y y + [-a.res 0 a.res]];
mesh.z = [mesh.z z + [-a.L/2 -a.gap/2 0 a.gap/2 a.L/2]];
bbox = [x-a.radius y-a.radius z-a.L/2; x+a.radius y+a.radius z+a.L/2];
end
