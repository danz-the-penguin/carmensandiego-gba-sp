extends Node
## PortraitManager: Procedural Pixel-Art Character Avatars (2010s Neo-Retro Style)

var portraits: Dictionary = {}

func _ready() -> void:
	_generate_all_portraits()

func get_portrait(id: String) -> Texture2D:
	if portraits.has(id):
		return portraits[id]
	return portraits.get("chief", null)

func _generate_all_portraits() -> void:
	portraits["carmen"] = _draw_carmen()
	portraits["len_bulk"] = _draw_len_bulk()
	portraits["lady_agatha"] = _draw_lady_agatha()
	portraits["nick_brunch"] = _draw_nick_brunch()
	portraits["katherine_drib"] = _draw_katherine_drib()
	portraits["fast_eddie"] = _draw_fast_eddie()
	portraits["darlene_dirk"] = _draw_darlene_dirk()
	portraits["scar_graynolt"] = _draw_scar_graynolt()
	
	# Witnesses & ACME Staff
	portraits["banker"] = _draw_banker()
	portraits["pilot"] = _draw_pilot()
	portraits["curator"] = _draw_curator()
	portraits["chief"] = _draw_chief()

func _create_base_canvas(bg_color: Color) -> Image:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(bg_color)
	# 1px Dark Bezel Border
	for x in range(32):
		img.set_pixel(x, 0, Color(0.18, 0.24, 0.36, 1.0))
		img.set_pixel(x, 31, Color(0.12, 0.16, 0.24, 1.0))
	for y in range(32):
		img.set_pixel(0, y, Color(0.18, 0.24, 0.36, 1.0))
		img.set_pixel(31, y, Color(0.12, 0.16, 0.24, 1.0))
	return img

func _draw_carmen() -> Texture2D:
	var img := _create_base_canvas(Color(0.12, 0.06, 0.14))
	var red := Color(0.78, 0.12, 0.20)
	var yellow := Color(0.98, 0.82, 0.15)
	var skin := Color(0.85, 0.65, 0.52)
	var shadow := Color(0.15, 0.08, 0.12)

	# Fedora Brim
	for x in range(4, 28):
		img.set_pixel(x, 12, red)
		img.set_pixel(x, 13, red)
	# Fedora Crown
	for x in range(9, 23):
		for y in range(5, 11):
			img.set_pixel(x, y, red)
	# Yellow Band
	for x in range(9, 23):
		img.set_pixel(x, 11, yellow)

	# Face Shadow & Shaded Eyes
	for x in range(11, 21):
		for y in range(14, 21):
			img.set_pixel(x, y, skin)
	# Mystery Shadow over eyes
	for x in range(11, 21):
		img.set_pixel(x, 14, shadow)
		img.set_pixel(x, 15, shadow)
	# Glowing Gaze
	img.set_pixel(13, 16, Color(1.0, 1.0, 0.8))
	img.set_pixel(18, 16, Color(1.0, 1.0, 0.8))
	# Confident smile
	img.set_pixel(15, 19, Color(0.6, 0.1, 0.1))
	img.set_pixel(16, 19, Color(0.6, 0.1, 0.1))

	# Red Trench Coat & High Collar
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, red)
	# Collar Lapels
	for y in range(21, 27):
		img.set_pixel(11, y, Color(0.65, 0.08, 0.15))
		img.set_pixel(20, y, Color(0.65, 0.08, 0.15))
	# Ruby Ring Sparkle
	img.set_pixel(24, 26, Color(1.0, 0.2, 0.3))
	img.set_pixel(25, 26, Color(1.0, 0.9, 0.4))

	return ImageTexture.create_from_image(img)

func _draw_len_bulk() -> Texture2D:
	var img := _create_base_canvas(Color(0.08, 0.10, 0.16))
	var hair := Color(0.10, 0.10, 0.12)
	var skin := Color(0.88, 0.72, 0.58)
	var leather := Color(0.14, 0.16, 0.22)
	var glasses := Color(0.05, 0.05, 0.08)

	# Buzzcut hair
	for x in range(10, 22):
		for y in range(6, 11):
			img.set_pixel(x, y, hair)
	# Square Jaw Face
	for x in range(9, 23):
		for y in range(11, 22):
			img.set_pixel(x, y, skin)
	# Dark Sunglasses
	for x in range(10, 22):
		img.set_pixel(x, 13, glasses)
		img.set_pixel(x, 14, glasses)
	# Sunglasses Glint
	img.set_pixel(12, 13, Color(0.7, 0.8, 0.9))
	img.set_pixel(18, 13, Color(0.7, 0.8, 0.9))
	# Smirk
	img.set_pixel(15, 18, Color(0.4, 0.2, 0.2))
	img.set_pixel(16, 18, Color(0.4, 0.2, 0.2))

	# Heavy Biker Leather Jacket
	for x in range(5, 27):
		for y in range(22, 31):
			img.set_pixel(x, y, leather)
	# Arm Tattoo Hint
	img.set_pixel(6, 25, Color(0.2, 0.4, 0.6))
	img.set_pixel(7, 26, Color(0.2, 0.4, 0.6))

	return ImageTexture.create_from_image(img)

