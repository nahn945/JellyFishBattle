extends Node

const COLOR_NORMAL : Color = Color(1.0, 1.0, 1.0)
const COLOR_HIT : Color = Color(1.0, 0.1, 0.0)

@onready var hp_1p : ProgressBar = $CanvasLayer/UI/VBoxContainer/HP1
@onready var hp_2p : ProgressBar = $CanvasLayer/UI/VBoxContainer2/HP2
@onready var player1 : RigidBody2D = $Player1
@onready var player2 : RigidBody2D = $Player2

@onready var result : Control = $CanvasLayer/Result
@onready var winner_label : Label = $CanvasLayer/Result/VBoxContainer/Winner

@onready var count_label : Label = $CanvasLayer/CountLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player1.stop_operating()
	player2.stop_operating()
	
	await start_count()
	
	player1.activate_operating()
	player2.activate_operating()

func start_count():
	count_label.show()
	for i in range(3, 0, -1):
		count_label.text = var_to_str(i)
		await get_tree().create_timer(1.0).timeout
	count_label.hide()

func set_damage(value : float, id : int):
	var subject : ProgressBar
	if id == 1:
		subject = hp_1p
	elif id == 2:
		subject = hp_2p
	damage_effect(subject, COLOR_HIT)
	
	subject.value -= value
	check_game_end()

func check_game_end():
	if hp_1p.value == 0:
		player1.stop_operating()
		player2.stop_operating()
		player1.lose()
		winner_label.text = "Player2 Win!"
		result.show()
	elif hp_2p.value == 0:
		player1.stop_operating()
		player2.stop_operating()
		player2.lose()
		winner_label.text = "Player1 Win!"
		result.show()

func end_damage(id : int):
	if id == 1:
		damage_effect(hp_1p, COLOR_NORMAL)
	elif id == 2:
		damage_effect(hp_2p, COLOR_NORMAL)

func damage_effect(subject : ProgressBar, color : Color):
	subject.self_modulate = color

func restart():
	get_tree().change_scene_to_file("res://GameScene/game_scene.tscn")

func back_to_title():
	get_tree().change_scene_to_file("res://TitleScene/title_scene.tscn")
