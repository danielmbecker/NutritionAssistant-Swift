//
//  LabelOpticalTelemetryAnalyzer.swift
//  NutritionAssistant
//
//  Milestone 5.1: 5-Metric Optical & Physical Telemetry Analyzer
//  Computes labelResolution, labelLighting (including specular glare clipping),
//  photoAngle (perspective trapezoid distortion), labelSharpness (Laplacian focus variance),
//  and labelCurvature (parabolic baseline bowing on cans/bottles).
//

import CoreGraphics
import Foundation
import ImageIO

enum LabelOpticalTelemetryAnalyzer {

    // MARK: - Public Entry Points

    /// Analyzes raw image `Data` alongside the Vision `ScannedDocumentSnapshot` and `FDAClassifiedLabel`
    /// to compute all 5 optical and physical telemetry metrics.
    static func analyze(
        imageData: Data,
        snapshot: ScannedDocumentSnapshot,
        classified: FDAClassifiedLabel,
        quadCorners: [CGPoint]? = nil
    ) -> LabelOpticalTelemetry {
        let (cgImage, orientation) = decodeCGImageAndOrientation(from: imageData)
        return analyze(
            cgImage: cgImage,
            orientation: orientation,
            snapshot: snapshot,
            classified: classified,
            quadCorners: quadCorners
        )
    }

    /// Analyzes a `CGImage` alongside the Vision `ScannedDocumentSnapshot` and `FDAClassifiedLabel`
    /// to compute all 5 optical and physical telemetry metrics.
    static func analyze(
        cgImage: CGImage?,
        orientation: CGImagePropertyOrientation? = nil,
        snapshot: ScannedDocumentSnapshot,
        classified: FDAClassifiedLabel,
        quadCorners: [CGPoint]? = nil
    ) -> LabelOpticalTelemetry {
        // 1. Compute labelResolution metrics.
        let (imgW, imgH, effW, effH, areaRatio, medianLinePx) = computeResolutionMetrics(
            cgImage: cgImage,
            orientation: orientation,
            classified: classified
        )

        // 2 & 4. Compute labelLighting and labelSharpness from an 8-bit luma sample of the label region.
        let (meanLuma, contrastStd, glareRatio, lightingClass, sharpnessScore, isBlurred) =
            computeLightingAndSharpnessMetrics(
                cgImage: cgImage,
                labelBox: classified.labelRegionBoundingBox
            )

        // 5. Compute labelCurvature (parabolic horizontal baseline bowing across multi-word lines).
        let (bowingRatio, isCurved) = computeCurvatureMetrics(
            snapshot: snapshot,
            classified: classified
        )

        // 3. Compute photoAngle (horizontal/vertical trapezoid ratios and composite perspective angle).
        let (hRatio, vRatio, perspectiveDegrees) = computePhotoAngleMetrics(
            snapshot: snapshot,
            classified: classified,
            quadCorners: quadCorners
        )

        return LabelOpticalTelemetry(
            imagePixelWidth: imgW,
            imagePixelHeight: imgH,
            effectiveLabelPixelWidth: effW,
            effectiveLabelPixelHeight: effH,
            labelAreaCoverageRatio: areaRatio,
            medianLinePixelHeight: medianLinePx,
            meanLuminance: meanLuma,
            contrastStdDev: contrastStd,
            glareClippingRatio: glareRatio,
            lightingClassification: lightingClass,
            horizontalTrapezoidRatio: hRatio,
            verticalTrapezoidRatio: vRatio,
            estimatedPerspectiveAngleDegrees: perspectiveDegrees,
            sharpnessScore: sharpnessScore,
            isLikelyBlurred: isBlurred,
            horizontalBaselineBowingRatio: bowingRatio,
            isCurvedSurfaceLikely: isCurved
        )
    }

    // MARK: - 1. Label Resolution Analysis

