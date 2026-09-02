extends Control

# TerraBlocks v1.50 hotfix - Godot 4.7 target.
# Sleek gameplay HUD, fair shape bags, Test Mode, and Hammer / Rotate-Mirror / Reset tools.
# The same project remains mouse/touch friendly for Web, iOS, Android, and desktop.

const BOARD_SIZE: int = 9
const SAVE_PATH: String = "user://terrablocks_save.json"
const PROFILE_PATH: String = "user://terrablocks_profile.json"
const INPUT_ACTION_GUARD_MS: int = 130
const MAX_CLEAR_PARTICLES: int = 72
# Low-processor mode is the primary mobile/Web thermal optimization. The
# engine is fully idle when nothing is moving, runs celebration FX at ~30 FPS,
# and only returns to ~60 FPS while the player is actively dragging.
const LOW_POWER_DRAG_SLEEP_USEC: int = 16667
const LOW_POWER_FX_SLEEP_USEC: int = 33333
const LOW_POWER_BACKGROUND_SLEEP_USEC: int = 250000
const WEB_SYNC_SCRIPT: String = "(function(){try{if(window.__terrablocks_sync_timer){clearTimeout(window.__terrablocks_sync_timer);window.__terrablocks_sync_timer=null;}var fs=(typeof FS!==\"undefined\")?FS:((typeof Module!==\"undefined\"&&Module[\"FS\"])?Module[\"FS\"]:null);if(!fs||!fs.syncfs)return;window.__terrablocks_do_sync=window.__terrablocks_do_sync||function(){if(window.__terrablocks_syncing){window.__terrablocks_sync_pending=true;return;}window.__terrablocks_syncing=true;fs.syncfs(false,function(err){window.__terrablocks_syncing=false;if(err)console.warn(\"TerraBlocks IndexedDB sync failed\",err);if(window.__terrablocks_sync_pending){window.__terrablocks_sync_pending=false;window.__terrablocks_do_sync();}});};window.__terrablocks_do_sync();}catch(e){console.warn(\"TerraBlocks IndexedDB sync unavailable\",e);}})();"
const WEB_SYNC_SCHEDULE_SCRIPT: String = "(function(){try{var fs=(typeof FS!==\"undefined\")?FS:((typeof Module!==\"undefined\"&&Module[\"FS\"])?Module[\"FS\"]:null);if(!fs||!fs.syncfs)return;window.__terrablocks_do_sync=window.__terrablocks_do_sync||function(){if(window.__terrablocks_syncing){window.__terrablocks_sync_pending=true;return;}window.__terrablocks_syncing=true;fs.syncfs(false,function(err){window.__terrablocks_syncing=false;if(err)console.warn(\"TerraBlocks IndexedDB sync failed\",err);if(window.__terrablocks_sync_pending){window.__terrablocks_sync_pending=false;window.__terrablocks_do_sync();}});};if(window.__terrablocks_sync_timer)return;window.__terrablocks_sync_timer=setTimeout(function(){window.__terrablocks_sync_timer=null;window.__terrablocks_do_sync();},8000);}catch(e){console.warn(\"TerraBlocks IndexedDB sync scheduling unavailable\",e);}})();"
const NORMAL_BOARD_TOOL_INTERVAL: int = 1000
const TEST_BOARD_TOOL_INTERVAL: int = 100
const TOOL_TAP_DRAG_THRESHOLD: float = 10.0
const SCORE_HISTORY_LIMIT: int = 5000
const LEADERBOARD_VERSION: String = "1.50"
const ALL_CLEAR_REARM_OCCUPANCY: int = 36
const TEST_STARTING_TOOL_COUNT: int = 3

const CLEAR_FX_DURATION: float = 0.85
const MULTI_FX_DURATION: float = 1.00
const COMBO_FX_DURATION: float = 2.20
const COMBO_RESET_FX_DURATION: float = 0.90
const ALL_CLEAR_FX_DURATION: float = 2.60
const PIECE_DRAG_POINTER_GAP: float = 24.0
const TOOL_REWARD_FX_DURATION: float = 2.55
const TEST_TOOL_REWARD_FX_DURATION: float = 1.65
const TOOL_COUNTER_POP_DURATION: float = 0.72
const SCORE_GAIN_FX_DURATION: float = 1.75

const MUSIC_STREAM: AudioStream = preload("res://assets/audio/bg_music.wav")
const PLACE_STREAM: AudioStream = preload("res://assets/audio/place_block.wav")
const CLEAR_LINE_STREAM: AudioStream = preload("res://assets/audio/clear_line.wav")
const CLEAR_BOX_STREAM: AudioStream = preload("res://assets/audio/clear_box.wav")
const HAMMER_STREAM: AudioStream = preload("res://assets/audio/hammer.wav")
const TRANSFORM_STREAM: AudioStream = preload("res://assets/audio/rotate_mirror.wav")
const RESET_STREAM: AudioStream = preload("res://assets/audio/place_block.wav")
const GAME_OVER_STREAM: AudioStream = preload("res://assets/audio/game_over.wav")
const HAMMER_ICON_TEXTURE: Texture2D = preload("res://assets/icons/hammer.png")
const TRANSFORM_ICON_TEXTURE: Texture2D = preload("res://assets/icons/rotate-mirror.png")
const RESET_ICON_TEXTURE: Texture2D = preload("res://assets/icons/reset.png")
const SCORE_FONT: FontFile = preload("res://assets/fonts/CormorantGaramond-Variable.ttf")
const UI_FONT: FontFile = preload("res://assets/fonts/Manrope-Variable.ttf")
const BACKGROUND_TEXTURES: Array[Texture2D] = [
    preload("res://assets/backgrounds/background_1.jpg"),
    preload("res://assets/backgrounds/background_2.jpg"),
    preload("res://assets/backgrounds/background_3.jpg"),
    preload("res://assets/backgrounds/background_4.jpg"),
    preload("res://assets/backgrounds/background_5.png"),
]

enum ScreenMode {
    HOME,
    GAME,
    STATS,
    SETTINGS,
}

enum ToolType {
    HAMMER,
    TRANSFORM,
    RESET,
}

