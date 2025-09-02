using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.SensorHistory;

class SevenSegView extends WatchUi.WatchFace {

    private var _segmentMaps as Lang.Dictionary<Lang.Number, Lang.Array<Lang.Number>>;
    private var _monthNames as Lang.Array<Lang.String>;
    private var _lastUpdateTime as Lang.Number;
    private var _batteryLevel as Lang.Number;

    function initialize() {
        WatchFace.initialize();
        
        // 7-segment display mapping: [a, b, c, d, e, f, g]
        // segments are labeled clockwise from top, then middle
        _segmentMaps = {
            0 => [1, 1, 1, 1, 1, 1, 0],  // 0: all except middle
            1 => [0, 1, 1, 0, 0, 0, 0],  // 1: top right, bottom right
            2 => [1, 1, 0, 1, 1, 0, 1],  // 2: top, top right, bottom, bottom left, middle
            3 => [1, 1, 1, 1, 0, 0, 1],  // 3: top, top right, bottom right, bottom, middle
            4 => [0, 1, 1, 0, 0, 1, 1],  // 4: top right, bottom right, top left, middle
            5 => [1, 0, 1, 1, 0, 1, 1],  // 5: top, bottom right, bottom, top left, middle
            6 => [1, 0, 1, 1, 1, 1, 1],  // 6: top, bottom right, bottom, bottom left, top left, middle
            7 => [1, 1, 1, 0, 0, 0, 0],  // 7: top, top right, bottom right
            8 => [1, 1, 1, 1, 1, 1, 1],  // 8: all segments
            9 => [1, 1, 1, 1, 0, 1, 1]   // 9: all except bottom left
        };
        
        _monthNames = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        
        _lastUpdateTime = 0;
        _batteryLevel = 0;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Clear the screen with white background
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
        dc.clear();
        
        // Get current time and date
        var now = System.getClockTime();
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        
        // Update battery level
        var stats = System.getSystemStats();
        var batteryLevel = stats.battery.toNumber();
        if (batteryLevel < 0 || batteryLevel > 100) {
            batteryLevel = 100; // Default to 100% if invalid
        }
        _batteryLevel = batteryLevel;
        
        // Draw time (large, center)
        drawLargeTime(dc, now.hour, now.min);
        
        // Draw date (top left)
        drawDate(dc, today.day, today.month);
        
        // Draw heart rate (top right)
        drawHeartRate(dc);
        
        // Draw battery indicator
        drawBatteryIndicator(dc);
        
        _lastUpdateTime = System.getClockTime().min;
    }

    function onHide() as Void {
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }

    private function drawLargeTime(dc as Graphics.Dc, hour as Lang.Number, minute as Lang.Number) as Void {
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        
        // Time digit positions - optimized for 176x176 display
        var digitWidth = 38;
        var digitHeight = 56;
        var digitSpacing = 40;
        var colonWidth = 12;
        
        // Calculate positions for HH:MM
        var totalWidth = digitWidth * 4 + colonWidth + digitSpacing * 3;
        var startX = centerX - totalWidth / 2 + 57;
        var timeY = centerY - digitHeight / 2 + 25;
        
        // Draw hour digits
        var hourTens = hour / 10;
        var hourOnes = hour % 10;
        drawSevenSegmentDigit(dc, startX, timeY, digitWidth, digitHeight, hourTens, true);
        drawSevenSegmentDigit(dc, startX + digitSpacing, timeY, digitWidth, digitHeight, hourOnes, true);
        
        // Draw colon
        var colonX = startX + digitSpacing * 2;
        drawColon(dc, colonX, timeY, digitHeight);
        
        // Draw minute digits
        var minuteTens = minute / 10;
        var minuteOnes = minute % 10;
        drawSevenSegmentDigit(dc, startX + digitSpacing * 2 + colonWidth, timeY, digitWidth, digitHeight, minuteTens, true);
        drawSevenSegmentDigit(dc, startX + digitSpacing * 3 + colonWidth, timeY, digitWidth, digitHeight, minuteOnes, true);
    }

