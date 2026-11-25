class_name PlayArea
extends RefCounted
## The one physical play area that every virtual room shares (plan Section 6.1).
## Units are metres. The origin is the centre of the taped square on the floor,
## which is also the XROrigin3D's local origin after recentering.

const SIZE := Vector2(2.5, 2.5)
## Distance from the edge at which we count a "boundary hit" (plan Section 6.7).
const BOUNDARY_MARGIN := 0.2


static func half_extents() -> Vector2:
	return SIZE * 0.5


## True if a point in play-area space (XROrigin3D local space) is inside the safe square.
static func is_inside(local_pos: Vector3, margin: float = BOUNDARY_MARGIN) -> bool:
	var h := half_extents() - Vector2(margin, margin)
	return absf(local_pos.x) <= h.x and absf(local_pos.z) <= h.y


## Stride gain needed so a room of `room_size` fits in the play area (plan Section 6.6).
## A room twice as large as the play area gives a gain of 2 on that axis. Never below 1.
static func stride_gain_for(room_size: Vector2, cap: float = 2.0) -> Vector2:
	return Vector2(
		clampf(room_size.x / SIZE.x, 1.0, cap),
		clampf(room_size.y / SIZE.y, 1.0, cap)
	)