# One canonical member per family. Families are drawn from a shuffled bag and
# each family draws from its own shuffled set of unique rotations. This keeps
# the result random while preventing long droughts such as never seeing a
# horizontal 1x5 or the five-block cross.
const SHAPE_FAMILIES := [
    [Vector2i(0, 0)],
    [Vector2i(0, 0), Vector2i(1, 0)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
    [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)],
    [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
    [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
    [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
    [Vector2i(0, 0), Vector2i(1, 1)],
    [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)],
    [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],
    [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],
    [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],
    [Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
]

const SHAPE_PALETTES: Array[Color] = [
    Color("#4fc3f7"),
    Color("#f4b942"),
    Color("#62d49f"),
    Color("#b38cff"),
    Color("#ff7f73"),
    Color("#58d9d1"),
]

var board: Array = []
var pieces: Array = []

var screen_mode: int = ScreenMode.HOME
var has_active_run: bool = false
var show_new_game_warning: bool = false
var input_guard_until_msec: int = 0
var last_saved_state_json: String = ""
var last_saved_profile_json: String = ""

# Persistent all-time profile stats. Test Mode never contributes to these.
var lifetime_games_played: int = 0
var lifetime_total_score: int = 0
var lifetime_cells_placed: int = 0
var lifetime_total_clears: int = 0
var lifetime_rows_cleared: int = 0
var lifetime_columns_cleared: int = 0
var lifetime_boxes_cleared: int = 0
var lifetime_all_clears: int = 0
var lifetime_best_score: int = 0
var lifetime_highest_combo: int = 1
var lifetime_largest_multi_clear: int = 0
var lifetime_hammers_earned: int = 0
var lifetime_hammers_used: int = 0
var lifetime_transforms_earned: int = 0
var lifetime_transforms_used: int = 0
var lifetime_resets_earned: int = 0
var lifetime_resets_used: int = 0
var score_history: Array[Dictionary] = []
var player_id: String = ""
var world_rank: int = -1
var world_total_players: int = 0
var world_rank_status: String = "NOT CONNECTED"

var background_enabled: bool = true
var bgm_enabled: bool = true
var sfx_enabled: bool = true
var web_music_user_gesture_started: bool = false
var active_background_index: int = 0
var next_background_index: int = 0

var score: int = 0
var last_move_score: int = 0
var consecutive_clear_count: int = 0
var score_multiplier: int = 1
# True once this normal run has made its first successful placement and
# therefore counts toward lifetime Games Played. Test Mode never registers.
var run_counted_in_games: bool = false
var run_recorded_in_history: bool = false
var hammer_count: int = 0
var transform_count: int = 0
var reset_count: int = 0
var next_board_tool_score: int = NORMAL_BOARD_TOOL_INTERVAL
var pending_board_tool_pickups: int = 0
var board_tool_pickups: Dictionary = {}
var palette_index: int = 0
var game_over: bool = false
var all_clear_armed: bool = false
var test_mode_setting: bool = false
var run_test_mode: bool = false
var light_mode: bool = false
var shape_family_bag: Array[int] = []
var shape_orientation_bags: Dictionary = {}

var dragging_piece: int = -1
var dragging_hammer: bool = false
var dragging_transform: bool = false
var dragging_reset: bool = false
var mouse_pos: Vector2 = Vector2.ZERO
var pointer_is_touch: bool = false
var hammer_hover_piece: int = -1
var transform_hover_piece: int = -1
var selected_tap_tool: int = -1
var pending_tool_press: int = -1
var pending_tool_press_start: Vector2 = Vector2.ZERO

# One Rotate/Mirror tool is spent to arm one offered shape. Taps then cycle
# Rotate, Rotate, Rotate, Mirror forever until the shape is placed/destroyed.
var transform_piece_index: int = -1
var transform_step: int = 0 # 0/1/2 = next tap rotates; 3 = next tap mirrors.
var transform_gesture_active: bool = false
var transform_gesture_start: Vector2 = Vector2.ZERO
var last_message: String = ""

# Lightweight visual FX state. These never block input.
var clear_fx_time: float = 0.0
var clear_fx_cells: Array[Vector2i] = []
var clear_fx_ghosts: Array[Dictionary] = []
var clear_fx_units: int = 0
var multi_fx_time: float = 0.0
var multi_fx_units: int = 0
var combo_fx_time: float = 0.0
var combo_fx_multiplier: int = 1
var combo_fx_previous_multiplier: int = 1
var combo_fx_delta: int = 0
var combo_reset_fx_time: float = 0.0
var combo_reset_from_multiplier: int = 1
var all_clear_fx_time: float = 0.0
var all_clear_fx_color: Color = Color.WHITE
var tool_reward_queue: Array[Dictionary] = []
var active_tool_reward: Dictionary = {}
var tool_reward_fx_time: float = 0.0
var tool_reward_fx_duration: float = TOOL_REWARD_FX_DURATION
var tool_hidden_reward_counts: Array[int] = [0, 0, 0]
var tool_counter_pop_time: Array[float] = [0.0, 0.0, 0.0]
var score_gain_fx_time: float = 0.0
var score_gain_components: Array[Dictionary] = []
var test_diag_elapsed: float = 0.0
var test_diag_peak_process_ms: float = 0.0
var test_diag_snapshot: Dictionary = {}

var board_rect: Rect2 = Rect2()
var piece_rects: Array[Rect2] = []
var home_rect: Rect2 = Rect2()
var theme_toggle_rect: Rect2 = Rect2()
var home_new_game_rect: Rect2 = Rect2()
var home_continue_rect: Rect2 = Rect2()
var home_stats_rect: Rect2 = Rect2()
var home_test_mode_rect: Rect2 = Rect2()
var home_settings_rect: Rect2 = Rect2()
var home_background_toggle_rect: Rect2 = Rect2()
var home_bgm_toggle_rect: Rect2 = Rect2()
var home_sfx_toggle_rect: Rect2 = Rect2()
var stats_overview_tab_rect: Rect2 = Rect2()
var stats_scores_tab_rect: Rect2 = Rect2()
var stats_tab: int = 0
var warning_confirm_rect: Rect2 = Rect2()
var warning_cancel_rect: Rect2 = Rect2()
var tool_cancel_rect: Rect2 = Rect2()
var tools_panel_rect: Rect2 = Rect2()
var hammer_tool_rect: Rect2 = Rect2()
var transform_tool_rect: Rect2 = Rect2()
var reset_tool_rect: Rect2 = Rect2()
var hammer_icon_rect: Rect2 = Rect2()
var transform_icon_rect: Rect2 = Rect2()
var reset_icon_rect: Rect2 = Rect2()
var cell_size: float = 54.0

var font: Font

var bg: Color = Color("#070b10")
var panel: Color = Color("#10161d")
var panel_alt: Color = Color("#151d26")
var board_empty: Color = Color("#111820")
var board_empty_alt: Color = Color("#161f29")
var grid_line: Color = Color("#273440")
var grid_major: Color = Color("#5d7181")
var text_main: Color = Color("#f4f7f9")
var text_dim: Color = Color("#8794a2")
var danger: Color = Color("#ef665f")
var success: Color = Color("#6bd69b")

var music_player: AudioStreamPlayer
var place_player: AudioStreamPlayer
var clear_player: AudioStreamPlayer
var tool_player: AudioStreamPlayer
var game_over_player: AudioStreamPlayer
var leaderboard_request: HTTPRequest
var leaderboard_request_kind: String = ""
var pending_world_score: int = -1


func _ready() -> void:
    font = UI_FONT
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    # TerraBlocks is mostly static. Low-processor mode lets Godot skip rendering
    # entirely when nothing visual changes instead of spinning a WebGL frame loop.
    OS.low_processor_usage_mode = true
    OS.low_processor_usage_mode_sleep_usec = LOW_POWER_BACKGROUND_SLEEP_USEC
    Engine.max_fps = 60
    randomize()
    _setup_audio()
    _load_profile()
    _ensure_player_id()
    _setup_leaderboard()
    _load_save_file()
    _apply_audio_settings()
    # Native/desktop can start BGM immediately. Browsers (especially iOS
    # Safari) must start audio directly from a genuine user gesture, so Web
    # intentionally waits for _ensure_music_after_user_gesture().
    if not OS.has_feature("web"):
        _start_music()
    _apply_theme_palette()
    _refresh_world_rank()
    screen_mode = ScreenMode.HOME
    queue_redraw()
    # GUI input still arrives while _process is disabled. Start truly idle and
    # wake only for a real interaction or a timed visual effect.
    set_process(false)


func _setup_audio() -> void:
    # v1.49 BGM fix: use the scene-level player that proved reliable in testing.
    # The imported WAV is used directly; no runtime Resource duplication.
    music_player = get_node_or_null("BGMPlayer") as AudioStreamPlayer
    if music_player == null:
        music_player = AudioStreamPlayer.new()
        music_player.name = "BGMPlayer_Fallback"
        music_player.stream = MUSIC_STREAM
        add_child(music_player)
    music_player.stream = MUSIC_STREAM
    music_player.bus = &"Master"
    music_player.process_mode = Node.PROCESS_MODE_ALWAYS
    music_player.stream_paused = false

    # bg_music.wav already has looping enabled in its Godot import settings.
    # The finished callback and watchdog below provide additional recovery if
    # playback is ever interrupted unexpectedly.

    if not music_player.finished.is_connected(_on_music_finished):
        music_player.finished.connect(_on_music_finished)

    if OS.has_feature("web"):
        music_player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE

    # Safety net: if the audio backend unexpectedly drops/stops the BGM, restart
    # it. On Web, only do this after the first real user gesture has unlocked
    # browser audio.
    var bgm_watchdog: Timer = Timer.new()
    bgm_watchdog.name = "BGMWatchdog"
    bgm_watchdog.wait_time = 1.0
    bgm_watchdog.one_shot = false
    bgm_watchdog.autostart = true
    bgm_watchdog.process_mode = Node.PROCESS_MODE_ALWAYS
    bgm_watchdog.timeout.connect(_bgm_watchdog_tick)
    add_child(bgm_watchdog)

    place_player = AudioStreamPlayer.new()
    place_player.stream = PLACE_STREAM
    add_child(place_player)

    clear_player = AudioStreamPlayer.new()
    add_child(clear_player)

    tool_player = AudioStreamPlayer.new()
    tool_player.stream = HAMMER_STREAM
    add_child(tool_player)

    game_over_player = AudioStreamPlayer.new()
    game_over_player.stream = GAME_OVER_STREAM
    add_child(game_over_player)

    _apply_audio_settings()


func _apply_audio_settings() -> void:
    if music_player != null:
        music_player.volume_db = -8.0
        music_player.stream_paused = false
        if not bgm_enabled and music_player.playing:
            music_player.stop()
    if place_player != null:
        place_player.volume_db = (-5.0 if sfx_enabled else -80.0)
    if clear_player != null:
        clear_player.volume_db = (-6.0 if sfx_enabled else -80.0)
    if tool_player != null:
        tool_player.volume_db = (-4.0 if sfx_enabled else -80.0)
    if game_over_player != null:
        game_over_player.volume_db = (-3.0 if sfx_enabled else -80.0)


func _play_sfx(player: AudioStreamPlayer) -> void:
    if sfx_enabled and player != null:
        player.play()


func _on_music_finished() -> void:
    if not bgm_enabled or music_player == null:
        return
    if OS.has_feature("web") and not web_music_user_gesture_started:
        return
    music_player.stream_paused = false
    music_player.play(0.0)


func _bgm_watchdog_tick() -> void:
    if not bgm_enabled or music_player == null:
        return
    if OS.has_feature("web") and not web_music_user_gesture_started:
        return
    if not music_player.playing:
        music_player.stream_paused = false
        music_player.play(0.0)


func _start_music() -> void:
    if not bgm_enabled:
        return
    if music_player != null:
        music_player.stream_paused = false
        if not music_player.playing:
            music_player.play(0.0)


func _ensure_music_after_user_gesture() -> void:
    if not bgm_enabled or music_player == null:
        return
    if OS.has_feature("web"):
        # Do not attempt Web BGM during boot. The first play() happens directly
        # inside a real click/touch event so iOS Safari unlocks WebAudio. The WAV
        # then loops internally; no six-second restart loop is used.
        if not web_music_user_gesture_started:
            web_music_user_gesture_started = true
            music_player.stream_paused = false
            music_player.play(0.0)
            return
        # If Safari suspended/stopped playback after a tab/app transition, the
        # next genuine gesture is a safe place to resume it.
        if not music_player.playing:
            music_player.stream_paused = false
            music_player.play(0.0)
        return
    _start_music()


func _process(delta: float) -> void:
    var needs_redraw: bool = false

    var drag_active: bool = _drag_animation_active()
    var fx_active: bool = _celebration_animation_active()

    # Only real motion keeps the engine processing. Static combo state, static
    # UI, and delayed Web storage commits no longer need a frame loop.
    if drag_active:
        _set_low_power_sleep(LOW_POWER_DRAG_SLEEP_USEC)
    elif fx_active:
        _set_low_power_sleep(LOW_POWER_FX_SLEEP_USEC)
    else:
        _set_low_power_sleep(LOW_POWER_BACKGROUND_SLEEP_USEC)

    # Active drags remain responsive at up to 60 FPS. Touch positions are
    # already event-driven; mouse position is sampled here while dragging.
    if drag_active:
        if not pointer_is_touch:
            var live_mouse_pos: Vector2 = get_local_mouse_position()
            if not live_mouse_pos.is_equal_approx(mouse_pos):
                _handle_pointer_move(live_mouse_pos, false)
        needs_redraw = true

    # Celebration timers advance at the low-power FX cadence (~30 FPS).
    if clear_fx_time > 0.0:
        clear_fx_time = maxf(0.0, clear_fx_time - delta)
        needs_redraw = true
    if multi_fx_time > 0.0:
        multi_fx_time = maxf(0.0, multi_fx_time - delta)
        needs_redraw = true
    if combo_fx_time > 0.0:
        combo_fx_time = maxf(0.0, combo_fx_time - delta)
        needs_redraw = true
    if combo_reset_fx_time > 0.0:
        combo_reset_fx_time = maxf(0.0, combo_reset_fx_time - delta)
        needs_redraw = true
    if all_clear_fx_time > 0.0:
        all_clear_fx_time = maxf(0.0, all_clear_fx_time - delta)
        needs_redraw = true
    if score_gain_fx_time > 0.0:
        score_gain_fx_time = maxf(0.0, score_gain_fx_time - delta)
        needs_redraw = true

    if active_tool_reward.is_empty() and not tool_reward_queue.is_empty():
        var clear_sequence_done: bool = clear_fx_time <= 0.0 and multi_fx_time <= 0.10 and combo_fx_time <= 0.12 and all_clear_fx_time <= 0.18
        if clear_sequence_done:
            _start_next_tool_reward()
            needs_redraw = true

    if not active_tool_reward.is_empty():
        tool_reward_fx_time = maxf(0.0, tool_reward_fx_time - delta)
        needs_redraw = true
        if tool_reward_fx_time <= 0.0:
            _finish_active_tool_reward()

    for tool_index in range(tool_counter_pop_time.size()):
        if tool_counter_pop_time[tool_index] > 0.0:
            tool_counter_pop_time[tool_index] = maxf(0.0, tool_counter_pop_time[tool_index] - delta)
            needs_redraw = true

    if run_test_mode and screen_mode == ScreenMode.GAME:
        var process_ms: float = float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0
        test_diag_peak_process_ms = maxf(test_diag_peak_process_ms, process_ms)
        test_diag_elapsed += delta
        if test_diag_elapsed >= 1.0:
            test_diag_elapsed = fmod(test_diag_elapsed, 1.0)
            test_diag_snapshot = {
                "fps": int(round(float(Performance.get_monitor(Performance.TIME_FPS)))),
                "process_ms": process_ms,
                "peak_ms": test_diag_peak_process_ms,
                "draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
                "video_mem": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
                "texture_mem": int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
            }
            test_diag_peak_process_ms = 0.0
            needs_redraw = true

    if needs_redraw:
        queue_redraw()

    # Static Home/Stats/game screens stop processing completely.
    if not _timed_processing_needed():
        set_process(false)
        _set_low_power_sleep(LOW_POWER_BACKGROUND_SLEEP_USEC)


func _drag_animation_active() -> bool:
    return dragging_piece >= 0 or dragging_hammer or dragging_transform or dragging_reset or transform_gesture_active or pending_tool_press >= 0

func _celebration_animation_active() -> bool:
    if clear_fx_time > 0.0 or multi_fx_time > 0.0 or combo_fx_time > 0.0 or combo_reset_fx_time > 0.0:
        return true
    if all_clear_fx_time > 0.0 or score_gain_fx_time > 0.0 or not active_tool_reward.is_empty():
        return true
    for pop_time in tool_counter_pop_time:
        if float(pop_time) > 0.0:
            return true
    return not tool_reward_queue.is_empty()


func _timed_processing_needed() -> bool:
    return _drag_animation_active() or _celebration_animation_active() or (run_test_mode and screen_mode == ScreenMode.GAME)


func _wake_processing(interactive: bool = false) -> void:
    if interactive:
        # Avoid inheriting the 250 ms background sleep on the first touch/click.
        # The next process tick will choose the correct lower-power cadence.
        _set_low_power_sleep(LOW_POWER_DRAG_SLEEP_USEC)
    if not is_processing():
        set_process(true)


func _set_low_power_sleep(usec: int) -> void:
    var target: int = maxi(1000, usec)
    if OS.low_processor_usage_mode_sleep_usec != target:
        OS.low_processor_usage_mode_sleep_usec = target


func _reset_animation_state() -> void:
    clear_fx_time = 0.0
    clear_fx_cells.clear()
    clear_fx_ghosts.clear()
    clear_fx_units = 0
    multi_fx_time = 0.0
    multi_fx_units = 0
    combo_fx_time = 0.0
    combo_fx_multiplier = 1
    combo_fx_previous_multiplier = 1
    combo_fx_delta = 0
    combo_reset_fx_time = 0.0
    combo_reset_from_multiplier = 1
    all_clear_fx_time = 0.0
    all_clear_fx_color = Color.WHITE
    tool_reward_queue.clear()
    active_tool_reward.clear()
    tool_reward_fx_time = 0.0
    tool_reward_fx_duration = TOOL_REWARD_FX_DURATION
    tool_hidden_reward_counts = [0, 0, 0]
    tool_counter_pop_time = [0.0, 0.0, 0.0]
    score_gain_fx_time = 0.0
    score_gain_components.clear()


func _new_game() -> void:
    board.clear()
    for y in range(BOARD_SIZE):
        var row: Array = []
        for x in range(BOARD_SIZE):
            row.append(-1)
        board.append(row)

    pieces.clear()
    score = 0
    last_move_score = 0
    consecutive_clear_count = 0
    score_multiplier = 1
    run_counted_in_games = false
    run_recorded_in_history = false
    run_test_mode = test_mode_setting
    if not BACKGROUND_TEXTURES.is_empty():
        active_background_index = posmod(next_background_index, BACKGROUND_TEXTURES.size())
        next_background_index = posmod(active_background_index + 1, BACKGROUND_TEXTURES.size())
    var starting_tools: int = TEST_STARTING_TOOL_COUNT if run_test_mode else 0
    hammer_count = starting_tools
    transform_count = starting_tools
    reset_count = starting_tools
    next_board_tool_score = _board_tool_interval()
    pending_board_tool_pickups = 0
    board_tool_pickups.clear()
    var previous_palette_index: int = palette_index
    palette_index = randi_range(0, SHAPE_PALETTES.size() - 1)
    if SHAPE_PALETTES.size() > 1 and palette_index == previous_palette_index:
        palette_index = posmod(palette_index + randi_range(1, SHAPE_PALETTES.size() - 1), SHAPE_PALETTES.size())
    game_over = false
    all_clear_armed = false
    shape_family_bag.clear()
    shape_orientation_bags.clear()
    dragging_piece = -1
    dragging_hammer = false
    dragging_transform = false
    dragging_reset = false
    hammer_hover_piece = -1
    transform_hover_piece = -1
    selected_tap_tool = -1
    pending_tool_press = -1
    transform_piece_index = -1
    transform_step = 0
    transform_gesture_active = false
    last_message = "Place all 3 shapes for a new set."
    _reset_animation_state()
    show_new_game_warning = false
    _generate_pieces()
    has_active_run = true
    screen_mode = ScreenMode.GAME
    if run_test_mode:
        _wake_processing()
    _save_state()
    _arm_input_guard()
    queue_redraw()

func _generate_pieces() -> void:
    pieces.clear()
    for i in range(3):
        pieces.append(_create_piece())


func _create_piece() -> Dictionary:
    return {
        "cells": _random_shape(),
        "used": false,
        "destroyed": false,
    }

func _random_shape() -> Array:
    if shape_family_bag.is_empty():
        for family_index in range(SHAPE_FAMILIES.size()):
            shape_family_bag.append(family_index)
        shape_family_bag.shuffle()

    var family_index: int = shape_family_bag.pop_back()
    var family_cells: Array = SHAPE_FAMILIES[family_index] as Array
    var rotations: Array = _unique_rotations(family_cells)
    var orientation_bag: Array = shape_orientation_bags.get(family_index, []) as Array
    if orientation_bag.is_empty():
        for rotation_index in range(rotations.size()):
            orientation_bag.append(rotation_index)
        orientation_bag.shuffle()

    var selected_rotation: int = int(orientation_bag.pop_back())
    shape_orientation_bags[family_index] = orientation_bag
    return (rotations[selected_rotation] as Array).duplicate()


func _unique_rotations(cells: Array) -> Array:
    var unique: Array = []
    var signatures: Dictionary = {}
    var rotated: Array = _normalize_cells(cells)
    for step in range(4):
        var signature: String = _shape_signature(rotated)
        if not signatures.has(signature):
            signatures[signature] = true
            unique.append(rotated.duplicate())
        rotated = _rotate_cells(rotated, true)
    return unique


func _mirror_cells(cells: Array) -> Array:
    # Mirror across the local vertical axis. Combined with the three rotations
    # before/after it, this traverses the full dihedral orientation set.
    var mirrored: Array = []
    for cell_value in cells:
        var cell: Vector2i = cell_value
        mirrored.append(Vector2i(-cell.x, cell.y))
    return _normalize_cells(mirrored)


func _unique_transformations(cells: Array) -> Array:
    var unique: Array = []
    var signatures: Dictionary = {}
    var current: Array = _normalize_cells(cells)
    for handedness in range(2):
        var rotated: Array = current.duplicate()
        for step in range(4):
            var signature: String = _shape_signature(rotated)
            if not signatures.has(signature):
                signatures[signature] = true
                unique.append(rotated.duplicate())
            rotated = _rotate_cells(rotated, true)
        current = _mirror_cells(current)
    return unique

func _update_layout() -> void:
    var w: float = size.x
    var side_margin: float = maxf(14.0, floor(w * 0.028))
    cell_size = clamp(floor((w - side_margin * 2.0) / float(BOARD_SIZE)), 38.0, 56.0)
    var board_px: float = cell_size * float(BOARD_SIZE)

    home_rect = Rect2(Vector2(side_margin, 14.0), Vector2(38.0, 38.0))
    theme_toggle_rect = Rect2(Vector2(w - side_margin - 34.0, 16.0), Vector2(34.0, 34.0))
    board_rect = Rect2(Vector2((w - board_px) * 0.5, 164.0), Vector2(board_px, board_px))

    var pieces_y: float = board_rect.end.y + 22.0
    var card_gap: float = 7.0
    var total_w: float = w - side_margin * 2.0
    var card_w: float = (total_w - card_gap * 2.0) / 3.0
    var card_h: float = minf(card_w, 154.0)
    piece_rects.clear()
    for i in range(3):
        piece_rects.append(Rect2(Vector2(side_margin + float(i) * (card_w + card_gap), pieces_y), Vector2(card_w, card_h)))

    tools_panel_rect = Rect2(Vector2(side_margin, pieces_y + card_h + 9.0), Vector2(total_w, 96.0))
    var tool_gap: float = 7.0
    var tool_w: float = (tools_panel_rect.size.x - tool_gap * 2.0) / 3.0
    hammer_tool_rect = Rect2(tools_panel_rect.position, Vector2(tool_w, tools_panel_rect.size.y))
    transform_tool_rect = Rect2(Vector2(hammer_tool_rect.end.x + tool_gap, tools_panel_rect.position.y), Vector2(tool_w, tools_panel_rect.size.y))
    reset_tool_rect = Rect2(Vector2(transform_tool_rect.end.x + tool_gap, tools_panel_rect.position.y), Vector2(tool_w, tools_panel_rect.size.y))

    var icon_size: Vector2 = Vector2(54.0, 54.0)
    var icon_half: float = icon_size.x * 0.5
    var icon_top: float = 20.0
    hammer_icon_rect = Rect2(Vector2(hammer_tool_rect.get_center().x - icon_half, hammer_tool_rect.position.y + icon_top), icon_size)
    transform_icon_rect = Rect2(Vector2(transform_tool_rect.get_center().x - icon_half, transform_tool_rect.position.y + icon_top), icon_size)
    reset_icon_rect = Rect2(Vector2(reset_tool_rect.get_center().x - icon_half, reset_tool_rect.position.y + icon_top), icon_size)
    var menu_w: float = minf(360.0, w - 56.0)
    var menu_x: float = (w - menu_w) * 0.5
    home_new_game_rect = Rect2(Vector2(menu_x, 298.0), Vector2(menu_w, 60.0))
    home_continue_rect = Rect2(Vector2(menu_x, 370.0), Vector2(menu_w, 60.0))
    home_stats_rect = Rect2(Vector2(menu_x, 442.0), Vector2(menu_w, 60.0))
    home_test_mode_rect = Rect2(Vector2(menu_x, 514.0), Vector2(menu_w, 54.0))
    home_settings_rect = Rect2(Vector2(menu_x, 580.0), Vector2(menu_w, 54.0))
    # The same toggle hit rectangles are used only on the dedicated Settings page.
    home_background_toggle_rect = Rect2(Vector2(menu_x, 250.0), Vector2(menu_w, 52.0))
    home_bgm_toggle_rect = Rect2(Vector2(menu_x, 318.0), Vector2(menu_w, 52.0))
    home_sfx_toggle_rect = Rect2(Vector2(menu_x, 386.0), Vector2(menu_w, 52.0))
    var stats_tab_w: float = 116.0
    stats_overview_tab_rect = Rect2(Vector2(w * 0.5 - stats_tab_w - 4.0, 74.0), Vector2(stats_tab_w, 34.0))
    stats_scores_tab_rect = Rect2(Vector2(w * 0.5 + 4.0, 74.0), Vector2(stats_tab_w, 34.0))

    var warning_w: float = minf(430.0, w - 44.0)
    var warning_x: float = (w - warning_w) * 0.5
    var warning_button_gap: float = 14.0
    var warning_inner_margin: float = 28.0
    var warning_button_w: float = (warning_w - warning_inner_margin * 2.0 - warning_button_gap) * 0.5
    var warning_button_y: float = 550.0
    warning_confirm_rect = Rect2(Vector2(warning_x + warning_inner_margin, warning_button_y), Vector2(warning_button_w, 46.0))
    warning_cancel_rect = Rect2(Vector2(warning_confirm_rect.end.x + warning_button_gap, warning_button_y), Vector2(warning_button_w, 46.0))
    # Tool Mode controls live entirely in the existing 22 px gap between the
    # board and offered shapes. This avoids crowding the score/status area and
    # does not push the lower HUD off-screen on 540x960 phones.
    var tool_mode_y: float = board_rect.end.y + 2.0
    tool_cancel_rect = Rect2(Vector2(w - side_margin - 19.0, tool_mode_y), Vector2(18.0, 18.0))

func _draw() -> void:
    _update_layout()
    _apply_theme_palette()
    if screen_mode == ScreenMode.GAME and background_enabled and not BACKGROUND_TEXTURES.is_empty():
        _draw_game_background()
    else:
        draw_rect(Rect2(Vector2.ZERO, size), bg)
    if not light_mode:
        for glow_index in range(6, 0, -1):
            var glow_radius: float = float(glow_index) * 82.0
            var glow_alpha: float = 0.008 + float(6 - glow_index) * 0.002
            draw_circle(Vector2(size.x * 0.5, 150.0), glow_radius, Color(0.12, 0.24, 0.34, glow_alpha))
    if screen_mode == ScreenMode.HOME:
        _draw_home_screen()
    elif screen_mode == ScreenMode.STATS:
        _draw_stats_screen()
    elif screen_mode == ScreenMode.SETTINGS:
        _draw_settings_screen()
    else:
        _draw_game_screen()


func _draw_game_background() -> void:
    var index: int = posmod(active_background_index, BACKGROUND_TEXTURES.size())
    var texture: Texture2D = BACKGROUND_TEXTURES[index]
    if texture == null:
        draw_rect(Rect2(Vector2.ZERO, size), bg)
        return
    var texture_size: Vector2 = texture.get_size()
    if texture_size.x <= 0.0 or texture_size.y <= 0.0:
        draw_rect(Rect2(Vector2.ZERO, size), bg)
        return
    var scale_factor: float = maxf(size.x / texture_size.x, size.y / texture_size.y)
    var draw_size: Vector2 = texture_size * scale_factor
    var draw_pos: Vector2 = (size - draw_size) * 0.5
    draw_texture_rect(texture, Rect2(draw_pos, draw_size), false)
    # Keep the existing glass/board UI readable over bright scenery.
    var veil: Color = Color(0.015, 0.025, 0.035, 0.34) if not light_mode else Color(1.0, 1.0, 1.0, 0.24)
    draw_rect(Rect2(Vector2.ZERO, size), veil)


func _apply_theme_palette() -> void:
    if light_mode:
        bg = Color("#f4f2ee")
        panel = Color("#fffefb")
        panel_alt = Color("#edf0f2")
        board_empty = Color("#faf9f6")
        board_empty_alt = Color("#edf1f4")
        grid_line = Color("#cbd4dc")
        grid_major = Color("#a6b5c1")
        text_main = Color("#3b485a")
        text_dim = Color("#7b8795")
        danger = Color("#d9534f")
        success = Color("#2f9e72")
    else:
        bg = Color("#070b10")
        panel = Color("#10161d")
        panel_alt = Color("#151d26")
        board_empty = Color("#111820")
        board_empty_alt = Color("#161f29")
        grid_line = Color("#273440")
        grid_major = Color("#5d7181")
        text_main = Color("#f4f7f9")
        text_dim = Color("#8794a2")
        danger = Color("#ef665f")
        success = Color("#6bd69b")


func _draw_premium_panel(rect: Rect2, fill: Color, border: Color, radius: int = 10, border_width: int = 1, shadow_strength: float = 1.0) -> void:
    if shadow_strength > 0.0:
        var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
        shadow_style.bg_color = Color(0.0, 0.0, 0.0, (0.13 if light_mode else 0.34) * shadow_strength)
        shadow_style.corner_radius_top_left = radius
        shadow_style.corner_radius_top_right = radius
        shadow_style.corner_radius_bottom_left = radius
        shadow_style.corner_radius_bottom_right = radius
        draw_style_box(shadow_style, Rect2(rect.position + Vector2(0.0, 3.0), rect.size))

    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = fill
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.set_border_width_all(border_width)
    style.border_color = border
    draw_style_box(style, rect)
    draw_line(rect.position + Vector2(float(radius), 2.0), Vector2(rect.end.x - float(radius), rect.position.y + 2.0), Color(1.0, 1.0, 1.0, 0.42 if light_mode else 0.12), 1.0)


func _draw_concept_panel(rect: Rect2, border: Color, alpha: float = 1.0, radius: int = 9, shadow_strength: float = 1.0) -> void:
    # Native surfaces stay sharp at every browser scale and avoid the pale
    # fringes produced by stretching generated square panel bitmaps.
    var snapped: Rect2 = Rect2(rect.position.round(), rect.size.round())
    # Several restrained layers approximate the broad ambient shadow in the
    # concept without relying on a mobile-unfriendly blur shader.
    for shadow_layer in range(4, 0, -1):
        var spread: float = float(shadow_layer) * 1.15
        var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
        var layer_alpha: float = (0.015 if light_mode else 0.032) * shadow_strength * alpha * float(5 - shadow_layer)
        shadow_style.bg_color = Color(0.0, 0.0, 0.0, layer_alpha)
        shadow_style.corner_radius_top_left = radius + shadow_layer
        shadow_style.corner_radius_top_right = radius + shadow_layer
        shadow_style.corner_radius_bottom_left = radius + shadow_layer
        shadow_style.corner_radius_bottom_right = radius + shadow_layer
        draw_style_box(shadow_style, Rect2(snapped.position + Vector2(0.0, 2.0 + spread), snapped.size).grow(spread))

    var surface_style: StyleBoxFlat = StyleBoxFlat.new()
    surface_style.bg_color = Color(0.985, 0.98, 0.965, alpha) if light_mode else Color(0.060, 0.087, 0.115, alpha)
    surface_style.corner_radius_top_left = radius
    surface_style.corner_radius_top_right = radius
    surface_style.corner_radius_bottom_left = radius
    surface_style.corner_radius_bottom_right = radius
    surface_style.set_border_width_all(1)
    surface_style.border_color = Color(border.r, border.g, border.b, border.a * alpha)
    draw_style_box(surface_style, snapped)

    var inset: Rect2 = snapped.grow(-2.0)
    var inset_style: StyleBoxFlat = StyleBoxFlat.new()
    inset_style.bg_color = Color(0.965, 0.955, 0.93, alpha) if light_mode else Color(0.040, 0.062, 0.083, alpha)
    inset_style.corner_radius_top_left = maxi(1, radius - 2)
    inset_style.corner_radius_top_right = maxi(1, radius - 2)
    inset_style.corner_radius_bottom_left = maxi(1, radius - 2)
    inset_style.corner_radius_bottom_right = maxi(1, radius - 2)
    inset_style.set_border_width_all(1)
    inset_style.border_color = Color(0.17, 0.23, 0.28, 0.72 * alpha) if not light_mode else Color(1.0, 1.0, 1.0, 0.54 * alpha)
    draw_style_box(inset_style, inset)
    draw_line(snapped.position + Vector2(float(radius), 1.0), Vector2(snapped.end.x - float(radius), snapped.position.y + 1.0), Color(1.0, 1.0, 1.0, 0.18 * alpha), 1.0)
    draw_line(inset.position + Vector2(float(maxi(2, radius - 3)), 1.0), Vector2(inset.end.x - float(maxi(2, radius - 3)), inset.position.y + 1.0), Color(0.31, 0.44, 0.55, 0.10 * alpha) if not light_mode else Color(1.0, 1.0, 1.0, 0.34 * alpha), 1.0)


func _draw_panel_outline(rect: Rect2, color: Color, width: int = 1, radius: int = 11) -> void:
    var outline_style: StyleBoxFlat = StyleBoxFlat.new()
    outline_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
    outline_style.corner_radius_top_left = radius
    outline_style.corner_radius_top_right = radius
    outline_style.corner_radius_bottom_left = radius
    outline_style.corner_radius_bottom_right = radius
    outline_style.set_border_width_all(width)
    outline_style.border_color = color
    draw_style_box(outline_style, rect)


func _draw_header_button(rect: Rect2, is_home: bool) -> void:
    # v1.24 gameplay navigation is intentionally just a back arrow. Keeping the
    # hit target larger than the visible glyph makes it comfortable on phones.
    if not is_home:
        return
    var center: Vector2 = rect.get_center()
    var arrow_color: Color = Color(text_main.r, text_main.g, text_main.b, 0.86)
    var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.34)
    var points_shadow: PackedVector2Array = PackedVector2Array([
        center + Vector2(7.0, -10.0) + Vector2(1.0, 1.0),
        center + Vector2(-4.0, 0.0) + Vector2(1.0, 1.0),
        center + Vector2(7.0, 10.0) + Vector2(1.0, 1.0),
    ])
    var points: PackedVector2Array = PackedVector2Array([
        center + Vector2(7.0, -10.0),
        center + Vector2(-4.0, 0.0),
        center + Vector2(7.0, 10.0),
    ])
    draw_polyline(points_shadow, shadow_color, 3.2, true)
    draw_polyline(points, arrow_color, 2.3, true)
    draw_line(center + Vector2(-3.0, 0.0), center + Vector2(12.0, 0.0), arrow_color, 2.3, true)


func _draw_theme_toggle() -> void:
    if light_mode:
        _draw_premium_panel(theme_toggle_rect, panel, grid_line, 9, 1, 0.55)
    else:
        _draw_concept_panel(theme_toggle_rect, grid_line, 1.0, 9, 0.45)
    var center: Vector2 = theme_toggle_rect.get_center()
    if light_mode:
        draw_circle(center, 5.0, Color("#e39a31"))
        for ray_index in range(8):
            var angle: float = float(ray_index) / 8.0 * TAU
            var direction: Vector2 = Vector2(cos(angle), sin(angle))
            draw_line(center + direction * 8.0, center + direction * 11.0, Color("#d68b27"), 1.5, true)
    else:
        draw_circle(center, 8.0, Color("#9fc8e9"))
        draw_circle(center + Vector2(3.5, -2.5), 7.0, panel)


func _toggle_theme() -> void:
    light_mode = not light_mode
    _apply_theme_palette()
    _save_state()
    _arm_input_guard()
    queue_redraw()


func _draw_home_screen() -> void:
    var w: float = size.x

    _draw_theme_toggle()
    _text_tracked_center("TERRABLOCKS", Rect2(Vector2(20.0, 142.0), Vector2(w - 40.0, 56.0)), 27, text_main, 4.2)
    _text_tracked_center("PLACE · CLEAR · COMBO", Rect2(Vector2(20.0, 194.0), Vector2(w - 40.0, 24.0)), 11, text_dim, 1.5)

    var rank_text: String = "WORLD RANK  —"
    if world_rank > 0:
        rank_text = "WORLD RANK  #%s" % _format_score(world_rank)
    _text_tracked_center(rank_text, Rect2(Vector2(20.0, 232.0), Vector2(w - 40.0, 24.0)), 11, text_main, 1.2)
    var rank_subtitle: String = world_rank_status
    if world_rank > 0 and world_total_players > 0:
        rank_subtitle = "%s OF %s PLAYERS" % [_format_score(world_rank), _format_score(world_total_players)]
    _text_tracked_center(rank_subtitle, Rect2(Vector2(20.0, 254.0), Vector2(w - 40.0, 18.0)), 8, text_dim, 0.7)

    _draw_menu_button(home_new_game_rect, "NEW GAME", "", true)
    _draw_menu_button(home_continue_rect, "CONTINUE", "" if has_active_run else "NO RUN", has_active_run)
    _draw_menu_button(home_stats_rect, "STATS", "ALL-TIME RECORDS", true)
    _draw_menu_button(
        home_test_mode_rect,
        "TEST MODE  %s" % ("ON" if test_mode_setting else "OFF"),
        "10× TOOL RATES · PERFORMANCE HUD",
        true
    )

    _draw_menu_button(home_settings_rect, "SETTINGS", "BACKGROUND · AUDIO", true)

    if show_new_game_warning:
        _draw_new_game_warning()


func _draw_settings_screen() -> void:
    var w: float = size.x
    _draw_back_arrow()
    _text_tracked_center("SETTINGS", Rect2(Vector2(70.0, 70.0), Vector2(w - 140.0, 42.0)), 20, text_main, 3.0)
    _text_tracked_center("GAME DISPLAY & AUDIO", Rect2(Vector2(40.0, 116.0), Vector2(w - 80.0, 24.0)), 9, text_dim, 1.2)

    _draw_setting_toggle(home_background_toggle_rect, "BACKGROUND", background_enabled)
    _draw_setting_toggle(home_bgm_toggle_rect, "BGM", bgm_enabled)
    _draw_setting_toggle(home_sfx_toggle_rect, "SOUND FX", sfx_enabled)

    var note_rect := Rect2(Vector2(48.0, 470.0), Vector2(w - 96.0, 76.0))
    _text_center("Settings are saved automatically.", Rect2(note_rect.position, Vector2(note_rect.size.x, 24.0)), 9, text_dim)
    _text_center("Background changes on each New Game.", Rect2(note_rect.position + Vector2(0.0, 26.0), Vector2(note_rect.size.x, 24.0)), 9, text_dim)


func _draw_setting_toggle(rect: Rect2, label: String, enabled: bool) -> void:
    _draw_concept_panel(rect, grid_line, 0.86, 9, 0.30)
    _text(label, rect.position + Vector2(13.0, 24.0), 10, text_main)
    var toggle_rect: Rect2 = Rect2(Vector2(rect.end.x - 57.0, rect.position.y + 8.0), Vector2(44.0, 22.0))
    var toggle_fill: Color = Color(0.20, 0.68, 0.95, 0.92) if enabled else Color(0.20, 0.24, 0.28, 0.92)
    draw_rect(toggle_rect, toggle_fill, true)
    draw_arc(toggle_rect.get_center(), 11.0, PI * 0.5, PI * 1.5, 18, toggle_fill, 22.0, true)
    draw_arc(toggle_rect.get_center(), 11.0, -PI * 0.5, PI * 0.5, 18, toggle_fill, 22.0, true)
    var knob_x: float = toggle_rect.end.x - 11.0 if enabled else toggle_rect.position.x + 11.0
    draw_circle(Vector2(knob_x, toggle_rect.get_center().y), 8.0, Color(0.97, 0.98, 1.0, 1.0))


func _draw_stats_screen() -> void:
    var w: float = size.x
    _draw_back_arrow()
    _draw_theme_toggle()
    _text_tracked_center("STATS", Rect2(Vector2(70.0, 28.0), Vector2(w - 140.0, 42.0)), 20, text_main, 3.0)
    _draw_stats_tabs()
    if stats_tab == 0:
        _draw_stats_overview()
    else:
        _draw_stats_history()
    if OS.has_feature("web") and not OS.is_userfs_persistent():
        _text_center("Browser storage may not persist in this session.", Rect2(Vector2(26.0, size.y - 36.0), Vector2(w - 52.0, 20.0)), 9, danger)

func _draw_stats_tabs() -> void:
    var tabs: Array = [[stats_overview_tab_rect, "OVERVIEW", 0], [stats_scores_tab_rect, "SCORES", 1]]
    for item in tabs:
        var rect: Rect2 = item[0]
        var active: bool = stats_tab == int(item[2])
        var border: Color = _current_shape_color() if active else grid_line
        _draw_concept_panel(rect, Color(border.r, border.g, border.b, 0.70 if active else 0.42), 1.0, 10, 0.25)
        _text_center(String(item[1]), rect, 9, text_main if active else text_dim)

func _draw_stats_overview() -> void:
    var w: float = size.x
    var hero_rect: Rect2 = Rect2(Vector2(34.0, 122.0), Vector2(w - 68.0, 92.0))
    _draw_concept_panel(hero_rect, grid_major, 1.0, 14, 0.8)
    _text_tracked_center("BEST SCORE", Rect2(hero_rect.position + Vector2(0.0, 12.0), Vector2(hero_rect.size.x, 20.0)), 10, text_dim, 1.8)
    _text_center(_format_score(lifetime_best_score), Rect2(hero_rect.position + Vector2(0.0, 34.0), Vector2(hero_rect.size.x, 48.0)), 34, text_main)

    var left: float = 34.0
    var content_w: float = w - 68.0
    var y: float = 236.0
    _draw_stats_section_title("LIFETIME", y)
    y += 27.0
    _draw_stats_row("Games Played", str(lifetime_games_played), left, y, content_w)
    y += 27.0
    _draw_stats_row("Total Score", _format_score(lifetime_total_score), left, y, content_w)
    y += 27.0
    var average_score: int = 0
    if lifetime_games_played > 0:
        average_score = int(round(float(lifetime_total_score) / float(lifetime_games_played)))
    _draw_stats_row("Average Score", _format_score(average_score), left, y, content_w)
    y += 27.0
    _draw_stats_row("Cells Placed", _format_score(lifetime_cells_placed), left, y, content_w)

    y += 40.0
    _draw_stats_section_title("CLEARING", y)
    y += 27.0
    _draw_stats_row("Total Clears", _format_score(lifetime_total_clears), left, y, content_w)
    y += 29.0
    _draw_stats_triplet("ROWS", lifetime_rows_cleared, "COLUMNS", lifetime_columns_cleared, "3×3", lifetime_boxes_cleared, y)
    y += 44.0
    _draw_stats_row("All Clears", str(lifetime_all_clears), left, y, content_w)

    y += 40.0
    _draw_stats_section_title("RECORDS", y)
    y += 27.0
    _draw_stats_row("Highest Combo", "x%d" % lifetime_highest_combo, left, y, content_w)
    y += 27.0
    var multi_text: String = "—" if lifetime_largest_multi_clear < 2 else str(lifetime_largest_multi_clear)
    _draw_stats_row("Largest Multi-Clear", multi_text, left, y, content_w)

    y += 40.0
    _draw_stats_section_title("TOOLS", y)
    y += 28.0
    _draw_tool_stat_row("HAMMER", lifetime_hammers_earned, lifetime_hammers_used, y)
    y += 40.0
    _draw_tool_stat_row("ROTATE / MIRROR", lifetime_transforms_earned, lifetime_transforms_used, y)
    y += 40.0
    _draw_tool_stat_row("RESET", lifetime_resets_earned, lifetime_resets_used, y)

func _sort_history_desc(a: Dictionary, b: Dictionary) -> bool:
    return int(a.get("score", 0)) > int(b.get("score", 0))

func _format_history_date(iso_date: String) -> String:
    var parts: PackedStringArray = iso_date.split("-")
    if parts.size() != 3:
        return iso_date
    var month_names: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    var month: int = clampi(int(parts[1]), 1, 12)
    return "%s %d, %d" % [month_names[month - 1], int(parts[2]), int(parts[0])]

func _draw_stats_history() -> void:
    var w: float = size.x
    var rank_rect := Rect2(Vector2(34.0, 122.0), Vector2(w - 68.0, 64.0))
    _draw_concept_panel(rank_rect, grid_major, 1.0, 12, 0.5)
    var rank_text: String = "—" if world_rank <= 0 else "#%s" % _format_score(world_rank)
    _text_tracked("WORLD RANK", rank_rect.position + Vector2(14.0, 23.0), 9, text_dim, 1.2)
    _text(rank_text, rank_rect.position + Vector2(14.0, 49.0), 20, text_main)
    var rank_status: String = world_rank_status
    if world_rank > 0 and world_total_players > 0:
        rank_status = "OF %s PLAYERS" % _format_score(world_total_players)
    var status_size: Vector2 = font.get_string_size(rank_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
    _text(rank_status, Vector2(rank_rect.end.x - 14.0 - status_size.x, rank_rect.position.y + 39.0), 8, text_dim)

    _draw_stats_section_title("TOP 10 SCORES", 204.0)
    var sorted: Array = score_history.duplicate(true)
    sorted.sort_custom(_sort_history_desc)
    var y: float = 236.0
    if sorted.is_empty():
        _text_center("Complete a normal run to build score history.", Rect2(Vector2(34.0, y), Vector2(w - 68.0, 54.0)), 10, text_dim)
    else:
        for i in range(mini(10, sorted.size())):
            var item: Dictionary = sorted[i] as Dictionary
            var row_rect := Rect2(Vector2(34.0, y), Vector2(w - 68.0, 28.0))
            if i < 3:
                draw_rect(row_rect, Color(1.0, 1.0, 1.0, 0.022 if not light_mode else 0.18))
            _text("%d" % (i + 1), row_rect.position + Vector2(4.0, 19.0), 9, text_dim)
            _text(_format_score(int(item.get("score", 0))), row_rect.position + Vector2(35.0, 20.0), 13, text_main)
            var date_text: String = _format_history_date(String(item.get("date", "")))
            var date_size: Vector2 = font.get_string_size(date_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
            _text(date_text, Vector2(row_rect.end.x - date_size.x - 4.0, row_rect.position.y + 19.0), 9, text_dim)
            y += 29.0

    _draw_stats_section_title("SCORE DISTRIBUTION", 550.0)
    _draw_score_histogram(Rect2(Vector2(34.0, 586.0), Vector2(w - 68.0, 190.0)))

func _draw_score_histogram(rect: Rect2) -> void:
    _draw_concept_panel(rect, grid_line, 0.78, 10, 0.25)
    if score_history.is_empty():
        _text_center("NO COMPLETED SCORES YET", rect, 9, text_dim)
        return
    var max_score: int = 1
    for item in score_history:
        max_score = maxi(max_score, int(item.get("score", 0)))
    var bin_count: int = 8
    var bin_width: int = maxi(1, int(ceil(float(max_score) / float(bin_count))))
    var bins: Array[int] = []
    bins.resize(bin_count)
    for i in range(bin_count):
        bins[i] = 0
    var max_bin: int = 1
    for item in score_history:
        var value: int = maxi(0, int(item.get("score", 0)))
        var index: int = mini(bin_count - 1, int(value / bin_width))
        bins[index] += 1
        max_bin = maxi(max_bin, bins[index])
    var inner := Rect2(rect.position + Vector2(18.0, 22.0), rect.size - Vector2(36.0, 52.0))
    var gap: float = 5.0
    var bar_w: float = (inner.size.x - gap * float(bin_count - 1)) / float(bin_count)
    for i in range(bin_count):
        var ratio: float = float(bins[i]) / float(max_bin)
        var bar_h: float = inner.size.y * ratio
        var bar_rect := Rect2(Vector2(inner.position.x + float(i) * (bar_w + gap), inner.end.y - bar_h), Vector2(bar_w, bar_h))
        var accent: Color = _current_shape_color()
        draw_rect(bar_rect, Color(accent.r, accent.g, accent.b, 0.70))
        if bins[i] > 0:
            _text_center(str(bins[i]), Rect2(Vector2(bar_rect.position.x - 2.0, bar_rect.position.y - 18.0), Vector2(bar_rect.size.x + 4.0, 16.0)), 8, text_dim)
    _text("0", Vector2(inner.position.x, rect.end.y - 12.0), 8, text_dim)
    var max_text: String = _format_score(max_score)
    var max_size: Vector2 = font.get_string_size(max_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
    _text(max_text, Vector2(inner.end.x - max_size.x, rect.end.y - 12.0), 8, text_dim)


func _draw_back_arrow() -> void:
    var center: Vector2 = home_rect.get_center()
    draw_line(center + Vector2(7.0, -9.0), center + Vector2(-3.0, 0.0), text_main, 2.2, true)
    draw_line(center + Vector2(-3.0, 0.0), center + Vector2(7.0, 9.0), text_main, 2.2, true)


func _draw_stats_section_title(title: String, y: float) -> void:
    _text_tracked(title, Vector2(34.0, y + 13.0), 10, text_dim, 1.8)
    draw_line(Vector2(132.0, y + 9.0), Vector2(size.x - 34.0, y + 9.0), Color(grid_line.r, grid_line.g, grid_line.b, 0.58), 1.0)


func _draw_stats_row(label: String, value: String, x: float, y: float, width: float) -> void:
    _text(label, Vector2(x, y + 16.0), 12, text_dim)
    var value_size: Vector2 = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
    _text(value, Vector2(x + width - value_size.x, y + 16.0), 14, text_main)


func _draw_stats_triplet(label_a: String, value_a: int, label_b: String, value_b: int, label_c: String, value_c: int, y: float) -> void:
    var margin: float = 34.0
    var gap: float = 8.0
    var width: float = (size.x - margin * 2.0 - gap * 2.0) / 3.0
    var labels: Array[String] = [label_a, label_b, label_c]
    var values: Array[int] = [value_a, value_b, value_c]
    for i in range(3):
        var rect: Rect2 = Rect2(Vector2(margin + float(i) * (width + gap), y), Vector2(width, 42.0))
        _draw_concept_panel(rect, grid_line, 0.62, 8, 0.35)
        _text_center(labels[i], Rect2(rect.position + Vector2(0.0, 4.0), Vector2(rect.size.x, 14.0)), 8, text_dim)
        _text_center(str(values[i]), Rect2(rect.position + Vector2(0.0, 17.0), Vector2(rect.size.x, 21.0)), 14, text_main)


func _draw_tool_stat_row(label: String, earned: int, used: int, y: float) -> void:
    var rect: Rect2 = Rect2(Vector2(34.0, y), Vector2(size.x - 68.0, 37.0))
    _draw_concept_panel(rect, grid_line, 0.58, 8, 0.30)
    _text(label, rect.position + Vector2(12.0, 23.0), 11, text_main)
    _text("EARNED  %d" % earned, rect.position + Vector2(rect.size.x * 0.46, 22.0), 9, text_dim)
    var used_text: String = "USED  %d" % used
    var used_size: Vector2 = font.get_string_size(used_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
    _text(used_text, Vector2(rect.end.x - 12.0 - used_size.x, rect.position.y + 22.0), 9, text_dim)

func _draw_menu_button(rect: Rect2, title: String, subtitle: String, enabled: bool) -> void:
    var border: Color = grid_major if enabled else grid_line
    var title_color: Color = text_main if enabled else Color(text_dim.r, text_dim.g, text_dim.b, 0.55)
    if light_mode:
        _draw_premium_panel(rect, panel, border, 12, 1 if not enabled else 2, 0.8)
    else:
        _draw_concept_panel(rect, Color(border.r, border.g, border.b, 0.72), 1.0 if enabled else 0.62, 12, 0.8)
        if enabled:
            _draw_panel_outline(rect, Color(border.r, border.g, border.b, 0.72), 2, 12)
    _text_center(title, Rect2(rect.position + Vector2(0.0, 10.0), Vector2(rect.size.x, 30.0)), 18, title_color)
    if subtitle != "":
        _text_center(subtitle, Rect2(rect.position + Vector2(0.0, 36.0), Vector2(rect.size.x, 18.0)), 9, text_dim)

func _draw_new_game_warning() -> void:
    var w: float = size.x
    var warning_w: float = minf(430.0, w - 44.0)
    var warning_rect: Rect2 = Rect2(Vector2((w - warning_w) * 0.5, 410.0), Vector2(warning_w, 210.0))

    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.72))
    _draw_premium_panel(warning_rect, panel_alt, danger, 15, 2, 1.0)
    _text_center("START A NEW GAME?", Rect2(warning_rect.position + Vector2(12.0, 24.0), Vector2(warning_rect.size.x - 24.0, 30.0)), 20, text_main)
    _text_center("Your current board and score will be lost.", Rect2(warning_rect.position + Vector2(12.0, 72.0), Vector2(warning_rect.size.x - 24.0, 24.0)), 12, text_dim)

    var destructive_fill: Color = Color("#fff1ef") if light_mode else Color("#342020")
    _draw_premium_panel(warning_confirm_rect, destructive_fill, danger, 9, 2, 0.55)
    _text_center("NEW GAME", warning_confirm_rect, 13, text_main)

    _draw_premium_panel(warning_cancel_rect, panel, grid_major, 9, 1, 0.55)
    _text_center("CANCEL", warning_cancel_rect, 13, text_main)


func _sanitize_interaction_indices() -> void:
    var piece_count: int = pieces.size()
    if dragging_piece < -1 or dragging_piece >= piece_count:
        dragging_piece = -1
    if transform_piece_index < -1 or transform_piece_index >= piece_count:
        transform_piece_index = -1
        transform_step = 0
        transform_gesture_active = false
    if hammer_hover_piece < -1 or hammer_hover_piece >= piece_count:
        hammer_hover_piece = -1
    if transform_hover_piece < -1 or transform_hover_piece >= piece_count:
        transform_hover_piece = -1

func _draw_game_screen() -> void:
    _sanitize_interaction_indices()
    _draw_game_header()
    _draw_score_hud()
    _draw_board()
    _draw_tool_mode_board_overlay()
    _draw_piece_cards()
    _draw_tools_panel()
    _draw_tool_mode_banner()

    if dragging_piece >= 0:
        _draw_dragging_piece()
    if dragging_hammer:
        _draw_hammer_drag_preview()
    if dragging_transform:
        _draw_transform_drag_preview()
    if dragging_reset:
        _draw_reset_drag_preview()

    _draw_animation_overlays()

    if game_over:
        _draw_game_over()

func _draw_game_header() -> void:
    # Branding belongs on Home; gameplay stays visually quiet and board-first.
    _draw_header_button(home_rect, true)
    _draw_theme_toggle()
    if run_test_mode:
        _draw_test_diagnostics()

func _bytes_to_mb(value: int) -> float:
    return float(maxi(0, value)) / (1024.0 * 1024.0)

func _draw_test_diagnostics() -> void:
    var rect := Rect2(Vector2(62.0, 11.0), Vector2(size.x - 124.0, 48.0))
    draw_rect(rect, Color(0.07, 0.04, 0.10, 0.88))
    draw_rect(rect, Color(0.72, 0.51, 0.93, 0.72), false, 1.0)
    var fps: int = int(test_diag_snapshot.get("fps", 0))
    var process_ms: float = float(test_diag_snapshot.get("process_ms", 0.0))
    var peak_ms: float = float(test_diag_snapshot.get("peak_ms", 0.0))
    var draw_calls: int = int(test_diag_snapshot.get("draw_calls", 0))
    var video_mb: float = _bytes_to_mb(int(test_diag_snapshot.get("video_mem", 0)))
    var texture_mb: float = _bytes_to_mb(int(test_diag_snapshot.get("texture_mem", 0)))
    _text("TEST · FPS %d · PROC %.2fms · PEAK %.2fms" % [fps, process_ms, peak_ms], rect.position + Vector2(8.0, 18.0), 8, Color("#eadcff"))
    _text("DRAW %d · VIDEO %.1fMB · TEX %.1fMB" % [draw_calls, video_mb, texture_mb], rect.position + Vector2(8.0, 36.0), 8, Color("#b9a6ce"))


func _draw_score_hud() -> void:
    var w: float = size.x
    var shape_color: Color = _current_shape_color()

    _text_tracked("SCORE", Vector2(16.0, 77.0), 10, text_dim, 1.8)
    var formatted_score: String = _format_score(score)
    var score_font_size: int = 43
    if formatted_score.length() > 9:
        score_font_size = 28
    elif formatted_score.length() > 7:
        score_font_size = 34
    var score_origin: Vector2 = Vector2(15.0, 111.0)
    _text_with_font(formatted_score, score_origin, score_font_size, text_main, SCORE_FONT)

    # Keep the previous move's score visible until the next placement. A fresh
    # move gets a gentle elderly-friendly pulse rather than disappearing.
    if last_move_score > 0:
        var gain_text: String = "+%d" % last_move_score
        var gain_font_size: int = 15
        if last_move_score >= 10000:
            gain_font_size = 13
        var score_size: Vector2 = SCORE_FONT.get_string_size(formatted_score, HORIZONTAL_ALIGNMENT_LEFT, -1, score_font_size)
        var gain_size: Vector2 = font.get_string_size(gain_text, HORIZONTAL_ALIGNMENT_LEFT, -1, gain_font_size)
        var gain_x: float = score_origin.x + score_size.x + 11.0
        var gain_y: float = 104.0
        var max_gain_x: float = w - 144.0 - gain_size.x
        gain_x = minf(gain_x, max_gain_x)
        var gain_color: Color = Color(shape_color.r, shape_color.g, shape_color.b, 0.90)
        if score_gain_fx_time > 0.0:
            var gain_t: float = clampf(1.0 - score_gain_fx_time / SCORE_GAIN_FX_DURATION, 0.0, 1.0)
            var pulse: float = sin(gain_t * PI)
            gain_y -= pulse * 3.0
            gain_color = gain_color.lerp(Color.WHITE, pulse * 0.34)
        _text(gain_text, Vector2(gain_x, gain_y), gain_font_size, gain_color)

    var best_text: String = "BEST  %s" % _format_score(lifetime_best_score)
    _text_tracked(best_text, Vector2(16.0, 133.0), 9, text_dim, 0.8)

    _draw_combo_ladder(w, shape_color)

    # Tool Mode owns this strip while a tap-selected tool is active. Keeping
    # normal status text out of it prevents instructions from colliding with
    # either the board frame or the mode controls.
    if selected_tap_tool < 0:
        _text_center(last_message, Rect2(Vector2(118.0, 132.0), Vector2(w - 236.0, 22.0)), 10, text_dim)


func _draw_combo_ladder(w: float, _shape_color: Color) -> void:
    var multiplier: int = score_multiplier
    var display_multiplier: int = multiplier
    var alpha: float = 1.0
    var scale: float = 1.0

    if multiplier <= 1 and combo_reset_fx_time > 0.0:
        var reset_t: float = clampf(1.0 - combo_reset_fx_time / COMBO_RESET_FX_DURATION, 0.0, 1.0)
        display_multiplier = combo_reset_from_multiplier
        alpha = 1.0 - reset_t
        scale = 1.0 - reset_t * 0.10

    if combo_fx_time > 0.0 and combo_fx_multiplier > 1:
        var combo_t: float = clampf(1.0 - combo_fx_time / COMBO_FX_DURATION, 0.0, 1.0)
        var settle_t: float = clampf(combo_t / 0.62, 0.0, 1.0)
        display_multiplier = combo_fx_multiplier
        scale *= 1.0 + sin(settle_t * PI) * 0.08

    var animate_aura: bool = combo_fx_time > 0.0 or combo_reset_fx_time > 0.0
    if display_multiplier >= 2 and animate_aura:
        var time_s: float = float(Time.get_ticks_msec()) * 0.001
        var idle_pulse: float = 0.5 + 0.5 * sin(time_s * (4.0 if display_multiplier < 5 else 4.8))
        scale *= 1.0 + lerpf(0.012, 0.040 if display_multiplier >= 5 else 0.028, idle_pulse)

    var center: Vector2 = _combo_frame_rect().get_center()
    _draw_combo_text_indicator(center, display_multiplier, alpha, scale, animate_aura)


func _draw_combo_text_indicator(center: Vector2, multiplier: int, alpha: float = 1.0, scale: float = 1.0, animate_aura: bool = false) -> void:
    if alpha <= 0.0:
        return

    var combo_color: Color = _combo_color(multiplier)
    var strength: float = _combo_glow_strength(multiplier)
    var time_s: float = float(Time.get_ticks_msec()) * 0.001 if animate_aura else float(multiplier) * 0.731

    # Text-only HUD keeps the same visual language, but after the celebration
    # settles the aura becomes static instead of forcing permanent redraws.
    var aura_pulse: float = 0.5 + 0.5 * sin(time_s * (3.2 + float(mini(multiplier, 6)) * 0.16))
    var aura_radius_x: float = (29.0 + 5.0 * strength + 4.0 * aura_pulse) * scale
    var aura_radius_y: float = (24.0 + 4.0 * strength + 3.0 * aura_pulse) * scale

    if multiplier >= 2:
        for aura_layer in range(2, 0, -1):
            var layer_t: float = float(aura_layer) / 2.0
            var aura_center: Vector2 = center + Vector2(0.0, -2.0)
            var radius: float = maxf(aura_radius_x, aura_radius_y) * (0.78 + layer_t * 0.24)
            draw_circle(aura_center, radius, Color(combo_color.r, combo_color.g, combo_color.b, alpha * (0.018 + 0.018 * strength) * (1.0 - layer_t * 0.35)))

        var ember_count: int = 2 if multiplier < 4 else (3 if multiplier < 6 else 4)
        for ember_index in range(ember_count):
            var phase: float = fmod(time_s * (0.32 + float(ember_index) * 0.019) + float(ember_index) * 0.137, 1.0)
            var angle: float = float(ember_index) / float(ember_count) * TAU + sin(time_s * 0.8 + float(ember_index)) * 0.22
            var distance: float = (29.0 + phase * (11.0 + strength * 9.0)) * scale
            var ember_pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * distance + Vector2(0.0, -5.0 * phase)
            var ember_alpha: float = alpha * (1.0 - phase) * (0.10 + 0.17 * strength)
            draw_circle(ember_pos, (1.0 + strength * 1.1) * scale, Color(1.0, 0.88, 0.62, ember_alpha))

    var number_size: int = maxi(18, int(round(float(_combo_number_size(multiplier)) * scale)))
    var label_size: int = 7 if multiplier < 4 else 6
    var number_rect: Rect2 = Rect2(center + Vector2(-46.0, -26.0 * scale), Vector2(92.0, 40.0 * scale))
    var label_rect: Rect2 = Rect2(center + Vector2(-50.0, 10.0 * scale), Vector2(100.0, 18.0 * scale))

    # Small offset passes create a readable neon glow without a heavy badge.
    if multiplier >= 2:
        var glow_alpha: float = alpha * (0.15 + 0.12 * strength)
        for offset in [Vector2(-1.25, 0.0), Vector2(1.25, 0.0)]:
            _text_center_alpha("x%d" % multiplier, Rect2(number_rect.position + offset, number_rect.size), number_size, combo_color, glow_alpha)

    _text_center_alpha("x%d" % multiplier, number_rect, number_size, combo_color, alpha)
    # Keep the label geometrically centered under the multiplier. Tracking made
    # the short word COMBO look optically shifted on narrow mobile screens.
    _text_center_alpha(_combo_stage_label(multiplier), label_rect, label_size, Color(combo_color.r, combo_color.g, combo_color.b, 0.88 * alpha), alpha)


func _combo_number_size(multiplier: int) -> int:
    if multiplier <= 1:
        return 23
    if multiplier == 2:
        return 26
    if multiplier == 3:
        return 28
    if multiplier == 4:
        return 30
    return 31


func _combo_stage_label(multiplier: int) -> String:
    if multiplier >= 5:
        return "MEGA COMBO"
    if multiplier >= 4:
        return "SUPER COMBO"
    if multiplier >= 2:
        return "COMBO"
    return "BASE"


func _combo_color(multiplier: int) -> Color:
    if multiplier <= 1:
        return Color("#93d8ff")
    if multiplier == 2:
        return Color("#ffd447")
    if multiplier == 3:
        return Color("#ffab33")
    if multiplier == 4:
        return Color("#ff7c2f")
    if multiplier == 5:
        return Color("#ff5030")
    return Color("#ff2f56")


func _combo_glow_strength(multiplier: int) -> float:
    if multiplier <= 1:
        return 0.34
    return clampf(0.48 + float(mini(multiplier, 6) - 2) * 0.13, 0.48, 1.0)



func _combo_frame_rect() -> Rect2:
    return Rect2(Vector2(size.x - 98.0, 54.0), Vector2(78.0, 78.0))



func _draw_board_frame() -> void:
    var frame_rect: Rect2 = Rect2(board_rect.position.round(), board_rect.size.round()).grow(11.0)
    var outer_radius: int = 14

    # Broad shadow keeps the board lifted, while the dark theme gets a restrained
    # icy rim like the approved concept art. The glow is intentionally outside
    # the play cells so placement precision stays untouched.
    for shadow_layer in range(7, 0, -1):
        var spread: float = float(shadow_layer) * 1.7
        var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
        shadow_style.bg_color = Color(0.0, 0.0, 0.0, (0.010 if light_mode else 0.027) * float(8 - shadow_layer))
        shadow_style.corner_radius_top_left = outer_radius + shadow_layer
        shadow_style.corner_radius_top_right = outer_radius + shadow_layer
        shadow_style.corner_radius_bottom_left = outer_radius + shadow_layer
        shadow_style.corner_radius_bottom_right = outer_radius + shadow_layer
        draw_style_box(shadow_style, Rect2(frame_rect.position + Vector2(0.0, 4.0 + spread), frame_rect.size).grow(spread))

    if not light_mode:
        var ice: Color = Color("#87d7ff")
        for glow_index in range(4, 0, -1):
            var glow_grow: float = 1.0 + float(glow_index) * 2.2
            var glow_alpha: float = 0.018 + float(5 - glow_index) * 0.018
            _draw_panel_outline(frame_rect.grow(glow_grow), Color(ice.r, ice.g, ice.b, glow_alpha), 2, outer_radius + glow_index)

    var frame_style: StyleBoxFlat = StyleBoxFlat.new()
    frame_style.bg_color = (Color(1.0, 0.99, 0.98, 0.34) if light_mode else Color(0.035, 0.067, 0.098, 0.34)) if background_enabled else (Color("#fffdfa") if light_mode else Color("#091119"))
    frame_style.corner_radius_top_left = outer_radius
    frame_style.corner_radius_top_right = outer_radius
    frame_style.corner_radius_bottom_left = outer_radius
    frame_style.corner_radius_bottom_right = outer_radius
    frame_style.set_border_width_all(2)
    frame_style.border_color = Color("#aab8c3") if light_mode else Color("#89a9bb")
    draw_style_box(frame_style, frame_rect)

    # A second fine metallic rim makes the edge feel machined rather than soft.
    var second_rim: Rect2 = frame_rect.grow(-3.0)
    _draw_panel_outline(second_rim, Color("#d7e5ed") if light_mode else Color("#426278"), 1, 11)

    var inner_lip: Rect2 = board_rect.grow(5.0)
    var lip_style: StyleBoxFlat = StyleBoxFlat.new()
    lip_style.bg_color = (Color(0.91, 0.93, 0.94, 0.28) if light_mode else Color(0.059, 0.102, 0.137, 0.28)) if background_enabled else (Color("#e9edf0") if light_mode else Color("#0f1a23"))
    lip_style.corner_radius_top_left = 8
    lip_style.corner_radius_top_right = 8
    lip_style.corner_radius_bottom_left = 8
    lip_style.corner_radius_bottom_right = 8
    lip_style.set_border_width_all(1)
    lip_style.border_color = Color("#c8d1d8") if light_mode else Color("#45677c")
    draw_style_box(lip_style, inner_lip)

    # Upper-left cold highlights and darker lower/right edges establish the
    # same crisp lighting direction used by the glass blocks.
    draw_line(frame_rect.position + Vector2(float(outer_radius), 2.0), Vector2(frame_rect.end.x - float(outer_radius), frame_rect.position.y + 2.0), Color(1.0, 1.0, 1.0, 0.72 if light_mode else 0.40), 1.0)
    draw_line(Vector2(frame_rect.position.x + 2.0, frame_rect.position.y + float(outer_radius)), Vector2(frame_rect.position.x + 2.0, frame_rect.end.y - float(outer_radius)), Color(0.82, 0.94, 1.0, 0.40 if light_mode else 0.23), 1.0)
    draw_line(Vector2(frame_rect.position.x + float(outer_radius), frame_rect.end.y - 2.0), Vector2(frame_rect.end.x - float(outer_radius), frame_rect.end.y - 2.0), Color(0.0, 0.0, 0.0, 0.26 if light_mode else 0.66), 1.0)
    draw_line(Vector2(frame_rect.end.x - 2.0, frame_rect.position.y + float(outer_radius)), Vector2(frame_rect.end.x - 2.0, frame_rect.end.y - float(outer_radius)), Color(0.0, 0.0, 0.0, 0.20 if light_mode else 0.54), 1.0)


func _draw_board_intersection_studs() -> void:
    for grid_y in range(1, BOARD_SIZE):
        for grid_x in range(1, BOARD_SIZE):
            var center: Vector2 = board_rect.position + Vector2(float(grid_x) * cell_size, float(grid_y) * cell_size)
            var is_region_joint: bool = grid_x % 3 == 0 and grid_y % 3 == 0
            if is_region_joint:
                draw_circle(center + Vector2(0.0, 1.0), 4.1, Color(0.0, 0.0, 0.0, 0.38 if not light_mode else 0.16))
                draw_circle(center, 3.45, Color("#8295a4") if not light_mode else Color("#8799a8"))
                draw_circle(center + Vector2(-0.8, -1.0), 1.15, Color(1.0, 1.0, 1.0, 0.36))
            else:
                var socket_fill: Color = Color("#0b1117") if not light_mode else Color("#f5f3ef")
                var socket_edge: Color = Color("#687985") if not light_mode else Color("#8e9daa")
                draw_circle(center, 2.15, socket_fill)
                draw_arc(center, 1.8, 0.0, TAU, 20, socket_edge, 0.85, true)
                draw_circle(center, 0.55, Color(socket_edge.r, socket_edge.g, socket_edge.b, 0.72))


func _draw_board() -> void:
    # Build the empty board from nine quiet 3x3 panels. This keeps the regions
    # readable without the noisy one-cell checkerboard effect.
    _draw_board_frame()

    for region_y in range(3):
        for region_x in range(3):
            var region_rect: Rect2 = Rect2(
                board_rect.position + Vector2(float(region_x * 3) * cell_size, float(region_y * 3) * cell_size),
                Vector2.ONE * cell_size * 3.0
            )
            var region_parity: int = (region_x + region_y) % 2
            var region_color: Color = board_empty if region_parity == 0 else board_empty_alt
            if background_enabled:
                region_color.a = 0.24
            draw_rect(region_rect, region_color)

    for i in range(1, BOARD_SIZE):
        var x_line: float = board_rect.position.x + float(i) * cell_size
        var y_line: float = board_rect.position.y + float(i) * cell_size
        if i % 3 != 0:
            draw_line(Vector2(x_line, board_rect.position.y), Vector2(x_line, board_rect.end.y), grid_line, 1.0)
            draw_line(Vector2(board_rect.position.x, y_line), Vector2(board_rect.end.x, y_line), grid_line, 1.0)

    for major_index in [3, 6]:
        var x_major: float = board_rect.position.x + float(major_index) * cell_size
        var y_major: float = board_rect.position.y + float(major_index) * cell_size
        var gutter_width: float = 2.0 if light_mode else 4.0
        draw_line(Vector2(x_major, board_rect.position.y), Vector2(x_major, board_rect.end.y), grid_major, gutter_width)
        draw_line(Vector2(board_rect.position.x, y_major), Vector2(board_rect.end.x, y_major), grid_major, gutter_width)
        if not light_mode:
            draw_line(Vector2(x_major + 2.0, board_rect.position.y), Vector2(x_major + 2.0, board_rect.end.y), Color(1.0, 1.0, 1.0, 0.055), 1.0)
            draw_line(Vector2(board_rect.position.x, y_major + 2.0), Vector2(board_rect.end.x, y_major + 2.0), Color(1.0, 1.0, 1.0, 0.055), 1.0)

    _draw_board_intersection_studs()

    # Blocks sit above the board hardware, preserving the sense that the
    # sockets belong to the board rather than the playable pieces.
    for y in range(BOARD_SIZE):
        if y >= board.size() or not (board[y] is Array):
            continue
        var board_row: Array = board[y] as Array
        for x in range(BOARD_SIZE):
            if x >= board_row.size():
                continue
            var rect: Rect2 = _cell_rect(x, y)
            var value: int = int(board_row[x])
            if value >= 0:
                var block_color: Color = SHAPE_PALETTES[posmod(value, SHAPE_PALETTES.size())]
                _draw_crisp_cell(rect.grow(-3.5), block_color, 1.0)
                var pickup_key: String = _board_pickup_key(Vector2i(x, y))
                if board_tool_pickups.has(pickup_key):
                    var tool_type: int = clampi(int(board_tool_pickups[pickup_key]), ToolType.HAMMER, ToolType.RESET)
                    var badge_size: float = minf(27.0, cell_size * 0.52)
                    var badge_rect := Rect2(rect.get_center() - Vector2.ONE * badge_size * 0.5, Vector2.ONE * badge_size)
                    draw_circle(rect.get_center(), badge_size * 0.57, Color(0.02, 0.04, 0.06, 0.72))
                    _draw_tool_icon(badge_rect, tool_type, 0.98)

    draw_rect(board_rect, grid_major, false, 1.5)


func _draw_tool_mode_board_overlay() -> void:
    if selected_tap_tool < 0:
        return
    # A selected tap tool enters a distinct Tool Mode. Hammer/Transform make the
    # board clearly secondary; Reset keeps the board readable because it is the
    # target, but gives it a strong red focus outline.
    var dim_alpha: float = 0.34 if selected_tap_tool != ToolType.RESET else 0.16
    draw_rect(board_rect, Color(0.0, 0.0, 0.0, dim_alpha))
    if selected_tap_tool == ToolType.RESET:
        var accent: Color = _tool_color(ToolType.RESET)
        draw_rect(board_rect.grow(2.0), Color(accent.r, accent.g, accent.b, 0.94), false, 3.0)
        draw_rect(board_rect.grow(5.0), Color(accent.r, accent.g, accent.b, 0.20), false, 2.0)


func _draw_tool_mode_banner() -> void:
    if selected_tap_tool < 0:
        return
    var accent: Color = _tool_color(selected_tap_tool)
    var label: String = "HAMMER  ·  SELECT A SHAPE"
    if selected_tap_tool == ToolType.TRANSFORM:
        label = "ROTATE / MIRROR  ·  SELECT A SHAPE"
    elif selected_tap_tool == ToolType.RESET:
        label = "RESET  ·  TAP THE BOARD"

    # Compact Tool Mode strip in the dedicated gap between the board and the
    # three offered shapes. The 18 px height fits inside the existing 22 px
    # spacing, so the board and lower HUD keep their original positions.
    var side_margin: float = board_rect.position.x
    var gap_y: float = board_rect.end.y + 2.0
    var banner_end_x: float = tool_cancel_rect.position.x - 5.0
    var banner_rect := Rect2(Vector2(side_margin, gap_y), Vector2(maxf(120.0, banner_end_x - side_margin), 18.0))
    _draw_concept_panel(banner_rect, Color(accent.r, accent.g, accent.b, 0.68), 0.96, 6, 0.22)
    _text_center(label, Rect2(banner_rect.position + Vector2(5.0, 0.0), Vector2(banner_rect.size.x - 10.0, 18.0)), 7, Color(0.96, 0.98, 1.0, 0.96))

    # Dedicated close button in the same gap. It is deliberately compact but
    # keeps a generous hit rectangle through tool_cancel_rect.
    var c: Vector2 = tool_cancel_rect.get_center()
    draw_circle(c + Vector2(0.0, 0.5), 9.0, Color(0.0, 0.0, 0.0, 0.28))
    draw_circle(c, 8.5, Color(0.10, 0.13, 0.16, 0.98) if not light_mode else Color(0.96, 0.97, 0.98, 0.98))
    draw_arc(c, 8.0, 0.0, TAU, 24, Color(accent.r, accent.g, accent.b, 0.86), 1.0, true)
    var x_color: Color = Color(0.96, 0.98, 1.0, 0.96) if not light_mode else Color(0.18, 0.22, 0.26, 0.96)
    draw_line(c + Vector2(-2.8, -2.8), c + Vector2(2.8, 2.8), x_color, 1.6, true)
    draw_line(c + Vector2(2.8, -2.8), c + Vector2(-2.8, 2.8), x_color, 1.6, true)


func _draw_piece_cards() -> void:
    var visible_piece_count: int = mini(3, mini(piece_rects.size(), pieces.size()))
    for i in range(visible_piece_count):
        var rect: Rect2 = piece_rects[i]
        var piece: Dictionary = pieces[i] as Dictionary
        var used: bool = bool(piece.get("used", true))
        var has_fit: bool = false if used else _piece_has_any_fit(piece)
        var transformable: bool = false if used else _piece_can_transform(piece)
        var is_transform_piece: bool = i == transform_piece_index and not used
        var tap_eligible: bool = false
        if selected_tap_tool == ToolType.HAMMER:
            tap_eligible = not used
        elif selected_tap_tool == ToolType.TRANSFORM:
            tap_eligible = not used and transformable

        var base_alpha: float = 1.0 if has_fit else 0.24
        if is_transform_piece or tap_eligible:
            base_alpha = 1.0
        if dragging_transform and not transformable:
            base_alpha = 0.16
        if selected_tap_tool >= 0 and not tap_eligible and not is_transform_piece:
            base_alpha = 0.12

        var border: Color = grid_line
        var border_width: float = 1.0
        if is_transform_piece:
            border = _current_shape_color()
            border_width = 2.0
        elif tap_eligible:
            border = _tool_color(selected_tap_tool)
            border_width = 2.0
        elif dragging_transform and transform_hover_piece == i and transformable:
            border = success
            border_width = 2.0
        elif dragging_hammer and hammer_hover_piece == i:
            border = danger
            border_width = 2.0

        if light_mode:
            _draw_premium_panel(rect, Color(panel.r, panel.g, panel.b, 0.42 if background_enabled else panel.a), border, 9, int(border_width), 0.42)
        else:
            _draw_concept_panel(rect, Color(border.r, border.g, border.b, minf(0.92, border.a + 0.34)), 0.38 if background_enabled else 1.0, 9, 0.42)
        # Keep the card linework fully opaque even when the card surface is translucent.
        _draw_panel_outline(rect, Color(border.r, border.g, border.b, 0.96), int(border_width), 9)

        if used:
            var used_text: String = "DESTROYED" if bool(piece.get("destroyed", false)) else "USED"
            _text_center(used_text, rect, 10, Color(text_dim.r, text_dim.g, text_dim.b, 0.48))
            continue

        if i == dragging_piece:
            continue

        _draw_piece_in_rect(piece, rect, base_alpha)

        if is_transform_piece:
            _draw_transform_action_badge(rect, transform_step == 3)
            _text_center("TAP · DRAG", Rect2(rect.position + Vector2(0.0, rect.size.y - 22.0), Vector2(rect.size.x, 17.0)), 8, _current_shape_color())
        elif tap_eligible:
            _text_center("TAP", Rect2(rect.position + Vector2(0.0, rect.size.y - 22.0), Vector2(rect.size.x, 17.0)), 8, _tool_color(selected_tap_tool))
        elif not has_fit:
            _text_center("NO FIT", Rect2(rect.position + Vector2(0.0, rect.size.y - 22.0), Vector2(rect.size.x, 17.0)), 8, text_dim)

func _draw_piece_in_rect(piece: Dictionary, rect: Rect2, alpha: float) -> void:
    var bounds: Vector2i = _piece_bounds(piece)
    # A fixed maximum cell size makes 1x4 and 1x5 visibly different instead of
    # scaling both bars to nearly the same width.
    var mini: float = minf(28.0, minf((rect.size.x - 18.0) / float(bounds.x), (rect.size.y - 28.0) / float(bounds.y)))
    var piece_px: Vector2 = Vector2(float(bounds.x) * mini, float(bounds.y) * mini)
    var origin: Vector2 = rect.get_center() - piece_px * 0.5
    var cells: Array = piece["cells"] as Array
    var color: Color = _current_shape_color()

    for cell_value in cells:
        var c: Vector2i = cell_value
        var cell_rect: Rect2 = Rect2(origin + Vector2(c.x, c.y) * mini, Vector2(mini - 2.0, mini - 2.0))
        _draw_crisp_cell(cell_rect, color, alpha)


func _draw_tools_panel() -> void:
    _draw_tool_card(hammer_tool_rect, ToolType.HAMMER)
    _draw_tool_card(transform_tool_rect, ToolType.TRANSFORM)
    _draw_tool_card(reset_tool_rect, ToolType.RESET)

func _draw_tool_card(rect: Rect2, tool_type: int) -> void:
    var count: int = _tool_count(tool_type)
    var display_count: int = maxi(0, count - tool_hidden_reward_counts[tool_type])
    var icon_rect: Rect2 = _tool_icon_rect(tool_type)
    var can_use: bool = display_count > 0 and not game_over
    if tool_type == ToolType.HAMMER:
        can_use = can_use and _has_unused_piece()
    elif tool_type == ToolType.TRANSFORM:
        can_use = can_use and transform_piece_index < 0 and _has_transformable_unused_piece()
    elif tool_type == ToolType.RESET:
        can_use = can_use and _occupied_cell_count() > 0

    var accent: Color = _tool_color(tool_type)
    var selected: bool = selected_tap_tool == tool_type
    var accent_alpha: float = 0.76 if selected else (0.34 if light_mode else 0.26)
    var accent_border := Color(accent.r, accent.g, accent.b, accent_alpha)
    if light_mode:
        _draw_premium_panel(rect, Color(panel.r, panel.g, panel.b, 0.42 if background_enabled else panel.a), accent_border, 9, 2 if selected else 1, 0.42)
    else:
        _draw_concept_panel(rect, accent_border, 0.38 if background_enabled else 1.0, 9, 0.42)
    # Keep tool-card borders crisp and fully visible over the scenery.
    var tool_outline: Color = Color(accent.r, accent.g, accent.b, 0.96 if selected else 0.72)
    _draw_panel_outline(rect, tool_outline, 2 if selected else 1, 9)

    _draw_tool_icon(icon_rect, tool_type, 1.0 if can_use or selected else 0.34)

    var counter_scale: float = 1.0
    if tool_counter_pop_time[tool_type] > 0.0:
        var counter_t: float = 1.0 - tool_counter_pop_time[tool_type] / TOOL_COUNTER_POP_DURATION
        counter_scale = 1.0 + 0.38 * sin(clampf(counter_t, 0.0, 1.0) * PI)
        var badge_center: Vector2 = _tool_badge_center(icon_rect)
        var ring_radius: float = 11.0 + counter_t * 17.0
        draw_arc(badge_center, ring_radius, 0.0, TAU, 24, Color(1.0, 0.30, 0.24, (1.0 - counter_t) * 0.68), 1.4, true)
    _draw_tool_quantity_badge(icon_rect, display_count, 1.0 if display_count > 0 else 0.48, counter_scale)

func _tool_count(tool_type: int) -> int:
    match tool_type:
        ToolType.HAMMER:
            return hammer_count
        ToolType.TRANSFORM:
            return transform_count
        ToolType.RESET:
            return reset_count
    return 0

func _tool_icon_rect(tool_type: int) -> Rect2:
    match tool_type:
        ToolType.HAMMER:
            return hammer_icon_rect
        ToolType.TRANSFORM:
            return transform_icon_rect
        ToolType.RESET:
            return reset_icon_rect
    return Rect2()

func _tool_color(tool_type: int) -> Color:
    match tool_type:
        ToolType.HAMMER:
            return Color("#52b8ff")
        ToolType.TRANSFORM:
            return Color("#4fd6c3")
        ToolType.RESET:
            return Color("#ff5c67")
    return Color.WHITE

func _draw_tool_icon(rect: Rect2, tool_type: int, alpha: float = 1.0) -> void:
    var texture: Texture2D = _tool_icon_texture(tool_type)
    if texture != null:
        draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, alpha))


func _tool_icon_texture(tool_type: int) -> Texture2D:
    match tool_type:
        ToolType.HAMMER:
            return HAMMER_ICON_TEXTURE
        ToolType.TRANSFORM:
            return TRANSFORM_ICON_TEXTURE
        ToolType.RESET:
            return RESET_ICON_TEXTURE
    return null

func _tool_badge_center(icon_rect: Rect2) -> Vector2:
    return Vector2(round(icon_rect.end.x - 2.0), round(icon_rect.position.y + 3.0))

func _draw_tool_quantity_badge(icon_rect: Rect2, count: int, alpha: float, scale: float = 1.0) -> void:
    # iPhone-style notification badge: red bubble, white number, top-right.
    var center: Vector2 = _tool_badge_center(icon_rect)
    var radius: float = (10.5 if count < 10 else 11.5) * scale
    draw_circle(center + Vector2(0.0, 1.0), radius, Color(0.0, 0.0, 0.0, 0.24 * alpha))
    draw_circle(center, radius, Color(1.0, 0.23, 0.19, 0.98 * alpha))
    var count_text: String = str(count)
    var count_font_size: int = 10 if count_text.length() <= 1 else (8 if count_text.length() <= 2 else 7)
    var count_width: float = font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_font_size).x
    var ascent: float = font.get_ascent(count_font_size)
    var descent: float = font.get_descent(count_font_size)
    var baseline := Vector2(round(center.x - count_width * 0.5), round(center.y + (ascent - descent) * 0.5))
    draw_string(font, baseline, count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_font_size, Color(1.0, 1.0, 1.0, alpha))


func _draw_dragging_piece() -> void:
    if dragging_piece < 0 or dragging_piece >= pieces.size():
        dragging_piece = -1
        return

    var piece: Dictionary = pieces[dragging_piece] as Dictionary
    if bool(piece["used"]):
        return

    var drag_center: Vector2 = _piece_drag_center(mouse_pos, piece)
    var anchor: Vector2i = _drag_anchor(drag_center, piece)
    var can_place: bool = _can_place(piece, anchor)
    var cells: Array = piece["cells"] as Array
    var preview_color: Color = success if can_place else danger

    if can_place:
        var imminent_clear: Dictionary = _find_clear_result_with_piece(piece, anchor)
        if int(imminent_clear["units"]) > 0:
            _draw_imminent_clear_preview(imminent_clear)

    # The board preview is the only snapped layer. It shows the exact cells that
    # will be used if the pointer is released at its current position.
    for cell_value in cells:
        var c: Vector2i = cell_value
        var gx: int = anchor.x + c.x
        var gy: int = anchor.y + c.y
        if gx >= 0 and gx < BOARD_SIZE and gy >= 0 and gy < BOARD_SIZE:
            var rect: Rect2 = _cell_rect(gx, gy).grow(-3.0)
            draw_rect(rect, Color(preview_color.r, preview_color.g, preview_color.b, 0.30))
            draw_rect(rect, preview_color, false, 2.0)

    # Draw the actual piece independently at the unsnapped pointer position.
    # On touch, the fingertip points just below the piece instead of covering its
    # centre. The same centre is used for the snapped preview and final drop.
    var bounds: Vector2i = _piece_bounds(piece)
    var piece_px: Vector2 = Vector2(float(bounds.x) * cell_size, float(bounds.y) * cell_size)
    var top_left: Vector2 = drag_center - piece_px * 0.5
    for cell_value in cells:
        var c: Vector2i = cell_value
        var floating_rect: Rect2 = Rect2(
            top_left + Vector2(c.x, c.y) * cell_size + Vector2(2.0, 2.0),
            Vector2(cell_size - 4.0, cell_size - 4.0)
        )
        _draw_crisp_cell(floating_rect, _current_shape_color(), 0.92)


func _draw_hammer_drag_preview() -> void:
    if hammer_hover_piece >= 0:
        var piece_rect: Rect2 = piece_rects[hammer_hover_piece]
        draw_rect(piece_rect.grow(-2.0), Color(danger.r, danger.g, danger.b, 0.15))
        draw_rect(piece_rect.grow(-2.0), danger, false, 2.5)
    _draw_tool_icon(Rect2(mouse_pos + Vector2(-21.0, -62.0), Vector2(42.0, 42.0)), ToolType.HAMMER, 0.96)

func _draw_transform_drag_preview() -> void:
    if transform_hover_piece >= 0:
        var piece_rect: Rect2 = piece_rects[transform_hover_piece]
        draw_rect(piece_rect.grow(-2.0), Color(success.r, success.g, success.b, 0.13))
        draw_rect(piece_rect.grow(-2.0), success, false, 2.5)
        _draw_rotate_hint(piece_rect.get_center(), success, 13.0)
    _draw_tool_icon(Rect2(mouse_pos + Vector2(-21.0, -62.0), Vector2(42.0, 42.0)), ToolType.TRANSFORM, 0.96)

func _draw_reset_drag_preview() -> void:
    var accent: Color = _tool_color(ToolType.RESET)
    if board_rect.has_point(mouse_pos):
        draw_rect(board_rect, Color(accent.r, accent.g, accent.b, 0.08))
        draw_rect(board_rect, Color(accent.r, accent.g, accent.b, 0.78), false, 2.0)
    _draw_tool_icon(Rect2(mouse_pos + Vector2(-21.0, -62.0), Vector2(42.0, 42.0)), ToolType.RESET, 0.96)

func _draw_imminent_clear_preview(clear_result: Dictionary) -> void:
    var clear_cells: Dictionary = clear_result["cells"] as Dictionary
    var pulse: float = 0.50 + 0.18 * sin(float(Time.get_ticks_msec()) * 0.012)
    var glow_color: Color = _current_shape_color()
    for pos_value in clear_cells.keys():
        var pos: Vector2i = pos_value
        var rect: Rect2 = _cell_rect(pos.x, pos.y).grow(-1.5)
        draw_rect(rect, Color(glow_color.r, glow_color.g, glow_color.b, pulse * 0.42))
        draw_rect(rect, Color(1.0, 1.0, 1.0, pulse), false, 2.5)


func _draw_rotate_hint(center: Vector2, color: Color, radius: float = 10.0) -> void:
    # Clean clockwise action glyph: a near-complete arc with a filled arrowhead.
    # The previous two-line arrowhead looked like a small loading spinner.
    var start_angle: float = -PI * 0.88
    var end_angle: float = PI * 0.58
    draw_arc(center, radius, start_angle, end_angle, 24, color, 2.2, true)
    var tip: Vector2 = center + Vector2(cos(end_angle), sin(end_angle)) * radius
    var tangent := Vector2(-sin(end_angle), cos(end_angle)).normalized()
    var normal := Vector2(-tangent.y, tangent.x)
    var base: Vector2 = tip - tangent * 5.3
    draw_colored_polygon(PackedVector2Array([tip + tangent * 1.2, base + normal * 3.2, base - normal * 3.2]), color)


func _draw_mirror_hint(center: Vector2, color: Color, radius: float = 10.0) -> void:
    # Clear horizontal flip glyph: a dashed mirror axis plus arrows moving to the
    # opposite handedness on each side.
    var line_top: float = center.y - radius
    var line_bottom: float = center.y + radius
    for dash_index in range(3):
        var y0: float = line_top + float(dash_index) * radius * 0.72
        draw_line(Vector2(center.x, y0), Vector2(center.x, minf(line_bottom, y0 + radius * 0.42)), color, 1.7, true)
    var stem: float = radius * 0.70
    draw_line(center + Vector2(-2.5, -2.5), center + Vector2(-stem, -2.5), color, 1.8, true)
    draw_line(center + Vector2(2.5, 2.5), center + Vector2(stem, 2.5), color, 1.8, true)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(-stem - 1.5, -2.5),
        center + Vector2(-stem + 3.0, -6.0),
        center + Vector2(-stem + 3.0, 1.0)
    ]), color)
    draw_colored_polygon(PackedVector2Array([
        center + Vector2(stem + 1.5, 2.5),
        center + Vector2(stem - 3.0, -1.0),
        center + Vector2(stem - 3.0, 6.0)
    ]), color)


