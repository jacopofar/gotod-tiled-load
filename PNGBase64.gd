extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var body = Marshalls.base64_to_raw("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNku3PyPwAFRwKsRM/YIAAAAABJRU5ErkJggg==")
	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	print(image)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
