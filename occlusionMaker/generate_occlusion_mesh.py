import bpy
import sys
from mathutils import Vector

input_file_path = sys.argv[sys.argv.index("--") + 1]
output_file_path = sys.argv[sys.argv.index("--") + 2]

bpy.ops.wm.read_factory_settings(use_empty=True)

bpy.ops.import_scene.gltf(filepath=input_file_path)

bpy.ops.object.select_all(action='DESELECT')
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj

bpy.ops.object.join()

joined_object = bpy.context.view_layer.objects.active

scale_factor = 1.1
joined_object.scale = (scale_factor, scale_factor, scale_factor)
bpy.ops.object.transform_apply(scale=True)

remesh_mod = joined_object.modifiers.new(name="Remesh", type='REMESH')
remesh_mod.mode = 'VOXEL'
remesh_mod.voxel_size = 1.2  # Adjust this value based on your needs
remesh_mod.use_remove_disconnected = False

bpy.ops.object.modifier_apply(modifier=remesh_mod.name)

bpy.ops.export_scene.gltf(filepath=output_file_path)
