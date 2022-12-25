extends ReferenceRect

func _process(_delta):
	if get_parent().get_parent().isOnMenu: return
	if Input.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			hide()
		else:
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			show()

func _on_resumeButton_pressed():
	get_tree().paused = false
	hide()


func _on_menuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene("res://levels/mainMenu.tscn")


func _on_quitButton_pressed():
	get_tree().quit()


func _on_loadingScreen_visibility_changed():
	self.set_process(false)
