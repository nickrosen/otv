//
//  StatusView.swift
//  otv
//
//  Created by Nick Rosen on 2/18/24.
//

import SwiftUI

struct StatusView: View {
    @Binding var statusMessage: String
    var completeCount: Int?
    var totalCount: Int?
    
    
    var body: some View {
        VStack { // Use VStack to vertically stack the Text views
//            Text("Hello, World!")
            Text(statusMessage).font(.custom("Elementary", size: 30))
            if let completeCount = completeCount, let totalCount = totalCount {
//                Text("Completed \(completeCount) of \(totalCount)")
                VStack{
                    ProgressView(value: Float(completeCount), total: Float(totalCount))
                    Text("\(completeCount)/\(totalCount)").font(.custom("Cold Brew", size: 40))
                }.padding(.horizontal, 20).padding(.vertical, 16)
            }
        }
    }
}

#Preview {
    StatusView(statusMessage: .constant("Hey Now!"))
}
