import SpriteKit
import SwiftUI

struct PetancaFieldView: UIViewRepresentable {
    @ObservedObject var viewModel: GameViewModel

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.ignoresSiblingOrder = true
        let scene = PetancaScene()
        scene.onBallLanded = { id, point in
            DispatchQueue.main.async { viewModel.ballDidLand(id: id, at: point) }
        }
        scene.onCochonnetLanded = { point in
            DispatchQueue.main.async { viewModel.cochonnetDidLand(at: point) }
        }
        view.presentScene(scene)
        viewModel.scene = scene
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        guard let scene = uiView.scene as? PetancaScene else { return }
        scene.syncField(size: uiView.bounds.size)
        if viewModel.fieldSize != uiView.bounds.size, uiView.bounds.width > 0, uiView.bounds.height > 0 {
            viewModel.fieldSize = uiView.bounds.size
        }
    }
}
