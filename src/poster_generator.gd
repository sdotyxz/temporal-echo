extends Node2D

func _ready():
	print("🎨 生成游戏宣传图...")
	
	# 等待一帧确保渲染完成
	await get_tree().process_frame
	
	# 截图
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	
	# 保存为PNG
	var path = "res://assets/promo/temporal_echo_poster.png"
	var error = image.save_png(path)
	
	if error == OK:
		print("✅ 图片已保存: ", path)
	else:
		print("❌ 保存失败: ", error)
	
	# 退出
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()
