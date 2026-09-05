https://github.com/hcosta/godot-rl-projects/raw/refs/heads/main/ai-snake-2d/assets/ai-snake-2d.webm

## Training

```
python stable_baselines3_example.py --env_path="exports/game.exe" --save_model_path=model.zip --n_parallel=16 --speedup=500  --timesteps=1000000 --onnx_export_path=model.onnx
```

## Check logs

```
tensorboard --logdir=.
```