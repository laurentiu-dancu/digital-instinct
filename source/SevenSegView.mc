using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;

class SevenSegView extends WatchUi.WatchFace {

    private var _segmentMaps as Dictionary<Number, Array<Boolean>>;
    private var _monthNames as Array<String>;

    function initialize() {
        WatchFace.initialize();
        
        // 7-segment display mapping: [a, b, c, d, e, f, g]
        // segments are labeled clockwise from top
        _segmentMaps = {
            0 => [true, true, true, true, true, true, false],
            1 => [false, true, true, false, false, false, false],
            2 => [true, true, false, true, true, false, true],
            3 => [true, true, true, true, false, false, true],
            4 => [false, true, true, false, false, true, true],
            5 => [true, false, true, true, false, true, true],
            6 => [true, false, true, true, true, true, true],
            7 => [true, true, true, false, false, false, false],
            8 => [true, true, true, true, true, true, true],
            9 => [true, true, true, true, false, true, true]
        };
        
        _monthNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {
        // Clear the screen with white background
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        // Get current time and date
        var now = System.getClockTime();
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        
        // Draw time (large, center)
        drawLargeTime(dc, now.hour, now.min);
        
        // Draw date (top left)
        drawDate(dc, today.day, today.month - 1);
        
        // Draw heart rate (top right)
        drawHeartRate(dc);
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    private function drawLargeTime(dc as Dc, hour as Number, minute as Number) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        
        // Time digit positions
        var digitWidth = 32;
        var digitHeight = 48;
        var digitSpacing = 40;
        var colonWidth = 8;
        
        // Calculate positions for HH:MM
        var totalWidth = digitWidth * 4 + colonWidth + digitSpacing * 3;
        var startX = centerX - totalWidth / 2;
        var timeY = centerY - digitHeight / 2 + 10;
        
        // Draw hour digits
        var hourTens = hour / 10;
        var hourOnes = hour % 10;
        drawSevenSegmentDigit(dc, startX, timeY, digitWidth, digitHeight, hourTens, false);
        drawSevenSegmentDigit(dc, startX + digitSpacing, timeY, digitWidth, digitHeight, hourOnes, false);
        
        // Draw colon
        var colonX = startX + digitSpacing * 2;
        drawColon(dc, colonX, timeY, digitHeight);
        
        // Draw minute digits
        var minuteTens = minute / 10;
        var minuteOnes = minute % 10;
        drawSevenSegmentDigit(dc, startX + digitSpacing * 2 + colonWidth, timeY, digitWidth, digitHeight, minuteTens, false);
        drawSevenSegmentDigit(dc, startX + digitSpacing * 3 + colonWidth, timeY, digitWidth, digitHeight, minuteOnes, false);
    }

    private function drawDate(dc as Dc, day as Number, monthIndex as Number) as Void {
        var dateX = 15;
        var dateY = 25;
        var smallDigitWidth = 16;
        var smallDigitHeight = 24;
        var spacing = 18;
        
        // Draw day (DD)
        var dayTens = day / 10;
        var dayOnes = day % 10;
        drawSevenSegmentDigit(dc, dateX, dateY, smallDigitWidth, smallDigitHeight, dayTens, false);
        drawSevenSegmentDigit(dc, dateX + spacing, dateY, smallDigitWidth, smallDigitHeight, dayOnes, false);
        
        // Draw month text using custom mini segments
        var monthX = dateX + spacing * 2 + 5;
        drawMonthText(dc, monthX, dateY, _monthNames[monthIndex]);
    }

    private function drawHeartRate(dc as Dc) as Void {
        var hrInfo = ActivityMonitor.getHeartRateHistory(1, true);
        var heartRate = 0;
        
        if (hrInfo != null && hrInfo.next() != null) {
            var sample = hrInfo.next();
            if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                heartRate = sample.heartRate;
            }
        }
        
        // Position in top right corner
        var hrX = dc.getWidth() - 50;
        var hrY = 25;
        
        if (heartRate > 0) {
            // Draw simple text for heart rate since it's in the round area
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.drawText(hrX, hrY, Graphics.FONT_TINY, heartRate.toString(), Graphics.TEXT_JUSTIFY_RIGHT);
            dc.drawText(hrX, hrY + 12, Graphics.FONT_TINY, "BPM", Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    private function drawSevenSegmentDigit(dc as Dc, x as Number, y as Number, width as Number, height as Number, digit as Number, showBackground as Boolean) as Void {
        var segments = _segmentMaps[digit];
        var thickness = 3;
        var gap = 2;
        
        // Segment coordinates
        var segmentCoords = calculateSegmentCoords(x, y, width, height, thickness, gap);
        
        // Draw background segments (dithered gray) first if requested
        if (showBackground) {
            for (var i = 0; i < 7; i++) {
                if (!segments[i]) {
                    drawDitheredSegment(dc, segmentCoords[i]);
                }
            }
        }
        
        // Draw active segments in black
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < 7; i++) {
            if (segments[i]) {
                drawSegment(dc, segmentCoords[i]);
            }
        }
    }

    private function calculateSegmentCoords(x as Number, y as Number, width as Number, height as Number, thickness as Number, gap as Number) as Array<Array<Number>> {
        var halfWidth = width / 2;
        var halfHeight = height / 2;
        var midY = y + halfHeight;
        
        return [
            // Segment a (top)
            [x + gap, y, x + width - gap, y + thickness],
            // Segment b (top right)
            [x + width - thickness, y + gap, x + width, midY - gap],
            // Segment c (bottom right)
            [x + width - thickness, midY + gap, x + width, y + height - gap],
            // Segment d (bottom)
            [x + gap, y + height - thickness, x + width - gap, y + height],
            // Segment e (bottom left)
            [x, midY + gap, x + thickness, y + height - gap],
            // Segment f (top left)
            [x, y + gap, x + thickness, midY - gap],
            // Segment g (middle)
            [x + gap, midY - thickness/2, x + width - gap, midY + thickness/2]
        ];
    }

    private function drawSegment(dc as Dc, coords as Array<Number>) as Void {
        dc.fillRectangle(coords[0], coords[1], coords[2] - coords[0], coords[3] - coords[1]);
    }

    private function drawDitheredSegment(dc as Dc, coords as Array<Number>) as Void {
        // Create dithered pattern for gray appearance
        var startX = coords[0];
        var startY = coords[1];
        var endX = coords[2];
        var endY = coords[3];
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        for (var x = startX; x < endX; x += 2) {
            for (var y = startY; y < endY; y += 2) {
                // Checkerboard dithering pattern
                if ((x + y) % 4 == 0) {
                    dc.drawPoint(x, y);
                }
            }
        }
    }

    private function drawColon(dc as Dc, x as Number, y as Number, height as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var dotSize = 3;
        var quarterHeight = height / 4;
        
        // Upper dot
        dc.fillRectangle(x, y + quarterHeight, dotSize, dotSize);
        // Lower dot
        dc.fillRectangle(x, y + height - quarterHeight - dotSize, dotSize, dotSize);
    }

    private function drawMonthText(dc as Dc, x as Number, y as Number, monthStr as String) as Void {
        // Simple bitmap-style text for month using mini 7-segment style
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        var charWidth = 12;
        var charHeight = 16;
        var charSpacing = 14;
        
        for (var i = 0; i < monthStr.length(); i++) {
            var char = monthStr.substring(i, i + 1);
            drawMiniChar(dc, x + i * charSpacing, y, charWidth, charHeight, char);
        }
    }

    private function drawMiniChar(dc as Dc, x as Number, y as Number, width as Number, height as Number, char as String) as Void {
        // Simplified character patterns for A-Z in mini 7-segment style
        var patterns = {
            "A" => [[1,1,1,0,1,1,1]], // simplified A pattern
            "B" => [[1,1,1,1,1,1,1]], // simplified B pattern  
            "C" => [[1,0,0,1,1,1,0]], // C pattern
            "D" => [[0,1,1,1,1,1,0]], // D pattern
            "E" => [[1,0,0,1,1,1,1]], // E pattern
            "F" => [[1,0,0,0,1,1,1]], // F pattern
            "G" => [[1,0,1,1,1,1,1]], // G pattern
            "H" => [[0,1,1,0,1,1,1]], // H pattern
            "I" => [[0,1,1,0,0,0,0]], // I pattern
            "J" => [[0,1,1,1,1,0,0]], // J pattern
            "L" => [[0,0,0,1,1,1,0]], // L pattern
            "M" => [[1,1,1,0,1,1,0]], // M pattern
            "N" => [[0,0,1,0,1,0,1]], // N pattern
            "O" => [[1,1,1,1,1,1,0]], // O pattern
            "P" => [[1,1,0,0,1,1,1]], // P pattern
            "R" => [[0,0,0,0,1,0,1]], // R pattern
            "S" => [[1,0,1,1,0,1,1]], // S pattern
            "T" => [[0,0,0,1,1,1,1]], // T pattern
            "U" => [[0,1,1,1,1,1,0]], // U pattern
            "V" => [[0,1,1,1,1,1,0]], // V pattern (same as U)
            "Y" => [[0,1,1,1,0,1,1]]  // Y pattern
        };
        
        var pattern = patterns.get(char);
        if (pattern != null) {
            drawMiniSevenSeg(dc, x, y, width, height, pattern[0]);
        }
    }

    private function drawMiniSevenSeg(dc as Dc, x as Number, y as Number, width as Number, height as Number, segments as Array<Boolean>) as Void {
        var thickness = 2;
        var gap = 1;
        var halfWidth = width / 2;
        var halfHeight = height / 2;
        var midY = y + halfHeight;
        
        var coords = [
            // Segment a (top)
            [x + gap, y, x + width - gap, y + thickness],
            // Segment b (top right)
            [x + width - thickness, y + gap, x + width, midY - gap],
            // Segment c (bottom right)
            [x + width - thickness, midY + gap, x + width, y + height - gap],
            // Segment d (bottom)
            [x + gap, y + height - thickness, x + width - gap, y + height],
            // Segment e (bottom left)
            [x, midY + gap, x + thickness, y + height - gap],
            // Segment f (top left)
            [x, y + gap, x + thickness, midY - gap],
            // Segment g (middle)
            [x + gap, midY - thickness/2, x + width - gap, midY + thickness/2]
        ];
        
        for (var i = 0; i < 7; i++) {
            if (segments[i]) {
                var coord = coords[i];
                dc.fillRectangle(coord[0], coord[1], coord[2] - coord[0], coord[3] - coord[1]);
            }
        }
    }

    function onPartialUpdate(dc as Dc) as Void {
        // For battery optimization, we could implement partial updates here
        onUpdate(dc);
    }

}