func _draw_transform_action_badge(rect: Rect2, mirror_next: bool) -> void:
    # Keep the next-action indicator inside the offered-piece card but out of the
    # actual block silhouette. A stronger icon plus a tiny caption is much easier
    # to read than the old spinner-like badge drawn over the piece center.
    var badge_center := Vector2(rect.end.x - 22.0, rect.position.y + 22.0)
    var accent: Color = _current_shape_color()
    draw_circle(badge_center + Vector2(0.0, 1.0), 15.0, Color(0.0, 0.0, 0.0, 0.36))
    draw_circle(badge_center, 14.0, Color(0.035, 0.055, 0.072, 0.96) if not light_mode else Color(0.98, 0.98, 0.97, 0.96))
    draw_arc(badge_center, 13.4, 0.0, TAU, 30, Color(accent.r, accent.g, accent.b, 0.94), 1.3, true)
    if mirror_next:
        _draw_mirror_hint(badge_center, Color(1.0, 1.0, 1.0, 0.98), 7.6)
    else:
        _draw_rotate_hint(badge_center, Color(1.0, 1.0, 1.0, 0.98), 7.6)

    var label: String = "MIRROR" if mirror_next else "ROTATE"
    var label_rect := Rect2(Vector2(rect.end.x - 50.0, rect.position.y + 38.0), Vector2(56.0, 14.0))
    _text_center(label, label_rect, 6, Color(accent.r, accent.g, accent.b, 0.94))


