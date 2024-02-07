//
//  ProcessingView.swift
//  otv
//
//  Created by Nick Rosen on 2/4/24.
//

// OTV is creating 983 songs in 17 playlists including 17 Taylor's Version replacements

import SwiftUI

struct ProcessingView: View {
    let processingPlaylistCount: Int
    let processingSongCount: Int
    @Binding var processedSongCount: Int
    let tvSongCount: Int
    
    
    var body: some View {
        VStack{
            Image("lwymmd").resizable().scaledToFit()
//                .padding(.bottom, 40)
            Text("OTV is replacing \(tvSongCount) songs on \(String(processingPlaylistCount)) playlists with").multilineTextAlignment(.center).font(.custom("Cold Brew", size: 48)).foregroundColor(Color(hex: "#00CCFF")).padding(.bottom, -10)
            
            Image("otv").resizable().scaledToFit()
//                .padding(.bottom, 40)
            Text("OTV IS WORKING ON REPLACING STOLEN LULLABIES WITH (TAYLOR'S VERSION). THIS MAY TAKE A LITTLE WHILE, SO FEEL FREE TO LEAVE THE APP AND GO LISTEN TO 'ALL TO WELL (10 MINUTE VERSION),' AND IT SHOULD BE DONE BY THE TIME YOU GET BACK").multilineTextAlignment(.center).font(.custom("Elementary", size: 32)).foregroundColor(Color(hex: "#18B7F6")).padding(.horizontal, 20)
            
            Spacer()
            HStack{
                Text("\(processedSongCount)/\(processingSongCount)").font(.custom("Cold Brew", size: 40))
                ProgressView(value: Float(processedSongCount), total: Float(processingSongCount))
            }.padding(.horizontal, 20).padding(.vertical, 16)
            Image("footer").resizable().scaledToFit()
            
//                .padding(.bottom, 40)
        }
    }
}

#Preview {
    ProcessingView(processingPlaylistCount: 12, processingSongCount: 973, processedSongCount: .constant(428), tvSongCount: 97)
}
