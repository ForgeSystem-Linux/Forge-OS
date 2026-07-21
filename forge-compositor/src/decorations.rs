use smithay::utils::{Logical, Point, Rectangle, Size};

use crate::state::{DecorationMode, WindowInfo};

pub struct DecorationColors {
    pub titlebar_bg: [f32; 4],
    pub titlebar_focused_bg: [f32; 4],
    pub border_focused: [f32; 4],
    pub border_unfocused: [f32; 4],
    pub button_close: [f32; 4],
    pub button_maximize: [f32; 4],
    pub button_minimize: [f32; 4],
}

impl Default for DecorationColors {
    fn default() -> Self {
        Self {
            titlebar_bg: [0.11, 0.11, 0.18, 1.0],
            titlebar_focused_bg: [0.14, 0.14, 0.21, 1.0],
            border_focused: [0.54, 0.71, 0.98, 1.0],
            border_unfocused: [0.19, 0.19, 0.27, 1.0],
            button_close: [0.95, 0.54, 0.66, 1.0],
            button_maximize: [0.64, 0.81, 0.40, 1.0],
            button_minimize: [0.99, 0.79, 0.35, 1.0],
        }
    }
}

pub struct DecorationRenderer {
    pub colors: DecorationColors,
    pub titlebar_height: i32,
    pub button_size: i32,
    pub button_padding: i32,
    pub border_width: i32,
}

impl Default for DecorationRenderer {
    fn default() -> Self {
        Self {
            colors: DecorationColors::default(),
            titlebar_height: 32,
            button_size: 18,
            button_padding: 6,
            border_width: 2,
        }
    }
}

impl DecorationRenderer {
    pub fn new() -> Self { Self::default() }

    pub fn total_geometry(&self, window: &WindowInfo) -> Rectangle<i32, Logical> {
        if window.decorations.mode != DecorationMode::ServerSide {
            return window.geometry;
        }
        Rectangle::new(window.position, Size::from((window.geometry.size.w, window.geometry.size.h + self.titlebar_height)))
    }

    pub fn button_at_point(&self, window: &WindowInfo, point: Point<i32, Logical>) -> Option<DecorationButton> {
        if window.decorations.mode != DecorationMode::ServerSide { return None; }
        let pos = window.position;
        let geo = window.geometry;
        let button_y = pos.y + (self.titlebar_height - self.button_size) / 2;
        let bsx = pos.x + geo.size.w - 3 * (self.button_size + self.button_padding);
        let bs = self.button_size;
        let bp = self.button_padding;

        let close = Rectangle::new((bsx, button_y).into(), Size::from((bs, bs)));
        if close.contains(point) { return Some(DecorationButton::Close); }
        let max = Rectangle::new((bsx + bs + bp, button_y).into(), Size::from((bs, bs)));
        if max.contains(point) { return Some(DecorationButton::Maximize); }
        let min = Rectangle::new((bsx + 2 * (bs + bp), button_y).into(), Size::from((bs, bs)));
        if min.contains(point) { return Some(DecorationButton::Minimize); }
        None
    }

    pub fn is_on_titlebar(&self, window: &WindowInfo, point: Point<i32, Logical>) -> bool {
        if window.decorations.mode != DecorationMode::ServerSide { return false; }
        let rect = Rectangle::new(window.position, Size::from((window.geometry.size.w, self.titlebar_height)));
        rect.contains(point)
    }

    pub fn get_elements(&self, window: &WindowInfo) -> Vec<DecorationElement> {
        if window.decorations.mode != DecorationMode::ServerSide { return vec![]; }
        let pos = window.position;
        let geo = window.geometry;
        let focused = window.is_focused;
        let bw = self.border_width;
        let th = self.titlebar_height;
        let bs = self.button_size;
        let bp = self.button_padding;

        let bg = if focused { self.colors.titlebar_focused_bg } else { self.colors.titlebar_bg };
        let bc = if focused { self.colors.border_focused } else { self.colors.border_unfocused };
        let mut e = Vec::new();

        e.push(DecorationElement { rect: Rectangle::new(pos, Size::from((geo.size.w, th))), color: bg });
        e.push(DecorationElement { rect: Rectangle::new(pos, Size::from((geo.size.w + bw * 2, bw))), color: bc });
        e.push(DecorationElement { rect: Rectangle::new((pos.x - bw, pos.y).into(), Size::from((bw, geo.size.h + th))), color: bc });
        e.push(DecorationElement { rect: Rectangle::new((pos.x + geo.size.w, pos.y).into(), Size::from((bw, geo.size.h + th))), color: bc });
        e.push(DecorationElement { rect: Rectangle::new((pos.x - bw, pos.y + geo.size.h + th).into(), Size::from((geo.size.w + bw * 2, bw))), color: bc });

        let by = pos.y + (th - bs) / 2;
        let bsx = pos.x + geo.size.w - 3 * (bs + bp);
        e.push(DecorationElement { rect: Rectangle::new((bsx, by).into(), Size::from((bs, bs))), color: self.colors.button_close });
        e.push(DecorationElement { rect: Rectangle::new((bsx + bs + bp, by).into(), Size::from((bs, bs))), color: self.colors.button_maximize });
        e.push(DecorationElement { rect: Rectangle::new((bsx + 2 * (bs + bp), by).into(), Size::from((bs, bs))), color: self.colors.button_minimize });

        e
    }
}

#[derive(Debug, Clone)]
pub struct DecorationElement {
    pub rect: Rectangle<i32, Logical>,
    pub color: [f32; 4],
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DecorationButton {
    Close,
    Maximize,
    Minimize,
}
