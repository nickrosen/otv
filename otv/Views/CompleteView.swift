//
//  CompleteView.swift
//  otv
//
//  Created by Nick Rosen on 2/4/24.
//

import SwiftUI

struct CompleteView: View {
    let processedPlaylistCount: Int
    let processedSongCount: Int
    
    var body: some View {
        VStack{
            Image("lwymmd").resizable().scaledToFit()
//                .padding(.bottom, 40)
            if processedSongCount > 0 {
                Text("CONGRATULATIONS").multilineTextAlignment(.center).font(.custom("Elementary", size: 64)).foregroundColor(Color(hex: "#18B7F6")).padding(.horizontal, 20)
                Text("OTV Replaced").multilineTextAlignment(.center).font(.custom("Cold Brew", size: 78)).foregroundColor(Color(hex: "#00CCFF")).padding(.bottom, -10).padding(.top, 40)
                Text("\(processedSongCount) songs on").multilineTextAlignment(.center).font(.custom("Cold Brew", size: 78)).foregroundColor(Color(hex: "#00CCFF")).padding(.bottom, -10)
                Text("\(String(processedPlaylistCount)) playlists").multilineTextAlignment(.center).font(.custom("Cold Brew", size: 78)).foregroundColor(Color(hex: "#00CCFF")).padding(.bottom, -10)
            } else{
                Text("No songs found to replace").multilineTextAlignment(.center).font(.custom("Elementary", size: 64)).foregroundColor(Color(hex: "#18B7F6")).padding(.horizontal, 20)
            }
            Image("otv").resizable().scaledToFit()
//                .padding(.bottom, 40)
            
            
            Spacer()
            Image("footer").resizable().scaledToFit()
//                .padding(.bottom, 40)
        }
    }
}

#Preview {
    CompleteView(processedPlaylistCount: 12, processedSongCount: 433)
}
