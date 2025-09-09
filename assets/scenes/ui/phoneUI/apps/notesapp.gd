extends PanelContainer
@onready var noteSelection = $noteSelection
@onready var noteReader = $noteReader
@onready var noteText : RichTextLabel = $noteReader/richTextLabel

var noteButton : PackedScene = preload("res://assets/scenes/ui/phoneUI/apps/noteButton.tscn")
@export_category("Notes App")
@export var notes : Array[NoteResource]
@export var currentNote : NoteResource

func _ready() -> void:
	initializeNotes()

func initializeNotes()->void:
	clearNotes()
	##Get the notes the player has collected from the gamestate. Will be commented out for now until it is implemented
	#notes = gameState.notes
	for i in notes:
		var button = noteButton.instantiate()
		noteSelection.add_child(button)
		button.noteResource = i
		button.text = button.noteResource.noteName
		button.pressed.connect(displayNote.bind(button.noteResource))

func clearNotes()->void:
	for i in noteSelection.get_children():
		if i is Button:
			i.queue_free()

func displayNote(note:NoteResource)->void:
	currentNote = note
	noteReader.show()
	noteSelection.hide()
	noteText.text = note.note

func back()->void:
	currentNote = null
	noteReader.hide()
	noteSelection.show()
