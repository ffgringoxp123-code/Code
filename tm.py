import sys
import time
import threading
import ctypes
import ctypes.wintypes
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QPushButton, QLabel, QSlider, QListWidget, QListWidgetItem,
    QLineEdit, QAbstractItemView
)
from PyQt6.QtCore import (
    Qt, QTimer, pyqtSignal, QObject, QRectF,
    QPoint, QSize
)
from PyQt6.QtGui import (
    QPainter, QColor, QPen, QPainterPath, QRegion, QLinearGradient,
    QFont, QFontMetrics, QBrush
)

def get_active_window_process():
    try:
        hwnd = ctypes.windll.user32.GetForegroundWindow()
        pid = ctypes.wintypes.DWORD()
        ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        PROCESS_QUERY_LIMITED = 0x1000
        handle = ctypes.windll.kernel32.OpenProcess(PROCESS_QUERY_LIMITED, False, pid.value)
        if not handle:
            return ""
        buf = ctypes.create_unicode_buffer(260)
        size = ctypes.wintypes.DWORD(260)
        ctypes.windll.kernel32.QueryFullProcessImageNameW(handle, 0, buf, ctypes.byref(size))
        ctypes.windll.kernel32.CloseHandle(handle)
        return buf.value
    except:
        return ""

def is_roblox_focused():
    exe = get_active_window_process().lower()
    return "robloxplayer" in exe

class Bridge(QObject):
    toggle     = pyqtSignal()
    hold_start = pyqtSignal()
    hold_stop  = pyqtSignal()

bridge = Bridge()
mouse_ctrl = None
try:
    from pynput.mouse import Button, Controller
    from pynput import keyboard as kb_module
    mouse_ctrl = Controller()
except ImportError:
    pass

clicking  = False
cps       = 250
hold_mode = False
current_bind = {"type": "key", "value": "e", "label": "E"}
_key_held    = False
BIND_CATALOGUE = []

def _add(label, typ, val):
    BIND_CATALOGUE.append({"label": label, "type": typ, "value": val})

_add("Mouse Left",    "mouse", "left")
_add("Mouse Right",   "mouse", "right")
_add("Mouse Middle",  "mouse", "middle")
_add("Mouse Side 1",  "mouse", "x1")
_add("Mouse Side 2",  "mouse", "x2")
for ch in "abcdefghijklmnopqrstuvwxyz":
    _add(ch.upper(), "key", ch)
for d in "0123456789":
    _add(d, "key", d)
for i in range(1, 13):
    _add(f"F{i}", "key_special", f"f{i}")
_specials = [
    ("Space",      "space"),
    ("Enter",      "enter"),
    ("Tab",        "tab"),
    ("Backspace",  "backspace"),
    ("Delete",     "delete"),
    ("Escape",     "esc"),
    ("Insert",     "insert"),
    ("Home",       "home"),
    ("End",        "end"),
    ("Page Up",    "page_up"),
    ("Page Down",  "page_down"),
    ("Up",         "up"),
    ("Down",       "down"),
    ("Left",       "left"),
    ("Right",      "right"),
    ("Caps Lock",  "caps_lock"),
    ("Shift",      "shift"),
    ("Ctrl",       "ctrl"),
    ("Alt",        "alt"),
    ("Num Lock",   "num_lock"),
    ("Scroll Lock","scroll_lock"),
    ("Print Scr",  "print_screen"),
    ("Pause",      "pause"),
    ("Menu",       "menu"),
]
for label, val in _specials:
    _add(label, "key_special", val)
for i in range(10):
    _add(f"Num {i}", "key", str(i))
_puncts = [
    ("`",  "`"),  ("~",  "~"),  ("-",  "-"),  ("_",  "_"),
    ("=",  "="),  ("+",  "+"),  ("[",  "["),  ("{",  "{"),
    ("]",  "]"),  ("}",  "}"),  ("\\", "\\"), ("|",  "|"),
    (";",  ";"),  (":",  ":"),  ("'",  "'"),  ('"',  '"'),
    (",",  ","),  ("<",  "<"),  (".",  "."),  (">",  ">"),
    ("/",  "/"),  ("?",  "?"),  ("@",  "@"),  ("#",  "#"),
    ("$",  "$"),  ("%",  "%"),  ("^",  "^"),  ("&",  "&"),
    ("*",  "*"),  ("(",  "("),  (")",  ")"),
]
for label, val in _puncts:
    _add(label, "key", val)

