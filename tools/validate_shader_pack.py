from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / "shaders"
FINAL = (SHADERS / "final.fsh").read_text(encoding="utf-8")


def require(text, needle, label):
    if needle not in text:
        raise AssertionError(f"Missing {label}: {needle}")


require(FINAL, "0.987", "global brightness")
require(FINAL, "1.0135", "global contrast")
require(FINAL, "mix(1.0, 0.5, night)", "night brightness")
require(FINAL, "uniform int worldTime", "Iris worldTime uniform type")
require(FINAL, "float timeOfDay = float(worldTime)",
        "world time conversion")
require(FINAL, "0.8333333", "rain darkness")
require(FINAL, "0.6666667", "thunder darkness")
require(FINAL, "0.988", "Nether brightness")
require(FINAL, "1.0115", "Nether contrast")
require(FINAL, "1.011", "End brightness")
require(FINAL, "color, 0.988)", "End saturation")
require(FINAL, "1.0115", "End contrast")
require(FINAL, "isEyeInWater", "underwater state")
require(FINAL, "exposedToRain(worldPosition)", "world-space rain exposure")
require(FINAL, "thunderStrength > 0.001", "thunder-priority weather")

block_properties = (SHADERS / "block.properties").read_text(encoding="utf-8")
for block in (
    "minecraft:ice",
    "minecraft:packed_ice",
    "minecraft:blue_ice",
    "minecraft:frosted_ice",
    "minecraft:glass",
    "minecraft:tinted_glass",
    "minecraft:glass_pane",
    "minecraft:water",
):
    if block not in block_properties:
        raise AssertionError(f"Missing reflective material mapping: {block}")
for color in (
    "white", "orange", "magenta", "light_blue", "yellow", "lime",
    "pink", "gray", "light_gray", "cyan", "purple", "blue", "brown",
    "green", "red", "black",
):
    for suffix in ("stained_glass", "stained_glass_pane"):
        require(block_properties, f"minecraft:{color}_{suffix}",
                f"reflective glass variant {color} {suffix}")
for target in ("DRAWBUFFERS:012", "gl_FragData[2]"):
    require((SHADERS / "lib" / "gbuffers.fsh").read_text(encoding="utf-8"),
            target, "material metadata target")
require((SHADERS / "shaders.properties").read_text(encoding="utf-8"),
        "blend.gbuffers_translucent.colortex1=off",
        "unblended translucent depth metadata")
require(FINAL, "materialData.a", "per-fragment surface depth")
require(FINAL, "baseReflectance", "material-specific Fresnel reflection")
require(FINAL, "uniform sampler2D colortex2", "reflective material target")
require(FINAL, "skyColor * (0.25 + 0.75 * skyFade)",
        "reflection fallback")
require(FINAL, "sceneWorld.y > worldPosition.y + 0.25",
        "rain roof height mask")
require(FINAL, "if (thunderStrength > 0.001)", "independent thunder factor")
require((SHADERS / "lib" / "gbuffers.fsh").read_text(encoding="utf-8"),
        "gl_FragCoord.z", "stored receiver depth")
require((SHADERS / "lib" / "gbuffers.vsh").read_text(encoding="utf-8"),
        "vFogDistance", "vertex fog distance output")
require((SHADERS / "lib" / "gbuffers.fsh").read_text(encoding="utf-8"),
        "vFogDistance", "fragment fog distance input")
require((SHADERS / "lib" / "gbuffers.fsh").read_text(encoding="utf-8"),
        "fogColor", "Iris-compatible fog preservation")
for material_blend in (
    "blend.gbuffers_translucent.colortex2=off",
    "blend.gbuffers_water.colortex1=off",
    "blend.gbuffers_water.colortex2=off",
):
    require((SHADERS / "shaders.properties").read_text(encoding="utf-8"),
            material_blend, "unblended metadata buffer")
vertex_materials = (SHADERS / "lib" / "gbuffers.vsh").read_text(
    encoding="utf-8")
for mapping in (
    "blockId == 10001.0) vMaterial = 1.0",
    "blockId == 10002.0) vMaterial = 2.0",
    "blockId == 10003.0) vMaterial = 3.0",
):
    require(vertex_materials, mapping, "distinct reflective material IDs")

for source in SHADERS.rglob("*"):
    if source.suffix not in (".fsh", ".vsh", ".glsl"):
        continue
    text = source.read_text(encoding="utf-8")
    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
    if code.count("{") != code.count("}"):
        raise AssertionError(f"Unbalanced braces: {source}")

print("Shader requirement assertions passed.")
