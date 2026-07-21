use smithay::input::keyboard::KeysymHandle;

use crate::state::ForgeState;

pub fn handle_keyboard_shortcuts(
    state: &mut ForgeState,
    handle: &KeysymHandle<'_>,
    event_state: smithay::backend::input::KeyState,
) {
    if event_state != smithay::backend::input::KeyState::Pressed {
        return;
    }

    let sym = handle.modified_sym();

    if let Some(keyboard) = state.seat.get_keyboard() {
        let modifiers = keyboard.modifier_state();

        // Alt+Tab - Switch windows
        if modifiers.alt && sym == smithay::input::keyboard::keysyms::KEY_Tab.into() {
            if modifiers.shift {
                state.focus_previous_window();
            } else {
                state.focus_next_window();
            }
        }

        // Alt+F4 - Close window
        if modifiers.alt && sym == smithay::input::keyboard::keysyms::KEY_F4.into() {
            state.close_active_window();
        }

        // Alt+F9 - Minimize
        if modifiers.alt && sym == smithay::input::keyboard::keysyms::KEY_F9.into() {
            state.minimize_active_window();
        }

        // Alt+F10 - Maximize toggle
        if modifiers.alt && sym == smithay::input::keyboard::keysyms::KEY_F10.into() {
            state.maximize_toggle();
        }

        // Ctrl+Alt+T - Open terminal
        if modifiers.ctrl
            && modifiers.alt
            && sym == smithay::input::keyboard::keysyms::KEY_t.into()
        {
            std::process::Command::new("weston-terminal").spawn().ok();
        }

        // Super+1-4 - Switch workspaces
        if modifiers.logo && !modifiers.ctrl && !modifiers.alt && !modifiers.shift {
            let keys = [
                smithay::input::keyboard::keysyms::KEY_1,
                smithay::input::keyboard::keysyms::KEY_2,
                smithay::input::keyboard::keysyms::KEY_3,
                smithay::input::keyboard::keysyms::KEY_4,
            ];
            for (i, &key) in keys.iter().enumerate() {
                if sym == key.into() {
                    state.switch_workspace(i);
                    break;
                }
            }
        }

        // Super+Shift+1-4 - Move window to workspace
        if modifiers.logo && modifiers.shift && !modifiers.ctrl && !modifiers.alt {
            let keys = [
                smithay::input::keyboard::keysyms::KEY_exclam,
                smithay::input::keyboard::keysyms::KEY_at,
                smithay::input::keyboard::keysyms::KEY_numbersign,
                smithay::input::keyboard::keysyms::KEY_dollar,
            ];
            for (i, &key) in keys.iter().enumerate() {
                if sym == key.into() {
                    state.move_window_to_workspace(i);
                    break;
                }
            }
        }

        // Super+Arrow keys - Snap windows (placeholder)
        if modifiers.logo && !modifiers.ctrl && !modifiers.alt {
            if sym == smithay::input::keyboard::keysyms::KEY_Left.into() {
                // TODO: Snap left
            }
            if sym == smithay::input::keyboard::keysyms::KEY_Right.into() {
                // TODO: Snap right
            }
            if sym == smithay::input::keyboard::keysyms::KEY_Up.into() {
                // TODO: Maximize
            }
            if sym == smithay::input::keyboard::keysyms::KEY_Down.into() {
                // TODO: Minimize
            }
        }
    }
}