_qpc_freq = ctypes.c_int64(0)
ctypes.windll.kernel32.QueryPerformanceFrequency(ctypes.byref(_qpc_freq))
_freq = _qpc_freq.value

def _qpc():
    val = ctypes.c_int64(0)
    ctypes.windll.kernel32.QueryPerformanceCounter(ctypes.byref(val))
    return val.value / _freq

def click_loop():
    ctypes.windll.winmm.timeBeginPeriod(1)
    click_count = 0
    start_time = _qpc()
    while True:
        if clicking and is_roblox_focused() and mouse_ctrl:
            target_time = start_time + (click_count * (1.0 / max(cps, 1)))
            now = _qpc()
            if now >= target_time:
                mouse_ctrl.click(Button.left)
                click_count += 1
                if now - target_time > 0.005:
                    click_count = int((now - start_time) * cps) + 1
        else:
            click_count = 0
            start_time = _qpc()
            time.sleep(0.001)
        if not clicking or not is_roblox_focused():
            time.sleep(0.001)

def _key_matches(key):
    b = current_bind
    if b["type"] == "key":
        try:
            return key.char == b["value"]
        except AttributeError:
            return False
    elif b["type"] == "key_special":
        try:
            return key.name == b["value"]
        except AttributeError:
            return False
    return False

def _mouse_matches(btn):
    b = current_bind
    if b["type"] != "mouse":
        return False
    return btn.name == b["value"]

def on_key_press(key):
    global _key_held
    if not is_roblox_focused():
        return
    if _key_matches(key):
        if hold_mode:
            if not _key_held:
                _key_held = True
                bridge.hold_start.emit()
        else:
            bridge.toggle.emit()

def on_key_release(key):
    global _key_held
    if _key_matches(key):
        if hold_mode and _key_held:
            _key_held = False
            bridge.hold_stop.emit()

def on_mouse_press(x, y, btn, pressed):
    global _key_held
    if not is_roblox_focused():
        return
    if _mouse_matches(btn):
        if pressed:
            if hold_mode:
                if not _key_held:
                    _key_held = True
                    bridge.hold_start.emit()
            else:
                bridge.toggle.emit()
        else:
            if hold_mode and _key_held:
                _key_held = False
                bridge.hold_stop.emit()

if mouse_ctrl:
    threading.Thread(target=click_loop, daemon=True).start()
    kb_listener = kb_module.Listener(on_press=on_key_press, on_release=on_key_release)
    kb_listener.daemon = True
    kb_listener.start()

    from pynput import mouse as mouse_module
    ms_listener = mouse_module.Listener(on_click=on_mouse_press)
    ms_listener.daemon = True
    ms_listener.start()

class HLine(QWidget):
    def __init__(self, color="#3a1f5c"):
        super().__init__()
        self.setFixedHeight(1)
        self._color = color
    def paintEvent(self, e):
        p = QPainter(self)
        p.setPen(QPen(QColor(self._color), 1))
        p.drawLine(0, 0, self.width(), 0)

class BindPicker(QWidget):
    bind_chosen = pyqtSignal(dict)

    def __init__(self, parent=None):
        super().__init__(parent, Qt.WindowType.Popup | Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground, True)
        self.setFixedSize(180, 260)
        self._build()

    def _build(self):
        lay = QVBoxLayout(self)
        lay.setContentsMargins(6, 6, 6, 6)
        lay.setSpacing(4)
        self.search = QLineEdit()
        self.search.setPlaceholderText("Search…")
        self.search.setObjectName("bindSearch")
        self.search.textChanged.connect(self._filter)
        lay.addWidget(self.search)
        self.lst = QListWidget()
        self.lst.setObjectName("bindList")
        self.lst.setSelectionMode(QAbstractItemView.SelectionMode.SingleSelection)
        self.lst.itemClicked.connect(self._pick)
        lay.addWidget(self.lst)
        self._populate("")

    def _populate(self, filt):
        self.lst.clear()
        filt = filt.lower()
        for entry in BIND_CATALOGUE:
            if filt and filt not in entry["label"].lower():
                continue
            item = QListWidgetItem(entry["label"])
            item.setData(Qt.ItemDataRole.UserRole, entry)
            self.lst.addItem(item)

    def _filter(self, text):
        self._populate(text)

    def _pick(self, item):
        self.bind_chosen.emit(item.data(Qt.ItemDataRole.UserRole))
        self.hide()

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        path = QPainterPath()
        path.addRoundedRect(QRectF(self.rect()), 10, 10)
        grad = QLinearGradient(0, 0, self.width(), self.height())
        grad.setColorAt(0.0, QColor("#1a0e2e"))
        grad.setColorAt(1.0, QColor("#100a1c"))
        p.fillPath(path, grad)
        p.setPen(QPen(QColor("#a855f7"), 1.5))
        p.drawPath(path)

    def showAt(self, global_pos: QPoint):
        self.search.clear()
        self._populate("")
        self.move(global_pos.x(), global_pos.y() - self.height() - 4)
        self.show()
        self.search.setFocus()

