//
//  CorrelationChartView.swift
//  IronPath
//
//  Created by Gabriel Hollenbeck on 12/27/25.
//

import SwiftUI
import Charts

struct CorrelationChartView: View {
    let data: CorrelationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Protein vs Volume")
                .font(.headline)
            
            Chart {
                ForEach(data.dataPoints, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Protein", point.proteinIntake)
                    )
                    .foregroundStyle(Color.macroProtein)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Volume", point.workoutVolume / 10)
                    )
                    .foregroundStyle(Color.macroCarbs)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisValueLabel() {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)g")
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
        }
    }
}

#Preview {
    CorrelationChartView(
        data: CorrelationData(
            startDate: Date(),
            endDate: Date(),
            dataPoints: []
        )
    )
    .padding()
}

