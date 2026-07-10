import SwiftUI

/// Entry point for creating or editing a tea profile.
/// Presents the multi-step Edit Tea Profile experience.
struct AddTeaSheet: View {
    var editingTea: Tea?
    var defaultSteepSeconds: Int = 180

    var body: some View {
        EditTeaProfileView(
            editingTea: editingTea,
            defaultSteepSeconds: defaultSteepSeconds
        )
    }
}
