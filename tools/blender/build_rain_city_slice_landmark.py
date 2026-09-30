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
    # Opaque service planes sit proud of the retained shell. Warmth is localized
    # beneath the shelves/hood; dark planes preserve recess depth without glass.
    for i,z in enumerate((-41,-37,-33)):
        back=m['steel'] if i == 0 else m['brick']
        box(target,f'ServiceBack{i}',(-5.0,1.4,z),(.08,1.75,3.45),back,.04)
        box(target,f'ShelterStrip{i}',(-4.93,2.19,z),(.06,.11,3.25),m['warm'],.012)
        for zz in (z-1.8,z+1.8):
            box(target,f'BayPier{i}_{zz}',(-5.1,1.4,zz),(.45,2.4,.22),m['cream'],.055)
        for yy in (.35,2.4):
            box(target,f'BayRail{i}_{yy}',(-5.06,yy,z),(.52,.17,3.85),m['steel'],.025)
        box(target,f'Counter{i}',(-4.96,.86,z),(.62,.17,3.55),m['cream'],.035)
        for zz in (z-.9,z+.9):
            box(target,f'WindowMullion{i}_{zz}',(-4.86,1.65,zz),(.15,1.42,.075),m['steel'],.012)
    # Bake bay: broad hood/throat above a deep dark chamber, raised hearth below.
    # These large shapes read at route distance; the narrow heat strip is the
    # only chamber glow, sharing the existing warm material and no live light.
    box(target,'OvenSurround',(-4.91,1.48,-37),(.10,1.48,2.65),m['brick'],.045)
    hood=[(1.86,-38.17),(2.23,-37.85),(2.23,-36.15),(1.86,-35.83)]
    slab(target,'OvenHood',hood,-4.72,.34,m['steel'])
    box(target,'OvenThroat',(-4.76,1.84,-37),(.28,.15,1.82),m['steel'],.025)
    box(target,'OvenMouth',(-4.82,1.35,-37),(.12,.68,1.62),m['pepper'],.08)
    for z in (-37.94,-36.06):
        box(target,f'OvenJamb{z}',(-4.73,1.34,z),(.22,.77,.18),m['cream'],.025)
    box(target,'OvenLintel',(-4.72,1.76,-37),(.22,.14,2.02),m['cream'],.025)
    box(target,'OvenHeat',(-4.73,1.105,-37),(.06,.06,1.45),m['warm'],.012)
    box(target,'OvenHearth',(-4.66,.99,-37),(.64,.16,2.17),m['cream'],.03)
    box(target,'HearthUnderlip',(-4.38,.895,-37),(.09,.07,2.04),m['steel'],.01)
    # Prep bay: one board, short stock shelf and a broad uncluttered worktop.
    box(target,'PrepShelf',(-4.82,1.61,-41),(.24,.10,2.6),m['steel'],.015)
    for i,z in enumerate((-41.68,-40.95)):
        cylinder_between(target,f'PrepTin{i}',(-4.8,1.66,z),(-4.8,1.98,z),.17,m['orange'],10)
        box(target,f'PrepTinLabel{i}',(-4.61,1.81,z),(.045,.13,.17),m['cream'],.01)
    box(target,'PrepWorktop',(-4.78,1.02,-41),(.40,.11,2.75),m['cream'],.025)
    box(target,'PrepBoard',(-4.55,1.1,-41.20),(.16,.06,1.12),m['orange'],.015)
    box(target,'PrepOrderBoard',(-4.83,2.03,-41),(.10,.31,1.20),m['steel'],.02)
    for i in range(2):
        box(target,f'PrepMenuStroke{i}',(-4.75,2.10-i*.10,-41),(.04,.025,.76-i*.18),m['cream'],0)
    # Collection bay: quiet brick wall, off-center stacked takeaway boxes and a
    # short tray shelf. It intentionally does not mirror the preparation bay.
    box(target,'CollectionShelf',(-4.82,1.29,-33),(.32,.11,2.6),m['steel'],.018)
    for i in range(2):
        box(target,f'CollectionBox{i}',(-4.73,1.42+i*.18,-33.65+i*.08),(.34,.16,.96),m['cream'],.02)
        box(target,f'CollectionBoxLid{i}',(-4.72,1.505+i*.18,-33.65+i*.08),(.36,.035,1.0),m['orange'],.008)
    box(target,'CollectionTray',(-4.74,1.40,-32.42),(.34,.08,.62),m['orange'],.015)
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
        if obj.type=='MESH':
            obj.name=obj.name.replace('RainCity_','Slice_')
            # Bevel UVs vary slightly across processes. Bounded precision
            # preserves their spatial projection: RC_* batches are remapped to
            # textured production materials by Godot, so UVs must not collapse.
            for layer in obj.data.uv_layers:
                for corner in layer.data:
                    corner.uv=(round(corner.uv.x,4),round(corner.uv.y,4))
    triangles=sum(len(o.data.polygons) for o in target.objects if o.type=='MESH')
    bpy.context.scene['presentation_only']=True;bpy.context.scene['source_parts']=parts;bpy.context.scene['material_batches']=batches
    SOURCE.parent.mkdir(parents=True,exist_ok=True);OUTPUT.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    bpy.ops.export_scene.gltf(filepath=str(OUTPUT),export_format='GLB',use_selection=False,export_apply=True,export_materials='EXPORT',export_yup=True)
    print(f'Slice landmark: parts={parts}, batches={batches}, polygons={triangles}, bytes={OUTPUT.stat().st_size}')
if __name__=='__main__':main()