    private function drawDate(dc as Graphics.Dc, day as Lang.Number, monthIndex as Lang.Number) as Void {
        var dateX = 12;
        var dateY = 25;
        var smallDigitWidth = 16;
        var smallDigitHeight = 22;
        var spacing = 16;
        
        // Draw day (DD)
        var dayTens = day / 10;
        var dayOnes = day % 10;
        
        drawSevenSegmentDigit(dc, dateX, dateY, smallDigitWidth, smallDigitHeight, dayTens, true);
        drawSevenSegmentDigit(dc, dateX + spacing, dateY, smallDigitWidth, smallDigitHeight, dayOnes, true);
        
        // Draw month text
        var monthX = dateX + spacing * 2 + 6;
        var monthArrayIndex = monthIndex - 1;
        drawMonthText(dc, monthX, dateY, monthArrayIndex);
    }

    private function drawHeartRate(dc as Graphics.Dc) as Void {
        var heartRate = 0;
        
        // Try to get heart rate data safely
        try {
            var hrInfo = ActivityMonitor.getHeartRateHistory(1, true);
            if (hrInfo != null) {
                var sample = hrInfo.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    heartRate = sample.heartRate;
                }
            }
        } catch (ex) {
            heartRate = 0;
        }
        
        // Position in top right corner
        var hrX = dc.getWidth() - 50;
        var hrY = 20;
        
