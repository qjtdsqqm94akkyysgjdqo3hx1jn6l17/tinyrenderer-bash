# Lesson 2: Triangle Rasterization
`triange_paralel.bash` technically works, but is really really REALLY slow.
`triange_paralel-1ppc.bash` is faster, but not as fast as the "old school" method in `triange.bash` & `modelrederer.bash`

Run model renderer:
```bash
# Default BG Color & OBJ model, but with canvas resolution of 800x800
bash lesson02/modelrederer.bash '' '800x800'

# Default BG Color & custom OBJ model, with canvas resolution of 800x800
bash lesson02/modelrederer.bash 'path/to/model.obj' '800x800'
```
