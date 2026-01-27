@tool
extends SceneTree

func _init():
	print("Starting material generation...")
	var mat = StandardMaterial3D.new()
	
	# Load Textures
	# Note: We need to ensure these paths are correct relative to the project root
	var base_path = "res://assets/TexturesVol3/Vol 3/Floor Tile 1/PNG/1k/"
	
	mat.albedo_texture = load(base_path + "floor_tile_1_color.png")
	mat.normal_enabled = true
	mat.normal_texture = load(base_path + "floor_tile_1_normal.png")
	mat.roughness_texture = load(base_path + "floor_tile_1_roughness.png")
	mat.metallic = 1.0
	mat.metallic_texture = load(base_path + "floor_tile_1_metallic.png")
	mat.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAY
	mat.ao_enabled = true
	mat.ao_texture = load(base_path + "floor_tile_1_ao.png")
	
	# Tiling - Floor is 10000x10000, texture is 1k (aspect 1). 
	# If 1 unit = 1 meter, 10000m. 1k texture maybe covers 2m? 4m?
	# Let's try 1000x1000 tiling for high density or 100x100.
	# User wants "usable form". 
	mat.uv1_scale = Vector3(500, 500, 500)
	
	var dir = DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("resources/materials")
	
	var save_path = "res://resources/materials/floor_tile_1.tres"
	var err = ResourceSaver.save(mat, save_path)
	
	if err == OK:
		print("Material saved successfully to: ", save_path)
	else:
		print("Failed to save material. Error code: ", err)
	
	quit()
