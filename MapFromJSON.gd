extends Node

var map_url: String =  "http://localhost:8000/maps/first/chunk_0_0.json"
var map_data: Dictionary
var tilesets_textures: Dictionary = {}
var atlas_textures: Dictionary = {}
var animated_frames: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_map_metadata_request_completed")

	# Read the map
	var error = http_request.request(map_url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Callback for map JSON loaded
func _http_map_metadata_request_completed(_result, _response_code, _headers, body):
	map_data =  parse_json(body.get_string_from_utf8())

	var map_url_base = map_url.left(map_url.find_last("/"))

	for tileset in map_data["tilesets"]:
		var tileset_url = map_url_base + "/" + tileset["source"]
		var http_request = HTTPRequest.new()
		add_child(http_request)
		print("Loading tileset", tileset, " from ", tileset_url)
		var firstgid = int(tileset["firstgid"])
		tilesets_textures[firstgid] = {}
		http_request.connect("request_completed", self, "_http_tileset_metadata_request_completed", [firstgid, map_url_base])
		# Read the map
		var error = http_request.request(tileset_url)
		if error != OK:
			push_error("An error occurred in the HTTP request.")

func _http_tileset_metadata_request_completed(_result, _response_code, _headers, body, firstgid, map_url_base):
	print("Loaded tileset metadata for (first) GID ", firstgid)
	var tileset_data =  parse_json(body.get_string_from_utf8())
	tilesets_textures[firstgid]["tile_width"] = int(tileset_data["tilewidth"])
	tilesets_textures[firstgid]["tile_height"] = int(tileset_data["tileheight"])
	tilesets_textures[firstgid]["image_width"] = int(tileset_data["imagewidth"])
	tilesets_textures[firstgid]["image_height"] = int(tileset_data["imageheight"])
	tilesets_textures[firstgid]["animations"] = {}
	tilesets_textures[firstgid]["calculated_size"] = (tilesets_textures[firstgid]["image_width"] * tilesets_textures[firstgid]["image_height"]) / (tilesets_textures[firstgid]["tile_width"] * tilesets_textures[firstgid]["tile_height"])

	# read the animation key if present, used later to recreate animated tiles
	if "tiles" in tileset_data:
		for tile_extra_metadata in tileset_data["tiles"]:
			# this can be an animation or other properties
			if "animation" in tile_extra_metadata:
				# this is an array with frames having duration and gid. gid is relative to the tileset
				# so adding the offset we get the absolute id
				var absolute_gid_frames = []
				for anim_frame_desc in tile_extra_metadata["animation"]:
					absolute_gid_frames.append({"duration": int(anim_frame_desc["duration"]), "gid": int(anim_frame_desc["tileid"]) + firstgid})
				tilesets_textures[firstgid]["animations"][int(tile_extra_metadata["id"]) + firstgid] = absolute_gid_frames

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_http_tileset_image_request_completed", [firstgid])
	# Read the map
	var error = http_request.request(map_url_base + "/" + tileset_data["image"])
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_tileset_image_request_completed(_result, _response_code, _headers, body, gid):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	tilesets_textures[gid]["texture"] = texture

	# when all tileset textures are loaded, we can add the sprites
	var pending = false
	for ts in tilesets_textures.values():
		if not "texture" in ts:
			pending = true
			break
	if not pending:
		draw_map()


func get_atlas_from_gid(gid: int):
	if not gid in atlas_textures:
		var thisatlas: AtlasTexture = AtlasTexture.new()
		for candidate_gid in tilesets_textures.keys():
			if (gid >= candidate_gid) and (gid <= candidate_gid + (tilesets_textures[candidate_gid]["calculated_size"])):
				thisatlas.set_atlas(tilesets_textures[candidate_gid]["texture"])
				var atlax_x = int(gid - candidate_gid) % (tilesets_textures[candidate_gid]["image_width"] / tilesets_textures[candidate_gid]["tile_width"])
				var atlas_y = floor((gid - candidate_gid) / (tilesets_textures[candidate_gid]["image_width"] / tilesets_textures[candidate_gid]["tile_width"]))

				thisatlas.set_region(Rect2(
					atlax_x * tilesets_textures[candidate_gid]["tile_width"],
					atlas_y * tilesets_textures[candidate_gid]["tile_height"],
					tilesets_textures[candidate_gid]["tile_width"],
					tilesets_textures[candidate_gid]["tile_height"]
				))
				atlas_textures[gid] = thisatlas
				break
	return atlas_textures[gid]

# gets the sprite frames or null if not an animation
func get_animation_from_gid(gid:int) -> SpriteFrames:
	# if it's not an animation but known static tile, immediately return null
	if gid in atlas_textures:
		return null
	if gid in animated_frames:
		return animated_frames[gid]
	else:
		for candidate_gid in tilesets_textures.keys():
			if (gid >= candidate_gid) and (gid <= candidate_gid + (tilesets_textures[candidate_gid]["calculated_size"])):
				print("tileset_textures: ", tilesets_textures)
				if not gid in tilesets_textures[candidate_gid]["animations"]:
					return null
				var new_animation = SpriteFrames.new()
				new_animation.add_animation("anim")
				print("---")
				print("visible animations: ", tilesets_textures[candidate_gid]["animations"])
				print("keys: ", tilesets_textures[candidate_gid]["animations"].keys())
				print("is ", gid, " in there? ", gid in tilesets_textures[candidate_gid]["animations"].keys())
				for single_frame in tilesets_textures[candidate_gid]["animations"][gid]:
					# TODO here only the frame is used, duration is ignored
					new_animation.add_frame("anim", get_atlas_from_gid(single_frame["gid"]))
				animated_frames[gid] = new_animation
				return new_animation
		return null

func draw_map():
	for layer in map_data["layers"]:
		if layer["type"] != "tilelayer":
			continue
		var x = layer["x"]
		var y = layer["y"]
		var height = int(layer["height"])
		var width = int(layer["width"])
		var data = layer["data"]

		var tile_idx: int = 0
		while tile_idx < data.size():
			var gid = data[tile_idx]
			# tile position in the chunk

			var pos_rel_x = tile_idx % width
			var pos_rel_y = floor(tile_idx / width)
			tile_idx += 1
			if gid == 0:
				continue
			# TODO find if this is an animation, if it is create an animated sprite instead
			var anim = get_animation_from_gid(gid)
			if anim != null:
				print("Found animation for gid ", gid)
				var anims = AnimatedSprite.new()
				anims.set_position(Vector2((pos_rel_x * height) + x, (pos_rel_y * width) + y))
				anims.frames = anim
				anims.play("anim")
				add_child(anims)

			else:

				var this_atlas = get_atlas_from_gid(gid)
				var ns = Sprite.new()

				ns.set_position(Vector2((pos_rel_x * height) + x, (pos_rel_y * width) + y))
				ns.set_texture(this_atlas)
				add_child(ns)