func _draw_lady_agatha() -> Texture2D:
	var img := _create_base_canvas(Color(0.14, 0.12, 0.08))
	var blonde := Color(0.96, 0.84, 0.32)
	var skin := Color(0.94, 0.80, 0.70)
	var gold := Color(1.0, 0.88, 0.25)
	var gown := Color(0.25, 0.15, 0.35)

	# Blonde Curls
	for x in range(8, 24):
		for y in range(6, 13):
			img.set_pixel(x, y, blonde)
	# Face
	for x in range(11, 21):
		for y in range(12, 21):
			img.set_pixel(x, y, skin)
	# Left Eye Normal
	img.set_pixel(13, 14, Color(0.2, 0.3, 0.5))
	# Right Eye Golden Monocle
	for x in range(17, 21):
		img.set_pixel(x, 13, gold)
		img.set_pixel(x, 16, gold)
	img.set_pixel(17, 14, gold)
	img.set_pixel(17, 15, gold)
	img.set_pixel(20, 14, gold)
	img.set_pixel(20, 15, gold)
	# Monocle lens glass
	img.set_pixel(18, 14, Color(0.6, 0.85, 1.0, 0.8))
	img.set_pixel(19, 15, Color(0.6, 0.85, 1.0, 0.8))
	# Monocle chain
	img.set_pixel(20, 17, gold)
	img.set_pixel(21, 19, gold)

	# Velvet Gown & Pearl Necklace
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, gown)
	for x in range(13, 19):
		img.set_pixel(x, 22, Color(0.95, 0.95, 1.0))

	return ImageTexture.create_from_image(img)

func _draw_nick_brunch() -> Texture2D:
	var img := _create_base_canvas(Color(0.12, 0.10, 0.08))
	var brown := Color(0.48, 0.32, 0.18)
	var skin := Color(0.88, 0.74, 0.60)
	var coat := Color(0.38, 0.26, 0.16)

	# Fedora Hat
	for x in range(6, 26):
		img.set_pixel(x, 11, brown)
	for x in range(10, 22):
		for y in range(6, 11):
			img.set_pixel(x, y, brown)
	# Face
	for x in range(11, 21):
		for y in range(12, 21):
			img.set_pixel(x, y, skin)
	# Tired detective eyes
	img.set_pixel(13, 14, Color(0.2, 0.15, 0.1))
	img.set_pixel(18, 14, Color(0.2, 0.15, 0.1))
	# Bushy Mustache
	for x in range(13, 19):
		img.set_pixel(x, 17, brown)
	# Trench coat
	for x in range(7, 25):
		for y in range(22, 31):
			img.set_pixel(x, y, coat)
	# Gold Watch peeking
	img.set_pixel(8, 26, Color(1.0, 0.85, 0.2))

	return ImageTexture.create_from_image(img)

func _draw_katherine_drib() -> Texture2D:
	var img := _create_base_canvas(Color(0.10, 0.12, 0.16))
	var hair := Color(0.15, 0.15, 0.18)
	var skin := Color(0.90, 0.76, 0.64)
	var goggles := Color(0.65, 0.52, 0.25)

	# Hair
	for x in range(8, 24):
		for y in range(5, 13):
			img.set_pixel(x, y, hair)
	# Brass Pilot Goggles on Forehead
	for x in range(10, 22):
		img.set_pixel(x, 10, goggles)
	img.set_pixel(12, 10, Color(0.4, 0.8, 0.9))
	img.set_pixel(18, 10, Color(0.4, 0.8, 0.9))
	# Face
	for x in range(11, 21):
		for y in range(12, 21):
			img.set_pixel(x, y, skin)
	img.set_pixel(13, 14, Color(0.2, 0.2, 0.3))
	img.set_pixel(18, 14, Color(0.2, 0.2, 0.3))
	# Aviator Jacket
	for x in range(7, 25):
		for y in range(22, 31):
			img.set_pixel(x, y, Color(0.35, 0.25, 0.18))
	# Gold Locket
	img.set_pixel(15, 24, Color(1.0, 0.85, 0.2))
	img.set_pixel(16, 24, Color(1.0, 0.85, 0.2))

	return ImageTexture.create_from_image(img)

