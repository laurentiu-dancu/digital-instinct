# 7-Segment Watch Face for Garmin Instinct 2

A minimalist digital watch face inspired by classic 7-segment displays, designed specifically for the Garmin Instinct 2's 176×176 monochrome MIP display.

## Features

- **Classic 7-segment time display**: Large, clear time in 24-hour format
- **Date display**: Day and month in compact 7-segment style (top left)
- **Heart rate monitor**: Current BPM display (top right, optimized for round area)
- **Dithered gray segments**: Unlit segments shown with subtle dithered pattern
- **Battery optimized**: Designed for the Instinct 2's always-on display

## Design Philosophy

This watch face embraces the constraints of the 1-bit MIP display by using dithering techniques to create the appearance of gray for unlit segments, while maintaining excellent readability and battery efficiency.

## Installation

1. Build using Connect IQ SDK
2. Deploy to Garmin Instinct 2 via Connect IQ Store or sideloading

## Technical Details

- **Display**: 176×176 monochrome MIP
- **Language**: Monkey C
- **Target Device**: Garmin Instinct 2
- **SDK Version**: 3.2.0+

The watch face uses efficient rendering techniques optimized for the MIP display technology, ensuring minimal battery drain while providing clear time visibility in all lighting conditions.