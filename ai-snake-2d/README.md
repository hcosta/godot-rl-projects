<video src="assets/ai-snake-2d.mp4" controls width="100%">
  Tu navegador no soporta la reproducción de video.
</video>

## Training

```
python stable_baselines3_example.py --env_path="exports/game.exe" --save_model_path=model.zip --n_parallel=16 --speedup=500  --timesteps=1000000 --onnx_export_path=model.onnx
```

## Check logs

```
tensorboard --logdir=.
```