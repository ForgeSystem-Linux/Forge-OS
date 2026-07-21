use smithay::input::pointer::{
    AxisFrame, ButtonEvent, GestureHoldBeginEvent, GestureHoldEndEvent,
    GesturePinchBeginEvent, GesturePinchEndEvent, GesturePinchUpdateEvent,
    GestureSwipeBeginEvent, GestureSwipeEndEvent, GestureSwipeUpdateEvent,
    MotionEvent, PointerGrab, PointerInnerHandle, RelativeMotionEvent,
};
use smithay::utils::{Logical, Point};

use crate::state::ForgeState;

pub struct MoveGrab {
    pub start_data: smithay::input::pointer::GrabStartData<ForgeState>,
    pub initial_cursor_pos: Point<f64, Logical>,
    pub initial_window_pos: Point<i32, Logical>,
}

impl PointerGrab<ForgeState> for MoveGrab {
    fn motion(
        &mut self,
        state: &mut ForgeState,
        handle: &mut PointerInnerHandle<'_, ForgeState>,
        focus: Option<(<ForgeState as smithay::input::SeatHandler>::PointerFocus, Point<f64, Logical>)>,
        event: &MotionEvent,
    ) {
        let delta = (
            event.location.x - self.initial_cursor_pos.x,
            event.location.y - self.initial_cursor_pos.y,
        );
        let new_pos = (
            self.initial_window_pos.x + delta.0 as i32,
            self.initial_window_pos.y + delta.1 as i32,
        );
        tracing::debug!("Moving window to {:?}", new_pos);
        handle.motion(state, focus, event);
    }

    fn button(
        &mut self,
        state: &mut ForgeState,
        handle: &mut PointerInnerHandle<'_, ForgeState>,
        event: &ButtonEvent,
    ) {
        handle.button(state, event);
        if event.state == smithay::backend::input::ButtonState::Released {
            handle.unset_grab(self, state, event.serial, event.time, true);
        }
    }

    fn relative_motion(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, focus: Option<(<ForgeState as smithay::input::SeatHandler>::PointerFocus, Point<f64, Logical>)>, event: &RelativeMotionEvent) {
        handle.relative_motion(state, focus, event);
    }
    fn axis(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, details: AxisFrame) {
        handle.axis(state, details);
    }
    fn frame(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>) {
        handle.frame(state);
    }
    fn gesture_swipe_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeBeginEvent) {
        handle.gesture_swipe_begin(state, event);
    }
    fn gesture_swipe_update(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeUpdateEvent) {
        handle.gesture_swipe_update(state, event);
    }
    fn gesture_swipe_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeEndEvent) {
        handle.gesture_swipe_end(state, event);
    }
    fn gesture_pinch_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchBeginEvent) {
        handle.gesture_pinch_begin(state, event);
    }
    fn gesture_pinch_update(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchUpdateEvent) {
        handle.gesture_pinch_update(state, event);
    }
    fn gesture_pinch_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchEndEvent) {
        handle.gesture_pinch_end(state, event);
    }
    fn gesture_hold_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureHoldBeginEvent) {
        handle.gesture_hold_begin(state, event);
    }
    fn gesture_hold_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureHoldEndEvent) {
        handle.gesture_hold_end(state, event);
    }

    fn start_data(&self) -> &smithay::input::pointer::GrabStartData<ForgeState> {
        &self.start_data
    }

    fn unset(&mut self, _state: &mut ForgeState) {}
}

pub struct ResizeGrab {
    pub start_data: smithay::input::pointer::GrabStartData<ForgeState>,
    pub initial_cursor_pos: Point<f64, Logical>,
    pub initial_window_size: (i32, i32),
    pub resize_edge: u32,
}

impl PointerGrab<ForgeState> for ResizeGrab {
    fn motion(
        &mut self,
        state: &mut ForgeState,
        handle: &mut PointerInnerHandle<'_, ForgeState>,
        focus: Option<(<ForgeState as smithay::input::SeatHandler>::PointerFocus, Point<f64, Logical>)>,
        event: &MotionEvent,
    ) {
        let delta = (
            event.location.x - self.initial_cursor_pos.x,
            event.location.y - self.initial_cursor_pos.y,
        );

        let (mut new_width, mut new_height) = self.initial_window_size;
        match self.resize_edge {
            0 => { new_width -= delta.0 as i32; new_height -= delta.1 as i32; }
            1 => { new_height -= delta.1 as i32; }
            2 => { new_width += delta.0 as i32; new_height -= delta.1 as i32; }
            3 => { new_width += delta.0 as i32; }
            4 => { new_width += delta.0 as i32; new_height += delta.1 as i32; }
            5 => { new_height += delta.1 as i32; }
            6 => { new_width -= delta.0 as i32; new_height += delta.1 as i32; }
            7 => { new_width -= delta.0 as i32; }
            _ => {}
        }

        new_width = new_width.max(200);
        new_height = new_height.max(150);
        tracing::debug!("Resizing window to {}x{}", new_width, new_height);
        handle.motion(state, focus, event);
    }

    fn button(
        &mut self,
        state: &mut ForgeState,
        handle: &mut PointerInnerHandle<'_, ForgeState>,
        event: &ButtonEvent,
    ) {
        handle.button(state, event);
        if event.state == smithay::backend::input::ButtonState::Released {
            handle.unset_grab(self, state, event.serial, event.time, true);
        }
    }

    fn relative_motion(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, focus: Option<(<ForgeState as smithay::input::SeatHandler>::PointerFocus, Point<f64, Logical>)>, event: &RelativeMotionEvent) {
        handle.relative_motion(state, focus, event);
    }
    fn axis(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, details: AxisFrame) {
        handle.axis(state, details);
    }
    fn frame(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>) {
        handle.frame(state);
    }
    fn gesture_swipe_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeBeginEvent) {
        handle.gesture_swipe_begin(state, event);
    }
    fn gesture_swipe_update(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeUpdateEvent) {
        handle.gesture_swipe_update(state, event);
    }
    fn gesture_swipe_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureSwipeEndEvent) {
        handle.gesture_swipe_end(state, event);
    }
    fn gesture_pinch_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchBeginEvent) {
        handle.gesture_pinch_begin(state, event);
    }
    fn gesture_pinch_update(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchUpdateEvent) {
        handle.gesture_pinch_update(state, event);
    }
    fn gesture_pinch_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GesturePinchEndEvent) {
        handle.gesture_pinch_end(state, event);
    }
    fn gesture_hold_begin(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureHoldBeginEvent) {
        handle.gesture_hold_begin(state, event);
    }
    fn gesture_hold_end(&mut self, state: &mut ForgeState, handle: &mut PointerInnerHandle<'_, ForgeState>, event: &GestureHoldEndEvent) {
        handle.gesture_hold_end(state, event);
    }

    fn start_data(&self) -> &smithay::input::pointer::GrabStartData<ForgeState> {
        &self.start_data
    }

    fn unset(&mut self, _state: &mut ForgeState) {}
}
