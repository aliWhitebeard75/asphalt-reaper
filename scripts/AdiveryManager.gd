# AdiveryManager.gd  — Autoload
# ─────────────────────────────────────────────────────────────────────────────
# Wraps the Adivery plugin rewarded-ad system for use anywhere in the game.
#
# Why extends Node (not Adivery):
#   Extending a custom GDScript class in an autoload can silently fail on
#   Android if the class isn't fully registered before the autoload is
#   instantiated. By extending plain Node we avoid that entirely and create
#   the Adivery node ourselves — same result as the README's Method 1.
#
# USAGE (from any script):
#   if AdiveryManager.is_ad_ready():
#       AdiveryManager.show_rewarded_now()
#   AdiveryManager.ad_loaded.connect(...)              # ad finished loading
#   AdiveryManager.ad_reward_granted.connect(...)      # player watched fully
#   AdiveryManager.ad_closed_without_reward.connect(...)  # player skipped
# ─────────────────────────────────────────────────────────────────────────────

extends Node

# ── Inspector-editable IDs ────────────────────────────────────────────────────
@export_group("Adivery IDs (replace with yours from panel.adivery.com)")
@export var adivery_app_id: String   = "e6df7af2-738b-4406-95b4-c77c7dc10396"
@export var rewarded_zone_id: String = "e34188af-5d2a-495d-8886-8e9c258e83a1"

# ── Internal state ────────────────────────────────────────────────────────────
var _adivery: Adivery = null
var _rewarded_ad: RewardedAdvertisement = null
var _rewarded_ready: bool = false
var _plugin_ok: bool = false   # true if Engine.has_singleton("GodotAdivery")

# ── Game-facing signals ───────────────────────────────────────────────────────
signal ad_loaded                   # rewarded ad finished loading → enable button
signal ad_reward_granted           # player watched full ad → grant revival
signal ad_closed_without_reward    # player closed early → no reward

func _ready() -> void:
	# Adivery plugin only works on Android.
	if not OS.has_feature("android"):
		return

	# Create the rewarded ad resource FIRST and add it to the Adivery node
	# BEFORE add_child, so that Adivery._ready() finds the ad in the list
	# and fires request_rewarded_ad() automatically (because request == true).
	_rewarded_ad = RewardedAdvertisement.new()
	_rewarded_ad.placement_id = rewarded_zone_id
	_rewarded_ad.request = true   # tells Adivery._ready() to auto-request

	_adivery = Adivery.new()
	_adivery.app_id = adivery_app_id
	_adivery.add_advertisement(_rewarded_ad)   # register BEFORE add_child

	# Connect signals BEFORE add_child so we can't miss an early callback.
	_adivery.rewarded_ad_loaded.connect(_on_rewarded_loaded)
	_adivery.rewarded_ad_closed.connect(_on_rewarded_closed)

	# add_child triggers _enter_tree → _ready on _adivery:
	#   configure() sets up the JNI singleton, then request_rewarded_ad() fires
	#   automatically for every ad with request == true in advertisements[].
	add_child(_adivery)

	# Record whether the JNI singleton was actually available after configure().
	# If false → plugin AAR was not included in the build (see README checklist).
	_plugin_ok = Engine.has_singleton("GodotAdivery")

# ── Public API ────────────────────────────────────────────────────────────────

## Returns true if the native Android plugin loaded successfully.
## False means the AAR wasn't included — check: Use Custom Build, plugin enabled.
func is_plugin_initialized() -> bool:
	return _plugin_ok

func is_ad_ready() -> bool:
	return _rewarded_ready and _plugin_ok

func show_rewarded_now() -> void:
	if not is_ad_ready():
		return
	_rewarded_ready = false
	_adivery.show_rewarded_ad(_rewarded_ad)

# ── Adivery signal handlers ───────────────────────────────────────────────────

func _on_rewarded_loaded(_adv: Advertisement) -> void:
	_rewarded_ready = true
	ad_loaded.emit()   # tell GameOver the button can be enabled

func _on_rewarded_closed(_adv: Advertisement, is_rewarded: bool) -> void:
	if is_rewarded:
		ad_reward_granted.emit()
	else:
		ad_closed_without_reward.emit()
	# Pre-load the next ad immediately so it is ready for the next run.
	_rewarded_ready = false
	_adivery.request_rewarded_ad(_rewarded_ad)
