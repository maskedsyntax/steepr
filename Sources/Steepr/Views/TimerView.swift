import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: SessionViewModel
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            if let step = viewModel.currentStep {
                VStack(spacing: 10) {
                    Text(step.name)
                        .font(.system(size: 32, weight: .bold))
                    
                    if let notes = step.notes {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.secondary)
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
                .frame(width: 250, height: 250)
                
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
                VStack(spacing: 30) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.blue)
                    
                    Text("Enjoy your tea!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Button("Done") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 500)
    }
}
