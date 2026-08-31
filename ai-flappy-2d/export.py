import os
from stable_baselines3 import PPO
from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx

# RUTA EXACTA DE TU ARCHIVO
ruta_zip = "logs/sb3/experiment_2_cp/experiment_2_400000_steps.zip"
nombre_onnx = "model.onnx"

print(f"Buscando modelo en: {ruta_zip}")

if not os.path.exists(ruta_zip):
    print("ERROR: No encuentro el archivo. Revisa la ruta.")
else:
    print("Cargando cerebro...")
    # Forzamos CPU para evitar errores de CUDA al exportar
    model = PPO.load(ruta_zip, device="cpu") 
    
    print(f"Exportando a {nombre_onnx}...")
    export_model_as_onnx(model, nombre_onnx)
    print("¡ÉXITO! Ya tienes tu archivo .onnx listo para Godot.")