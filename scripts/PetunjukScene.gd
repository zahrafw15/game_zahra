extends Control

@onready var tombol_kembali = $Button_Kembali as Button



func _ready():
	tombol_kembali.button_down.connect(on_kembali_pressed)


func on_kembali_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
