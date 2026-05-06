import SwiftUI
import AppKit

/// Loads a vector icon (e.g. SVG) bundled via `Bundle.module`, falling
/// back to an SF Symbol of the same name if no bundled file matches.
/// Used for Material Symbols icons that aren't shipped as SF Symbols.
struct BundledIcon: View {
    let name: String          // resource name (without extension), or SF Symbol
    var size: CGFloat = 14    // target visual size in points

    var body: some View {
        if let url = Bundle.module.url(forResource: name, withExtension: "svg"),
           let nsImage = NSImage(contentsOf: url) {
            Image(nsImage: nsImage.withTemplateRendering())
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: name)
        }
    }
}

private extension NSImage {
    func withTemplateRendering() -> NSImage {
        let copy = self.copy() as! NSImage
        copy.isTemplate = true
        return copy
    }
}