func _draw_fast_eddie() -> Texture2D:
	var img := _create_base_canvas(Color(0.08, 0.12, 0.16))
	var red_hair := Color(0.85, 0.25, 0.15)
	var skin := Color(0.88, 0.72, 0.58)

	# Messy Red Hair
	for x in range(8, 24):
		for y in range(5, 12):
			img.set_pixel(x, y, red_hair)
	# Face
	for x in range(10, 22):
		for y in range(11, 21):
			img.set_pixel(x, y, skin)
	# Eye Patch on Right Eye
	for x in range(16, 20):
		img.set_pixel(x, 13, Color(0.1, 0.1, 0.1))
		img.set_pixel(x, 14, Color(0.1, 0.1, 0.1))
	img.set_pixel(12, 14, Color(0.2, 0.4, 0.3)) # Left green eye
	# Sailor stripes shirt
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, Color(0.15, 0.35, 0.65) if y % 2 == 0 else Color(0.9, 0.9, 0.95))

	return ImageTexture.create_from_image(img)

func _draw_darlene_dirk() -> Texture2D:
	var img := _create_base_canvas(Color(0.06, 0.14, 0.16))
	var brown := Color(0.38, 0.25, 0.15)
	var skin := Color(0.85, 0.70, 0.58)
	var scar := Color(0.72, 0.35, 0.35)

	# Hair
	for x in range(9, 23):
		for y in range(5, 12):
			img.set_pixel(x, y, brown)
	# Face
	for x in range(10, 22):
		for y in range(11, 21):
			img.set_pixel(x, y, skin)
	# Piercing eyes
	img.set_pixel(13, 14, Color(0.15, 0.35, 0.5))
	img.set_pixel(18, 14, Color(0.15, 0.35, 0.5))
	# Scar across cheek
	img.set_pixel(17, 16, scar)
	img.set_pixel(18, 17, scar)
	img.set_pixel(19, 18, scar)
	# Diver Wetsuit
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, Color(0.12, 0.22, 0.28))

	return ImageTexture.create_from_image(img)

func _draw_scar_graynolt() -> Texture2D:
	var img := _create_base_canvas(Color(0.14, 0.14, 0.10))
	var blonde := Color(0.95, 0.85, 0.35)
	var skin := Color(0.92, 0.76, 0.62)

	# Pompadour Hair
	for x in range(10, 22):
		for y in range(4, 11):
			img.set_pixel(x, y, blonde)
	# Face
	for x in range(11, 21):
		for y in range(11, 21):
			img.set_pixel(x, y, skin)
	img.set_pixel(13, 14, Color(0.2, 0.2, 0.2))
	img.set_pixel(18, 14, Color(0.2, 0.2, 0.2))
	# Sharp yellow & charcoal suit
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, Color(0.2, 0.22, 0.28))
	# Gold Cane Handle on side
	img.set_pixel(8, 23, Color(1.0, 0.85, 0.2))
	img.set_pixel(8, 24, Color(1.0, 0.85, 0.2))
	img.set_pixel(7, 24, Color(1.0, 0.85, 0.2))

	return ImageTexture.create_from_image(img)

func _draw_banker() -> Texture2D:
	var img := _create_base_canvas(Color(0.08, 0.14, 0.12))
	var visor := Color(0.15, 0.65, 0.35)
	var skin := Color(0.90, 0.76, 0.64)

	# Green Banker Visor
	for x in range(7, 25):
		img.set_pixel(x, 10, visor)
	for x in range(9, 23):
		for y in range(6, 10):
			img.set_pixel(x, y, Color(0.1, 0.1, 0.12))
	# Face
	for x in range(10, 22):
		for y in range(11, 21):
			img.set_pixel(x, y, skin)
	img.set_pixel(13, 13, Color(0.2, 0.2, 0.2))
	img.set_pixel(18, 13, Color(0.2, 0.2, 0.2))
	# White shirt + red tie
	for x in range(7, 25):
		for y in range(22, 31):
			img.set_pixel(x, y, Color(0.92, 0.94, 0.96))
	for y in range(22, 30):
		img.set_pixel(15, y, Color(0.8, 0.15, 0.15))
		img.set_pixel(16, y, Color(0.8, 0.15, 0.15))

	return ImageTexture.create_from_image(img)