func _draw_animation_overlays() -> void:
    if clear_fx_time > 0.0:
        _draw_clear_fx()
    if multi_fx_time > 0.0:
        _draw_multi_clear_fx()
    if score_gain_fx_time > 0.0:
        _draw_score_gain_fx()
    if combo_fx_time > 0.0:
        _draw_combo_fx()
    if all_clear_fx_time > 0.0:
        _draw_all_clear_fx()
    if not active_tool_reward.is_empty():
        _draw_tool_reward_fx()


func _draw_clear_fx() -> void:
    var t: float = clampf(1.0 - clear_fx_time / CLEAR_FX_DURATION, 0.0, 1.0)
    var global_hold: float = 1.0 - clampf((t - 0.76) / 0.24, 0.0, 1.0)
    var particles_per_ghost: int = 0
    if not clear_fx_ghosts.is_empty():
        particles_per_ghost = mini(3, maxi(1, int(floor(float(MAX_CLEAR_PARTICLES) / float(clear_fx_ghosts.size())))))

    for ghost in clear_fx_ghosts:
        var pos: Vector2i = ghost.get("pos", Vector2i(-1, -1))
        if pos.x < 0 or pos.x >= BOARD_SIZE or pos.y < 0 or pos.y >= BOARD_SIZE:
            continue
        var delay: float = float(ghost.get("delay", 0.0)) * 0.46
        var local_t: float = (t - delay) / maxf(0.01, 1.0 - delay)
        var rect: Rect2 = _cell_rect(pos.x, pos.y).grow(-3.5)
        var ghost_color: Color = ghost.get("color", _current_shape_color())

        if local_t < 0.0:
            _draw_crisp_cell(rect, ghost_color, 1.0)
            continue

        local_t = clampf(local_t, 0.0, 1.0)
        if local_t < 0.26:
            # Quick but obvious bright acknowledgement before the cell breaks.
            var charge: float = local_t / 0.26
            var pulse: float = 0.5 - 0.5 * cos(charge * PI)
            _draw_crisp_cell(rect, ghost_color.lerp(Color.WHITE, 0.38 + pulse * 0.30), 1.0)
            draw_rect(rect.grow(2.0 + pulse * 1.5), Color(0.78, 0.95, 1.0, (0.30 + pulse * 0.36) * global_hold), false, 2.0)
        elif local_t < 0.48:
            # Fast highlight sweep to make the clear direction easy to read.
            var sweep_t: float = (local_t - 0.26) / 0.22
            _draw_crisp_cell(rect, ghost_color.lerp(Color.WHITE, 0.58), 1.0)
            var sweep_x: float = rect.position.x + rect.size.x * sweep_t
            draw_rect(Rect2(Vector2(sweep_x - 2.5, rect.position.y), Vector2(5.0, rect.size.y)), Color(1.0, 1.0, 1.0, sin(sweep_t * PI) * 0.78))
        else:
            var break_t: float = (local_t - 0.48) / 0.52
            var scale: float = lerpf(1.0, 0.12, break_t * break_t)
            var animated_rect: Rect2 = Rect2(rect.get_center() - rect.size * scale * 0.5, rect.size * scale)
            _draw_crisp_cell(animated_rect, ghost_color.lerp(Color.WHITE, 0.44 * (1.0 - break_t)), 1.0 - break_t * 0.68)
            draw_rect(animated_rect.grow(1.5), Color(1.0, 1.0, 1.0, (1.0 - break_t) * 0.58), false, 1.5)

        # Small debris falls down after the cell starts clearing. It is fully
        # procedural, so there are no particle textures or extra assets.
        var particle_t: float = clampf((local_t - 0.20) / 0.80, 0.0, 1.0)
        if particle_t > 0.0:
            for particle_index in range(particles_per_ghost):
                var seed: float = float(pos.x * 37 + pos.y * 61 + particle_index * 83)
                var horizontal: float = sin(seed * 0.071) * (5.0 + float(particle_index) * 2.2)
                var start_x: float = rect.get_center().x + sin(seed * 0.113) * rect.size.x * 0.26
                var start_y: float = rect.get_center().y + cos(seed * 0.097) * rect.size.y * 0.14
                var fall: float = 8.0 + particle_t * particle_t * (24.0 + float(particle_index) * 8.0)
                var drift: float = horizontal * particle_t
                var particle_pos: Vector2 = Vector2(start_x + drift, start_y + fall)
                var particle_alpha: float = (1.0 - particle_t) * 0.74
                var particle_size: float = maxf(1.2, 3.6 - particle_t * 1.8 + float(particle_index % 2))
                var particle_color: Color = ghost_color.lightened(0.30 if particle_index == 0 else 0.12)
                particle_color.a = particle_alpha
                draw_rect(Rect2(particle_pos - Vector2.ONE * particle_size * 0.5, Vector2.ONE * particle_size), particle_color)

    if clear_fx_units == 1:
        var center: Vector2 = board_rect.get_center()
        var appear: float = clampf(t / 0.18, 0.0, 1.0)
        var disappear: float = 1.0 - clampf((t - 0.66) / 0.34, 0.0, 1.0)
        var alpha: float = minf(appear, disappear)
        var label_rect: Rect2 = Rect2(Vector2(center.x - 100.0, board_rect.position.y + 20.0), Vector2(200.0, 56.0))
        _text_tracked_center("CLEAR", label_rect, 20, Color(text_main.r, text_main.g, text_main.b, alpha), 2.4)

