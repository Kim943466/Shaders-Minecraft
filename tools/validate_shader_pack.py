from pathlib import Path
import re
import zipfile


ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT / "shaders"
FINAL = (SHADERS / "final.fsh").read_text(encoding="utf-8")


def require(text, needle, label):
    if needle not in text:
        raise AssertionError(f"Missing {label}: {needle}")


require(FINAL, "0.987", "global brightness")
require(FINAL, "1.0135", "global contrast")
require(FINAL, "mix(1.0, 0.5, night)", "night brightness")
require(FINAL, "0.8333333", "rain darkness")
require(FINAL, "0.6666667", "thunder darkness")
require(FINAL, "0.988", "Nether brightness")
require(FINAL, "1.0115", "Nether contrast")
require(FINAL, "1.011", "End brightness")
require(FINAL, "0.988", "End saturation")
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

for source in SHADERS.rglob("*"):
    if source.suffix not in (".fsh", ".vsh", ".glsl"):
        continue
    text = source.read_text(encoding="utf-8")
    code = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
    if code.count("{") != code.count("}"):
        raise AssertionError(f"Unbalanced braces: {source}")

print("Shader requirement assertions passed.")
