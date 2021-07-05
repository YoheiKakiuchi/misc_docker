## Build Docker
```
git clone -b work https://github.com/s-noda/euslib.git s-noda_euslib
(cd s-noda_euslib; ./expand_branch.sh)

Docker build -f Dockerfile -t nodasim .
```

## walking-nodasim.lの使い方

```
$ roseus walking-nodasim.l
roseus$ (create-model-and-viewer)
roseus$ (go-pos-simulation 0.5 0 0)
```

```
kxrl2l6a6h2.lは
robot_assembler/sample/kxr_rcb4robots/{kxrl2l6a6h2.roboasm.l, kxrl2l6a6h2.urdf.euscollada.fixed.yaml}
を用いて作ったeusモデル
(これをダウンロード: https://gist.github.com/YoheiKakiuchi/85126ade854492bdd12d8114ffd1e73b )
```

```
walking-control.lはlecture2021/walk_tototial/walking-control.lをコピーして、
*robot* -> *robot-model* に修正したもの
```
