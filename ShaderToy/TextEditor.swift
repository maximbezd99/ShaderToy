//
//  TextEditor.swift
//  ShaderToy
//
//  Created by Maxim Bezdenezhnykh on 17/11/2024.
//

import SwiftUI
import AppKit

struct ShaderTextEditor: NSViewRepresentable {
    
    @Binding
    var text: String
    
    func makeNSView(context: Context) -> _View {
        let view = _View()
        view.textView.string = text
        view.textView.delegate = context.coordinator
        
        context.coordinator.textView = view.textView
        
        return view
    }
    
    func updateNSView(_ nsView: _View, context: Context) {
        context.coordinator.update(text: text)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            textBinding: _text
        )
    }
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        fileprivate var textView: NSTextView?
        let textBinding: Binding<String>
        
        init(textBinding: Binding<String>) {
            self.textBinding = textBinding
        }
        
        func update(text: String) {
            if textView?.string != text {
                textView?.string = text
            }
        }
        
        // NSTextViewDelegate
        
        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            textBinding.wrappedValue = textView.string
        }
    }
}

extension ShaderTextEditor {
    final class _View: NSView {
        let textView = NSTextView()
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            setupUI()
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func resizeSubviews(withOldSize oldSize: NSSize) {
            super.resizeSubviews(withOldSize: oldSize)
        }
        
        private func setupUI() {
//            textView.maxSize = .init(width: CGFloat.infinity, height: .infinity)
//            textView.isHorizontallyResizable = true
//            textView.textContainer?.widthTracksTextView = false
//            textView.textContainer?.containerSize = .init(width: CGFloat.infinity, height: .infinity)
            textView.backgroundColor = .clear
            textView.textContainerInset = .init(width: 4, height: 8)
            textView.font = .monospacedSystemFont(ofSize: 13, weight: .medium)
        }
        
        private func setupLayout() {
            addSubview(textView)
            textView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                heightAnchor.constraint(equalToConstant: 500),
                textView.topAnchor.constraint(equalTo: self.topAnchor),
                textView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                textView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                textView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
            ])
        }
    }
}
