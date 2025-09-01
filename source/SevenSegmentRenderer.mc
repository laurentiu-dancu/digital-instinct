using Toybox.Graphics;
using Toybox.Lang;

// Utility class for rendering 7-segment displays with advanced features
class SevenSegmentRenderer {

    // Create a smooth dithered pattern for unlit segments
    static function drawDitheredRect(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, pattern as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        // Different dithering patterns for variety
        var ditherPattern = pattern % 3;
        
        for (var px = x; px < x + width; px++) {
            for (var py = y; py < y + height; py++) {
                var shouldDraw = false;
                
                switch (ditherPattern) {
                    case 0: // Checkerboard
                        shouldDraw = ((px + py) % 3 == 0);
                        break;
                    case 1: // Diagonal stripes
                        shouldDraw = ((px + py) % 4 == 0);
                        break;
                    case 2: // Sparse dots
                        shouldDraw = ((px * py) % 5 == 0);
                        break;
                }
                
                if (shouldDraw) {
                    dc.drawPoint(px, py);
                }
            }
        }
    }

    // Draw a rounded segment with proper anti-aliasing simulation
    static function drawRoundedSegment(dc as Graphics.Dc, x1 as Lang.Number, y1 as Lang.Number, x2 as Lang.Number, y2 as Lang.Number, thickness as Lang.Number, isActive as Lang.Boolean, ditherPattern as Lang.Number) as Void {
        if (isActive) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            if (x1 == x2) {
                // Vertical segment with rounded ends
                var halfThickness = thickness / 2;
                dc.fillRectangle(x1 - halfThickness, y1 + halfThickness, thickness, y2 - y1 - thickness);
                // Rounded ends
                dc.fillCircle(x1, y1 + halfThickness, halfThickness);
                dc.fillCircle(x1, y2 - halfThickness, halfThickness);
            } else {
                // Horizontal segment with rounded ends
                var halfThickness = thickness / 2;
                dc.fillRectangle(x1 + halfThickness, y1 - halfThickness, x2 - x1 - thickness, thickness);
                // Rounded ends
                dc.fillCircle(x1 + halfThickness, y1, halfThickness);
                dc.fillCircle(x2 - halfThickness, y1, halfThickness);
            }
        } else {
            // Draw dithered background
            if (x1 == x2) {
                // Vertical segment
                var halfThickness = thickness / 2;
                drawDitheredRect(dc, x1 - halfThickness, y1 + halfThickness, thickness, y2 - y1 - thickness, ditherPattern);
                // Rounded ends
                drawDitheredCircle(dc, x1, y1 + halfThickness, halfThickness, ditherPattern);
                drawDitheredCircle(dc, x1, y2 - halfThickness, halfThickness, ditherPattern);
            } else {
                // Horizontal segment
                var halfThickness = thickness / 2;
                drawDitheredRect(dc, x1 + halfThickness, y1 - halfThickness, x2 - x1 - thickness, thickness, ditherPattern);
                // Rounded ends
                drawDitheredCircle(dc, x1 + halfThickness, y1, halfThickness, ditherPattern);
                drawDitheredCircle(dc, x2 - halfThickness, y1, halfThickness, ditherPattern);
            }
        }
    }

    // Draw a dithered circle for rounded segment ends
    static function drawDitheredCircle(dc as Graphics.Dc, centerX as Lang.Number, centerY as Lang.Number, radius as Lang.Number, pattern as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        var ditherPattern = pattern % 3;
        
        // Simplified circle drawing using square approximation
        for (var x = centerX - radius; x <= centerX + radius; x++) {
            for (var y = centerY - radius; y <= centerY + radius; y++) {
                // Simple distance check using square approximation
                var dx = x - centerX;
                var dy = y - centerY;
                if (dx * dx + dy * dy <= radius * radius) {
                    var shouldDraw = false;
                    
                    switch (ditherPattern) {
                        case 0: // Checkerboard
                            shouldDraw = ((x + y) % 3 == 0);
                            break;
                        case 1: // Radial pattern
                            shouldDraw = ((dx + dy + x + y) % 4 == 0);
                            break;
                        case 2: // Sparse dots
                            shouldDraw = ((x * y) % 5 == 0);
                            break;
                    }
                    
                    if (shouldDraw) {
                        dc.drawPoint(x, y);
                    }
                }
            }
        }
    }

    // Calculate optimal segment thickness based on digit size
    static function calculateOptimalThickness(width as Lang.Number, height as Lang.Number) as Lang.Number {
        var minDimension = width < height ? width : height;
        if (minDimension >= 50) {
            return 6; // Large digits
        } else if (minDimension >= 30) {
            return 4; // Medium digits
        } else if (minDimension >= 20) {
            return 3; // Small digits
        } else {
            return 2; // Mini digits
        }
    }

    // Calculate optimal gap between segments
    static function calculateOptimalGap(width as Lang.Number, height as Lang.Number) as Lang.Number {
        var minDimension = width < height ? width : height;
        if (minDimension >= 2) {
            return 4; // Large digits
        } else if (minDimension >= 30) {
            return 3; // Medium digits
        } else if (minDimension >= 20) {
            return 2; // Small digits
        } else {
            return 1; // Mini digits
        }
    }

    // Generate segment coordinates with proper spacing
    static function generateSegmentCoordinates(x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, thickness as Lang.Number, gap as Lang.Number) as Lang.Array<Lang.Array<Lang.Number>> {
        var halfWidth = width / 2;
        var halfHeight = height / 2;
        var midY = y + halfHeight;
        
        return [
            // Segment a (top horizontal)
            [x + gap, y, x + width - gap, y + thickness],
            // Segment b (top right vertical)
            [x + width - thickness, y + gap, x + width, midY - gap],
            // Segment c (bottom right vertical)
            [x + width - thickness, midY + gap, x + width, y + height - gap],
            // Segment d (bottom horizontal)
            [x + gap, y + height - thickness, x + width - gap, y + height],
            // Segment e (bottom left vertical)
            [x, midY + gap, x + thickness, y + height - gap],
            // Segment f (top left vertical)
            [x, y + gap, x + thickness, midY - gap],
            // Segment g (middle horizontal)
            [x + gap, midY - thickness/2, x + width - gap, midY + thickness/2]
        ];
    }

    // Render a complete 7-segment digit with all features
    static function renderDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, digit as Lang.Number, segmentMap as Lang.Dictionary<Lang.Number, Lang.Array<Lang.Number>>, showBackground as Lang.Boolean, useRoundedSegments as Lang.Boolean) as Void {
        var segments = segmentMap[digit];
        if (segments == null) {
            return;
        }
        
        var thickness = calculateOptimalThickness(width, height);
        var gap = calculateOptimalGap(width, height);
        var coords = generateSegmentCoordinates(x, y, width, height, thickness, gap);
        
        // Draw background segments first if requested
        if (showBackground) {
            for (var i = 0; i < 7; i++) {
                if (segments[i] == 0) {
                    if (useRoundedSegments) {
                        drawRoundedSegment(dc, coords[i][0], coords[i][1], coords[i][2], coords[i][3], thickness, false, i);
                    } else {
                        drawDitheredRect(dc, coords[i][0], coords[i][1], coords[i][2] - coords[i][0], coords[i][3] - coords[i][1], i);
                    }
                }
            }
        }
        
        // Draw active segments
        for (var i = 0; i < 7; i++) {
            if (segments[i] == 1) {
                if (useRoundedSegments) {
                    drawRoundedSegment(dc, coords[i][0], coords[i][1], coords[i][2], coords[i][3], thickness, true, i);
                } else {
                    dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(coords[i][0], coords[i][1], coords[i][2] - coords[i][0], coords[i][3] - coords[i][1]);
                }
            }
        }
    }
}