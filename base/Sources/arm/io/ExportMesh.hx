package arm.io;

import iron.object.MeshObject;

class ExportMesh {

	public static function run(path: String, paintObjects: Array<MeshObject> = null, applyDisplacement = false) {
		if (paintObjects == null) paintObjects = Project.paintObjects;
		if (Context.raw.exportMeshFormat == FormatObj) ExportObj.run(path, paintObjects, applyDisplacement);
		else ExportArm.runMesh(path, paintObjects);
	}
}
