//
//  LoadingView.swift
//  otv
//
//  Created by Nick Rosen on 2/5/24.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2) // Optional: Increase the size of the spinner
                .padding()
        }
    }
}

#Preview {
    LoadingView()
}
