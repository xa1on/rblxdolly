// yo
// Heavily inspired by the t6gr importer, go check em out

var w = myComp.width/2;
var h = myComp.height/2;

app.beginUndoGroup("Camera import");
var comp = app.project.activeItem;

var nullLayer = comp.layers.addNull();
nullLayer.threeDLayer = true;
nullLayer.name = "RBLXMVM Camera Control";

cameraLayer.parent = null;
cameraLayer.property("Position").setValue([0, 0, 0])
cameraLayer.name = "MVM CAM";

var importFile = File.openDialog('select file');
importFile.open("r");

importFile.close();