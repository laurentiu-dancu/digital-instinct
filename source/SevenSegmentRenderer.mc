using Toybox.Graphics;
using Toybox.Lang;

// Helper class for rendering 7-segment displays with dithering support
class SevenSegmentRenderer {

    // Create dithered pattern for unlit segments
    static function drawDitheredRect(dc as Dc, x as Number, y as Number, width as Number, height as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        // 50% dithered pattern for light gray appearance
        for (var px = x; px < x + width; px++) {
            for (var py = y; py < y + height; py++) {
                // Checkerboard pattern every other pixel
                if ((px + py) % 3 == 0) {
                    dc.drawPoint(px, py);
                }
            }
        }
    }

    // Draw a single segment with proper thickness and rounded ends
    static function drawSegmentShape(dc as Dc, x1 as Number, y1 as Number, x2 as Number, y2 as Number, thickness as Number, isActive as Boolean) as Void {
        if (isActive) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (x1 == x2) {
                // Vertical segment
                dc.fillRectangle(x1 - thickness/2, y1, thickness, y2 - y1);
            } else {
                // Horizontal segment
                dc.fillRectangle(x1, y1 - thickness/2, x2 - x1, thickness);
            }
        } else {
            // Draw dithered background
            if (x1 == x2) {
                // Vertical segment
                drawDitheredRect(dc, x1 - thickness/2, y1, thickness, y2 - y1);
            } else {
                // Horizontal segment
                drawDitheredRect(dc, x1, y1 - thickness/2, x2 - x1, thickness);
            }
        }
    }

    // Calculate and draw complete 7-segment digit
    static function renderDigit(dc as Dc, x as Number, y as Number, width as Number, height as Number, digit as Number, showBackground as Boolean, segmentMap as Dictionary<Number, Array<Boolean>>) as Void {
        var segments = segmentMap[digit];
        var thickness = width > 20 ? 4 : 2;
        var gap = 2;
        
        var left = x;
        var right = x + width;
        var top = y;
        var middle = y + height / 2;
        var bottom = y + height;
        
        // Draw each segment
        var segmentDefs = [
            // a: top horizontal
            [left + gap, top, right - gap, top],
            // b: top right vertical  
            [right, top + gap, right, middle - gap],
            // c: bottom right vertical
            [right, middle + gap, right, bottom - gap],
            // d: bottom horizontal
            [left + gap, bottom, right - gap, bottom],
            // e: bottom left vertical
            [left, middle + gap, left, bottom - gap],
            // f: top left vertical
            [left, top + gap, left, middle - gap],
            // g: middle horizontal
            [left + gap, middle, right - gap, middle]
        ];
        
        for (var i = 0; i < 7; i++) {
            var isActive = segments != null && segments[i];
            var coords = segmentDefs[i];
            
            if (showBackground || isActive) {
                drawSegmentShape(dc, coords[0], coords[1], coords[2], coords[3], thickness, isActive);
            }
        }
    }
}