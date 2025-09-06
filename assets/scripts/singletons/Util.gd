extends Node


##Resizes an array, filling spaces with a given value
func resize_array_and_fill(array : Array, size : int, value : Variant) -> void:
	if array.size() > size:
		array.resize(size)
	while array.size() < size:
		array.append(value)


##Given an array of floats, picks a random index with the floats as the weight for the index
func pick_weighted(weight_array:Array[float]) -> int:
	#Sum all of the odds
	var sum : float = 0.0
	for i in weight_array:
		sum += i
	var random_selector = randf_range(0, sum)
	#Subtract each element until random_selector is 0
	var chosen_index : int = 0
	for idx in weight_array.size():
		random_selector -= weight_array[idx]
		if random_selector <= 0.0:
			chosen_index = idx
			break
	return chosen_index
