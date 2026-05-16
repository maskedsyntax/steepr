import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: SessionViewModel
    @EnvironmentObject var historyStore: HistoryStore
    var onDismiss: () -> Void
    
    @State private var rating = 5
    @State private var notes = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if let step = viewModel.currentStep {
                    VStack(spacing: 10) {
                        Text(step.name)
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        if !step.formattedTemperature.isEmpty {
                            Text(step.formattedTemperature)
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        if let notes = step.notes {
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10)
                            .opacity(0.1)
                            .foregroundColor(.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: CGFloat(viewModel.progress))
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear(duration: 1.0), value: viewModel.timeRemaining)
                        
                        Text(viewModel.formattedTime(viewModel.timeRemaining))
                            .font(.system(size: 64, weight: .bold).monospacedDigit())
                    }
                    .frame(maxWidth: 300)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Upcoming")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 5)
                        
                        if let steps = viewModel.profile?.steps {
                            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                if index > viewModel.currentStepIndex {
                                    HStack {
                                        Text(step.name)
                                        Spacer()
                                        Text(viewModel.formattedTime(step.duration))
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 300)
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            if viewModel.state == .running {
                                viewModel.pause()
                            } else {
                                viewModel.resume()
                            }
                        }) {
                            Image(systemName: viewModel.state == .running ? "pause.circle.fill" : "play.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: viewModel.skip) {
                            Image(systemName: "forward.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onDismiss) {
                            Image(systemName: "stop.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                } else if viewModel.state == .completed {
                    VStack(spacing: 20) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Enjoy your tea!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 15) {
                            Text("How was this brew?")
                                .font(.headline)
                            
                            HStack(spacing: 10) {
                                ForEach(1...5, id: \.self) { star in
                                    Button {
                                        rating = star
                                        Haptics.shared.playImpact()
                                    } label: {
                                        Image(systemName: star <= rating ? "star.fill" : "star")
                                            .font(.title)
                                            .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            TextField("Notes (optional)", text: $notes)
                                #if os(macOS)
                                .textFieldStyle(.roundedBorder)
                                #endif
                                .frame(maxWidth: 300)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                        
                        Button("Save & Done") {
                            saveToHistory()
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.vertical, 30)
                }
            }
            .padding(20)
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 500)
        #endif
    }
    
    private func saveToHistory() {
        let entry = HistoryEntry(
            date: Date(),
            profileName: viewModel.profile?.name ?? "Unknown Tea",
            rating: rating,
            notes: notes
        )
        historyStore.addEntry(entry)
    }
}
