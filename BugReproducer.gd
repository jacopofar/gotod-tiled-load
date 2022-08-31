extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var tilesets_textures = {
		1:{"animations":{}, "calculated_size":1536, "texture":[ImageTexture.new()], "tile_height":32, "tile_width":32},
		1537:{"animations":{1539:[{"duration":150, "gid":2248}, {"duration":150, "gid":2264}, {"duration":150, "gid":2347},
		{"duration":150, "gid":1549}]}, "calculated_size":1024, "texture":[ImageTexture.new()]}}
	var gid = 1539 # Replace with function body.
	print("tileset_textures: ", tilesets_textures)
	for candidate_gid in tilesets_textures.keys():
		if (gid >= candidate_gid) and (gid <= candidate_gid + (tilesets_textures[candidate_gid]["calculated_size"])):
			print("cannot find gid: ", gid)
			print("visible animations:", tilesets_textures[candidate_gid]["animations"])
			print("check using in: ", gid in tilesets_textures[candidate_gid]["animations"])
			print("check using in keys(): ", gid in tilesets_textures[candidate_gid]["animations"].keys())

			for k in tilesets_textures[candidate_gid]["animations"].keys():
				print("type of ", k, " is ", typeof(k))
				print("equality check ", k == gid)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