func _draw_pilot() -> Texture2D:
	var img := _create_base_canvas(Color(0.06, 0.10, 0.18))
	var cap := Color(0.12, 0.18, 0.30)
	var gold := Color(1.0, 0.85, 0.25)
	var skin := Color(0.90, 0.75, 0.62)

	# Pilot Officer Cap
	for x in range(8, 24):
		for y in range(6, 11):
			img.set_pixel(x, y, cap)
	# Gold Wings Emblem
	for x in range(13, 19):
		img.set_pixel(x, 9, gold)
	# Black visor
	for x in range(9, 23):
		img.set_pixel(x, 11, Color(0.08, 0.08, 0.1))
	# Face
	for x in range(11, 21):
		for y in range(12, 21):
			img.set_pixel(x, y, skin)
	img.set_pixel(13, 14, Color(0.2, 0.3, 0.4))
	img.set_pixel(18, 14, Color(0.2, 0.3, 0.4))
	# Airline uniform + gold epaulets
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, cap)
	img.set_pixel(7, 22, gold)
	img.set_pixel(8, 22, gold)
	img.set_pixel(23, 22, gold)
	img.set_pixel(24, 22, gold)

	return ImageTexture.create_from_image(img)

func _draw_curator() -> Texture2D:
	var img := _create_base_canvas(Color(0.14, 0.10, 0.08))
	var hair := Color(0.70, 0.70, 0.75) # Graying hair
	var skin := Color(0.88, 0.76, 0.65)
	var tweed := Color(0.35, 0.28, 0.20)

	# Gray Hair
	for x in range(9, 23):
		for y in range(6, 12):
			img.set_pixel(x, y, hair)
	# Face
	for x in range(11, 21):
		for y in range(12, 21):
			img.set_pixel(x, y, skin)
	# Round Spectacles
	for x in range(12, 16):
		img.set_pixel(x, 13, Color(0.7, 0.6, 0.3))
		img.set_pixel(x, 15, Color(0.7, 0.6, 0.3))
	for x in range(17, 21):
		img.set_pixel(x, 13, Color(0.7, 0.6, 0.3))
		img.set_pixel(x, 15, Color(0.7, 0.6, 0.3))
	# Bridge
	img.set_pixel(16, 14, Color(0.7, 0.6, 0.3))
	# Tweed Jacket + Bow tie
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, tweed)
	img.set_pixel(15, 23, Color(0.6, 0.1, 0.2))
	img.set_pixel(16, 23, Color(0.6, 0.1, 0.2))

	return ImageTexture.create_from_image(img)

func _draw_chief() -> Texture2D:
	var img := _create_base_canvas(Color(0.08, 0.10, 0.18))
	var cap := Color(0.10, 0.15, 0.26)
	var gold := Color(1.0, 0.85, 0.25)
	var skin := Color(0.88, 0.74, 0.60)

	# ACME Chief Police Cap
	for x in range(8, 24):
		for y in range(5, 10):
			img.set_pixel(x, y, cap)
	# ACME Star Badge
	img.set_pixel(15, 7, gold)
	img.set_pixel(16, 7, gold)
	img.set_pixel(15, 8, gold)
	img.set_pixel(16, 8, gold)
	# Visor
	for x in range(8, 24):
		img.set_pixel(x, 10, Color(0.05, 0.05, 0.08))
	# Face
	for x in range(10, 22):
		for y in range(11, 21):
			img.set_pixel(x, y, skin)
	img.set_pixel(13, 14, Color(0.2, 0.2, 0.2))
	img.set_pixel(18, 14, Color(0.2, 0.2, 0.2))
	# Chief Mustache
	for x in range(13, 19):
		img.set_pixel(x, 17, Color(0.3, 0.3, 0.35))
	# Uniform + Badge on chest
	for x in range(6, 26):
		for y in range(22, 31):
			img.set_pixel(x, y, cap)
	img.set_pixel(10, 24, gold)
	img.set_pixel(11, 25, gold)

	return ImageTexture.create_from_image(img)