func _draw_multi_clear_fx() -> void:
    var t: float = clampf(1.0 - multi_fx_time / MULTI_FX_DURATION, 0.0, 1.0)
    var appear: float = clampf(t / 0.16, 0.0, 1.0)
    var fade: float = 1.0 - clampf((t - 0.76) / 0.24, 0.0, 1.0)
    var alpha: float = minf(appear, fade)
    var center: Vector2 = board_rect.get_center()
    var shape_color: Color = _current_shape_color()

    # Slow expanding rings make multi-clears unmistakably stronger than a
    # normal clear without covering the cells for too long.
    for ring_index in range(4):
        var ring_t: float = clampf((t - float(ring_index) * 0.07) / 0.86, 0.0, 1.0)
        var radius: float = 28.0 + ring_t * (120.0 + float(ring_index) * 19.0)
        var ring_alpha: float = alpha * (0.50 - float(ring_index) * 0.075) * (1.0 - ring_t * 0.48)
        draw_arc(center, radius, 0.0, TAU, 40, Color(shape_color.r, shape_color.g, shape_color.b, ring_alpha), 3.0, true)

    var pulse: float = 1.0 + sin(clampf(t / 0.58, 0.0, 1.0) * PI) * 0.16
    var label_width: float = 300.0 * pulse
    var label_rect: Rect2 = Rect2(Vector2(center.x - label_width * 0.5, board_rect.position.y + 18.0), Vector2(label_width, 84.0))
    draw_rect(label_rect, Color(0.01, 0.03, 0.05, 0.46 * alpha))
    draw_rect(label_rect, Color(shape_color.r, shape_color.g, shape_color.b, 0.78 * alpha), false, 2.0)
    _text_center_alpha("%d× CLEAR" % multi_fx_units, Rect2(label_rect.position + Vector2(0.0, 7.0), Vector2(label_rect.size.x, 48.0)), 30, text_main, alpha)
    _text_tracked_center("MULTI CLEAR", Rect2(label_rect.position + Vector2(0.0, 52.0), Vector2(label_rect.size.x, 20.0)), 8, Color(shape_color.r, shape_color.g, shape_color.b, alpha), 1.5)


func _draw_score_gain_fx() -> void:
    if last_move_score <= 0 or score_gain_components.is_empty():
        return
    var t: float = clampf(1.0 - score_gain_fx_time / SCORE_GAIN_FX_DURATION, 0.0, 1.0)
    var appear: float = clampf(t / 0.13, 0.0, 1.0)
    var fade: float = 1.0 - clampf((t - 0.72) / 0.28, 0.0, 1.0)
    var alpha: float = minf(appear, fade)
    var start_center: Vector2 = board_rect.get_center() + Vector2(0.0, -24.0 if combo_fx_time > 0.0 else 0.0)
    var target_center: Vector2 = Vector2(130.0, 105.0)
    var travel_t: float = clampf((t - 0.20) / 0.70, 0.0, 1.0)
    var eased: float = 1.0 - pow(1.0 - travel_t, 3.0)
    var group_center: Vector2 = start_center.lerp(target_center, eased)

    var widths: Array[float] = []
    var total_width: float = 0.0
    var gap: float = 8.0
    for component in score_gain_components:
        var label: String = String(component.get("label", ""))
        var text_w: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
        var bubble_w: float = maxf(46.0, text_w + 22.0)
        widths.append(bubble_w)
        total_width += bubble_w
    total_width += gap * float(maxi(0, score_gain_components.size() - 1))

    var x: float = group_center.x - total_width * 0.5
    for i in range(score_gain_components.size()):
        var component: Dictionary = score_gain_components[i]
        var label: String = String(component.get("label", ""))
        var accent_kind: int = int(component.get("accent", 0))
        var bubble_w: float = widths[i]
        var bubble_h: float = 38.0
        var y_bob: float = -sin(clampf(t / 0.58, 0.0, 1.0) * PI) * (8.0 + float(i % 2) * 2.0)
        var rect := Rect2(Vector2(x, group_center.y - bubble_h * 0.5 + y_bob), Vector2(bubble_w, bubble_h))
        var accent: Color = _current_shape_color()
        if accent_kind == 1:
            accent = _combo_color(maxi(2, score_multiplier)) if score_multiplier > 1 else Color("#f4c45e")
        elif accent_kind == 2:
            accent = Color("#ffd76a")
        var fill := Color(0.025, 0.045, 0.065, 0.88 * alpha) if not light_mode else Color(1.0, 1.0, 1.0, 0.94 * alpha)
        _draw_premium_panel(rect, fill, Color(accent.r, accent.g, accent.b, 0.82 * alpha), 16, 1, 0.30)
        _text_center_alpha(label, rect, 15, Color(text_main.r, text_main.g, text_main.b, alpha), alpha)
        x += bubble_w + gap

func _draw_combo_fx() -> void:
    var t: float = clampf(1.0 - combo_fx_time / COMBO_FX_DURATION, 0.0, 1.0)
    var board_center: Vector2 = board_rect.get_center()
    var target: Vector2 = _combo_frame_rect().get_center()
    var combo_color: Color = _combo_color(combo_fx_multiplier)
    var strength: float = _combo_glow_strength(combo_fx_multiplier)

    if t < 0.72:
        # Sleek center celebration: typography, restrained glow, an expanding
        # hairline ring and lightweight confetti. No baked combo artwork.
        var local_t: float = t / 0.72
        var appear: float = clampf(local_t / 0.14, 0.0, 1.0)
        var fade: float = 1.0 - clampf((local_t - 0.86) / 0.14, 0.0, 1.0)
        var alpha: float = minf(appear, fade)
        var pop_t: float = clampf(local_t / 0.32, 0.0, 1.0)
        var scale: float = lerpf(0.70, 1.08, 1.0 - pow(1.0 - pop_t, 3.0))
        scale -= sin(clampf((local_t - 0.30) / 0.50, 0.0, 1.0) * PI) * 0.05

        var aura_pulse: float = 0.5 + 0.5 * sin(local_t * PI * (3.0 + strength))
        draw_circle(board_center, (68.0 + aura_pulse * 14.0) * scale, Color(combo_color.r, combo_color.g, combo_color.b, alpha * (0.035 + strength * 0.045)))
        draw_circle(board_center, (48.0 + aura_pulse * 8.0) * scale, Color(combo_color.r, combo_color.g, combo_color.b, alpha * (0.035 + strength * 0.030)))

        var ring_t: float = clampf(local_t / 0.72, 0.0, 1.0)
        var ring_radius: float = lerpf(42.0, 118.0, ring_t)
        draw_arc(board_center, ring_radius, 0.0, TAU, 40, Color(combo_color.r, combo_color.g, combo_color.b, alpha * (1.0 - ring_t) * 0.48), 1.5, true)

        # Confetti count rises slightly with combo level but stays intentionally
        # light for mobile/Web performance. Pieces drift downward as they spread.
        var confetti_count: int = 8 + mini(combo_fx_multiplier, 6)
        for confetti_index in range(confetti_count):
            var seed: float = float(confetti_index * 71 + combo_fx_multiplier * 43)
            var angle: float = fmod(seed * 0.193, TAU)
            var speed: float = 46.0 + fmod(seed * 1.37, 54.0)
            var launch_t: float = clampf((local_t - float(confetti_index % 5) * 0.018) / 0.82, 0.0, 1.0)
            var radial: float = speed * launch_t
            var gravity: float = launch_t * launch_t * (56.0 + float(confetti_index % 4) * 8.0)
            var confetti_pos: Vector2 = board_center + Vector2(cos(angle), sin(angle)) * radial + Vector2(0.0, gravity)
            var confetti_alpha: float = alpha * (1.0 - clampf((launch_t - 0.62) / 0.38, 0.0, 1.0))
            var confetti_size: Vector2 = Vector2(4.0 + float(confetti_index % 3) * 1.2, 2.0 + float((confetti_index + 1) % 2) * 1.2)
            var confetti_color: Color = combo_color.lerp(Color.WHITE, 0.32 if confetti_index % 4 == 0 else 0.0)
            confetti_color.a = confetti_alpha * 0.88
            draw_rect(Rect2(confetti_pos - confetti_size * 0.5, confetti_size), confetti_color)

        var number_size: int = int(round((52.0 + float(mini(combo_fx_multiplier, 6)) * 2.0) * scale))
        var number_rect: Rect2 = Rect2(board_center + Vector2(-150.0, -60.0 * scale), Vector2(300.0, 84.0 * scale))
        var label_text: String = _combo_stage_label(combo_fx_multiplier)
        var label_size: int = 14 if combo_fx_multiplier < 4 else 13
        var label_rect: Rect2 = Rect2(board_center + Vector2(-150.0, 24.0 * scale), Vector2(300.0, 32.0 * scale))

        # Four soft offset passes create premium bloom while keeping the center
        # clean and readable.
        var glow_alpha: float = alpha * (0.13 + strength * 0.12)
        for offset in [Vector2(-1.8, 0.0), Vector2(1.8, 0.0)]:
            _text_center_alpha("x%d" % combo_fx_multiplier, Rect2(number_rect.position + offset, number_rect.size), number_size, combo_color, glow_alpha)
        _text_center_alpha("x%d" % combo_fx_multiplier, number_rect, number_size, Color.WHITE.lerp(combo_color, 0.38), alpha)
        _text_tracked_center(label_text, label_rect, label_size, Color(combo_color.r, combo_color.g, combo_color.b, alpha * 0.96), 2.0)

        if combo_fx_delta > 0:
            _text_center_alpha("+%d LEVEL%s" % [combo_fx_delta, "S" if combo_fx_delta != 1 else ""], Rect2(board_center + Vector2(-120.0, 66.0 * scale), Vector2(240.0, 22.0)), 9, Color(combo_color.r, combo_color.g, combo_color.b, alpha * 0.72), alpha)
    else:
        # Keep the satisfying transfer into the persistent top-right combo HUD.
        var fly_t: float = clampf((t - 0.72) / 0.28, 0.0, 1.0)
        var eased: float = fly_t * fly_t * (3.0 - 2.0 * fly_t)
        var control: Vector2 = Vector2(target.x - 45.0, board_center.y - 128.0)
        var energy_pos: Vector2 = _quadratic_bezier(board_center, control, target, eased)
        var alpha: float = 1.0 - fly_t * 0.42
        for trail_index in range(3):
            var trail_t: float = maxf(0.0, eased - float(trail_index + 1) * 0.085)
            var trail_pos: Vector2 = _quadratic_bezier(board_center, control, target, trail_t)
            draw_circle(trail_pos, maxf(1.5, 5.0 - float(trail_index)), Color(combo_color.r, combo_color.g, combo_color.b, (0.20 - float(trail_index) * 0.045) * alpha))
        draw_circle(energy_pos, 6.5 - eased * 2.5, Color(combo_color.r, combo_color.g, combo_color.b, 0.42 * alpha))
        draw_circle(energy_pos, 2.6, Color(1.0, 1.0, 1.0, 0.88 * alpha))

func _quadratic_bezier(start: Vector2, control: Vector2, finish: Vector2, t: float) -> Vector2:
    var clamped_t: float = clampf(t, 0.0, 1.0)
    var inverse: float = 1.0 - clamped_t
    return inverse * inverse * start + 2.0 * inverse * clamped_t * control + clamped_t * clamped_t * finish


func _draw_tool_reward_fx() -> void:
    if active_tool_reward.is_empty():
        return
    var tool_type: int = int(active_tool_reward.get("tool_type", -1))
    var amount: int = int(active_tool_reward.get("amount", 1))
    if tool_type < 0 or tool_type >= tool_hidden_reward_counts.size():
        return

    var t: float = clampf(1.0 - tool_reward_fx_time / maxf(0.01, tool_reward_fx_duration), 0.0, 1.0)
    var center: Vector2 = board_rect.get_center()
    var target: Vector2 = _tool_icon_rect(tool_type).get_center()
    var position: Vector2 = center
    var scale: float = 1.0
    var alpha: float = 1.0
    var label_alpha: float = 0.0

    # Same dramatic timing as v1.23, but fewer expensive vector glow primitives.
    if t < 0.24:
        var intro_t: float = t / 0.24
        var eased: float = 1.0 - pow(1.0 - intro_t, 3.0)
        scale = lerpf(0.24, 1.90, eased)
        alpha = clampf(intro_t * 3.2, 0.0, 1.0)
        label_alpha = clampf(intro_t * 1.7, 0.0, 1.0)
    elif t < 0.50:
        var hold_t: float = (t - 0.24) / 0.26
        scale = 1.90 - sin(hold_t * PI) * 0.16
        label_alpha = 1.0
    elif t < 0.64:
        var settle_t: float = (t - 0.50) / 0.14
        scale = lerpf(1.90, 1.42, settle_t * settle_t * (3.0 - 2.0 * settle_t))
        label_alpha = 1.0
    elif t < 0.93:
        var fly_t: float = (t - 0.64) / 0.29
        var fly_eased: float = fly_t * fly_t * (3.0 - 2.0 * fly_t)
        var control: Vector2 = Vector2(target.x - 55.0, center.y - 145.0)
        position = _quadratic_bezier(center, control, target, fly_eased)
        scale = lerpf(1.42, 0.27, fly_eased)
        label_alpha = 1.0 - clampf(fly_t * 2.2, 0.0, 1.0)
    else:
        position = target
        var arrival_t: float = (t - 0.93) / 0.07
        scale = 0.27 + sin(arrival_t * PI) * 0.15
        alpha = 1.0 - arrival_t

    var accent: Color = _tool_color(tool_type)
    var glow_radius: float = 70.0 * scale
    draw_circle(position, glow_radius, Color(accent.r, accent.g, accent.b, 0.105 * alpha))
    draw_arc(position, glow_radius * 0.80, 0.0, TAU, 28, Color(accent.r, accent.g, accent.b, 0.55 * alpha), 2.6, true)
    var icon_size: float = 118.0 * scale
    _draw_tool_icon(Rect2(position - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size), tool_type, alpha)

    if label_alpha > 0.0:
        var tool_name: String = "HAMMER"
        if tool_type == ToolType.TRANSFORM:
            tool_name = "ROTATE / MIRROR"
        elif tool_type == ToolType.RESET:
            tool_name = "RESET"
        var label_rect: Rect2 = Rect2(center + Vector2(-150.0, 108.0), Vector2(300.0, 32.0))
        _text_tracked_center("%s EARNED" % tool_name, label_rect, 12, Color(text_main.r, text_main.g, text_main.b, label_alpha), 2.1)
        if amount > 1:
            _text_center_alpha("+%d" % amount, Rect2(label_rect.position + Vector2(0.0, 27.0), Vector2(label_rect.size.x, 26.0)), 16, accent, label_alpha)


