# Draw a geometry case as a coloured, labelled PNG with plain VTK (no ParaView needed).
#   python3 scene_views.py <case folder> <out prefix>   -> prefix_iso/side/top/front.png
import sys, os, re
import vtk
folder, outp = sys.argv[1], sys.argv[2]
src = open(os.path.join(folder, 'open_scene.py')).read()
PARTS = eval(re.search(r'PARTS = (\{.*?\n\})', src, re.S).group(1))     # the same colours and labels as open_scene.py
ren = vtk.vtkRenderer(); ren.SetBackground(.97, .97, .97)

def add(path, col, op=1.0):
    r = vtk.vtkPolyDataReader(); r.SetFileName(path); r.Update()
    m = vtk.vtkPolyDataMapper(); m.SetInputConnection(r.GetOutputPort()); m.ScalarVisibilityOff()
    a = vtk.vtkActor(); a.SetMapper(m); a.GetProperty().SetColor(*col); a.GetProperty().SetOpacity(op); ren.AddActor(a)
    return r.GetOutput().GetBounds()

names = [l.split('=')[1].strip() for l in open(os.path.join(folder, 'parts.txt')) if '=' in l]
allb, labels = [], []
for n in names:
    if n not in PARTS: continue
    t, c, off, thin = PARTS[n]
    b = add(os.path.join(folder, 'part_%s.vtk' % n), c); allb.append(b)
    cc = ((b[0] + b[1]) / 2, (b[2] + b[3]) / 2, (b[4] + b[5]) / 2)
    labels.append((t, c, tuple(cc[i] + off[i] for i in range(3))))
    if thin:
        sp = vtk.vtkSphereSource(); sp.SetCenter(*cc); sp.SetRadius(0.005); sp.Update()
        m = vtk.vtkPolyDataMapper(); m.SetInputConnection(sp.GetOutputPort())
        a = vtk.vtkActor(); a.SetMapper(m); a.GetProperty().SetColor(*c); ren.AddActor(a)
gp = os.path.join(folder, 'ground_plane.vtk')
if os.path.exists(gp): add(gp, (.55, .55, .55), 0.25)
for t, c, p in labels:
    a = vtk.vtkBillboardTextActor3D(); a.SetInput(t); a.SetPosition(*p)
    tp = a.GetTextProperty(); tp.SetColor(*c); tp.SetFontSize(20); tp.SetBold(1)
    tp.SetBackgroundColor(1, 1, 1); tp.SetBackgroundOpacity(0.75); tp.SetJustificationToCentered(); ren.AddActor(a)
w = vtk.vtkRenderWindow(); w.SetOffScreenRendering(1); w.AddRenderer(ren); w.SetSize(1400, 1000)
lo = [min(b[i * 2] for b in allb) for i in range(3)]; hi = [max(b[i * 2 + 1] for b in allb) for i in range(3)]
fp = [(lo[i] + hi[i]) / 2 for i in range(3)]; diag = sum((hi[i] - lo[i]) ** 2 for i in range(3)) ** .5 + 0.3
cam = ren.GetActiveCamera()
VIEWS = {'iso': (-0.65, -1.0, 0.5), 'side': (0, -1.0, 0.15), 'top': (-0.001, -0.001, 1.0), 'front': (-1.0, -0.001, 0.15)}
for name, d in VIEWS.items():
    k = 1.0 if name != 'top' else 1.0
    cam.SetFocalPoint(*fp)
    cam.SetPosition(fp[0] + d[0] * diag, fp[1] + d[1] * diag, fp[2] + d[2] * diag); cam.SetViewUp(0, 0, 1 if name != 'top' else 0)
    if name == 'top': cam.SetViewUp(0, 1, 0)
    ren.ResetCameraClippingRange(); w.Render()
    f = vtk.vtkWindowToImageFilter(); f.SetInput(w); f.Update()
    pw = vtk.vtkPNGWriter(); pw.SetFileName('%s_%s.png' % (outp, name)); pw.SetInputConnection(f.GetOutputPort()); pw.Write()
