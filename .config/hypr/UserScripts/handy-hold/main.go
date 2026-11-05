// handy-hold is hold to talk for Handy: start recording now, stop once every
// key of the combo is released.
//
// Build with: go build -o ~/.local/bin/handy-hold .
//
// It signals the running Handy directly, because starting the AppImage just to
// send --toggle-transcription adds about 250 ms before recording begins.
//
// Hyprland's release binds can't do this job: they don't fire reliably if Ctrl
// or Super comes up before the main key. So it reads the real key state from
// evdev instead, which needs membership of the input group.
//
// It waits for all the keys, not just the first: Handy pastes right after
// stopping, and a paste with Ctrl or Super still down would reach Hyprland's
// binds rather than the window.
//
// SIGUSR2 is a blind toggle, and Handy delays or drops it while transcribing. A
// lost signal swaps start and stop for every press after it, so the overlay
// window is used as the state: it is open from recording start until the
// transcription is done, and a signal is only sent when it fits that state.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

const (
	keyBytes  = 96 // room for 768 key bits
	eviocgkey = 0x80000000 | keyBytes<<16 | 'E'<<8 | 0x18

	pollInterval = 20 * time.Millisecond
	overlayWait  = time.Second      // how long Handy gets to open its overlay
	maxHold      = 10 * time.Minute // stop anyway if key state is ever misread
)

// The letter Y sits on KEY_Z on a German layout, so both count.
var comboKeys = []int{
	29, 97, // KEY_LEFTCTRL, KEY_RIGHTCTRL
	125, 126, // KEY_LEFTMETA, KEY_RIGHTMETA
	21, 44, // KEY_Y, KEY_Z
}

// handyPID finds the main process. Only that one handles SIGUSR2: the same
// signal would kill the transcription worker, so match the bare command line.
func handyPID() (int, error) {
	dirs, err := filepath.Glob("/proc/[0-9]*")
	if err != nil {
		return 0, err
	}
	for _, dir := range dirs {
		cmdline, err := os.ReadFile(dir + "/cmdline")
		if err != nil || string(cmdline) != "handy\x00" {
			continue
		}
		if pid, err := strconv.Atoi(filepath.Base(dir)); err == nil {
			return pid, nil
		}
	}
	return 0, fmt.Errorf("Handy is not running")
}

// overlayOpen asks Hyprland whether Handy's overlay window exists.
func overlayOpen() (bool, error) {
	path := filepath.Join(os.Getenv("XDG_RUNTIME_DIR"), "hypr",
		os.Getenv("HYPRLAND_INSTANCE_SIGNATURE"), ".socket.sock")
	conn, err := net.DialTimeout("unix", path, time.Second)
	if err != nil {
		return false, err
	}
	defer conn.Close()
	if err := conn.SetDeadline(time.Now().Add(time.Second)); err != nil {
		return false, err
	}
	if _, err := conn.Write([]byte("j/clients")); err != nil {
		return false, err
	}
	reply, err := io.ReadAll(conn)
	if err != nil {
		return false, err
	}
	return hasOverlay(reply)
}

func hasOverlay(clientsJSON []byte) (bool, error) {
	var clients []struct {
		Class string `json:"class"`
		Title string `json:"title"`
	}
	if err := json.Unmarshal(clientsJSON, &clients); err != nil {
		return false, err
	}
	for _, c := range clients {
		if c.Class == "Handy" && c.Title == "Recording" {
			return true, nil
		}
	}
	return false, nil
}

func toggle(pid int) error {
	return syscall.Kill(pid, syscall.SIGUSR2)
}

// handy is what hold needs from the outside world.
type handy struct {
	overlayOpen func() (bool, error)
	held        func() bool
	toggle      func() error
	sleep       func(time.Duration)
}

// hold runs one press of the combo. A press during transcription waits for it
// to finish, and is dropped with an error if the keys come up first.
func (h handy) hold() error {
	waited := time.Duration(0)
	wait := func() bool {
		h.sleep(pollInterval)
		waited += pollInterval
		return waited < maxHold
	}

	for {
		open, err := h.overlayOpen()
		if err != nil {
			return err
		}
		if !open {
			break
		}
		if !h.held() || !wait() {
			return errors.New("press ignored: Handy is still busy")
		}
	}

	if err := h.toggle(); err != nil {
		return err
	}
	// Even if this fails, carry on: the start may only be late, and a recording
	// that did start must still get its stop.
	startErr := h.awaitOverlay()

	for h.held() && wait() {
	}

	// Stopping must not fire if nothing is recording, say after a cancel in
	// Handy, as the toggle would start a new one. If the check itself fails,
	// send it anyway: this hold did send a start.
	open, err := h.overlayOpen()
	if err == nil && !open {
		return startErr
	}
	return errors.Join(startErr, err, h.toggle())
}

func (h handy) awaitOverlay() error {
	for waited := time.Duration(0); waited < overlayWait; waited += pollInterval {
		open, err := h.overlayOpen()
		if err != nil {
			return err
		}
		if open {
			return nil
		}
		h.sleep(pollInterval)
	}
	return errors.New("Handy did not start recording")
}

func openKeyboards() ([]int, error) {
	devices, err := os.ReadFile("/proc/bus/input/devices")
	if err != nil {
		return nil, err
	}
	event := regexp.MustCompile(`event\d+`)
	var fds []int
	for _, line := range strings.Split(string(devices), "\n") {
		if !strings.HasPrefix(line, "H: Handlers=") || !strings.Contains(line, "kbd") {
			continue
		}
		path := "/dev/input/" + event.FindString(line)
		fd, err := syscall.Open(path, syscall.O_RDONLY|syscall.O_NONBLOCK, 0)
		if err == nil { // skip a device that vanished or can't be read
			fds = append(fds, fd)
		}
	}
	return fds, nil
}

func comboHeld(fds []int) bool {
	for _, fd := range fds {
		var state [keyBytes]byte
		_, _, errno := syscall.Syscall(syscall.SYS_IOCTL, uintptr(fd),
			eviocgkey, uintptr(unsafe.Pointer(&state)))
		if errno != 0 {
			continue // keyboard unplugged mid-hold
		}
		for _, key := range comboKeys {
			if state[key/8]>>(key%8)&1 == 1 {
				return true
			}
		}
	}
	return false
}

func run() error {
	// Only one hold at a time; a second copy would toggle out of step.
	lockPath := os.Getenv("XDG_RUNTIME_DIR") + "/handy-hold.lock"
	lock, err := syscall.Open(lockPath, syscall.O_CREAT|syscall.O_WRONLY, 0o600)
	if err != nil {
		return err
	}
	if syscall.Flock(lock, syscall.LOCK_EX|syscall.LOCK_NB) != nil {
		return nil
	}

	pid, err := handyPID()
	if err != nil {
		return err
	}
	fds, err := openKeyboards()
	if err != nil {
		return err
	}
	if len(fds) == 0 {
		return errors.New("no readable keyboard, is this user in the input group?")
	}
	return handy{
		overlayOpen: overlayOpen,
		held:        func() bool { return comboHeld(fds) },
		toggle:      func() error { return toggle(pid) },
		sleep:       time.Sleep,
	}.hold()
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "handy-hold:", err)
		// Hyprland discards stderr, so this is the only sign of a failure.
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel()
		exec.CommandContext(ctx, "notify-send", "-a", "Handy", "handy-hold", err.Error()).Run()
		os.Exit(1)
	}
}
