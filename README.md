# 7-Segment Watch Face for Garmin Instinct 2

A beautiful, professional digital watch face inspired by classic 7-segment displays, designed specifically for the Garmin Instinct 2's 176×176 monochrome MIP display.

## Features

- **Professional 7-segment time display**: Large, clear time in 24-hour format with proper segment geometry
- **Advanced dithering system**: Multiple dithering patterns for unlit segments creating beautiful gray appearance
- **Date display**: Day and month in elegant 7-segment style (top left)
- **Heart rate monitor**: Current BPM display in 7-segment digits (top right)
- **Battery indicator**: Visual battery level with percentage (bottom center)
- **Rounded segments**: Optional rounded segment ends for premium look
- **Battery optimized**: Smart partial updates and efficient rendering

## Design Philosophy

This watch face transforms the constraints of the 1-bit MIP display into an advantage by using sophisticated dithering techniques to create the appearance of multiple gray levels. The result is a watch face that looks professional and modern while maintaining excellent readability and battery efficiency.

## Key Improvements

- **Fixed dithering**: Proper dithering algorithms with multiple patterns (checkerboard, diagonal stripes, sparse dots)
- **Correct segment mapping**: All digits now display properly with accurate 7-segment patterns
- **Beautiful typography**: Month abbreviations use proper 7-segment character patterns
- **Enhanced layout**: Optimized positioning for 176×176 display with better spacing
- **Professional rendering**: Rounded segments, proper thickness calculations, and anti-aliasing simulation
- **Smart updates**: Only redraws when time changes, saving battery

## Installation

1. Build using Connect IQ SDK 3.2.0+
2. Deploy to Garmin Instinct 2 via Connect IQ Store or sideloading

## Technical Details

- **Display**: 176×176 monochrome MIP
- **Language**: Monkey C
- **Target Device**: Garmin Instinct 2
- **SDK Version**: 3.2.0+
- **Rendering**: Advanced dithering with multiple patterns
- **Optimization**: Partial updates, efficient segment calculations

## Dithering Patterns

The watch face uses three different dithering patterns to create visual variety:
1. **Checkerboard**: Classic 50% dithering for consistent gray
2. **Diagonal Stripes**: Creates subtle texture variation
3. **Sparse Dots**: Provides a softer, more organic appearance

## Segment Geometry

All 7-segments are properly calculated with:
- Optimal thickness based on digit size
- Proper spacing between segments
- Accurate segment positioning
- Support for rounded segment ends

The watch face uses efficient rendering techniques optimized for the MIP display technology, ensuring minimal battery drain while providing a premium, professional appearance in all lighting conditions.