extends Sprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
   # Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed",Callable(self,"_http_tileset_metadata_request_completed"))

	# Read the tileset
	var error = http_request.request("http://localhost:8000/maps/first/victorian_streets.json")
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Callback for tileset JSON loaded
func _http_tileset_metadata_request_completed(_result, _response_code, _headers, body):
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_utf8())
	var tileset =  test_json_conv.get_data()
	print("tileset loaded")
	

	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed",Callable(self,"_http_tileset_image_request_completed"))

	# Request the image for the tileset
	# print(tileset)
	var error = http_request.request("http://localhost:8000/maps/first/" + tileset["image"])
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_tileset_image_request_completed(_result, _response_code, _headers, body):
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	var file = File.new()
	file.open("image_from_buffer.png", File.WRITE)
	file.store_buffer(body)
	file.close()
	
	if error != OK:
		push_error("Couldn't load the image.")

	var loaded_texture = ImageTexture.new()
	loaded_texture.create_from_image(image)

	var myatlastexture: AtlasTexture = AtlasTexture.new()
	myatlastexture.set_atlas(loaded_texture)
	myatlastexture.set_region(Rect2(128, 128, 32, 32 ))
	set_position(Vector2(30, 30))
	set_texture(myatlastexture)
	print("ALL DONE")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