    private static func computeResolutionMetrics(
        cgImage: CGImage?,
        orientation: CGImagePropertyOrientation?,
        classified: FDAClassifiedLabel
    ) -> (
        imageWidth: Int,
        imageHeight: Int,
        effectiveWidth: Int,
        effectiveHeight: Int,
        areaCoverage: Double,
        medianLinePixelHeight: Double
    ) {
        guard let cgImage else {
            return (0, 0, 0, 0, 0.0, 0.0)
        }

        let swapsDimensions: Bool
        if let orientation {
            switch orientation {
            case .left, .right, .leftMirrored, .rightMirrored:
                swapsDimensions = true
            default:
                swapsDimensions = false
            }
        } else {
            swapsDimensions = false
        }

        let imageWidth = swapsDimensions ? cgImage.height : cgImage.width
        let imageHeight = swapsDimensions ? cgImage.width : cgImage.height

        let clampedBox = clampNormalizedRect(classified.labelRegionBoundingBox)
        let effectiveWidth = max(1, Int((Double(imageWidth) * Double(clampedBox.width)).rounded()))
        let effectiveHeight = max(1, Int((Double(imageHeight) * Double(clampedBox.height)).rounded()))
        let areaCoverage = min(max(Double(clampedBox.width * clampedBox.height), 0.0), 1.0)
        let medianLinePx = max(0.0, Double(classified.medianBodyLineHeight) * Double(imageHeight))

        return (imageWidth, imageHeight, effectiveWidth, effectiveHeight, areaCoverage, medianLinePx)
    }

    // MARK: - 2 & 4. Label Lighting (Luma, Contrast, Glare) & Label Sharpness (Laplacian Variance)

    private static func computeLightingAndSharpnessMetrics(
        cgImage: CGImage?,
        labelBox: CGRect
    ) -> (
        meanLuminance: Double,
        contrastStdDev: Double,
        glareClippingRatio: Double,
        classification: LabelLightingClassification,
        sharpnessScore: Double,
        isLikelyBlurred: Bool
    ) {
        guard let cgImage, cgImage.width > 4, cgImage.height > 4 else {
            return (0.5, 0.2, 0.0, .balanced, 50.0, false)
        }

        let clamped = clampNormalizedRect(labelBox)
        let cropX = Int((CGFloat(cgImage.width) * clamped.minX).rounded(.down))
        let cropY = Int((CGFloat(cgImage.height) * clamped.minY).rounded(.down))
        let cropW = max(8, min(cgImage.width - cropX, Int((CGFloat(cgImage.width) * clamped.width).rounded())))
        let cropH = max(8, min(cgImage.height - cropY, Int((CGFloat(cgImage.height) * clamped.height).rounded())))

        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)
        let targetImage = cgImage.cropping(to: cropRect) ?? cgImage

        // Downsample into a bounded 8-bit grayscale grid (up to 240x240) for fast, deterministic O(N) pixel statistics.
        let maxSampleDimension = 240
        let scale = min(
            1.0,
            Double(maxSampleDimension) / Double(max(targetImage.width, targetImage.height))
        )
        let sampleW = max(16, Int((Double(targetImage.width) * scale).rounded()))
        let sampleH = max(16, Int((Double(targetImage.height) * scale).rounded()))

