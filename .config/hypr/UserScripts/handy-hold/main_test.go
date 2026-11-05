package main

import (
	"errors"
	"reflect"
	"testing"
	"time"
)

// world scripts one press. Each poll of held() uses up one of heldPolls, and the
// overlay answers follow what a real Handy would do with the signals.
type world struct {
	open       bool
	heldPolls  int
	closesIn   int // overlay polls until a running transcription ends
	cancelAt   int // held polls until the user cancels, 0 for never
	neverOpens bool
	opensIn    int // sleeps from the start signal until the overlay opens
	queryErr   error
	signals    []string
}

func (w *world) handy() handy {
	return handy{
		overlayOpen: func() (bool, error) {
			if w.queryErr != nil {
				return false, w.queryErr
			}
			if w.closesIn > 0 {
				w.closesIn--
				if w.closesIn == 0 {
					w.open = false
				}
			}
			return w.open, nil
		},
		held: func() bool {
			if w.cancelAt > 0 {
				w.cancelAt--
				if w.cancelAt == 0 {
					w.open = false
				}
			}
			w.heldPolls--
			return w.heldPolls >= 0
		},
		toggle: func() error {
			if w.open {
				w.signals = append(w.signals, "stop")
				w.open = false
				return nil
			}
			w.signals = append(w.signals, "start")
			w.open = !w.neverOpens && w.opensIn == 0
			return nil
		},
		sleep: func(time.Duration) {
			if w.opensIn > 0 {
				w.opensIn--
				if w.opensIn == 0 {
					w.open = true
				}
			}
		},
	}
}

func TestHold(t *testing.T) {
	tests := []struct {
		name  string
		world world
		want  []string
	}{
		{"normal hold", world{heldPolls: 5}, []string{"start", "stop"}},
		{"tap released at once", world{heldPolls: 0}, []string{"start", "stop"}},
		{"press during transcription, held past its end",
			world{open: true, closesIn: 3, heldPolls: 10}, []string{"start", "stop"}},
		{"cancelled in Handy during the hold",
			world{heldPolls: 5, cancelAt: 3}, []string{"start"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			w := tt.world
			if err := w.handy().hold(); err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(w.signals, tt.want) {
				t.Errorf("signals = %v, want %v", w.signals, tt.want)
			}
		})
	}
}

func TestHoldReportsADroppedPress(t *testing.T) {
	w := world{open: true, closesIn: 50, heldPolls: 2}
	if err := w.handy().hold(); err == nil {
		t.Fatal("want an error")
	}
	if w.signals != nil {
		t.Errorf("signals = %v, want none, a toggle while busy can swap start and stop", w.signals)
	}
}

func TestHoldStopsARecordingThatStartedLate(t *testing.T) {
	w := world{heldPolls: 200, opensIn: 100}
	if err := w.handy().hold(); err == nil {
		t.Fatal("want the late start reported")
	}
	if want := []string{"start", "stop"}; !reflect.DeepEqual(w.signals, want) {
		t.Errorf("signals = %v, want %v", w.signals, want)
	}
}

func TestHoldStopsIfConfirmingTheStartFails(t *testing.T) {
	w := world{heldPolls: 2}
	h := w.handy()
	query := h.overlayOpen
	calls := 0
	h.overlayOpen = func() (bool, error) {
		calls++
		if calls == 2 { // the first check after the start signal
			return false, errors.New("socket timeout")
		}
		return query()
	}
	if err := h.hold(); err == nil {
		t.Fatal("want an error")
	}
	if want := []string{"start", "stop"}; !reflect.DeepEqual(w.signals, want) {
		t.Errorf("signals = %v, want %v", w.signals, want)
	}
}

func TestHoldEndsAtMaxHold(t *testing.T) {
	w := world{heldPolls: int(maxHold/pollInterval) * 2}
	if err := w.handy().hold(); err != nil {
		t.Fatal(err)
	}
	if want := []string{"start", "stop"}; !reflect.DeepEqual(w.signals, want) {
		t.Errorf("signals = %v, want %v", w.signals, want)
	}
}

func TestHoldReportsAFailedStart(t *testing.T) {
	w := world{heldPolls: 5}
	h := w.handy()
	h.toggle = func() error { return errors.New("no such process") }
	if err := h.hold(); err == nil {
		t.Fatal("want an error")
	}
}

func TestHasOverlay(t *testing.T) {
	tests := []struct {
		name, reply string
		want        bool
	}{
		{"overlay", `[{"class":"kitty","title":"x"},{"class":"Handy","title":"Recording"}]`, true},
		{"main window only", `[{"class":"Handy","title":"Handy"}]`, false},
		{"same title elsewhere", `[{"class":"kitty","title":"Recording"}]`, false},
		{"no windows", `[]`, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := hasOverlay([]byte(tt.reply))
			if err != nil || got != tt.want {
				t.Errorf("got %v, %v, want %v", got, err, tt.want)
			}
		})
	}
	if _, err := hasOverlay([]byte("hyprland says no")); err == nil {
		t.Error("want an error for a non-JSON reply")
	}
}

func TestHoldReportsThatRecordingNeverStarted(t *testing.T) {
	w := world{heldPolls: 5, neverOpens: true}
	if err := w.handy().hold(); err == nil {
		t.Fatal("want an error")
	}
	if want := []string{"start"}; !reflect.DeepEqual(w.signals, want) {
		t.Errorf("signals = %v, want %v, a stop would start a recording", w.signals, want)
	}
}

func TestHoldStopsEvenIfStateCheckFails(t *testing.T) {
	w := world{heldPolls: 2}
	h := w.handy()
	query := h.overlayOpen
	calls := 0
	h.overlayOpen = func() (bool, error) {
		calls++
		if calls > 2 { // the check at release
			return false, errors.New("socket gone")
		}
		return query()
	}
	if err := h.hold(); err == nil {
		t.Fatal("want the check's error reported")
	}
	if want := []string{"start", "stop"}; !reflect.DeepEqual(w.signals, want) {
		t.Errorf("signals = %v, want %v", w.signals, want)
	}
}

func TestHoldSendsNothingIfStateIsUnknown(t *testing.T) {
	w := world{heldPolls: 5, queryErr: errors.New("no socket")}
	if err := w.handy().hold(); err == nil {
		t.Fatal("want an error")
	}
	if w.signals != nil {
		t.Errorf("signals = %v, want none", w.signals)
	}
}
