import SwiftUI

struct TeaGuideView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Brewing Temperatures") {
                    GuideRow(name: "Green Tea", detail: "75°C - 80°C", note: "Prevents bitterness.")
                    GuideRow(name: "White Tea", detail: "70°C - 80°C", note: "Delicate leaves need lower heat.")
                    GuideRow(name: "Oolong Tea", detail: "85°C - 95°C", note: "Varied; darker oolongs like more heat.")
                    GuideRow(name: "Black Tea", detail: "95°C - 100°C", note: "Full oxidation needs boiling water.")
                    GuideRow(name: "Pu-erh Tea", detail: "100°C", note: "Always rinse with boiling water first.")
                }
                
                Section("Pro Tips") {
                    Text("• Always rinse your teapot and cups with hot water first.")
                    Text("• Use filtered water for the best flavor.")
                    Text("• Don't squeeze the tea bag (if using one) as it releases tannins.")
                }
            }
            .navigationTitle("Tea Guide")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(width: 400, height: 500)
        #endif
    }
}

struct GuideRow: View {
    let name: String
    let detail: String
    let note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).bold()
                Spacer()
                Text(detail).foregroundColor(.blue)
            }
            Text(note).font(.caption).foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
