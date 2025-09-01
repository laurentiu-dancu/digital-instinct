#!/bin/bash

echo "Building 7-Segment Watch Face for Garmin Instinct 2..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "manifest.xml" ]; then
    echo "Error: manifest.xml not found. Please run this script from the project root."
    exit 1
fi

# Check if Monkey C compiler is available
if ! command -v monkeyc &> /dev/null; then
    echo "Warning: Monkey C compiler not found in PATH"
    echo "Please install Connect IQ SDK and add it to your PATH"
    echo "You can still build manually using:"
    echo "monkeyc -o out/face.prg -m manifest.xml -z resources/resources.zip source/*.mc"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p out

# Build the project
echo "Compiling source files..."
monkeyc -o out/face.prg -m manifest.xml -z resources/resources.zip source/*.mc

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Output file: out/face.prg"
    echo ""
    echo "To deploy to your device:"
    echo "1. Connect your Garmin Instinct 2"
    echo "2. Use Connect IQ Manager or sideload the .prg file"
else
    echo "❌ Build failed!"
    exit 1
fi
