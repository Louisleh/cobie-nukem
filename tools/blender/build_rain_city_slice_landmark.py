"""Original presentation-only Slice landmark; run with Blender --background --python."""
from pathlib import Path
import sys
import math
import bpy
sys.path.insert(0, str(Path(__file__).parent))
from build_rain_city_foundry import reset, material, box, cylinder_between, gp, consolidate_by_material
ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/source/blender/rain_city_slice_landmark.blend'
OUTPUT = ROOT / 'assets/models/environment/rain_city_slice_landmark.glb'

def slab(target, name, outline, x, depth, mat):
    n=len(outline)
    vertices=[gp(xx,y,z) for xx in (x-depth/2,x+depth/2) for y,z in outline]
    faces=[tuple(reversed(range(n))),tuple(range(n,2*n))]
    faces += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.materials.append(mat);mesh.update()
    obj=bpy.data.objects.new(name,mesh);target.objects.link(obj)
    bevel=obj.modifiers.new('EnamelRoundedEdge','BEVEL');bevel.width=.045;bevel.segments=2
    return obj

def main():
    target=reset();target.name='SLICE_LANDMARK_PRESENTATION'
    bpy.context.preferences.filepaths.save_version=0
    m={
      'steel':material('RC_HarbourSteel',(.18,.24,.25,1),.7,.36),
      'brick':material('RC_RainBrick',(.33,.12,.08,1),0,.7),
      'orange':material('SL_BakedEnamel',(.72,.16,.045,1),.12,.45,.24),
      'cream':material('SL_CreamEnamel',(1,.68,.27,1),.06,.55,.45),
      'warm':material('SL_ShelterGlow',(1,.48,.13,1),0,.7,.8),
      'pepper':material('SL_PepperEnamel',(.32,.028,.019,1),.12,.5,.18),
    }
    # Window inserts sit proud of the retained gameplay shell, recessed behind
    # a dimensional frame; opaque backplanes avoid costly glass overdraw.
    for i,z in enumerate((-41,-37,-33)):
        box(target,f'WarmBay{i}',(-5.0,1.4,z),(.08,1.75,3.45),m['warm'],.04)
        for zz in (z-1.8,z+1.8):
            box(target,f'BayPier{i}_{zz}',(-5.1,1.4,zz),(.45,2.4,.22),m['cream'],.055)
        for yy in (.35,2.4):
            box(target,f'BayRail{i}_{yy}',(-5.06,yy,z),(.52,.17,3.85),m['steel'],.025)
        box(target,f'Counter{i}',(-4.96,.86,z),(.62,.17,3.55),m['cream'],.035)
        for zz in (z-.9,z+.9):
            box(target,f'WindowMullion{i}_{zz}',(-4.86,1.65,zz),(.15,1.42,.075),m['steel'],.012)
    # Hand-built service silhouettes break up the opaque warm backplanes.
    # A central oven and two shelf bays read from the route without cluttering it.
    box(target,'OvenRecess',(-4.9,1.48,-37),(.08,1.08,1.65),m['steel'],.16)
    box(target,'OvenMouth',(-4.82,1.35,-37),(.08,.48,1.23),m['pepper'],.12)
    box(target,'OvenHearth',(-4.72,1.1,-37),(.28,.12,1.68),m['cream'],.025)
    for bay in (-41,-33):
        box(target,f'ServiceShelf{bay}',(-4.82,1.35,bay),(.24,.10,2.6),m['steel'],.015)
        for i in range(3):
            z=bay-.82+i*.82
            cylinder_between(target,f'ServiceTin{bay}_{i}',(-4.8,1.4,z),(-4.8,1.75,z),.17,m['orange'],10)
            box(target,f'TinLabel{bay}_{i}',(-4.61,1.58,z),(.045,.13,.17),m['cream'],.01)
        box(target,f'OrderBoard{bay}',(-4.83,2.06,bay),(.10,.38,1.2),m['steel'],.02)
        for i in range(3):
            box(target,f'MenuStroke{bay}_{i}',(-4.75,2.15-i*.09,bay),(.04,.025,.76-i*.12),m['cream'],0)
    # Roof cornice and shallow stepped pediment replace the slab's silhouette.
    for y,width in ((4.35,14.9),(4.62,13.5),(4.87,8.2)):
        box(target,f'Cornice{y}',(-5.22,y,-37),(.8,.24,width),m['cream'],.07)
    box(target,'RoofFascia',(-5.5,4.5,-37),(.5,.56,14.3),m['brick'],.06)
    # Folded, striped canopy: individual angled facets, no texture atlas needed.
    for i in range(20):
        z=-43.175+i*.65;mat=m['orange'] if i%2==0 else m['cream']
        box(target,f'CanopyStripe{i}',(-4.79,2.81,z),(1.12,.15,.64),mat,.02,rotation=(0,.25,0))
        box(target,f'CanopyValance{i}',(-4.3,2.47,z),(.11,.32,.64),mat,.035)
    for z in (-42.65,-31.35):
        cylinder_between(target,f'CanopyBrace{z}',(-5.2,1.95,z),(-4.3,2.68,z),.045,m['steel'],8)
    # The wedge leans sideways: tip low-left, broad crust high-right. Original
    # physical sign, no borrowed character/brand art. Front faces +X.
    outline=[(5.05,-38.95),(7.55,-37.8),(7.08,-35.0)]
    slab(target,'PizzaOutline',outline,-5.05,.3,m['steel'])
    cheese=[(5.28,-38.63),(7.32,-37.75),(6.94,-35.28)]
    slab(target,'PizzaCheese',cheese,-4.83,.16,m['cream'])
    cylinder_between(target,'RaisedCrust',(-4.69,7.35,-37.82),(-4.69,6.96,-35.12),.18,m['orange'],12)
    for i,(y,z) in enumerate(((6.82,-37.55),(6.75,-36.4),(6.0,-37.7))):
        cylinder_between(target,f'Pepperoni{i}',(-4.73,y,z),(-4.62,y,z),.23,m['pepper'],16)
    for z in (-38.2,-36.6):
        cylinder_between(target,f'EmblemSupport{z}',(-5.35,4.6,z),(-5.35,6.45,z),.09,m['steel'],8)
    for obj in target.objects:
        for modifier in obj.modifiers:
            if modifier.type == 'BEVEL': modifier.segments = 1
    parts=len([o for o in target.objects if o.type=='MESH']);batches=consolidate_by_material(target)
    for obj in target.objects:
        if obj.type=='MESH':obj.name=obj.name.replace('RainCity_','Slice_')
    triangles=sum(len(o.data.polygons) for o in target.objects if o.type=='MESH')
    bpy.context.scene['presentation_only']=True;bpy.context.scene['source_parts']=parts;bpy.context.scene['material_batches']=batches
    SOURCE.parent.mkdir(parents=True,exist_ok=True);OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_format='GLB',use_selection=False,export_apply=True,export_materials='EXPORT',export_yup=True)
    print(f'Slice landmark: parts={parts}, batches={batches}, polygons={triangles}, bytes={OUTPUT.stat().st_size}')
if __name__=='__main__':main()
