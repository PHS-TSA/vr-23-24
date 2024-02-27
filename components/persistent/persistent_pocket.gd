@tool
class_name PersistentPocket
extends XRToolsSnapZone

## Persistent Pocket Node
##
## The [PersistentPocket] type holds persistent items managed by the
## persistence system. The [PersistentPocket] type extends from
## [XRToolsSnapZone] to allow [PersistentItem] objects to be snapped or
## removed by the player.

## Enumeration to control pocket behavior when the parent item is held
enum HeldBehavior {
	## Ignore picked_up/dropped changes
	IGNORE,
	## Enable when picked up
	ENABLE,
	## Disable when picked up
	DISABLE
}

# Group for world-data properties
@export_group("World Data")

## This property specifies the unique ID of this pocket
@export var pocket_id: String

# Group for options
@export_group("Options")

## Pocket behavior when held
@export var held_behavior := HeldBehavior.ENABLE:
	# Called when the held_behavior property has been modified
	set(p_held_behavior):
		held_behavior = p_held_behavior
		if is_inside_tree() and _parent_body:
			_update_held_behavior()

# Parent pickable body
var _parent_body: XRToolsPickable


# Add support for is_xr_class
func is_xr_class(p_name: String) -> bool:
	return p_name == "PersistentPocket" or super(p_name)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

	# Skip initialization if in editor
	if Engine.is_editor_hint():
		return

	# Search for an ancestor XRToolsPickable
	_parent_body = XRTools.find_xr_ancestor(self, "*", "XRToolsPickable")
	if _parent_body:
		var _connection_err := _parent_body.picked_up.connect(_on_picked_up)
		var _connection_err2 := _parent_body.dropped.connect(_on_dropped)

	# Update the held behavior
	_update_held_behavior()


# Get configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify pocket ID is set
	if not pocket_id:
		var _did_append := warnings.append("Pocket ID not zet")

	# Verify pocket is in persistent group
	if not is_in_group("persistent"):
		var _did_append := warnings.append("Pocket not in 'persistent' group")

	# Return warnings
	return warnings


# Handle notifications
func _notification(what: int) -> void:
	# Ignore notifications on freeing objects
	if is_queued_for_deletion():
		return

	match what:
		Persistent.NOTIFICATION_LOAD_STATE:
			_load_state()

		Persistent.NOTIFICATION_SAVE_STATE:
			_save_state()

		Persistent.NOTIFICATION_DESTROY:
			_destroy()


# This method loads the pocket state from [PersistentWorld]. If the
# [PersistentWorld] indicates this pocket holds an item then the item is
# created and picked up by the pocket.
func _load_state() -> void:
	# Queue populating the pocket as new nodes cannot be created inside a
	# notification handler.
	_populate_pocket.call_deferred()


# This method saves the state of the pocket to [PersistentWorld].
func _save_state() -> void:
	# Handle pocket not holding on to PersistentItem
	if not picked_up_object is PersistentItem:
		# Save that the pocket is empty
		PersistentWorld.instance.clear_value(pocket_id)
		return
	var persistent_picked_up_object: PersistentItem = picked_up_object

	# Get the item_id of the PersistentItem in the pocket
	var item_id := persistent_picked_up_object.item_id

	# Save that the pocket holds the item
	PersistentWorld.instance.set_value(pocket_id, item_id)


# This method destroys the pocket and any item inside it.
func _destroy() -> void:
	# Propagate destruction for anything we hold
	if is_instance_valid(picked_up_object):
		print(self, " propagating destroy to ", picked_up_object.name)
		picked_up_object.propagate_notification(Persistent.NOTIFICATION_DESTROY)
		picked_up_object.queue_free()


# Populate the contents of a pocket
func _populate_pocket() -> void:
	# Get the ID of the item in the pocket
	var _item_id: Variant = PersistentWorld.instance.get_value(pocket_id)
	if not _item_id is String:
		return
	var item_id: String = _item_id

	# Construct the item for the pocket
	var zone := PersistentZone.find_instance(self)
	var item := zone.create_item_instance(item_id)
	if not item:
		return

	# Put the item in the pocket
	item.global_transform = global_transform
	pick_up_object.call_deferred(item)


# Called when the parent pickable body is picked up
func _on_picked_up(_pickable: XRToolsPickable) -> void:
	_update_held_behavior()


# Called when the parent pickable body is dropped
func _on_dropped(_pickable: XRToolsPickable) -> void:
	_update_held_behavior()


# Update the pocket enable
func _update_held_behavior() -> void:
	# Skip if no valid parent body
	if not is_instance_valid(_parent_body):
		return

	# Test if the parent pickable is held
	var is_held := _parent_body.is_picked_up()

	# Update the enabled state based on whether the parent body is held and
	# the desired behavior
	match held_behavior:
		HeldBehavior.ENABLE:
			enabled = is_held

		HeldBehavior.DISABLE:
			enabled = not is_held