RADIUS = 14

class AnimatedTitleLabel(QWidget):
    """Draws text filled with a gradient that continuously drifts across it."""

    _COLORS = ["#e879f9", "#c084fc", "#818cf8", "#a855f7", "#f0abfc", "#e879f9"]

    def __init__(self, text, parent=None):
        super().__init__(parent)
        self._text = text
        self._offset = 0.0
        self._font = QFont("Consolas", 15, QFont.Weight.Black)
        self._font.setLetterSpacing(QFont.SpacingType.AbsoluteSpacing, 3)
        fm = QFontMetrics(self._font)
        self._text_w = fm.horizontalAdvance(self._text)
        self.setFixedSize(self._text_w + 8, fm.height() + 4)
        self._timer = QTimer(self)
        self._timer.timeout.connect(self._animate)
        self._timer.start(33)

    def _animate(self):
        self._offset = (self._offset + 0.012) % 1.0
        self.update()

    def sizeHint(self):
        return QSize(self._text_w + 8, self.height())

    def paintEvent(self, e):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        fm = QFontMetrics(self._font)
        path = QPainterPath()
        path.addText(2, fm.ascent() + 2, self._font, self._text)



        span = self._text_w * 0.8
        start_x = -span + self._offset * span * 2
        grad = QLinearGradient(start_x, 0, start_x + span, 0)
        n = len(self._COLORS)
        for i, c in enumerate(self._COLORS):
            grad.setColorAt(i / (n - 1), QColor(c))
        grad.setSpread(QLinearGradient.Spread.RepeatSpread)

        p.fillPath(path, QBrush(grad))

class ChickenWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Turbo macro")
        self.setFixedSize(340, 250)
        self.setStyleSheet(self._stylesheet())
        self.setWindowFlags(
            Qt.WindowType.Window |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.WindowCloseButtonHint |
            Qt.WindowType.WindowMinimizeButtonHint |
            Qt.WindowType.FramelessWindowHint
        )
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating, True)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground, True)
        self._drag_pos = None
        self._build_ui()

        bridge.toggle.connect(self._toggle)
        bridge.hold_start.connect(self._hold_start)
        bridge.hold_stop.connect(self._hold_stop)

        self._focus_timer = QTimer()
        self._focus_timer.timeout.connect(self._check_focus)
        self._focus_timer.start(200)

    def mousePressEvent(self, e):
        if e.button() == Qt.MouseButton.LeftButton:
            self._drag_pos = e.globalPosition().toPoint() - self.frameGeometry().topLeft()

    def mouseMoveEvent(self, e):
        if self._drag_pos and e.buttons() == Qt.MouseButton.LeftButton:
            self.move(e.globalPosition().toPoint() - self._drag_pos)

    def mouseReleaseEvent(self, e):
        self._drag_pos = None

    def _build_ui(self):
        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)
        title_bar = QWidget()
        title_bar.setObjectName("titleBar")
        title_bar.setFixedHeight(42)
        tb = QHBoxLayout(title_bar)
        tb.setContentsMargins(16, 0, 12, 0)

        title = AnimatedTitleLabel("TURBO MACRO")
        tb.addWidget(title)
        tb.addStretch()

        self.state_text = QLabel("INACTIVE")
        self.state_text.setObjectName("stateText")
        tb.addWidget(self.state_text)

        close_btn = QPushButton("✕")
        close_btn.setObjectName("closeBtn")
        close_btn.setFixedSize(22, 22)
        close_btn.clicked.connect(self.close)
        tb.addWidget(close_btn)

        root.addWidget(title_bar)
        root.addWidget(HLine("#3a1f5c"))
        body = QWidget()
        body.setObjectName("body")
        body_lay = QVBoxLayout(body)
        body_lay.setContentsMargins(16, 12, 16, 12)
        body_lay.setSpacing(10)

        cps_row = QHBoxLayout()
        cps_lbl = QLabel("CPS")
        cps_lbl.setObjectName("rowLabel")
        self.cps_val = QLabel("250")
        self.cps_val.setObjectName("cpsVal")
        cps_row.addWidget(cps_lbl)
        cps_row.addStretch()
        cps_row.addWidget(self.cps_val)
        body_lay.addLayout(cps_row)

        self.slider = QSlider(Qt.Orientation.Horizontal)
        self.slider.setMinimum(1)
        self.slider.setMaximum(1000)
        self.slider.setValue(250)
        self.slider.setObjectName("cpsSlider")
        self.slider.setFixedHeight(26)
        self.slider.valueChanged.connect(self._on_slider)
        body_lay.addWidget(self.slider)

        body_lay.addWidget(HLine("#3a1f5c"))

        key_row = QHBoxLayout()
        key_lbl = QLabel("TOGGLE KEY")
        key_lbl.setObjectName("rowLabel")
        self.key_badge = QPushButton("E")
        self.key_badge.setObjectName("keyBadge")

        self.key_badge.setFixedSize(30, 30)
        self.key_badge.clicked.connect(self._open_picker)
        key_row.addWidget(key_lbl)
        key_row.addStretch()
        key_row.addWidget(self.key_badge)
        body_lay.addLayout(key_row)

        body_lay.addWidget(HLine("#3a1f5c"))

        mode_row = QHBoxLayout()
        mode_lbl = QLabel("MODE")
        mode_lbl.setObjectName("rowLabel")
        self.mode_btn = QPushButton("TOGGLE")
        self.mode_btn.setObjectName("modeBtn")
        self.mode_btn.setFixedHeight(26)
        self.mode_btn.setCheckable(True)
        self.mode_btn.setChecked(False)
        self.mode_btn.clicked.connect(self._on_mode_toggle)
        mode_row.addWidget(mode_lbl)
        mode_row.addStretch()
        mode_row.addWidget(self.mode_btn)
        body_lay.addLayout(mode_row)

        root.addWidget(body)

        self._picker = BindPicker(self)
        self._picker.bind_chosen.connect(self._apply_bind)
        self._picker.hide()

    def _open_picker(self):
        btn_global = self.key_badge.mapToGlobal(QPoint(0, 0))
        self._picker.showAt(btn_global)

    def _apply_bind(self, entry: dict):
        global current_bind, clicking, _key_held
        current_bind = entry
        _key_held = False
        clicking = False
        self.key_badge.setText(entry["label"])
        self._update_state()

    def _on_slider(self, val):
        global cps
        cps = val
        self.cps_val.setText(str(val))

    def _on_mode_toggle(self, checked):
        global hold_mode, clicking
        hold_mode = checked
        if not hold_mode and clicking:
            clicking = False
        self.mode_btn.setText("HOLD" if checked else "TOGGLE")
        self._update_state()

    def _toggle(self):
        global clicking
        clicking = not clicking
        self._update_state()

    def _hold_start(self):
        global clicking
        clicking = True
        self._update_state()

    def _hold_stop(self):
        global clicking
        clicking = False
        self._update_state()

    def _check_focus(self):
        self._update_state()

    def _update_state(self):
        focused = is_roblox_focused()
        if clicking and focused:
            self._set_state("ACTIVE", "active")
        else:
            self._set_state("INACTIVE", "inactive")

    def _set_state(self, text, mode):
        colors = {"inactive": "#ff4d8d", "active": "#c084fc"}
        color = colors.get(mode, "#ff4d8d")
        self.state_text.setStyleSheet(
            f"color: {color}; font-size:14px; letter-spacing:2px; font-weight:900;"
        )
        self.state_text.setText(text)

    def _stylesheet(self):
        return """
        QWidget {
            background-color: transparent;
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 13px;
            font-weight: 700;
            color: #f0e6ff;
        }
        QWidget#titleBar {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #2b0f4d, stop:0.5 #4c1d95, stop:1 #7e22ce);
            border-top-left-radius: 14px;
            border-top-right-radius: 14px;
        }
        QWidget#body {
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #1e0f38, stop:1 #150a24);
            border-bottom-left-radius: 14px;
            border-bottom-right-radius: 14px;
        }
        QLabel#title {
            font-size: 18px;
            font-weight: 900;
            letter-spacing: 4px;
            color: #f3e8ff;
        }
        QPushButton#closeBtn {
            background: transparent;
            border: none;
            color: #c9a6ff;
            font-size: 16px;
            font-weight: bold;
        }
        QPushButton#closeBtn:hover { color: #ff6ec7; }
        QLabel#rowLabel {
            font-size: 11px;
            font-weight: 900;
            letter-spacing: 2px;
            color: #c4a6e8;
        }
        QLabel#cpsVal {
            font-size: 16px;
            font-weight: 900;
            color: #e9d5ff;
            letter-spacing: 1px;
        }
        QSlider#cpsSlider::groove:horizontal {
            height: 16px;
            background: #241033;
            border: 1px solid #3a1f5c;
            border-radius: 8px;
        }
        QSlider#cpsSlider::handle:horizontal {
            width: 10px; height: 28px;
            margin: -6px 0;
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #c084fc, stop:1 #e879f9);
            border: 2px solid #a855f7;
            border-radius: 4px;
        }
        QSlider#cpsSlider::sub-page:horizontal {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                stop:0 #6d28d9, stop:0.5 #a855f7, stop:1 #e879f9);
            border: 1px solid #3a1f5c;
            border-radius: 8px;
        }
        QSlider#cpsSlider::add-page:horizontal {
            background: #241033;
            border: 1px solid #3a1f5c;
            border-radius: 8px;
        }
        QPushButton#keyBadge {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #2b0f4d, stop:1 #4c1d95);
            border: 2px solid #a855f7;
            border-radius: 6px;
            color: #f3e8ff;
            font-size: 12px;
            font-weight: 900;
            padding: 0;
            letter-spacing: 1px;
            min-width: 30px;
        }
        QPushButton#keyBadge:hover {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #4c1d95, stop:1 #7e22ce);
            border-color: #c084fc;
        }
        QPushButton#modeBtn {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #2b0f4d, stop:1 #4c1d95);
            border: 2px solid #a855f7;
            border-radius: 4px;
            color: #f3e8ff;
            font-size: 11px;
            font-weight: 900;
            letter-spacing: 2px;
            padding: 3px 12px;
            min-width: 64px;
        }
        QPushButton#modeBtn:hover {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                stop:0 #4c1d95, stop:1 #7e22ce);
        }
        QPushButton#modeBtn:checked {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                stop:0 #6d28d9, stop:1 #a855f7);
            color: #ffffff;
            border-color: #7e22ce;
        }
        QPushButton#modeBtn:checked:hover {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                stop:0 #7e22ce, stop:1 #c084fc);
        }
        QLineEdit#bindSearch {
            background: #1e0f38;
            border: 1px solid #a855f7;
            border-radius: 4px;
            color: #f3e8ff;
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            font-weight: 700;
            padding: 3px 6px;
        }
        QListWidget#bindList {
            background: #150a24;
            border: none;
            color: #c4a6e8;
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 12px;
            font-weight: 700;
            outline: none;
        }
        QListWidget#bindList::item {
            padding: 4px 8px;
            border-radius: 3px;
        }
        QListWidget#bindList::item:hover {
            background: #33204d;
            color: #f3e8ff;
        }
        QListWidget#bindList::item:selected {
            background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                stop:0 #9333ea, stop:1 #d946ef);
            color: #ffffff;
        }
        QScrollBar:vertical {
            background: #1e0f38;
            width: 6px;
            border-radius: 3px;
        }
        QScrollBar::handle:vertical {
            background: qlineargradient(x1:0, y1:0, x2:0, y2:1,
                stop:0 #a855f7, stop:1 #e879f9);
            border-radius: 3px;
            min-height: 20px;
        }
        QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical { height: 0; }
        """

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    win = ChickenWindow()
    win.show()
    sys.exit(app.exec())