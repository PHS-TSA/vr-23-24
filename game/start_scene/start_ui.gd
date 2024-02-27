extends CenterContainer

var save_list: Array[String]
@onready var load_game: VBoxContainer = $LoadGame
@onready var save_list_node: ItemList = $LoadGame/SaveList
@onready var main_menu: VBoxContainer = $MainMenu
@onready var load_game_btn: Button = $MainMenu/LoadGameBtn
@onready var new_game: Button = $NewGame
@onready var options: VBoxContainer = $Options


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_pane(1)

	# Get our list of save games
	if PersistentWorld.instance:
		save_list = PersistentWorld.instance.list_saves()

		save_list_node.clear()
		for entry in save_list:
			var _did_add := save_list_node.add_item(entry)

	load_game_btn.disabled = save_list.size() == 0


func _set_pane(p_no: int) -> void:
	main_menu.visible = p_no == 1
	new_game.visible = p_no == 2
	load_game.visible = p_no == 3
	options.visible = p_no == 4


# Main menu


func _on_new_game_btn_pressed() -> void:
	_set_pane(2)


func _on_load_game_btn_pressed() -> void:
	_set_pane(3)


func _on_options_btn_pressed() -> void:
	_set_pane(4)


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


# New game


func _on_easy_btn_pressed() -> void:
	var _new_game_started := GameState.new_game(GameState.GameDifficulty.GAME_EASY)


func _on_normal_btn_pressed() -> void:
	var _new_game_started := GameState.new_game(GameState.GameDifficulty.GAME_NORMAL)


func _on_hard_btn_pressed() -> void:
	var _new_game_started := GameState.new_game(GameState.GameDifficulty.GAME_HARD)


func _on_back_btn_pressed() -> void:
	_set_pane(1)


# Load game


func _on_start_button_pressed() -> void:
	var selected_items := save_list_node.get_selected_items()
	if selected_items.size() == 1:
		# Should be only one!
		var selected_item: int = selected_items[0]
		print("Selected item: ", selected_item)

		var save_name: String = save_list[selected_item]
		print("Loading save: ", save_name)
		var _new_game_started := GameState.load_game(save_name)
