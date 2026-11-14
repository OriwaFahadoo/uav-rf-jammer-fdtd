# Open this scene in ParaView with fixed colours and labels.
# From Terminal (the folder of this file is found from --script):
#   open -a ParaView --args --script="$PWD/open_scene.py"
# or in ParaView: Tools > Python Shell > Run Script > pick this file.
import os, sys
from paraview.simple import *

def _here():
    for a in sys.argv:
        if a.startswith('--script='):
            return os.path.dirname(os.path.abspath(a.split('=', 1)[1]))
    try:
        return os.path.dirname(os.path.abspath(__file__))
    except NameError:
        return os.getcwd()

HERE = _here()

# part name in the model -> (label, colour RGB 0..1, label offset (dx, dy, dz) in m from the part centre, thin part?)
PARTS = {
    'tx_wire':       ('TX antenna (dipole)',    (0.10, 0.35, 0.95), (-0.05, 0.0, 0.07), True),
    'jam_wire':      ('Jammer whip',            (0.90, 0.10, 0.10), (0.00, 0.0, 0.12), True),
    'jam_plate':     ('Jammer ground plate',    (1.00, 0.55, 0.00), (0.00, -0.12, -0.05), False),
    'jam_reflector': ('Corner reflector',       (0.10, 0.70, 0.25), (0.10, 0.0, 0.13), False),
    'jam_tsa':       ('TSA600 board',           (0.60, 0.20, 0.80), (-0.05, 0.0, 0.17), False),
}
GROUND = ('Ground plane (PEC, z = 0)', (0.55, 0.55, 0.55))

view = GetActiveViewOrCreate('RenderView')
view.OrientationAxesVisibility = 1
view.Background = [0.97, 0.97, 0.97]
try:
    view.UseColorPaletteForBackground = 0       # newer ParaView versions
except Exception:
    pass

def plain(rep, colour):
    """Fixed colour, no scalar colouring; works on ParaView 5.x and 6.x."""
    for fn in (lambda: setattr(rep, 'ColorArrayName', [None, '']),
               lambda: setattr(rep, 'ColorArrayName', ['POINTS', ''])):
        try:
            fn()
            break
        except Exception:
            pass
    for attr in ('DiffuseColor', 'AmbientColor'):
        try:
            setattr(rep, attr, list(colour))
        except Exception:
            pass

def solid(path, colour, opacity=1.0):
    src = OpenDataFile(path)
    rep = Show(src, view)
    try:
        rep.Representation = 'Surface'
    except Exception:
        pass
    plain(rep, colour)
    rep.Opacity = opacity
    return src

labels = []
legend = []
allb = []
if os.path.exists(os.path.join(HERE, 'parts.txt')):
    names = [l.split('=')[1].strip() for l in open(os.path.join(HERE, 'parts.txt')) if '=' in l]
else:
    names = list(PARTS)
for name in names:
    f = os.path.join(HERE, 'part_%s.vtk' % name)
    if name not in PARTS or not os.path.exists(f):
        continue
    text, colour, off, thin = PARTS[name]
    src = solid(f, colour)
    b = src.GetDataInformation().GetBounds()
    c = ((b[0] + b[1]) / 2, (b[2] + b[3]) / 2, (b[4] + b[5]) / 2)
    labels.append((text, colour, (c[0] + off[0], c[1] + off[1], c[2] + off[2])))
    legend.append((text, colour))
    if thin:                      # a small ball so the thin wire can be found
        try:
            ball = Sphere(Center=list(c), Radius=0.005, ThetaResolution=20, PhiResolution=20)
            rb = Show(ball, view)
            plain(rb, colour)
        except Exception as e:
            print('ball skipped:', e)
    allb.append(b)

gp = os.path.join(HERE, 'ground_plane.vtk')
if os.path.exists(gp):
    solid(gp, GROUND[1], opacity=0.25)
    legend.append((GROUND[0], GROUND[1]))

# 3D text labels (plain VTK, present in every ParaView)
from vtkmodules.vtkRenderingCore import vtkBillboardTextActor3D
ren = view.GetRenderer()
for text, colour, pos in labels:
    try:
        a = vtkBillboardTextActor3D()
        a.SetInput(text)
        a.SetPosition(*pos)
        tp = a.GetTextProperty()
        tp.SetColor(*colour)
        tp.SetFontSize(20)
        tp.SetBold(1)
        tp.SetBackgroundColor(1, 1, 1)
        tp.SetBackgroundOpacity(0.75)
        tp.SetJustificationToCentered()
        ren.AddActor(a)
    except Exception as e:
        print('label skipped:', text, e)

# colour key in the corner: one coloured line per part
for i, (text, colour) in enumerate(legend):
    try:
        t = Text(Text=u'\u25A0 ' + text)
        d = Show(t, view)
    except Exception as e:
        print('legend skipped:', e)
        break
    for loc in ('Any Location', 'AnyLocation'):   # the name differs between ParaView versions
        try:
            d.WindowLocation = loc
            break
        except Exception:
            pass
    try:
        d.Position = [0.01, 0.96 - 0.045 * i]
        d.Color = list(colour)
        d.FontSize = 16
        d.Bold = 1
    except Exception:
        pass

# camera: look at the metal parts (not at the big ground plane), 3/4 view from the TX side
if allb:
    lo = [min(b[0] for b in allb), min(b[2] for b in allb), min(b[4] for b in allb)]
    hi = [max(b[1] for b in allb), max(b[3] for b in allb), max(b[5] for b in allb)]
    fp = [(lo[i] + hi[i]) / 2 for i in range(3)]
    diag = sum((hi[i] - lo[i]) ** 2 for i in range(3)) ** 0.5 + 0.3
    view.CameraFocalPoint = fp
    view.CameraPosition = [fp[0] - 0.65 * diag, fp[1] - 1.0 * diag, fp[2] + 0.5 * diag]
    view.CameraViewUp = [0, 0, 1]
else:
    view.ResetCamera()
Render()