func _draw_all_clear_fx() -> void:
    var t: float = clampf(1.0 - all_clear_fx_time / ALL_CLEAR_FX_DURATION, 0.0, 1.0)
    var appear: float = clampf(t / 0.12, 0.0, 1.0)
    var disappear: float = 1.0 - clampf((t - 0.78) / 0.22, 0.0, 1.0)
    var alpha: float = minf(appear, disappear)
    var center: Vector2 = board_rect.get_center()

    # Slow full-board pulse with a long readable hold.
    var pulse_alpha: float = (0.16 + 0.11 * sin(t * PI * 4.0)) * alpha
    draw_rect(board_rect, Color(all_clear_fx_color.r, all_clear_fx_color.g, all_clear_fx_color.b, pulse_alpha))

    # Crisp confetti squares move gradually so the celebration remains readable.
    for i in range(14):
        var angle: float = float(i) / 14.0 * TAU
        var distance: float = 44.0 + t * (112.0 + float(i % 4) * 12.0)
        var confetti_center: Vector2 = center + Vector2(cos(angle), sin(angle)) * distance
        var confetti_size: float = 5.0 + float(i % 3) * 2.0
        var confetti_color: Color = SHAPE_PALETTES[i % SHAPE_PALETTES.size()]
        draw_rect(Rect2(confetti_center - Vector2.ONE * confetti_size * 0.5, Vector2.ONE * confetti_size), Color(confetti_color.r, confetti_color.g, confetti_color.b, alpha))

    for ring_index in range(2):
        var radius: float = 72.0 + t * (86.0 + float(ring_index) * 26.0)
        draw_arc(center, radius, 0.0, TAU, 40, Color(all_clear_fx_color.r, all_clear_fx_color.g, all_clear_fx_color.b, alpha * (0.44 - float(ring_index) * 0.10)), 2.0, true)

    var pop: float = 1.0 + 0.12 * sin(clampf(t / 0.56, 0.0, 1.0) * PI)
    var width: float = 344.0 * pop
    var title_rect: Rect2 = Rect2(Vector2(center.x - width * 0.5, center.y - 56.0), Vector2(width, 112.0))
    draw_rect(title_rect, Color(0.02, 0.04, 0.05, 0.82 * alpha))
    draw_rect(title_rect, Color(all_clear_fx_color.r, all_clear_fx_color.g, all_clear_fx_color.b, 0.98 * alpha), false, 3.0)
    _text_center_alpha("ALL CLEAR", Rect2(title_rect.position + Vector2(0.0, 7.0), Vector2(title_rect.size.x, 58.0)), 32, text_main, alpha)
    _text_tracked_center("BONUS", Rect2(title_rect.position + Vector2(0.0, 61.0), Vector2(title_rect.size.x, 35.0)), 10, Color(all_clear_fx_color.r, all_clear_fx_color.g, all_clear_fx_color.b, alpha), 1.8)


func _text_center_alpha(text: String, rect: Rect2, font_size: int, color: Color, alpha: float) -> void:
    var faded: Color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))
    _text_center(text, rect, font_size, faded)


func _start_score_animations(clear_result: Dictionary, clear_units: int, multiplier: int, all_clear: bool) -> void:
    clear_fx_cells.clear()
    var cells_value: Variant = clear_result.get("cells", {})
    if cells_value is Dictionary:
        var cells_dict: Dictionary = cells_value as Dictionary
        for pos_value in cells_dict.keys():
            var clear_pos: Vector2i = pos_value
            clear_fx_cells.append(clear_pos)

    if clear_units > 0:
        clear_fx_units = clear_units
        clear_fx_time = CLEAR_FX_DURATION

    if clear_units > 1:
        multi_fx_units = clear_units
        multi_fx_time = MULTI_FX_DURATION

    if multiplier > 1 and clear_units > 0:
        combo_fx_multiplier = multiplier
        combo_fx_time = COMBO_FX_DURATION

    if all_clear:
        all_clear_fx_color = SHAPE_PALETTES[posmod(palette_index + 1, SHAPE_PALETTES.size())]
        all_clear_fx_time = ALL_CLEAR_FX_DURATION


func _draw_game_over() -> void:
    var overlay: Rect2 = board_rect.grow(5.0)
    draw_rect(overlay, Color(0.03, 0.04, 0.05, 0.88))
    draw_rect(overlay, danger, false, 2.0)
    _text_center("GAME OVER", Rect2(Vector2(overlay.position.x, overlay.get_center().y - 55.0), Vector2(overlay.size.x, 44.0)), 31, text_main)
    _text_center("Score  %s" % _format_score(score), Rect2(Vector2(overlay.position.x, overlay.get_center().y + 2.0), Vector2(overlay.size.x, 35.0)), 18, _current_shape_color())
    _text_center("HOME → NEW GAME", Rect2(Vector2(overlay.position.x, overlay.get_center().y + 48.0), Vector2(overlay.size.x, 28.0)), 11, text_dim)


func _draw_crisp_cell(rect: Rect2, color: Color, alpha: float) -> void:
    if rect.size.x <= 1.0 or rect.size.y <= 1.0:
        return

    # Brighter glass treatment matching the concept: sharp cyan-tinted rim,
    # stronger upper-left bevel, luminous face, and a clean deep lower shadow.
    var tile: Rect2 = Rect2(rect.position.round(), rect.size.round())
    var shadow_offset: float = clampf(round(tile.size.y * 0.075), 1.0, 3.0)
    draw_rect(Rect2(tile.position + Vector2(0.0, shadow_offset), tile.size), Color(0.0, 0.0, 0.0, 0.42 * alpha))

    # Soft outer light without blurring the exact tile edge.
    var rim_glow: Color = color.lightened(0.24)
    rim_glow.a = 0.18 * alpha
    draw_rect(tile.grow(1.5), rim_glow, false, 1.0)

    var edge: Color = color.darkened(0.34)
    edge.a = 0.98 * alpha
    draw_rect(tile, edge)

    var bevel: float = clampf(round(minf(tile.size.x, tile.size.y) * 0.11), 2.0, 5.0)
    var inner: Rect2 = tile.grow(-bevel)
    var top_bevel: Color = color.lightened(0.56)
    var left_bevel: Color = color.lightened(0.29)
    var bottom_bevel: Color = color.darkened(0.42)
    var right_bevel: Color = color.darkened(0.29)
    top_bevel.a = alpha
    left_bevel.a = alpha
    bottom_bevel.a = alpha
    right_bevel.a = alpha

    draw_colored_polygon(PackedVector2Array([tile.position, Vector2(tile.end.x, tile.position.y), Vector2(inner.end.x, inner.position.y), inner.position]), top_bevel)
    draw_colored_polygon(PackedVector2Array([tile.position, inner.position, Vector2(inner.position.x, inner.end.y), Vector2(tile.position.x, tile.end.y)]), left_bevel)
    draw_colored_polygon(PackedVector2Array([Vector2(inner.position.x, inner.end.y), inner.end, tile.end, Vector2(tile.position.x, tile.end.y)]), bottom_bevel)
    draw_colored_polygon(PackedVector2Array([Vector2(inner.end.x, inner.position.y), Vector2(tile.end.x, tile.position.y), tile.end, inner.end]), right_bevel)

    var face_top: Color = color.lightened(0.31)
    var face_bottom: Color = color.darkened(0.06)
    face_top.a = alpha
    face_bottom.a = alpha
    var face_points: PackedVector2Array = PackedVector2Array([
        inner.position,
        Vector2(inner.end.x, inner.position.y),
        inner.end,
        Vector2(inner.position.x, inner.end.y),
    ])
    draw_polygon(face_points, PackedColorArray([face_top, face_top, face_bottom, face_bottom]))

    # Broad glass reflection across the upper third, plus a razor-bright top lip.
    var sheen_bottom_y: float = inner.position.y + inner.size.y * 0.40
    var sheen_top: Color = Color(1.0, 1.0, 1.0, 0.24 * alpha)
    var sheen_clear: Color = Color(1.0, 1.0, 1.0, 0.0)
    draw_polygon(
        PackedVector2Array([
            inner.position,
            Vector2(inner.end.x, inner.position.y),
            Vector2(inner.end.x, sheen_bottom_y),
            Vector2(inner.position.x, sheen_bottom_y),
        ]),
        PackedColorArray([sheen_top, sheen_top, sheen_clear, sheen_clear])
    )
    draw_line(inner.position + Vector2(1.0, 1.0), Vector2(inner.end.x - 1.0, inner.position.y + 1.0), Color(1.0, 1.0, 1.0, 0.76 * alpha), 1.0)
    draw_line(inner.position + Vector2(1.0, 1.0), Vector2(inner.position.x + 1.0, inner.end.y - 1.0), Color(0.78, 0.94, 1.0, 0.34 * alpha), 1.0)
    draw_rect(tile, Color(0.69, 0.91, 1.0, 0.70 * alpha), false, 1.0)


func _current_shape_color() -> Color:
    return SHAPE_PALETTES[posmod(palette_index, SHAPE_PALETTES.size())]


func _cell_rect(x: int, y: int) -> Rect2:
    return Rect2(board_rect.position + Vector2(float(x) * cell_size, float(y) * cell_size), Vector2(cell_size, cell_size))


func _piece_bounds(piece: Dictionary) -> Vector2i:
    var max_x: int = 0
    var max_y: int = 0
    var cells: Array = piece["cells"] as Array
    for cell_value in cells:
        var cell: Vector2i = cell_value
        max_x = maxi(max_x, cell.x)
        max_y = maxi(max_y, cell.y)
    return Vector2i(max_x + 1, max_y + 1)


func _drag_anchor(pos: Vector2, piece: Dictionary) -> Vector2i:
    var bounds: Vector2i = _piece_bounds(piece)
    var piece_px: Vector2 = Vector2(float(bounds.x) * cell_size, float(bounds.y) * cell_size)
    var top_left: Vector2 = pos - piece_px * 0.5
    var local: Vector2 = top_left - board_rect.position
    return Vector2i(int(round(local.x / cell_size)), int(round(local.y / cell_size)))


func _piece_drag_center(pos: Vector2, piece: Dictionary) -> Vector2:
    # Blockudoku-style lift: the pointer/finger sits just below the selected
    # shape instead of covering it. Apply this to mouse and touch so desktop
    # testing matches the phone interaction exactly.
    var bounds: Vector2i = _piece_bounds(piece)
    var half_height: float = float(bounds.y) * cell_size * 0.5
    return pos + Vector2(0.0, -half_height - PIECE_DRAG_POINTER_GAP)


func _can_place(piece: Dictionary, anchor: Vector2i) -> bool:
    if not piece.has("cells") or not (piece["cells"] is Array):
        return false
    var cells: Array = piece["cells"] as Array
    if cells.is_empty():
        return false
    for cell_value in cells:
        if not (cell_value is Vector2i):
            return false
        var cell: Vector2i = cell_value
        var x: int = anchor.x + cell.x
        var y: int = anchor.y + cell.y
        if x < 0 or x >= BOARD_SIZE or y < 0 or y >= BOARD_SIZE:
            return false
        if y >= board.size() or not (board[y] is Array):
            return false
        var board_row: Array = board[y] as Array
        if x >= board_row.size() or int(board_row[x]) >= 0:
            return false
    return true


func _normalize_cells(cells: Array) -> Array:
    var min_x: int = 999
    var min_y: int = 999
    for cell_value in cells:
        var cell: Vector2i = cell_value
        min_x = mini(min_x, cell.x)
        min_y = mini(min_y, cell.y)
    var normalized: Array = []
    for cell_value in cells:
        var cell: Vector2i = cell_value
        normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
    return normalized


func _rotate_cells(cells: Array, clockwise: bool) -> Array:
    var rotated: Array = []
    for cell_value in cells:
        var cell: Vector2i = cell_value
        if clockwise:
            rotated.append(Vector2i(-cell.y, cell.x))
        else:
            rotated.append(Vector2i(cell.y, -cell.x))
    return _normalize_cells(rotated)


func _shape_signature(cells: Array) -> String:
    var keys: Array[String] = []
    var normalized: Array = _normalize_cells(cells)
    for cell_value in normalized:
        var cell: Vector2i = cell_value
        keys.append("%d,%d" % [cell.x, cell.y])
    keys.sort()
    return ";".join(keys)


func _piece_can_transform(piece: Dictionary) -> bool:
    if not piece.has("cells") or not (piece["cells"] is Array):
        return false
    return _unique_transformations(piece["cells"] as Array).size() > 1

func _apply_transform_action(index: int) -> void:
    if index < 0 or index >= pieces.size() or index != transform_piece_index:
        return
    var piece: Dictionary = pieces[index] as Dictionary
    if bool(piece.get("used", true)) or not _piece_can_transform(piece):
        return
    var cells: Array = piece["cells"] as Array
    if transform_step == 3:
        pieces[index]["cells"] = _mirror_cells(cells)
        transform_step = 0
        last_message = "Mirrored shape · next tap rotates."
    else:
        pieces[index]["cells"] = _rotate_cells(cells, true)
        transform_step += 1
        last_message = "Rotated 90° · %s next." % ("mirror" if transform_step == 3 else "rotate")
    tool_player.stream = TRANSFORM_STREAM
    _play_sfx(tool_player)
    _save_state()
    _arm_input_guard()
    queue_redraw()

func _piece_has_any_transform_fit(piece: Dictionary) -> bool:
    if not piece.has("cells") or not (piece["cells"] is Array):
        return false
    for cells_value in _unique_transformations(piece["cells"] as Array):
        var test_piece: Dictionary = {"cells": (cells_value as Array), "used": false}
        if _piece_has_any_fit(test_piece):
            return true
    return false

func _piece_has_any_fit(piece: Dictionary) -> bool:
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            if _can_place(piece, Vector2i(x, y)):
                return true
    return false


func _place_piece(index: int, anchor: Vector2i) -> void:
    if index < 0 or index >= pieces.size():
        return
    var piece: Dictionary = pieces[index] as Dictionary
    if bool(piece.get("used", true)) or not _can_place(piece, anchor):
        return
    var cells: Array = piece["cells"] as Array

    for cell_value in cells:
        var c: Vector2i = cell_value
        board[anchor.y + c.y][anchor.x + c.x] = palette_index

    pieces[index]["used"] = true
    pieces[index]["destroyed"] = false

    if not run_test_mode and not run_counted_in_games:
        run_counted_in_games = true
        lifetime_games_played += 1

    if transform_piece_index == index:
        transform_piece_index = -1
        transform_step = 0
        transform_gesture_active = false
    place_player.stream = PLACE_STREAM
    _play_sfx(place_player)

    if not all_clear_armed and _occupied_cell_count() >= ALL_CLEAR_REARM_OCCUPANCY:
        all_clear_armed = true

    var clear_result: Dictionary = _find_clear_result()
    var clear_units: int = int(clear_result["units"])
    _update_combo(clear_units)
    _capture_clear_ghosts(clear_result)
    _collect_tools_from_clear_result(clear_result)
    _apply_clear_result(clear_result)

    var board_cleared: bool = clear_units > 0 and _board_is_empty()
    var all_clear_awarded: bool = board_cleared and all_clear_armed
    if all_clear_awarded:
        all_clear_armed = false
    _start_score_animations(clear_result, clear_units, score_multiplier, all_clear_awarded)

    var scored_points: int = _calculate_move_score(cells.size(), clear_units, score_multiplier, all_clear_awarded)
    score += scored_points
    last_move_score = scored_points
    _set_score_gain_components(cells.size(), clear_units, score_multiplier, all_clear_awarded)
    score_gain_fx_time = SCORE_GAIN_FX_DURATION
    _queue_board_tool_pickups_for_score()

    if not run_test_mode:
        lifetime_total_score += scored_points
        lifetime_cells_placed += cells.size()
        lifetime_total_clears += clear_units
        lifetime_rows_cleared += int(clear_result.get("rows", 0))
        lifetime_columns_cleared += int(clear_result.get("columns", 0))
        lifetime_boxes_cleared += int(clear_result.get("boxes", 0))
        if all_clear_awarded:
            lifetime_all_clears += 1
        lifetime_best_score = maxi(lifetime_best_score, score)
        lifetime_highest_combo = maxi(lifetime_highest_combo, score_multiplier)
        lifetime_largest_multi_clear = maxi(lifetime_largest_multi_clear, clear_units)

    if board_cleared:
        palette_index = posmod(palette_index + 1, SHAPE_PALETTES.size())

    if clear_units > 0:
        clear_player.stream = CLEAR_BOX_STREAM if bool(clear_result["had_box"]) else CLEAR_LINE_STREAM
        _play_sfx(clear_player)

    var message_parts: Array[String] = []
    if clear_units > 0:
        message_parts.append("%d clear%s" % [clear_units, "s" if clear_units != 1 else ""])
    if score_multiplier > 1:
        message_parts.append("x%d combo" % score_multiplier)
    if all_clear_awarded:
        message_parts.append("ALL CLEAR")
    elif board_cleared:
        message_parts.append("ALL CLEAR · bonus recharging")
    last_message = "  ·  ".join(message_parts)

    _refresh_offerings_if_needed()
    _check_game_over()
    _save_state()
    _save_profile()
    _arm_input_guard()
    queue_redraw()

func _update_combo(clear_units: int) -> void:
    var previous_multiplier: int = score_multiplier
    if clear_units > 0:
        if consecutive_clear_count <= 0:
            score_multiplier = maxi(1, clear_units)
        else:
            score_multiplier += clear_units
        consecutive_clear_count += 1
        combo_fx_previous_multiplier = previous_multiplier
        combo_fx_multiplier = score_multiplier
        combo_fx_delta = maxi(0, score_multiplier - previous_multiplier)
    else:
        consecutive_clear_count = 0
        score_multiplier = 1
        if previous_multiplier > 1:
            combo_reset_from_multiplier = previous_multiplier
            combo_reset_fx_time = COMBO_RESET_FX_DURATION


func _clear_bonus_base(clear_units: int) -> int:
    if clear_units <= 0:
        return 0
    if clear_units == 1:
        return 10
    return clear_units * 100

func _calculate_move_score(placement_cells: int, clear_units: int, multiplier: int, all_clear_bonus: bool) -> int:
    var clear_bonus: int = _clear_bonus_base(clear_units) * maxi(1, multiplier)
    return placement_cells + clear_bonus + (1000 if all_clear_bonus else 0)

func _set_score_gain_components(placement_cells: int, clear_units: int, multiplier: int, all_clear_bonus: bool) -> void:
    score_gain_components.clear()
    if placement_cells > 0:
        score_gain_components.append({"label": "+%d" % placement_cells, "accent": 0})
    var clear_base: int = _clear_bonus_base(clear_units)
    if clear_base > 0:
        var clear_label: String = "+%d" % clear_base
        if multiplier > 1:
            clear_label += " ×%d" % multiplier
        score_gain_components.append({"label": clear_label, "accent": 1})
    if all_clear_bonus:
        score_gain_components.append({"label": "+1000", "accent": 2})


func _find_clear_result() -> Dictionary:
    var to_clear: Dictionary = {}
    var units: int = 0
    var row_units: int = 0
    var column_units: int = 0
    var box_units: int = 0
    var had_line: bool = false
    var had_box: bool = false

    for row_index in range(BOARD_SIZE):
        var full_row: bool = true
        for x in range(BOARD_SIZE):
            if int(board[row_index][x]) < 0:
                full_row = false
                break
        if full_row:
            units += 1
            row_units += 1
            had_line = true
            for row_x in range(BOARD_SIZE):
                to_clear[Vector2i(row_x, row_index)] = true

    for col_index in range(BOARD_SIZE):
        var full_col: bool = true
        for y in range(BOARD_SIZE):
            if int(board[y][col_index]) < 0:
                full_col = false
                break
        if full_col:
            units += 1
            column_units += 1
            had_line = true
            for col_y in range(BOARD_SIZE):
                to_clear[Vector2i(col_index, col_y)] = true

    for box_y in range(3):
        for box_x in range(3):
            var full_box: bool = true
            for dy in range(3):
                for dx in range(3):
                    if int(board[box_y * 3 + dy][box_x * 3 + dx]) < 0:
                        full_box = false
                        break
                if not full_box:
                    break
            if full_box:
                units += 1
                box_units += 1
                had_box = true
                for clear_dy in range(3):
                    for clear_dx in range(3):
                        to_clear[Vector2i(box_x * 3 + clear_dx, box_y * 3 + clear_dy)] = true

    return {
        "cells": to_clear,
        "units": units,
        "rows": row_units,
        "columns": column_units,
        "boxes": box_units,
        "had_line": had_line,
        "had_box": had_box,
    }


func _find_clear_result_with_piece(piece: Dictionary, anchor: Vector2i) -> Dictionary:
    var preview_cells: Dictionary = {}
    for cell_value in piece["cells"] as Array:
        var cell: Vector2i = cell_value
        preview_cells[Vector2i(anchor.x + cell.x, anchor.y + cell.y)] = true

    var to_clear: Dictionary = {}
    var units: int = 0
    var had_line: bool = false
    var had_box: bool = false

    for row_index in range(BOARD_SIZE):
        var full_row: bool = true
        for x in range(BOARD_SIZE):
            if int(board[row_index][x]) < 0 and not preview_cells.has(Vector2i(x, row_index)):
                full_row = false
                break
        if full_row:
            units += 1
            had_line = true
            for row_x in range(BOARD_SIZE):
                to_clear[Vector2i(row_x, row_index)] = true

    for col_index in range(BOARD_SIZE):
        var full_col: bool = true
        for y in range(BOARD_SIZE):
            if int(board[y][col_index]) < 0 and not preview_cells.has(Vector2i(col_index, y)):
                full_col = false
                break
        if full_col:
            units += 1
            had_line = true
            for col_y in range(BOARD_SIZE):
                to_clear[Vector2i(col_index, col_y)] = true

    for box_y in range(3):
        for box_x in range(3):
            var full_box: bool = true
            for dy in range(3):
                for dx in range(3):
                    var pos: Vector2i = Vector2i(box_x * 3 + dx, box_y * 3 + dy)
                    if int(board[pos.y][pos.x]) < 0 and not preview_cells.has(pos):
                        full_box = false
                        break
                if not full_box:
                    break
            if full_box:
                units += 1
                had_box = true
                for clear_dy in range(3):
                    for clear_dx in range(3):
                        to_clear[Vector2i(box_x * 3 + clear_dx, box_y * 3 + clear_dy)] = true

    return {
        "cells": to_clear,
        "units": units,
        "had_line": had_line,
        "had_box": had_box,
    }


