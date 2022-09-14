extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var file_in = File.new()
	file_in.open("image_to_buffer.png", File.READ)
	var body = file_in.get_buffer(file_in.get_length())
	file_in.close()
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	print("ERROR: ", error, " IMAGE: ", image, " BUFFER SIZE: ", body.size())
	var file_out = File.new()
	file_out.open("image_from_buffer.png", File.WRITE)
	file_out.store_buffer(body)
	file_out.close()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