        drawHeartRateDigits(dc, hrX, hrY, heartRate);
    }

    private function drawHeartRateDigits(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, hr as Lang.Number) as Void {
        var digitWidth = 18;
        var digitHeight = 28;
        var spacing = 20;
        
        // Convert heart rate to digits
        var hrStr = hr.toString();
        if (hrStr.length() == 1) {
            drawSevenSegmentDigit(dc, x + spacing, y, digitWidth, digitHeight, hr.toNumber(), false);
        } else if (hrStr.length() == 2) {
            var tens = (hr / 10).toNumber();
            var ones = hr % 10;
            drawSevenSegmentDigit(dc, x, y, digitWidth, digitHeight, tens, false);
            drawSevenSegmentDigit(dc, x + spacing, y, digitWidth, digitHeight, ones, false);
        } else {
            var hundreds = (hr / 100).toNumber();
            var tens = ((hr % 100) / 10).toNumber();
            var ones = hr % 10;
            drawSevenSegmentDigit(dc, x, y, digitWidth, digitHeight, hundreds, false);
            drawSevenSegmentDigit(dc, x + spacing, y, digitWidth, digitHeight, tens, false);
            drawSevenSegmentDigit(dc, x + spacing * 2, y, digitWidth, digitHeight, ones, false);
        }
    }

    private function drawBatteryIndicator(dc as Graphics.Dc) as Void {
        var centerX = dc.getWidth() / 2;
        var batteryY = dc.getHeight() - 25;
        
        // Battery outline
        var batteryWidth = 40;
        var batteryHeight = 16;
        var batteryX = centerX - batteryWidth / 2;
        
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(batteryX, batteryY, batteryWidth, batteryHeight);
        
        // Battery terminal
        dc.fillRectangle(batteryX + batteryWidth, batteryY + 4, 3, 8);
        
        // Battery level
        var batteryLevel = _batteryLevel;
        if (batteryLevel < 0 || batteryLevel > 100) {
            batteryLevel = 100;
        }
        
        var fillWidth = (batteryWidth - 2) * batteryLevel / 100;
        if (fillWidth > 0) {
            dc.fillRectangle(batteryX + 1, batteryY + 1, fillWidth, batteryHeight - 2);
        }
        
        // Battery percentage text
        var percentText = batteryLevel.toString() + "%";
        dc.drawText(centerX, batteryY - 5, Graphics.FONT_TINY, percentText, Graphics.TEXT_JUSTIFY_CENTER);
    }

    private function drawSevenSegmentDigit(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, digit as Lang.Number, showBackground as Lang.Boolean) as Void {
        var segments = _segmentMaps[digit];
        if (segments == null) {
            return;
        }
        
        // Calculate chamfered segment parameters
        var thickness = width > 20 ? 6 : 3;
        var chamferSize = thickness / 2;
        var gap = 3; // Increased gap for better separation
        
        // Calculate segment positions with proper chamfering
        var left = x + gap;
        var right = x + width - gap;
        var top = y + gap;
        var bottom = y + height - gap;
        var midY = y + height / 2;
        
        // Draw each segment with chamfered ends
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        // Segment a (top horizontal) - chamfered on both ends
        if (segments[0] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, top, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, top, thickness, chamferSize, 0);
        }
        
        // Segment b (top right vertical) - chamfered on top and middle
        if (segments[1] == 1) {
            drawChamferedVerticalSegment(dc, right - thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedVerticalSegment(dc, right - thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize, 1);
        }
        
        // Segment c (bottom right vertical) - chamfered on middle and bottom
        if (segments[2] == 1) {
            drawChamferedVerticalSegment(dc, right - thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedVerticalSegment(dc, right - thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize, 2);
        }
        
        // Segment d (bottom horizontal) - chamfered on both ends
        if (segments[3] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, bottom - thickness, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, bottom - thickness, thickness, chamferSize, 3);
        }
        
        // Segment e (bottom left vertical) - chamfered on middle and bottom
        if (segments[4] == 1) {
            drawChamferedVerticalSegment(dc, left + thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedVerticalSegment(dc, left + thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize, 4);
        }
        
        // Segment f (top left vertical) - chamfered on top and middle
        if (segments[5] == 1) {
            drawChamferedVerticalSegment(dc, left + thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedVerticalSegment(dc, left + thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize, 5);
        }
        
        // Segment g (middle horizontal) - chamfered on both ends
        if (segments[6] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, midY - thickness/2, thickness, chamferSize);
        } else if (showBackground) {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, midY - thickness/2, thickness, chamferSize, 6);
        }
    }

    private function drawChamferedHorizontalSegment(dc as Graphics.Dc, leftX as Lang.Number, rightX as Lang.Number, centerY as Lang.Number, thickness as Lang.Number, chamferSize as Lang.Number) as Void {
        var halfThickness = thickness / 2;
        var topY = centerY - halfThickness;
        var bottomY = centerY + halfThickness;
        
        // Main rectangle (center part)
        dc.fillRectangle(leftX + chamferSize, topY, rightX - leftX - 2 * chamferSize, thickness);
        
        // Left chamfer (angled cut)
        for (var i = 0; i < chamferSize; i++) {
            var lineX = leftX + i;
            var lineTopY = topY + i;
            var lineBottomY = bottomY - i;
            if (lineTopY <= lineBottomY) {
                dc.drawLine(lineX, lineTopY, lineX, lineBottomY);
            }
        }
        
        // Right chamfer (angled cut)
        for (var i = 0; i < chamferSize; i++) {
            var lineX = rightX - i - 1;
            var lineTopY = topY + i;
            var lineBottomY = bottomY - i;
            if (lineTopY <= lineBottomY) {
                dc.drawLine(lineX, lineTopY, lineX, lineBottomY);
            }
        }
    }

    private function drawChamferedVerticalSegment(dc as Graphics.Dc, centerX as Lang.Number, topY as Lang.Number, bottomY as Lang.Number, thickness as Lang.Number, chamferSize as Lang.Number) as Void {
        var halfThickness = thickness / 2;
        var leftX = centerX - halfThickness;
        var rightX = centerX + halfThickness;
        
        // Main rectangle (center part)
        dc.fillRectangle(leftX, topY + chamferSize, thickness, bottomY - topY - 2 * chamferSize);
        
        // Top chamfer (angled cut)
        for (var i = 0; i < chamferSize; i++) {
            var lineY = topY + i;
            var lineLeftX = leftX + i;
            var lineRightX = rightX - i;
            if (lineLeftX <= lineRightX) {
                dc.drawLine(lineLeftX, lineY, lineRightX, lineY);
            }
        }
        
        // Bottom chamfer (angled cut)
        for (var i = 0; i < chamferSize; i++) {
            var lineY = bottomY - i - 1;
            var lineLeftX = leftX + i;
            var lineRightX = rightX - i;
            if (lineLeftX <= lineRightX) {
                dc.drawLine(lineLeftX, lineY, lineRightX, lineY);
            }
        }
    }

    private function drawDitheredChamferedHorizontalSegment(dc as Graphics.Dc, leftX as Lang.Number, rightX as Lang.Number, centerY as Lang.Number, thickness as Lang.Number, chamferSize as Lang.Number, pattern as Lang.Number) as Void {
        var halfThickness = thickness / 2;
        var topY = centerY - halfThickness;
        var bottomY = centerY + halfThickness;
        
        // Main rectangle (center part) with dithering
        drawDitheredRect(dc, leftX + chamferSize, topY, rightX - leftX - 2 * chamferSize, thickness, pattern);
        
        // Left chamfer with dithering
        for (var i = 0; i < chamferSize; i++) {
            var lineX = leftX + i;
            var lineTopY = topY + i;
            var lineBottomY = bottomY - i;
            for (var py = lineTopY; py <= lineBottomY; py++) {
                if (shouldDitherPixel(lineX, py, pattern)) {
                    dc.drawPoint(lineX, py);
                }
            }
        }
        
        // Right chamfer with dithering
        for (var i = 0; i < chamferSize; i++) {
            var lineX = rightX - i - 1;
            var lineTopY = topY + i;
            var lineBottomY = bottomY - i;
            for (var py = lineTopY; py <= lineBottomY; py++) {
                if (shouldDitherPixel(lineX, py, pattern)) {
                    dc.drawPoint(lineX, py);
                }
            }
        }
    }

    private function drawDitheredChamferedVerticalSegment(dc as Graphics.Dc, centerX as Lang.Number, topY as Lang.Number, bottomY as Lang.Number, thickness as Lang.Number, chamferSize as Lang.Number, pattern as Lang.Number) as Void {
        var halfThickness = thickness / 2;
        var leftX = centerX - halfThickness;
        var rightX = centerX + halfThickness;
        
        // Main rectangle (center part) with dithering
        drawDitheredRect(dc, leftX, topY + chamferSize, thickness, bottomY - topY - 2 * chamferSize, pattern);
        
        // Top chamfer with dithering
        for (var i = 0; i < chamferSize; i++) {
            var lineY = topY + i;
            var lineLeftX = leftX + i;
            var lineRightX = rightX - i;
            for (var px = lineLeftX; px <= lineRightX; px++) {
                if (shouldDitherPixel(px, lineY, pattern)) {
                    dc.drawPoint(px, lineY);
                }
            }
        }
        
        // Bottom chamfer with dithering
        for (var i = 0; i < chamferSize; i++) {
            var lineY = bottomY - i - 1;
            var lineLeftX = leftX + i;
            var lineRightX = rightX - i;
            for (var px = lineLeftX; px <= lineRightX; px++) {
                if (shouldDitherPixel(px, lineY, pattern)) {
                    dc.drawPoint(px, lineY);
                }
            }
        }
    }

    private function shouldDitherPixel(x as Lang.Number, y as Lang.Number, pattern as Lang.Number) as Lang.Boolean {
        var ditherPattern = pattern % 3;
        
        switch (ditherPattern) {
            case 0: // Checkerboard
                return ((x + y) % 3 == 0);
            case 1: // Diagonal stripes
                return ((x + y) % 4 == 0);
            case 2: // Sparse dots
                return ((x * y) % 5 == 0);
            default:
                return ((x + y) % 3 == 0);
        }
    }

    private function drawDitheredRect(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, pattern as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        for (var px = x; px < x + width; px++) {
            for (var py = y; py < y + height; py++) {
                if (shouldDitherPixel(px, py, pattern)) {
                    dc.drawPoint(px, py);
                }
            }
        }
    }

    private function drawColon(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, height as Lang.Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var dotSize = 6;
        var quarterHeight = height / 4;
        
        // Upper dot
        dc.fillRectangle(x, y + quarterHeight - dotSize/2, dotSize, dotSize);
        // Lower dot
        dc.fillRectangle(x, y + height - quarterHeight - dotSize/2, dotSize, dotSize);
    }

    private function drawMonthText(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, monthIndex as Lang.Number) as Void {
        // Validate month index
        if (monthIndex < 0 || monthIndex >= _monthNames.size()) {
            monthIndex = 0;
        }
        
        var monthStr = _monthNames[monthIndex];
        if (monthStr == null) {
            return;
        }
        
        // Draw month using 7-segment patterns
        var charWidth = 16;
        var charHeight = 22;
        var charSpacing = 16;
        
        for (var i = 0; i < monthStr.length(); i++) {
            var char = monthStr.substring(i, i + 1);
            drawMonthChar(dc, x + i * charSpacing, y, charWidth, charHeight, char);
        }
    }

    private function drawMonthChar(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, char as Lang.String) as Void {
        // 7-segment patterns for month abbreviations
        var patterns = {
            "J" => [0, 0, 1, 1, 1, 0, 0],  // J pattern
            "A" => [1, 1, 0, 0, 0, 1, 1],  // A pattern
            "N" => [0, 0, 1, 0, 1, 0, 1],  // N pattern
            "F" => [1, 0, 0, 0, 1, 1, 1],  // F pattern
            "E" => [1, 0, 0, 1, 1, 1, 1],  // E pattern
            "B" => [0, 1, 1, 1, 1, 1, 1],  // B pattern
            "R" => [0, 0, 0, 0, 1, 0, 1],  // R pattern
            "M" => [1, 1, 1, 0, 1, 1, 0],  // M pattern
            "Y" => [0, 1, 1, 1, 0, 1, 1],  // Y pattern
            "L" => [0, 0, 0, 1, 1, 1, 0],  // L pattern
            "G" => [1, 0, 1, 1, 1, 1, 1],  // G pattern
            "T" => [0, 0, 0, 1, 1, 1, 1],  // T pattern
            "U" => [0, 1, 1, 1, 1, 1, 0],  // U pattern
            "S" => [1, 0, 1, 1, 0, 1, 1],  // S pattern
            "O" => [1, 1, 1, 1, 1, 1, 0],  // O pattern
            "C" => [1, 0, 0, 1, 1, 1, 0],  // C pattern
            "D" => [0, 1, 1, 1, 1, 1, 0],  // D pattern
            "H" => [0, 1, 1, 0, 1, 1, 1],  // H pattern
            "I" => [0, 1, 1, 0, 0, 0, 0],  // I pattern
            "P" => [1, 1, 0, 0, 1, 1, 1],  // P pattern
            "V" => [0, 1, 1, 1, 1, 1, 0],  // V pattern
            "W" => [0, 1, 1, 1, 1, 1, 0]   // W pattern
        };
        
        var pattern = patterns.get(char);
        if (pattern != null) {
            var patternArray = pattern as Lang.Array<Lang.Number>;
            drawMiniSevenSeg(dc, x, y, width, height, patternArray);
        }
    }

    private function drawMiniSevenSeg(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number, width as Lang.Number, height as Lang.Number, segments as Lang.Array<Lang.Number>) as Void {
        var thickness = 3;
        var chamferSize = 1;
        var gap = 2;
        
        // Calculate segment positions with chamfering
        var left = x + gap;
        var right = x + width - gap;
        var top = y + gap;
        var bottom = y + height - gap;
        var midY = y + height / 2;
        
        // Draw each segment with chamfering
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        
        // Segment a (top horizontal)
        if (segments[0] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, top, thickness, chamferSize);
        } else {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, top, thickness, chamferSize, 0);
        }
        
        // Segment b (top right vertical)
        if (segments[1] == 1) {
            drawChamferedVerticalSegment(dc, right - thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize);
        } else {
            drawDitheredChamferedVerticalSegment(dc, right - thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize, 1);
        }
        
        // Segment c (bottom right vertical)
        if (segments[2] == 1) {
            drawChamferedVerticalSegment(dc, right - thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize);
        } else {
            drawDitheredChamferedVerticalSegment(dc, right - thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize, 2);
        }
        
        // Segment d (bottom horizontal)
        if (segments[3] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, bottom - thickness, thickness, chamferSize);
        } else {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, bottom - thickness, thickness, chamferSize, 3);
        }
        
        // Segment e (bottom left vertical)
        if (segments[4] == 1) {
            drawChamferedVerticalSegment(dc, left + thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize);
        } else {
            drawDitheredChamferedVerticalSegment(dc, left + thickness/2, midY + chamferSize, bottom - chamferSize, thickness, chamferSize, 4);
        }
        
        // Segment f (top left vertical)
        if (segments[5] == 1) {
            drawChamferedVerticalSegment(dc, left + thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize);
        } else {
            drawDitheredChamferedVerticalSegment(dc, left + thickness/2, top + chamferSize, midY - chamferSize, thickness, chamferSize, 5);
        }
        
        // Segment g (middle horizontal)
        if (segments[6] == 1) {
            drawChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, midY - thickness/2, thickness, chamferSize);
        } else {
            drawDitheredChamferedHorizontalSegment(dc, left + chamferSize, right - chamferSize, midY - thickness/2, thickness, chamferSize, 6);
        }
    }

    function onPartialUpdate(dc as Graphics.Dc) as Void {
        // Only update if time has changed (battery optimization)
        var currentMinute = System.getClockTime().min;
        if (currentMinute != _lastUpdateTime) {
            onUpdate(dc);
        }
    }
}