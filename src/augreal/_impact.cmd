loadProjectFile -file "/afs/athena.mit.edu/user/l/o/loganw/Documents/6.111/augmented-reality-on-fpga/src/augreal/augreal.ipf"
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
setMode -bs
setMode -bs
setMode -bs
setMode -bs
Program -p 2 
setMode -bs
deleteDevice -position 3
deleteDevice -position 2
deleteDevice -position 1