func _capture_clear_ghosts(clear_result: Dictionary) -> void:
    clear_fx_ghosts.clear()
    var cleared_value: Variant = clear_result.get("cells", {})
    if not (cleared_value is Dictionary):
        return
    var to_clear: Dictionary = cleared_value as Dictionary
    var had_box: bool = bool(clear_result.get("had_box", false))
    var had_line: bool = bool(clear_result.get("had_line", false))
    var average: Vector2 = Vector2.ZERO
    if not to_clear.is_empty():
        for pos_value in to_clear.keys():
            var average_pos: Vector2i = pos_value
            average += Vector2(average_pos)
        average /= float(to_clear.size())

    for pos_value in to_clear.keys():
        var pos: Vector2i = pos_value
        var palette_value: int = int(board[pos.y][pos.x])
        var ghost_color: Color = SHAPE_PALETTES[posmod(palette_value if palette_value >= 0 else palette_index, SHAPE_PALETTES.size())]
        var delay: float
        if had_box and not had_line:
            delay = clampf(Vector2(pos).distance_to(average) / 6.0, 0.0, 1.0) * 0.18
        else:
            delay = (float(pos.x + pos.y) / float((BOARD_SIZE - 1) * 2)) * 0.22
        clear_fx_ghosts.append({
            "pos": pos,
            "color": ghost_color,
            "delay": delay,
        })


func _apply_clear_result(clear_result: Dictionary) -> void:
    var cleared_value: Variant = clear_result.get("cells", {})
    if not (cleared_value is Dictionary):
        return
    var to_clear: Dictionary = cleared_value as Dictionary
    for pos_value in to_clear.keys():
        var pos: Vector2i = pos_value
        if pos.y >= 0 and pos.y < board.size() and board[pos.y] is Array:
            var row: Array = board[pos.y] as Array
            if pos.x >= 0 and pos.x < row.size():
                row[pos.x] = -1

func _board_is_empty() -> bool:
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            if int(board[y][x]) >= 0:
                return false
    return true


func _occupied_cell_count() -> int:
    var occupied: int = 0
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            if int(board[y][x]) >= 0:
                occupied += 1
    return occupied


func _board_tool_interval() -> int:
    return TEST_BOARD_TOOL_INTERVAL if run_test_mode else NORMAL_BOARD_TOOL_INTERVAL

func _board_pickup_key(pos: Vector2i) -> String:
    return "%d,%d" % [pos.x, pos.y]

func _sanitize_board_tool_pickups() -> void:
    var cleaned: Dictionary = {}
    for key_value in board_tool_pickups.keys():
        var key: String = String(key_value)
        var parts: PackedStringArray = key.split(",")
        if parts.size() != 2:
            continue
        var x: int = int(parts[0])
        var y: int = int(parts[1])
        if x < 0 or x >= BOARD_SIZE or y < 0 or y >= BOARD_SIZE:
            continue
        if y >= board.size() or not (board[y] is Array) or x >= (board[y] as Array).size() or int(board[y][x]) < 0:
            continue
        cleaned[_board_pickup_key(Vector2i(x, y))] = clampi(int(board_tool_pickups[key_value]), ToolType.HAMMER, ToolType.RESET)
    board_tool_pickups = cleaned

func _queue_board_tool_pickups_for_score() -> void:
    var interval: int = _board_tool_interval()
    while score >= next_board_tool_score:
        pending_board_tool_pickups += 1
        next_board_tool_score += interval
    _spawn_pending_board_tool_pickups()

func _spawn_pending_board_tool_pickups() -> void:
    if pending_board_tool_pickups <= 0:
        return
    var candidates: Array[Vector2i] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            if int(board[y][x]) < 0:
                continue
            var pos := Vector2i(x, y)
            if not board_tool_pickups.has(_board_pickup_key(pos)):
                candidates.append(pos)
    candidates.shuffle()
    while pending_board_tool_pickups > 0 and not candidates.is_empty():
        var pos: Vector2i = candidates.pop_back()
        board_tool_pickups[_board_pickup_key(pos)] = randi_range(ToolType.HAMMER, ToolType.RESET)
        pending_board_tool_pickups -= 1

func _grant_tool(tool_type: int, amount: int = 1) -> void:
    if amount <= 0:
        return
    match tool_type:
        ToolType.HAMMER:
            hammer_count += amount
        ToolType.TRANSFORM:
            transform_count += amount
        ToolType.RESET:
            reset_count += amount
        _:
            return
    _trigger_tool_earn(tool_type, amount)

func _collect_tools_from_clear_result(clear_result: Dictionary) -> void:
    var cleared_value: Variant = clear_result.get("cells", {})
    if not (cleared_value is Dictionary):
        return
    var earned: Array[int] = [0, 0, 0]
    for pos_value in (cleared_value as Dictionary).keys():
        var pos: Vector2i = pos_value
        var key: String = _board_pickup_key(pos)
        if board_tool_pickups.has(key):
            var tool_type: int = clampi(int(board_tool_pickups[key]), ToolType.HAMMER, ToolType.RESET)
            earned[tool_type] += 1
            board_tool_pickups.erase(key)
    for tool_type in range(earned.size()):
        if earned[tool_type] > 0:
            _grant_tool(tool_type, earned[tool_type])

func _trigger_tool_earn(tool_type: int, amount: int = 1) -> void:
    if tool_type < 0 or tool_type >= tool_hidden_reward_counts.size() or amount <= 0:
        return
    if not run_test_mode:
        if tool_type == ToolType.HAMMER:
            lifetime_hammers_earned += amount
        elif tool_type == ToolType.TRANSFORM:
            lifetime_transforms_earned += amount
        elif tool_type == ToolType.RESET:
            lifetime_resets_earned += amount
    tool_hidden_reward_counts[tool_type] += amount
    for queue_index in range(tool_reward_queue.size()):
        var queued_reward: Dictionary = tool_reward_queue[queue_index] as Dictionary
        if int(queued_reward.get("tool_type", -1)) == tool_type:
            queued_reward["amount"] = int(queued_reward.get("amount", 0)) + amount
            tool_reward_queue[queue_index] = queued_reward
            return
    tool_reward_queue.append({"tool_type": tool_type, "amount": amount})
    _wake_processing()

func _start_next_tool_reward() -> void:
    if not active_tool_reward.is_empty() or tool_reward_queue.is_empty():
        return
    active_tool_reward = tool_reward_queue.pop_front()
    tool_reward_fx_duration = TEST_TOOL_REWARD_FX_DURATION if run_test_mode else TOOL_REWARD_FX_DURATION
    tool_reward_fx_time = tool_reward_fx_duration


func _finish_active_tool_reward() -> void:
    if active_tool_reward.is_empty():
        return
    var tool_type: int = int(active_tool_reward.get("tool_type", -1))
    var amount: int = int(active_tool_reward.get("amount", 0))
    if tool_type >= 0 and tool_type < tool_hidden_reward_counts.size():
        tool_hidden_reward_counts[tool_type] = maxi(0, tool_hidden_reward_counts[tool_type] - amount)
        tool_counter_pop_time[tool_type] = TOOL_COUNTER_POP_DURATION
    active_tool_reward.clear()
    tool_reward_fx_time = 0.0


func _use_hammer_on_piece(index: int) -> bool:
    if hammer_count <= 0 or index < 0 or index >= pieces.size():
        return false
    var piece: Dictionary = pieces[index] as Dictionary
    if bool(piece.get("used", true)):
        return false

    hammer_count -= 1
    if not run_test_mode:
        lifetime_hammers_used += 1
    pieces[index]["used"] = true
    pieces[index]["destroyed"] = true
    if transform_piece_index == index:
        transform_piece_index = -1
        transform_step = 0
        transform_gesture_active = false
    dragging_piece = -1
    tool_player.stream = HAMMER_STREAM
    _play_sfx(tool_player)

    var refreshes_set: bool = _all_pieces_used()
    _refresh_offerings_if_needed()
    last_message = "Shape destroyed%s." % (" · new set ready" if refreshes_set else "")
    _check_game_over()
    _save_state()
    _save_profile()
    _arm_input_guard()
    queue_redraw()
    return true

func _use_transform_on_piece(index: int) -> bool:
    if index < 0 or index >= pieces.size():
        return false
    if transform_piece_index >= 0:
        last_message = "Rotate/Mirror already active on another shape."
        queue_redraw()
        return false
    if transform_count <= 0:
        return false
    var piece: Dictionary = pieces[index] as Dictionary
    if bool(piece.get("used", true)) or not _piece_can_transform(piece):
        return false

    transform_count -= 1
    if not run_test_mode:
        lifetime_transforms_used += 1
    transform_piece_index = index
    transform_step = 0
    transform_gesture_active = false
    tool_player.stream = TRANSFORM_STREAM
    _play_sfx(tool_player)
    last_message = "Rotate/Mirror ready · tap 3× rotate, 4th tap mirrors · drag to place."
    _check_game_over()
    _save_state()
    _save_profile()
    _arm_input_guard()
    queue_redraw()
    return true

func _use_reset_tool() -> bool:
    if reset_count <= 0:
        return false

    var occupied_entries: Array[Dictionary] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            var value: int = int(board[y][x])
            if value < 0:
                continue
            var pos := Vector2i(x, y)
            occupied_entries.append({
                "value": value,
                "tool": int(board_tool_pickups.get(_board_pickup_key(pos), -1)),
            })
    if occupied_entries.is_empty():
        return false

    reset_count -= 1
    if not run_test_mode:
        lifetime_resets_used += 1
    tool_player.stream = RESET_STREAM
    _play_sfx(tool_player)

    var all_positions: Array[Vector2i] = []
    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            all_positions.append(Vector2i(x, y))
    all_positions.shuffle()
    occupied_entries.shuffle()

    for y in range(BOARD_SIZE):
        for x in range(BOARD_SIZE):
            board[y][x] = -1
    board_tool_pickups.clear()
    for i in range(occupied_entries.size()):
        var pos: Vector2i = all_positions[i]
        var entry: Dictionary = occupied_entries[i]
        board[pos.y][pos.x] = int(entry.get("value", palette_index))
        var tool_type: int = int(entry.get("tool", -1))
        if tool_type >= ToolType.HAMMER and tool_type <= ToolType.RESET:
            board_tool_pickups[_board_pickup_key(pos)] = tool_type

    if not all_clear_armed and occupied_entries.size() >= ALL_CLEAR_REARM_OCCUPANCY:
        all_clear_armed = true

    var clear_result: Dictionary = _find_clear_result()
    var clear_units: int = int(clear_result.get("units", 0))
    _update_combo(clear_units)
    _capture_clear_ghosts(clear_result)
    _collect_tools_from_clear_result(clear_result)
    _apply_clear_result(clear_result)

    var board_cleared: bool = clear_units > 0 and _board_is_empty()
    var all_clear_awarded: bool = board_cleared and all_clear_armed
    if all_clear_awarded:
        all_clear_armed = false
    _start_score_animations(clear_result, clear_units, score_multiplier, all_clear_awarded)

    var scored_points: int = _calculate_move_score(0, clear_units, score_multiplier, all_clear_awarded)
    if scored_points > 0:
        score += scored_points
        _set_score_gain_components(0, clear_units, score_multiplier, all_clear_awarded)
        score_gain_fx_time = SCORE_GAIN_FX_DURATION
        _queue_board_tool_pickups_for_score()
    last_move_score = scored_points

    if not run_test_mode:
        lifetime_total_score += scored_points
        lifetime_total_clears += clear_units
        lifetime_rows_cleared += int(clear_result.get("rows", 0))
        lifetime_columns_cleared += int(clear_result.get("columns", 0))
        lifetime_boxes_cleared += int(clear_result.get("boxes", 0))
        if all_clear_awarded:
            lifetime_all_clears += 1
        lifetime_best_score = maxi(lifetime_best_score, score)
        lifetime_highest_combo = maxi(lifetime_highest_combo, score_multiplier)
        lifetime_largest_multi_clear = maxi(lifetime_largest_multi_clear, clear_units)

    if board_cleared:
        palette_index = posmod(palette_index + 1, SHAPE_PALETTES.size())
    if clear_units > 0:
        clear_player.stream = CLEAR_BOX_STREAM if bool(clear_result.get("had_box", false)) else CLEAR_LINE_STREAM
        _play_sfx(clear_player)

    var message_parts: Array[String] = ["Board reset"]
    if clear_units > 0:
        message_parts.append("%d clear%s" % [clear_units, "s" if clear_units != 1 else ""])
    if score_multiplier > 1:
        message_parts.append("x%d combo" % score_multiplier)
    if all_clear_awarded:
        message_parts.append("ALL CLEAR")
    last_message = "  ·  ".join(message_parts)

    _check_game_over()
    _save_state()
    _save_profile()
    _arm_input_guard()
    queue_redraw()
    return true

func _has_transformable_unused_piece() -> bool:
    for piece_value in pieces:
        var piece: Dictionary = piece_value as Dictionary
        if not bool(piece.get("used", true)) and _piece_can_transform(piece):
            return true
    return false

func _has_unused_piece() -> bool:
    for piece_value in pieces:
        var piece: Dictionary = piece_value as Dictionary
        if not bool(piece["used"]):
            return true
    return false


func _all_pieces_used() -> bool:
    for piece_value in pieces:
        var piece: Dictionary = piece_value as Dictionary
        if not bool(piece["used"]):
            return false
    return true


func _refresh_offerings_if_needed() -> void:
    if _all_pieces_used():
        transform_piece_index = -1
        transform_step = 0
        transform_gesture_active = false
        _generate_pieces()

func _check_game_over() -> void:
    var was_game_over: bool = game_over

    for piece_value in pieces:
        var piece: Dictionary = piece_value as Dictionary
        if bool(piece.get("used", true)):
            continue
        if _piece_has_any_fit(piece):
            game_over = false
            return

    if transform_piece_index >= 0 and transform_piece_index < pieces.size():
        var active_piece: Dictionary = pieces[transform_piece_index] as Dictionary
        if not bool(active_piece.get("used", true)) and _piece_has_any_transform_fit(active_piece):
            game_over = false
            dragging_piece = -1
            last_message = "No current fit · transform the selected shape."
            return

    # Unspent tools are valid escape routes, so don't end the run until they
    # have no useful action left.
    if transform_count > 0:
        for piece_value in pieces:
            var piece: Dictionary = piece_value as Dictionary
            if not bool(piece.get("used", true)) and _piece_has_any_transform_fit(piece):
                game_over = false
                last_message = "No fit · Rotate/Mirror can still help."
                return
    if reset_count > 0 and _occupied_cell_count() > 0:
        game_over = false
        last_message = "No fit · Reset can reshuffle the board."
        return
    if hammer_count > 0 and _has_unused_piece():
        game_over = false
        last_message = "No fit · Hammer can remove an offered shape."
        return

    game_over = true
    dragging_piece = -1
    dragging_hammer = false
    dragging_transform = false
    dragging_reset = false
    transform_gesture_active = false
    hammer_hover_piece = -1
    transform_hover_piece = -1
    selected_tap_tool = -1
    pending_tool_press = -1
    if not was_game_over:
        _play_sfx(game_over_player)
        _finalize_current_run_history("game_over")
    last_message = "No moves left."
    _save_state()
    _save_profile()

func _return_home() -> void:
    show_new_game_warning = false
    selected_tap_tool = -1
    pending_tool_press = -1
    _refresh_world_rank()
    _reset_animation_state()
    dragging_piece = -1
    dragging_hammer = false
    dragging_transform = false
    dragging_reset = false
    transform_gesture_active = false
    hammer_hover_piece = -1
    transform_hover_piece = -1
    _save_state()
    _save_profile()
    screen_mode = ScreenMode.HOME
    _arm_input_guard()
    queue_redraw()

func _save_state() -> void:
    var data: Dictionary = {
        "version": 45,
        "has_active_run": has_active_run,
        "test_mode_setting": test_mode_setting,
        "light_mode": light_mode,
        "background_enabled": background_enabled,
        "bgm_enabled": bgm_enabled,
        "sfx_enabled": sfx_enabled,
        "next_background_index": next_background_index,
    }
    if has_active_run:
        data["run"] = _serialize_run()
    var serialized: String = JSON.stringify(data)
    if serialized == last_saved_state_json:
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(serialized)
    file.flush()
    file.close()
    last_saved_state_json = serialized
    _mark_web_userfs_dirty()

func _save_profile() -> void:
    var data: Dictionary = {
        "version": 5,
        "games_played": lifetime_games_played,
        "total_score": lifetime_total_score,
        "cells_placed": lifetime_cells_placed,
        "total_clears": lifetime_total_clears,
        "rows_cleared": lifetime_rows_cleared,
        "columns_cleared": lifetime_columns_cleared,
        "boxes_cleared": lifetime_boxes_cleared,
        "all_clears": lifetime_all_clears,
        "best_score": lifetime_best_score,
        "highest_combo": lifetime_highest_combo,
        "largest_multi_clear": lifetime_largest_multi_clear,
        "hammers_earned": lifetime_hammers_earned,
        "hammers_used": lifetime_hammers_used,
        "transforms_earned": lifetime_transforms_earned,
        "transforms_used": lifetime_transforms_used,
        "resets_earned": lifetime_resets_earned,
        "resets_used": lifetime_resets_used,
        "score_history": score_history,
        "player_id": player_id,
        "world_rank": world_rank,
        "world_total_players": world_total_players,
    }
    var serialized: String = JSON.stringify(data)
    if serialized == last_saved_profile_json:
        return
    var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(serialized)
    file.flush()
    file.close()
    last_saved_profile_json = serialized
    _mark_web_userfs_dirty()

func _load_profile() -> void:
    if not FileAccess.file_exists(PROFILE_PATH):
        return
    var file: FileAccess = FileAccess.open(PROFILE_PATH, FileAccess.READ)
    if file == null:
        return
    var raw: String = file.get_as_text()
    file.close()
    last_saved_profile_json = raw
    var parsed: Variant = JSON.parse_string(raw)
    if not (parsed is Dictionary):
        return
    var data: Dictionary = parsed as Dictionary
    lifetime_games_played = maxi(0, int(data.get("games_played", 0)))
    lifetime_total_score = maxi(0, int(data.get("total_score", 0)))
    lifetime_cells_placed = maxi(0, int(data.get("cells_placed", 0)))
    lifetime_total_clears = maxi(0, int(data.get("total_clears", 0)))
    lifetime_rows_cleared = maxi(0, int(data.get("rows_cleared", 0)))
    lifetime_columns_cleared = maxi(0, int(data.get("columns_cleared", 0)))
    lifetime_boxes_cleared = maxi(0, int(data.get("boxes_cleared", 0)))
    lifetime_all_clears = maxi(0, int(data.get("all_clears", 0)))
    lifetime_best_score = maxi(0, int(data.get("best_score", 0)))
    lifetime_highest_combo = maxi(1, int(data.get("highest_combo", 1)))
    lifetime_largest_multi_clear = maxi(0, int(data.get("largest_multi_clear", 0)))
    # v1.37 migration keeps the user's historical tool totals while adopting
    # the new tool names/mechanics.
    lifetime_hammers_earned = maxi(0, int(data.get("hammers_earned", data.get("pickaxes_earned", 0))))
    lifetime_hammers_used = maxi(0, int(data.get("hammers_used", data.get("pickaxes_used", 0))))
    lifetime_transforms_earned = maxi(0, int(data.get("transforms_earned", data.get("rotates_earned", 0))))
    lifetime_transforms_used = maxi(0, int(data.get("transforms_used", data.get("rotates_used", 0))))
    lifetime_resets_earned = maxi(0, int(data.get("resets_earned", data.get("locks_earned", 0))))
    lifetime_resets_used = maxi(0, int(data.get("resets_used", data.get("locks_used", 0))))
    score_history.clear()
    var history_value: Variant = data.get("score_history", [])
    if history_value is Array:
        for item_value in (history_value as Array):
            if item_value is Dictionary:
                var item: Dictionary = item_value as Dictionary
                var history_score: int = maxi(0, int(item.get("score", 0)))
                var history_date: String = String(item.get("date", ""))
                if history_score > 0 and history_date != "":
                    score_history.append({"score": history_score, "date": history_date})
    while score_history.size() > SCORE_HISTORY_LIMIT:
        score_history.pop_front()
    player_id = String(data.get("player_id", ""))
    world_rank = int(data.get("world_rank", -1))
    world_total_players = maxi(0, int(data.get("world_total_players", 0)))

func _ensure_player_id() -> void:
    if player_id != "":
        return
    player_id = "%d-%d-%d" % [int(Time.get_unix_time_from_system()), randi(), randi()]
    _save_profile()

func _today_iso_date() -> String:
    var date: Dictionary = Time.get_date_dict_from_system()
    return "%04d-%02d-%02d" % [int(date.get("year", 1970)), int(date.get("month", 1)), int(date.get("day", 1))]

func _finalize_current_run_history(_reason: String = "finished") -> void:
    if run_test_mode or not run_counted_in_games or run_recorded_in_history:
        return
    run_recorded_in_history = true
    score_history.append({"score": maxi(0, score), "date": _today_iso_date()})
    while score_history.size() > SCORE_HISTORY_LIMIT:
        score_history.pop_front()
    _save_profile()
    _submit_world_score(score)

func _leaderboard_endpoint() -> String:
    return String(ProjectSettings.get_setting("terrablocks/leaderboard_endpoint", "")).strip_edges()

func _setup_leaderboard() -> void:
    leaderboard_request = HTTPRequest.new()
    add_child(leaderboard_request)
    leaderboard_request.request_completed.connect(_on_leaderboard_request_completed)

func _refresh_world_rank() -> void:
    var endpoint: String = _leaderboard_endpoint()
    if endpoint == "" or leaderboard_request == null:
        world_rank_status = "NOT CONNECTED"
        return
    if leaderboard_request_kind != "":
        return
    leaderboard_request_kind = "rank"
    world_rank_status = "UPDATING"
    var separator: String = "&" if endpoint.contains("?") else "?"
    var url: String = endpoint + separator + "player_id=" + player_id.uri_encode()
    var err: Error = leaderboard_request.request(url)
    if err != OK:
        leaderboard_request_kind = ""
        world_rank_status = "OFFLINE"

func _submit_world_score(final_score: int) -> void:
    var endpoint: String = _leaderboard_endpoint()
    if endpoint == "" or leaderboard_request == null:
        return
    if leaderboard_request_kind != "":
        pending_world_score = maxi(pending_world_score, final_score)
        return
    leaderboard_request_kind = "submit"
    var headers: PackedStringArray = PackedStringArray(["Content-Type: application/json"])
    var payload: Dictionary = {
        "player_id": player_id,
        "score": maxi(0, final_score),
        "best_score": lifetime_best_score,
        "date": _today_iso_date(),
        "game_version": LEADERBOARD_VERSION,
    }
    var err: Error = leaderboard_request.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if err != OK:
        leaderboard_request_kind = ""
        world_rank_status = "OFFLINE"

func _on_leaderboard_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var kind: String = leaderboard_request_kind
    leaderboard_request_kind = ""
    if response_code < 200 or response_code >= 300:
        world_rank_status = "OFFLINE"
        queue_redraw()
        return
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
    if parsed is Dictionary:
        var data: Dictionary = parsed as Dictionary
        if data.has("rank"):
            world_rank = maxi(1, int(data.get("rank", 1)))
        if data.has("total_players"):
            world_total_players = maxi(0, int(data.get("total_players", 0)))
        world_rank_status = "ONLINE"
        _save_profile()
    else:
        world_rank_status = "OFFLINE"
    queue_redraw()
    if pending_world_score >= 0:
        var queued_score: int = pending_world_score
        pending_world_score = -1
        _submit_world_score(queued_score)
    elif kind == "submit":
        _refresh_world_rank()

func _mark_web_userfs_dirty() -> void:
    if not OS.has_feature("web"):
        return
    # Browser-owned batching avoids keeping Godot's process loop awake just to
    # count down to IndexedDB persistence.
    JavaScriptBridge.eval(WEB_SYNC_SCHEDULE_SCRIPT, true)