        var pixels = [UInt8](repeating: 0, count: sampleW * sampleH)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: &pixels,
            width: sampleW,
            height: sampleH,
            bitsPerComponent: 8,
            bytesPerRow: sampleW,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return (0.5, 0.2, 0.0, .balanced, 50.0, false)
        }

        context.interpolationQuality = .medium
        context.draw(targetImage, in: CGRect(x: 0, y: 0, width: sampleW, height: sampleH))

        let totalCount = Double(pixels.count)
        guard totalCount > 0 else {
            return (0.5, 0.2, 0.0, .balanced, 50.0, false)
        }

        // First pass: Mean luminance and high-luma clipping count.
        var sumLuma: Double = 0.0
        var clippedBrightCount: Int = 0

        for px in pixels {
            let norm = Double(px) / 255.0
            sumLuma += norm
            if px >= 245 {
                clippedBrightCount += 1
            }
        }

        let meanLuma = sumLuma / totalCount

        // Second pass: Contrast (standard deviation of normalized luminance).
        var varianceSum: Double = 0.0
        for px in pixels {
            let diff = (Double(px) / 255.0) - meanLuma
            varianceSum += diff * diff
        }
        let contrastStdDev = (varianceSum / totalCount).squareRoot()

        // Interior pass: 2D Laplacian operator for sharpness & specular glare washout detection.
        // A specular glare patch has both very high brightness (px >= 245) and low local text contrast
        // or sits adjacent to washed-out gradients.
        var laplacianSum: Double = 0.0
        var laplacianSqSum: Double = 0.0
        var interiorCount: Int = 0
        var specularGlarePixelCount: Int = 0

        for y in 1..<(sampleH - 1) {
            let rowOffset = y * sampleW
            for x in 1..<(sampleW - 1) {
                let idx = rowOffset + x
                let center = Double(pixels[idx])
                let left = Double(pixels[idx - 1])
                let right = Double(pixels[idx + 1])
                let up = Double(pixels[idx - sampleW])
                let down = Double(pixels[idx + sampleW])

                let lap = abs((4.0 * center) - left - right - up - down) / 255.0
                laplacianSum += lap
                laplacianSqSum += lap * lap
                interiorCount += 1

                if pixels[idx] >= 246 {
                    // Check if 3x3 neighborhood is saturated (specular reflection blob vs clean white paper background).
                    let neighborAvg = (left + right + up + down) / 4.0
                    if neighborAvg >= 244.0 {
                        specularGlarePixelCount += 1
                    }
                }
            }
        }

        let rawBrightRatio = Double(clippedBrightCount) / totalCount
        let saturatedBlobRatio = interiorCount > 0 ? (Double(specularGlarePixelCount) / Double(interiorCount)) : 0.0
        // If the label is mostly white background (e.g. standard black-on-white artwork), high white ratio with high contrast (>0.22)
        // is normal paper whiteness; specular glare manifests either as localized blowout with lowered contrast or intense saturation.
        let glareClippingRatio: Double
        if contrastStdDev >= 0.24 && meanLuma <= 0.86 {
            glareClippingRatio = max(0.0, saturatedBlobRatio * 0.35)
        } else {
            glareClippingRatio = min(1.0, max(saturatedBlobRatio, rawBrightRatio * 0.65))
        }

        // Compute normalized sharpness score (0.0 - 100.0) from Laplacian standard deviation normalized by contrast.
        let lapMean = interiorCount > 0 ? (laplacianSum / Double(interiorCount)) : 0.0
        let lapVar = interiorCount > 0 ? max(0.0, (laplacianSqSum / Double(interiorCount)) - (lapMean * lapMean)) : 0.0
        let lapStd = lapVar.squareRoot()
        let contrastNormalizer = max(0.08, min(contrastStdDev, 0.35))
        let normalizedEdgeResponse = (lapStd / contrastNormalizer) * 95.0
        let sharpnessScore = min(100.0, max(0.0, normalizedEdgeResponse))
        let isLikelyBlurred = sharpnessScore < 22.0

        // Classify overall lighting state.
        let classification: LabelLightingClassification
        if glareClippingRatio >= 0.12 && contrastStdDev < 0.21 {
            classification = .highSpecularGlare
        } else if meanLuma < 0.24 {
            classification = .lowLight
        } else if meanLuma > 0.90 && contrastStdDev < 0.13 {
            classification = .overexposed
        } else if contrastStdDev < 0.11 {
            classification = .lowContrast
        } else {
            classification = .balanced
        }

        return (meanLuma, contrastStdDev, glareClippingRatio, classification, sharpnessScore, isLikelyBlurred)
    }

    // MARK: - 3. Photo Angle & Perspective Foreshortening Analysis

    private static func computePhotoAngleMetrics(
        snapshot: ScannedDocumentSnapshot,
        classified: FDAClassifiedLabel,
        quadCorners: [CGPoint]?
    ) -> (
        horizontalTrapezoidRatio: Double,
        verticalTrapezoidRatio: Double,
        estimatedPerspectiveDegrees: Double
    ) {
        var hRatio: Double = 1.0
        var vRatio: Double = 1.0

        if let corners = quadCorners, corners.count == 4 {
            // Expected order: [topLeft, topRight, bottomRight, bottomLeft] in top-left normalized coordinates.
            let topLeft = corners[0]
            let topRight = corners[1]
            let bottomRight = corners[2]
            let bottomLeft = corners[3]

            let topWidth = hypot(topRight.x - topLeft.x, topRight.y - topLeft.y)
            let bottomWidth = hypot(bottomRight.x - bottomLeft.x, bottomRight.y - bottomLeft.y)
            let leftHeight = hypot(bottomLeft.x - topLeft.x, bottomLeft.y - topLeft.y)
            let rightHeight = hypot(bottomRight.x - topRight.x, bottomRight.y - topRight.y)

            if bottomWidth > 0.01 {
                hRatio = Double(topWidth / bottomWidth)
            }
            if rightHeight > 0.01 {
                vRatio = Double(leftHeight / rightHeight)
            }
        } else {
            // Fallback: Estimate horizontal trapezoid foreshortening from top-half vs bottom-half full-width lines.
            let allBlocks = snapshot.textBlocks + (classified.primaryTable?.allUniqueCells.flatMap(\.paragraphs) ?? [])
            let labelBox = classified.labelRegionBoundingBox
            let midLabelY = labelBox.midY

            let topSpans = allBlocks
                .filter { $0.midY < midLabelY && $0.width >= labelBox.width * 0.45 }
                .map(\.width)
            let bottomSpans = allBlocks
                .filter { $0.midY >= midLabelY && $0.width >= labelBox.width * 0.45 }
                .map(\.width)

            if let maxTop = topSpans.max(), let maxBottom = bottomSpans.max(), maxBottom > 0.01 {
                hRatio = Double(maxTop / maxBottom)
            }
        }

        hRatio = min(max(hRatio, 0.5), 2.0)
        vRatio = min(max(vRatio, 0.5), 2.0)

        // Convert trapezoid foreshortening + 2D skew slope into an estimated composite camera angle in degrees.
        let skewSlope = Double(VisionSpatialRowStitcher.estimateSkewSlope(from: snapshot.textBlocks))
        let rollDegrees = abs(atan(skewSlope) * 180.0 / .pi)
        let pitchDistortion = abs(1.0 - hRatio)
        let yawDistortion = abs(1.0 - vRatio)
        let perspectiveRadians = acos(max(0.25, min(1.0, 1.0 - hypot(pitchDistortion, yawDistortion) * 0.85)))
        let perspectiveDegrees = perspectiveRadians * 180.0 / .pi
        let combinedAngle = min(75.0, hypot(perspectiveDegrees, rollDegrees))

        return (hRatio, vRatio, combinedAngle)
    }

    // MARK: - 5. Cylindrical Curvature (Horizontal Baseline Bowing) Analysis

    private static func computeCurvatureMetrics(
        snapshot: ScannedDocumentSnapshot,
        classified: FDAClassifiedLabel
    ) -> (horizontalBaselineBowingRatio: Double, isCurvedSurfaceLikely: Bool) {
        var allLines: [ScannedTextLine] = snapshot.textBlocks.flatMap(\.lines)
        for table in snapshot.tables {
            for cell in table.allUniqueCells {
                allLines.append(contentsOf: cell.lines)
            }
        }

        let minLineWidth = max(0.10, classified.labelRegionBoundingBox.width * 0.28)
        var bowingRatios: [Double] = []

        for line in allLines where line.words.count >= 3 && line.width >= minLineWidth {
            let sortedWords = line.words.sorted { $0.midX < $1.midX }
            guard let first = sortedWords.first, let last = sortedWords.last else { continue }
            let chordDX = last.midX - first.midX
            guard chordDX >= minLineWidth else { continue }

            let chordSlope = (last.midY - first.midY) / chordDX
            var maxInteriorDeflection: CGFloat = 0.0

            for interiorWord in sortedWords.dropFirst().dropLast() {
                let expectedY = first.midY + chordSlope * (interiorWord.midX - first.midX)
                let deflection = abs(interiorWord.midY - expectedY)
                if deflection > maxInteriorDeflection {
                    maxInteriorDeflection = deflection
                }
            }

            let ratio = Double(maxInteriorDeflection / chordDX)
            if ratio <= 0.20 {
                bowingRatios.append(ratio)
            }
        }

        guard !bowingRatios.isEmpty else {
            return (0.0, false)
        }

        let sorted = bowingRatios.sorted()
        let medianBowing = sorted[sorted.count / 2]
        let isCurved = medianBowing >= 0.014
        return (medianBowing, isCurved)
    }

    // MARK: - Private ImageIO & Geometry Helpers

    private static func decodeCGImageAndOrientation(
        from imageData: Data
    ) -> (CGImage?, CGImagePropertyOrientation?) {
        guard !imageData.isEmpty,
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return (nil, nil)
        }

        var orientation: CGImagePropertyOrientation?
        if let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let rawOrientation = props[kCGImagePropertyOrientation] as? UInt32,
           let parsed = CGImagePropertyOrientation(rawValue: rawOrientation) {
            orientation = parsed
        }
        return (cgImage, orientation)
    }

    private static func clampNormalizedRect(_ rect: CGRect) -> CGRect {
        let minX = min(max(rect.minX, 0.0), 0.98)
        let minY = min(max(rect.minY, 0.0), 0.98)
        let maxX = min(max(rect.maxX, minX + 0.02), 1.0)
        let maxY = min(max(rect.maxY, minY + 0.02), 1.0)
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
