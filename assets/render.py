# Forces Factorio-correct render settings, then renders combinator.blend to
# graphics/entity/combinator.png. Run via `make render` (not directly).
# ponytail: settings live here, not baked into the binary .blend
import bpy, os

scene = bpy.context.scene
r = scene.render

r.film_transparent = True                 # alpha background
r.image_settings.file_format = "PNG"
r.image_settings.color_mode = "RGBA"

r.resolution_x = 256                       # square; scale down via prototype `scale`
r.resolution_y = 256
r.resolution_percentage = 100

scene.view_settings.view_transform = "Standard"  # flat colors, not AgX/Filmic

out = os.path.join(os.path.dirname(bpy.data.filepath), "..",
                   "graphics", "entity", "combinator")
r.filepath = os.path.abspath(out)          # no frame suffix -> combinator.png
os.makedirs(os.path.dirname(r.filepath), exist_ok=True)

bpy.ops.render.render(write_still=True)
