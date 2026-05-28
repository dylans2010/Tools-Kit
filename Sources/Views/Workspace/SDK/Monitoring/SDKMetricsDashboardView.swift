// ToolsKit — SDKMetricsDashboardView.swift
// SDK Expansion — Phase 3

import SwiftUI

struct SDKMetricsDashboardView: View {
    @StateObject private var metricsCollector = SDKMetricsCollector.shared
    @State private var selectedMetricName: String?
    @State private var filterKind: SDKMetricPoint.MetricKind?

    private var snapshot: SDKMetricsSnapshot {
        metricsCollector.snapshot()
    }

    private var filteredPoints: [SDKMetricPoint] {
        guard let kind = filterKind else { return metricsCollector.recentPoints }
        return metricsCollector.recentPoints.filter { $0.kind == kind }
    }

    var body: some View {
        List {
            overviewSection
            countersSection
            gaugesSection
            timingsSection
            recentActivitySection
            actionsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Metrics Dashboard")
    }

    private var overviewSection: some View {
        Section(header: Text("Overview")) {
            LabeledContent("Total Points Recorded", value: "\(metricsCollector.totalPointsRecorded)")
            LabeledContent("Counters", value: "\(snapshot.counters.count)")
            LabeledContent("Gauges", value: "\(snapshot.gauges.count)")
            LabeledContent("Timings", value: "\(snapshot.timings.count)")
            LabeledContent("Metric Names", value: "\(metricsCollector.allMetricNames().count)")
        }
    }

    private var countersSection: some View {
        Section(header: Text("Counters")) {
            if snapshot.counters.isEmpty {
                Text("No counters recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.counters.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text(name)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Text("\(value)")
                            .font(.subheadline.bold().monospacedDigit())
                    }
                }
            }
        }
    }

    private var gaugesSection: some View {
        Section(header: Text("Gauges")) {
            if snapshot.gauges.isEmpty {
                Text("No gauges recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.gauges.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                    HStack {
                        Image(systemName: "gauge.medium")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text(name)
                            .font(.system(.caption, design: .monospaced))
                        Spacer()
                        Text(String(format: "%.2f", value))
                            .font(.subheadline.bold().monospacedDigit())
                    }
                }
            }
        }
    }

    private var timingsSection: some View {
        Section(header: Text("Timings")) {
            if snapshot.timings.isEmpty {
                Text("No timings recorded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.timings.sorted(by: { $0.key < $1.key }), id: \.key) { name, values in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(.green)
                                .frame(width: 24)
                            Text(name)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Text("\(values.count) samples")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: 16) {
                            if let avg = snapshot.averageTiming(for: name) {
                                VStack(alignment: .leading) {
                                    Text("Avg")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                    Text(String(format: "%.1fms", avg * 1000))
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if let p95 = snapshot.p95Timing(for: name) {
                                VStack(alignment: .leading) {
                                    Text("P95")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                    Text(String(format: "%.1fms", p95 * 1000))
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if let min = values.min() {
                                VStack(alignment: .leading) {
                                    Text("Min")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                    Text(String(format: "%.1fms", min * 1000))
                                        .font(.caption.monospacedDigit())
                                }
                            }
                            if let max = values.max() {
                                VStack(alignment: .leading) {
                                    Text("Max")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.tertiary)
                                    Text(String(format: "%.1fms", max * 1000))
                                        .font(.caption.monospacedDigit())
                                }
                            }
                        }
                        .padding(.leading, 32)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var recentActivitySection: some View {
        Section(header: Text("Recent Activity")) {
            Picker("Filter", selection: $filterKind) {
                Text("All").tag(Optional<SDKMetricPoint.MetricKind>.none)
                Text("Counter").tag(Optional(SDKMetricPoint.MetricKind.counter))
                Text("Gauge").tag(Optional(SDKMetricPoint.MetricKind.gauge))
                Text("Timing").tag(Optional(SDKMetricPoint.MetricKind.timing))
            }
            .pickerStyle(.segmented)

            ForEach(filteredPoints.prefix(20)) { point in
                HStack {
                    Image(systemName: kindIcon(point.kind))
                        .foregroundStyle(kindColor(point.kind))
                        .frame(width: 20)
                    Text(point.name)
                        .font(.system(size: 10, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(formattedValue(point))
                        .font(.caption.monospacedDigit())
                    Text(point.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 8))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var actionsSection: some View {
        Section(header: Text("Actions")) {
            Button(role: .destructive) {
                metricsCollector.reset()
            } label: {
                Label("Reset All Metrics", systemImage: "trash")
            }
        }
    }

    private func kindIcon(_ kind: SDKMetricPoint.MetricKind) -> String {
        switch kind {
        case .counter: return "number"
        case .gauge: return "gauge.medium"
        case .timing: return "clock"
        }
    }

    private func kindColor(_ kind: SDKMetricPoint.MetricKind) -> Color {
        switch kind {
        case .counter: return .blue
        case .gauge: return .orange
        case .timing: return .green
        }
    }

    private func formattedValue(_ point: SDKMetricPoint) -> String {
        switch point.kind {
        case .counter: return "\(Int(point.value))"
        case .gauge: return String(format: "%.2f", point.value)
        case .timing: return String(format: "%.1fms", point.value * 1000)
        }
    }
}

#Preview {
    NavigationStack {
        SDKMetricsDashboardView()
    }
}
