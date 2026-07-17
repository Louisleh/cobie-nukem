class_name MovingSetPiecePath
extends RefCounted

const EPSILON := 0.0001

var points: Array[Vector3] = []
var stop_distances: Array[float] = []
var total_length := 0.0
var _segment_lengths: Array[float] = []
var _segment_directions: Array[Vector3] = []


func configure(path_points: Array[Vector3], stop_fractions: Array[float]) -> void:
	clear()
	points = path_points.duplicate()
	if points.size() < 2:
		return
	for index in range(points.size() - 1):
		var segment := points[index + 1] - points[index]
		var segment_length := segment.length()
		_segment_lengths.append(segment_length)
		_segment_directions.append(segment / segment_length if segment_length > EPSILON else Vector3.ZERO)
		total_length += segment_length
	for marker in stop_fractions:
		stop_distances.append(marker * total_length)


func clear() -> void:
	points.clear()
	stop_distances.clear()
	_segment_lengths.clear()
	_segment_directions.clear()
	total_length = 0.0


func position_at(distance: float) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	if points.size() == 1 or total_length <= EPSILON:
		return points[0] if points.size() == 1 else points[-1]
	var remaining := clampf(distance, 0.0, total_length)
	for index in range(_segment_lengths.size()):
		var segment_length := _segment_lengths[index]
		if segment_length <= EPSILON:
			continue
		if remaining <= segment_length:
			return points[index] + _segment_directions[index] * remaining
		remaining -= segment_length
	return points[-1]


func next_stop(index: int) -> float:
	return stop_distances[index] if index >= 0 and index < stop_distances.size() else -1.0
