import Foundation
import Combine
import SwiftUI

@MainActor
public final class ReporterFeedbackViewModel: ObservableObject {
    @Published public var currentStep = 1
    @Published public var report = FeedbackReport()
    @Published public var isAnalyzing = false
    @Published public var isSubmitting = false
    @Published public var capturedDiagnostics: DiagnosticsData?
    @Published public var provideDiagnostics = true
    @Published public var submissionError: String?
    @Published public var isComplete = false

    public init(initialCategory: FeedbackCategory? = nil) {
        if let category = initialCategory {
            report.category = category
        }
    }

    public func nextStep() {
        if currentStep < 6 {
            withAnimation {
                currentStep += 1
            }
            if currentStep == 4 && provideDiagnostics {
                Task {
                    capturedDiagnostics = await DiagnosticsManager.shared.captureDiagnostics()
                    report.diagnostics = capturedDiagnostics
                }
            }
            if currentStep == 5 {
                runAIAnalysis()
            }
        }
    }

    public func prevStep() {
        if currentStep > 1 {
            withAnimation {
                currentStep -= 1
            }
        }
    }

    public func runAIAnalysis() {
        isAnalyzing = true
        Task {
            do {
                let result = try await AIAnalysisService.shared.analyzeReport(report)
                self.report.aiAnalysis = result
                self.report.priority = result.suggestedPriority
                self.report.tags = result.suggestedTags
                isAnalyzing = false
            } catch {
                isAnalyzing = false
            }
        }
    }

    public func submit() {
        isSubmitting = true
        Task {
            do {
                _ = try await FeedbackService.shared.submitReport(report)
                isSubmitting = false
                isComplete = true
            } catch {
                submissionError = error.localizedDescription
                isSubmitting = false
            }
        }
    }

    public func saveDraft() {
        report.status = .draft
        report.updatedAt = Date()
        // Save to persistent storage via service or manager
        // For this mock, FeedbackService handles saving.
        Task {
            _ = try? await FeedbackService.shared.submitReport(report)
        }
    }
}
