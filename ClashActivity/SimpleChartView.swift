//
//  SimpleChartView 2.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/25.
//


//
//  ChartView.swift
//  ClashR
//
//  Created by 董康鑫 on 2025/10/25.
//


// SimpleChartView.swift - 简化版（推荐用于 Widget）
import SwiftUI


struct SimpleChartView: View {
    
    let chartData: ChartData
    let lineColor: Color = .blue
    let showBackground: Bool = true
    let smoothness: CGFloat = 0.2
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            if showBackground {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.05))
            }
            
            if chartData.dataPoints.count > 1 {
                Canvas { context, size in
                    let padding: CGFloat = 4
                    let drawableWidth = size.width - (padding * 2)
                    let drawableHeight = size.height - (padding * 2)
                    
                    guard chartData.dataPoints.count > 0 else { return }
                    
                    let maxValue = chartData.maxValue
                    let minValue = chartData.minValue
                    let range = maxValue - minValue > 0 ? maxValue - minValue : 1
                    
                    // ✅ 修改：不均匀分散，而是根据数据点数量调整宽度
                    var points: [CGPoint] = []
                    
                    // 计算实际使用的宽度（少于20个点时，只用到需要的宽度）
                    let maxDataPoints = min(chartData.dataPoints.count, 20)
                    let usedWidth = drawableWidth * CGFloat(chartData.dataPoints.count - 1) / CGFloat(19)  // 20个点时用满
                    
                    for (index, dataPoint) in chartData.dataPoints.enumerated() {
                        // ✅ 靠左对齐：使用 usedWidth 而不是 drawableWidth
                        let xStep = usedWidth / CGFloat(max(chartData.dataPoints.count - 1, 1))
                        let x = padding + CGFloat(index) * xStep
                        
                        let normalized = (dataPoint.value - minValue) / range
                        let y = padding + drawableHeight - (normalized * drawableHeight)
                        
                        points.append(CGPoint(x: x, y: y))
                    }
                    
                    // ✅ 使用温和的曲线连接（转角处圆滑）
                    if points.count > 1 {
                        var path = Path()
                        path.move(to: points[0])
                        
                        for i in 1..<points.count {
                            let currentPoint = points[i]
                            let previousPoint = points[i - 1]
                            
                            // 计算控制点（转角处圆滑）
//                            if i == 1 {
//                                // 第一段：直接连接
//                                path.addLine(to: currentPoint)
//                            } else {
                                // 后续段：使用小的曲线平滑转角
                                let controlPoint1 = CGPoint(
                                    x: previousPoint.x + (currentPoint.x - previousPoint.x) * 0.3,
                                    y: previousPoint.y
                                )
                                let controlPoint2 = CGPoint(
                                    x: currentPoint.x - (currentPoint.x - previousPoint.x) * 0.3,
                                    y: currentPoint.y
                                )
                                
                                path.addCurve(
                                    to: currentPoint,
                                    control1: controlPoint1,
                                    control2: controlPoint2
                                )
//                            }
                        }
                        
                        context.stroke(
                            path,
                            with: .color(lineColor),
                            lineWidth: 1.5
                        )
                    }
                    
                    // 绘制数据点
                    for (index, point) in points.enumerated() {
                        let isLastPoint = index == points.count - 1
                        
                        if isLastPoint {
                            drawBreathingDot(context: context, point: point)
                        }
                    }
                }
            }
        }
        .cornerRadius(4)
        .onAppear {
            if chartData.dataPoints.count > 1 {
                startAnimation()
            }
        }
        .onChange(of: chartData.dataPoints.count) { oldValue, newValue in
            if newValue > 1 {
                startAnimation()
            }
        }
    }
    
    private func drawBreathingDot(context: GraphicsContext, point: CGPoint) {
        let baseScale: CGFloat = isAnimating ? 1.3 : 1.0
        let baseOpacity: Double = isAnimating ? 0.8 : 0.5
        
        // 第三层光晕
        let outerRadius3 = 6.0 * baseScale
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - outerRadius3,
                y: point.y - outerRadius3,
                width: outerRadius3 * 2,
                height: outerRadius3 * 2
            )),
            with: .color(lineColor.opacity(baseOpacity * 0.2))
        )
        
        // 第二层光晕
        let outerRadius2 = 4.5 * baseScale
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - outerRadius2,
                y: point.y - outerRadius2,
                width: outerRadius2 * 2,
                height: outerRadius2 * 2
            )),
            with: .color(lineColor.opacity(baseOpacity * 0.5))
        )
        
        // 第一层光晕
        let outerRadius1 = 3.5 * baseScale
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - outerRadius1,
                y: point.y - outerRadius1,
                width: outerRadius1 * 2,
                height: outerRadius1 * 2
            )),
            with: .color(lineColor.opacity(baseOpacity))
        )
        
        // 中心点
        context.fill(
            Path(ellipseIn: CGRect(
                x: point.x - 2,
                y: point.y - 2,
                width: 4,
                height: 4
            )),
            with: .color(lineColor)
        )
    }
    
    private func startAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }
    }
}

#Preview {
    SimpleChartView(
        chartData: ChartData(
            dataPoints: [
                ChartDataPoint(value: 800, timestamp: Date()),
                ChartDataPoint(value: 2000, timestamp: Date()),
                ChartDataPoint(value: 1500, timestamp: Date()),
                ChartDataPoint(value: 2500, timestamp: Date()),
                ChartDataPoint(value: 1800, timestamp: Date())
            ]
        )
    )
    .padding()
}