func _flush_web_userfs_sync(_force: bool = false) -> void:
    if not OS.has_feature("web"):
        return
    JavaScriptBridge.eval(WEB_SYNC_SCRIPT, true)


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_state()
        _save_profile()
        _flush_web_userfs_sync(true)
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
        # Native playback may resume immediately. Web waits until the next real
        # gesture because Safari can reject play() calls made from focus events.
        if not OS.has_feature("web"):
            _start_music()
        _wake_processing(true)
        queue_redraw()


func _exit_tree() -> void:
    _save_state()
    _save_profile()
    _flush_web_userfs_sync(true)


func _serialize_run() -> Dictionary:
    var board_data: Array = []
    for row_value in board:
        board_data.append((row_value as Array).duplicate())

    var piece_data: Array = []
    for piece_value in pieces:
        var piece: Dictionary = piece_value as Dictionary
        var serialized_cells: Array = []
        for cell_value in piece["cells"] as Array:
            var cell: Vector2i = cell_value
            serialized_cells.append([cell.x, cell.y])
        piece_data.append({
            "cells": serialized_cells,
            "used": bool(piece.get("used", false)),
            "destroyed": bool(piece.get("destroyed", false)),
        })

    return {
        "board": board_data,
        "pieces": piece_data,
        "score": score,
        "last_move_score": last_move_score,
        "consecutive_clear_count": consecutive_clear_count,
        "score_multiplier": score_multiplier,
        "run_counted_in_games": run_counted_in_games,
        "run_recorded_in_history": run_recorded_in_history,
        "hammer_count": hammer_count,
        "transform_count": transform_count,
        "reset_count": reset_count,
        "next_board_tool_score": next_board_tool_score,
        "pending_board_tool_pickups": pending_board_tool_pickups,
        "board_tool_pickups": board_tool_pickups,
        "transform_piece_index": transform_piece_index,
        "transform_step": transform_step,
        "palette_index": palette_index,
        "all_clear_armed": all_clear_armed,
        "run_test_mode": run_test_mode,
        "active_background_index": active_background_index,
        "last_message": last_message,
    }

func _load_save_file() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var raw: String = file.get_as_text()
    file.close()
    last_saved_state_json = raw

    var parsed: Variant = JSON.parse_string(raw)
    if not (parsed is Dictionary):
        return
    var data: Dictionary = parsed as Dictionary
    test_mode_setting = bool(data.get("test_mode_setting", false))
    light_mode = bool(data.get("light_mode", false))
    background_enabled = bool(data.get("background_enabled", true))
    bgm_enabled = bool(data.get("bgm_enabled", true))
    sfx_enabled = bool(data.get("sfx_enabled", true))
    next_background_index = maxi(0, int(data.get("next_background_index", 0)))
    _apply_audio_settings()
    _apply_theme_palette()
    has_active_run = bool(data.get("has_active_run", false))
    if not has_active_run:
        return

    var run_value: Variant = data.get("run", {})
    if not (run_value is Dictionary):
        has_active_run = false
        return
    if not _deserialize_run(run_value as Dictionary):
        has_active_run = false
    elif not run_test_mode and score > lifetime_best_score:
        lifetime_best_score = score
        _save_profile()


func _deserialize_run(data: Dictionary) -> bool:
    var board_value: Variant = data.get("board", [])
    var pieces_value: Variant = data.get("pieces", [])
    if not (board_value is Array) or not (pieces_value is Array):
        return false

    var loaded_board: Array = board_value as Array
    if loaded_board.size() != BOARD_SIZE:
        return false
    board.clear()
    for row_value in loaded_board:
        if not (row_value is Array):
            return false
        var source_row: Array = row_value as Array
        if source_row.size() != BOARD_SIZE:
            return false
        var row: Array = []
        for cell_value in source_row:
            var old_value: int = int(cell_value)
            row.append(-1 if old_value < 0 else posmod(old_value, SHAPE_PALETTES.size()))
        board.append(row)

    var loaded_pieces: Array = pieces_value as Array
    if loaded_pieces.size() != 3:
        return false
    pieces.clear()
    for piece_value in loaded_pieces:
        if not (piece_value is Dictionary):
            return false
        var source_piece: Dictionary = piece_value as Dictionary
        var cells_value: Variant = source_piece.get("cells", [])
        if not (cells_value is Array):
            return false
        var cells: Array = []
        var loaded_cells: Array = cells_value as Array
        if loaded_cells.is_empty() or loaded_cells.size() > 5:
            return false
        for pair_value in loaded_cells:
            if not (pair_value is Array):
                return false
            var pair: Array = pair_value as Array
            if pair.size() < 2:
                return false
            var cell_x: int = int(pair[0])
            var cell_y: int = int(pair[1])
            if cell_x < 0 or cell_x >= BOARD_SIZE or cell_y < 0 or cell_y >= BOARD_SIZE:
                return false
            cells.append(Vector2i(cell_x, cell_y))
        pieces.append({
            "cells": cells,
            "used": bool(source_piece.get("used", false)),
            "destroyed": bool(source_piece.get("destroyed", false)),
        })

    score = maxi(0, int(data.get("score", 0)))
    last_move_score = maxi(0, int(data.get("last_move_score", 0)))
    consecutive_clear_count = maxi(0, int(data.get("consecutive_clear_count", 0)))
    score_multiplier = maxi(1, int(data.get("score_multiplier", 1)))
    run_test_mode = bool(data.get("run_test_mode", false))
    active_background_index = maxi(0, int(data.get("active_background_index", 0)))
    if data.has("run_counted_in_games"):
        run_counted_in_games = bool(data.get("run_counted_in_games", false))
    else:
        run_counted_in_games = not run_test_mode
    if run_test_mode:
        run_counted_in_games = false
    run_recorded_in_history = bool(data.get("run_recorded_in_history", false))
    if run_test_mode:
        run_recorded_in_history = true

    # Tool-count migration keeps existing inventory, while v1.41 replaces
    # all automatic tool earning with board pickups every score interval.
    hammer_count = maxi(0, int(data.get("hammer_count", data.get("pickaxe_count", 0))))
    transform_count = maxi(0, int(data.get("transform_count", data.get("rotate_count", data.get("screwdriver_count", 0)))))
    reset_count = maxi(0, int(data.get("reset_count", data.get("lock_count", 0))))
    var board_tool_interval: int = _board_tool_interval()
    var inferred_next_tool_score: int = (int(floor(float(score) / float(board_tool_interval))) + 1) * board_tool_interval
    next_board_tool_score = maxi(board_tool_interval, int(data.get("next_board_tool_score", inferred_next_tool_score)))
    pending_board_tool_pickups = maxi(0, int(data.get("pending_board_tool_pickups", 0)))
    board_tool_pickups.clear()
    var pickup_value: Variant = data.get("board_tool_pickups", {})
    if pickup_value is Dictionary:
        for pickup_key_value in (pickup_value as Dictionary).keys():
            var pickup_key: String = String(pickup_key_value)
            var pickup_tool: int = clampi(int((pickup_value as Dictionary)[pickup_key_value]), ToolType.HAMMER, ToolType.RESET)
            board_tool_pickups[pickup_key] = pickup_tool
    _sanitize_board_tool_pickups()

    transform_piece_index = int(data.get("transform_piece_index", data.get("rotation_piece_index", -1)))
    transform_step = clampi(int(data.get("transform_step", 0)), 0, 3)

    palette_index = posmod(int(data.get("palette_index", 0)), SHAPE_PALETTES.size())
    all_clear_armed = bool(data.get("all_clear_armed", false))
    last_message = String(data.get("last_message", "Run resumed."))

    game_over = false
    dragging_piece = -1
    dragging_hammer = false
    dragging_transform = false
    dragging_reset = false
    transform_gesture_active = false
    hammer_hover_piece = -1
    transform_hover_piece = -1
    selected_tap_tool = -1
    pending_tool_press = -1
    pending_tool_press_start = Vector2.ZERO
    if transform_piece_index < 0 or transform_piece_index >= pieces.size() or bool((pieces[transform_piece_index] as Dictionary).get("used", true)):
        transform_piece_index = -1
        transform_step = 0
    shape_family_bag.clear()
    shape_orientation_bags.clear()
    _reset_animation_state()
    _check_game_over()
    return true

func _arm_input_guard(duration_ms: int = INPUT_ACTION_GUARD_MS) -> void:
    input_guard_until_msec = int(Time.get_ticks_msec()) + maxi(0, duration_ms)


func _input_guard_active() -> bool:
    return int(Time.get_ticks_msec()) < input_guard_until_msec


func _is_guarded_press_event(event: InputEvent) -> bool:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        # Godot marks the second press of a desktop double-click explicitly.
        if event.double_click:
            return true
        return _input_guard_active()
    if event is InputEventScreenTouch and event.pressed:
        return _input_guard_active()
    return false


func _gui_input(event: InputEvent) -> void:
    # Passive pointer motion must not wake the engine. Real drags keep the same
    # responsive cadence, but ordinary hover no longer re-arms processing or
    # recomputes layout/index state.
    if event is InputEventMouseMotion:
        if not _drag_animation_active():
            return
        _wake_processing(true)
        _handle_pointer_move(event.position, false)
        return

    if event is InputEventScreenDrag:
        if not _drag_animation_active():
            return
        _wake_processing(true)
        _handle_pointer_move(event.position, true)
        return

    # Press/release events can actually change game state, so geometry and
    # interaction indices are refreshed once here rather than on every motion.
    _wake_processing(true)
    _update_layout()
    _sanitize_interaction_indices()
    if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
        _ensure_music_after_user_gesture()

    # Ignore the accidental second press of a rapid double-click/tap after a
    # state-changing action. Releases still flow through so drag state cannot
    # get stuck.
    if _is_guarded_press_event(event):
        return

    if screen_mode == ScreenMode.HOME:
        _handle_home_input(event)
        return
    if screen_mode == ScreenMode.STATS:
        _handle_stats_input(event)
        return
    if screen_mode == ScreenMode.SETTINGS:
        _handle_settings_input(event)
        return

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _handle_pointer_press(event.position, false)
        else:
            _handle_pointer_release(event.position, false)
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _handle_pointer_press(event.position, true)
        else:
            _handle_pointer_release(event.position, true)


func _handle_home_input(event: InputEvent) -> void:
    var pos: Vector2 = Vector2.ZERO
    var pressed: bool = false
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
        pressed = event.pressed
    elif event is InputEventScreenTouch:
        pos = event.position
        pressed = event.pressed
    else:
        return

    if not pressed:
        return

    if show_new_game_warning:
        if warning_confirm_rect.has_point(pos):
            _finalize_current_run_history("abandoned")
            _new_game()
        elif warning_cancel_rect.has_point(pos):
            show_new_game_warning = false
            _arm_input_guard()
            queue_redraw()
        return

    if theme_toggle_rect.has_point(pos):
        _toggle_theme()
        return

    if home_settings_rect.has_point(pos):
        screen_mode = ScreenMode.SETTINGS
        _arm_input_guard()
        queue_redraw()
        return

    if home_test_mode_rect.has_point(pos):
        test_mode_setting = not test_mode_setting
        _save_state()
        _arm_input_guard()
        queue_redraw()
        return

    if home_new_game_rect.has_point(pos):
        if has_active_run:
            show_new_game_warning = true
            _arm_input_guard()
            queue_redraw()
        else:
            _new_game()
        return

    if home_continue_rect.has_point(pos) and has_active_run:
        screen_mode = ScreenMode.GAME
        last_message = "Run resumed."
        _arm_input_guard()
        queue_redraw()
        return

    if home_stats_rect.has_point(pos):
        screen_mode = ScreenMode.STATS
        _arm_input_guard()
        queue_redraw()


func _handle_settings_input(event: InputEvent) -> void:
    var pos: Vector2 = Vector2.ZERO
    var pressed: bool = false
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
        pressed = event.pressed
    elif event is InputEventScreenTouch:
        pos = event.position
        pressed = event.pressed
    else:
        return
    if not pressed:
        return

    if home_rect.has_point(pos):
        screen_mode = ScreenMode.HOME
        _arm_input_guard()
        queue_redraw()
        return

    if home_background_toggle_rect.has_point(pos):
        background_enabled = not background_enabled
        _save_state()
        _arm_input_guard()
        queue_redraw()
        return

    if home_bgm_toggle_rect.has_point(pos):
        bgm_enabled = not bgm_enabled
        _apply_audio_settings()
        if bgm_enabled:
            _ensure_music_after_user_gesture()
        _save_state()
        _arm_input_guard()
        queue_redraw()
        return

    if home_sfx_toggle_rect.has_point(pos):
        sfx_enabled = not sfx_enabled
        _apply_audio_settings()
        _save_state()
        _arm_input_guard()
        queue_redraw()
        return


func _handle_stats_input(event: InputEvent) -> void:
    var pos: Vector2 = Vector2.ZERO
    var pressed: bool = false
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        pos = event.position
        pressed = event.pressed
    elif event is InputEventScreenTouch:
        pos = event.position
        pressed = event.pressed
    else:
        return
    if not pressed:
        return
    if home_rect.has_point(pos):
        screen_mode = ScreenMode.HOME
        _refresh_world_rank()
        _arm_input_guard()
        queue_redraw()
        return
    if theme_toggle_rect.has_point(pos):
        _toggle_theme()
        return
    if stats_overview_tab_rect.has_point(pos):
        stats_tab = 0
        _arm_input_guard()
        queue_redraw()
        return
    if stats_scores_tab_rect.has_point(pos):
        stats_tab = 1
        _arm_input_guard()
        queue_redraw()


func _handle_pointer_move(pos: Vector2, is_touch: bool = false) -> void:
    if is_touch:
        pointer_is_touch = true
    mouse_pos = pos

    if pending_tool_press >= 0:
        if pos.distance_to(pending_tool_press_start) >= TOOL_TAP_DRAG_THRESHOLD:
            var tool_type: int = pending_tool_press
            pending_tool_press = -1
            selected_tap_tool = -1
            if tool_type == ToolType.HAMMER:
                dragging_hammer = true
                _update_hammer_hover(pos)
                last_message = "Drag Hammer to an offered shape."
            elif tool_type == ToolType.TRANSFORM:
                dragging_transform = true
                _update_transform_hover(pos)
                last_message = "Drag Rotate/Mirror to an offered shape."
            elif tool_type == ToolType.RESET:
                dragging_reset = true
                last_message = "Drag Reset onto the board."
            queue_redraw()
        return

    if dragging_hammer:
        _update_hammer_hover(pos)
        queue_redraw()
        return
    if dragging_transform:
        _update_transform_hover(pos)
        queue_redraw()
        return
    if dragging_reset:
        queue_redraw()
        return
    if transform_gesture_active:
        _update_transform_gesture(pos)
        return
    if dragging_piece >= 0:
        queue_redraw()

func _toggle_tap_tool(tool_type: int) -> void:
    if selected_tap_tool == tool_type:
        selected_tap_tool = -1
        last_message = "Tool selection cancelled."
    else:
        selected_tap_tool = tool_type
        if tool_type == ToolType.HAMMER:
            last_message = "Hammer Mode · select an offered shape."
        elif tool_type == ToolType.TRANSFORM:
            last_message = "Rotate/Mirror Mode · select an offered shape."
        elif tool_type == ToolType.RESET:
            last_message = "Reset Mode · tap the board."
    queue_redraw()

func _handle_pointer_press(pos: Vector2, is_touch: bool = false) -> void:
    pointer_is_touch = is_touch
    mouse_pos = pos
    if theme_toggle_rect.has_point(pos):
        selected_tap_tool = -1
        _toggle_theme()
        return
    if home_rect.has_point(pos):
        selected_tap_tool = -1
        _return_home()
        return

    if selected_tap_tool >= 0 and tool_cancel_rect.has_point(pos):
        selected_tap_tool = -1
        pending_tool_press = -1
        last_message = "Tool selection cancelled."
        _arm_input_guard()
        queue_redraw()
        return

    if hammer_tool_rect.has_point(pos):
        if hammer_count > 0 and _has_unused_piece():
            pending_tool_press = ToolType.HAMMER
            pending_tool_press_start = pos
            dragging_piece = -1
            transform_gesture_active = false
        else:
            selected_tap_tool = -1
            last_message = "No Hammers available."
        queue_redraw()
        return

    if transform_tool_rect.has_point(pos):
        if transform_piece_index >= 0:
            selected_tap_tool = -1
            last_message = "Rotate/Mirror is already active on a shape."
        elif transform_count > 0 and _has_transformable_unused_piece():
            pending_tool_press = ToolType.TRANSFORM
            pending_tool_press_start = pos
            dragging_piece = -1
            transform_gesture_active = false
        else:
            selected_tap_tool = -1
            last_message = "No usable Rotate/Mirror tools available."
        queue_redraw()
        return

    if reset_tool_rect.has_point(pos):
        if reset_count > 0 and _occupied_cell_count() > 0:
            pending_tool_press = ToolType.RESET
            pending_tool_press_start = pos
            dragging_piece = -1
            dragging_hammer = false
            dragging_transform = false
            dragging_reset = false
            transform_gesture_active = false
        else:
            selected_tap_tool = -1
            last_message = "Reset needs a non-empty board."
        queue_redraw()
        return

    if game_over:
        selected_tap_tool = -1
        return

    # Tap-selected tools act on their highlighted target. Reset targets the board;
    # Hammer / Rotate-Mirror target one of the offered shapes.
    if selected_tap_tool == ToolType.RESET:
        if board_rect.has_point(pos):
            selected_tap_tool = -1
            if _use_reset_tool():
                return
        # Missed taps no longer exit Tool Mode. Use the explicit X (or tap the
        # selected tool card again) when cancellation is intended.
        queue_redraw()
        return

    if selected_tap_tool >= 0:
        for i in range(mini(piece_rects.size(), pieces.size())):
            if not piece_rects[i].has_point(pos):
                continue
            var selected_piece: Dictionary = pieces[i] as Dictionary
            if bool(selected_piece.get("used", true)):
                break
            if selected_tap_tool == ToolType.HAMMER:
                selected_tap_tool = -1
                _use_hammer_on_piece(i)
                return
            if selected_tap_tool == ToolType.TRANSFORM and _piece_can_transform(selected_piece):
                selected_tap_tool = -1
                _use_transform_on_piece(i)
                return
            break
        # Keep Tool Mode active after a missed/invalid tap; the dedicated X is
        # the explicit cancellation affordance.
        queue_redraw()
        return

    if transform_piece_index >= 0 and transform_piece_index < pieces.size() and transform_piece_index < piece_rects.size() and piece_rects[transform_piece_index].has_point(pos):
        var transform_piece: Dictionary = pieces[transform_piece_index] as Dictionary
        if not bool(transform_piece.get("used", true)):
            transform_gesture_active = true
            transform_gesture_start = pos
            dragging_piece = -1
            queue_redraw()
            return

    for i in range(mini(piece_rects.size(), pieces.size())):
        var piece: Dictionary = pieces[i] as Dictionary
        if piece_rects[i].has_point(pos) and not bool(piece.get("used", true)):
            dragging_piece = i
            dragging_hammer = false
            dragging_transform = false
            dragging_reset = false
            transform_gesture_active = false
            queue_redraw()
            return

func _handle_pointer_release(pos: Vector2, is_touch: bool = false) -> void:
    if is_touch:
        pointer_is_touch = true
    mouse_pos = pos

    if pending_tool_press >= 0:
        var tool_type: int = pending_tool_press
        pending_tool_press = -1
        pointer_is_touch = false
        _toggle_tap_tool(tool_type)
        return

    if dragging_hammer:
        _update_hammer_hover(pos)
        var target_piece: int = hammer_hover_piece
        dragging_hammer = false
        pointer_is_touch = false
        hammer_hover_piece = -1
        if target_piece >= 0:
            _use_hammer_on_piece(target_piece)
            return
        last_message = "Hammer returned."
        queue_redraw()
        return

    if dragging_transform:
        _update_transform_hover(pos)
        var target_piece: int = transform_hover_piece
        dragging_transform = false
        pointer_is_touch = false
        transform_hover_piece = -1
        if target_piece >= 0 and _use_transform_on_piece(target_piece):
            return
        last_message = "Rotate/Mirror returned."
        queue_redraw()
        return

    if dragging_reset:
        var on_board: bool = board_rect.has_point(pos)
        dragging_reset = false
        pointer_is_touch = false
        if on_board and _use_reset_tool():
            return
        last_message = "Reset returned."
        queue_redraw()
        return

    if transform_gesture_active:
        transform_gesture_active = false
        pointer_is_touch = false
        _apply_transform_action(transform_piece_index)
        return

    if dragging_piece >= 0:
        var index: int = dragging_piece
        dragging_piece = -1
        pointer_is_touch = false
        if index < 0 or index >= pieces.size():
            queue_redraw()
            return
        var piece: Dictionary = pieces[index] as Dictionary
        if bool(piece.get("used", true)):
            queue_redraw()
            return
        var anchor: Vector2i = _drag_anchor(_piece_drag_center(pos, piece), piece)
        if _can_place(piece, anchor):
            _place_piece(index, anchor)
        else:
            queue_redraw()
    pointer_is_touch = false

func _update_hammer_hover(pos: Vector2) -> void:
    hammer_hover_piece = -1
    for i in range(mini(piece_rects.size(), pieces.size())):
        var piece: Dictionary = pieces[i] as Dictionary
        if piece_rects[i].has_point(pos) and not bool(piece.get("used", true)):
            hammer_hover_piece = i
            return

func _update_transform_hover(pos: Vector2) -> void:
    transform_hover_piece = -1
    for i in range(mini(piece_rects.size(), pieces.size())):
        var piece: Dictionary = pieces[i] as Dictionary
        if piece_rects[i].has_point(pos) and not bool(piece.get("used", true)) and _piece_can_transform(piece):
            transform_hover_piece = i
            return

func _update_transform_gesture(pos: Vector2) -> void:
    if transform_piece_index < 0 or transform_piece_index >= pieces.size():
        transform_gesture_active = false
        return
    var delta: Vector2 = pos - transform_gesture_start
    if delta.length() >= 14.0:
        dragging_piece = transform_piece_index
        transform_gesture_active = false
        mouse_pos = pos
        queue_redraw()

func _format_score(value: int) -> String:
    var negative: bool = value < 0
    var digits: String = str(absi(value))
    var formatted: String = ""
    while digits.length() > 3:
        formatted = "," + digits.right(3) + formatted
        digits = digits.left(digits.length() - 3)
    formatted = digits + formatted
    return "-" + formatted if negative else formatted


func _text(text: String, pos: Vector2, font_size: int, color: Color) -> void:
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _text_with_font(text: String, pos: Vector2, font_size: int, color: Color, custom_font: Font) -> void:
    draw_string(custom_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _tracked_text_width(text: String, font_size: int, tracking: float) -> float:
    var width: float = 0.0
    for character_index in range(text.length()):
        var character: String = text.substr(character_index, 1)
        width += font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
        if character_index < text.length() - 1:
            width += tracking
    return width


func _text_tracked(text: String, pos: Vector2, font_size: int, color: Color, tracking: float) -> void:
    var cursor_x: float = pos.x
    for character_index in range(text.length()):
        var character: String = text.substr(character_index, 1)
        draw_string(font, Vector2(cursor_x, pos.y), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
        cursor_x += font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + tracking


func _text_tracked_center(text: String, rect: Rect2, font_size: int, color: Color, tracking: float) -> void:
    var text_width: float = _tracked_text_width(text, font_size, tracking)
    var font_height: float = font.get_height(font_size)
    var baseline_y: float = rect.position.y + (rect.size.y - font_height) * 0.5 + font.get_ascent(font_size)
    var baseline: Vector2 = Vector2(rect.position.x + (rect.size.x - text_width) * 0.5, baseline_y)
    _text_tracked(text, baseline, font_size, color, tracking)


func _text_center(text: String, rect: Rect2, font_size: int, color: Color) -> void:
    # Font ascent/height gives much more reliable visual centering than using
    # the glyph bounding box, especially for all-caps dialog and combo text.
    var font_height: float = font.get_height(font_size)
    var baseline_y: float = rect.position.y + (rect.size.y - font_height) * 0.5 + font.get_ascent(font_size)
    draw_string(font, Vector2(rect.position.x, baseline_y), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)
