//
//  FAQView.swift
//  otv
//
//  Created by Nick Rosen on 2/18/24.
//

import SwiftUI

struct FAQView: View {
    let faqs = [
        FAQ(question: "Where are my new playlists?", answer: "In Apple Music. If you cannot find them, sort your playlists by ‘Recently Added’."),
        FAQ(question: "What is this new playlist called ‘OTV: Replacement Tracks’?", answer: "It is a list of all the Taylor’s Versions that were added to your playlists, you can keep it or delete it."),
        FAQ(question: "Why doesn’t it delete my old playlists?", answer: "Apple Music doesn’t allow us to delete playlists, but also, we wouldn’t want to risk messing it up and deleting something you didn’t want to go away. You can delete the old versions if you want, or keep them."),
        FAQ(question: "What happens if I push the button again?", answer: "It will run the program again. If you kept the old playlists, you may end up with duplicates, but if you deleted the old versions, it should tell you there are no songs to replace."),
        FAQ(question: "Does it work for Spotify or other streaming platform?", answer: "This app is only for Apple Music."),
        FAQ(question: "What will happen when Rep (TV) and Debut (TV) are released?", answer: "We will update the app and you just have to run the app again. If you didn’t delete the old versions of the playlists, you may end up with some duplicates, but just delete those."),
    ]
    
    var body: some View {
        List(faqs, id: \.question) { faq in
            Section(header: Text(faq.question).fontWeight(.bold)) {
                Text(faq.answer)
                    .padding()
            }
        }
        .listStyle(GroupedListStyle()) // Use GroupedListStyle for a grouped appearance
        .navigationTitle("FAQs")
    }
}

struct FAQ {
    let question: String
    let answer: String
}

#Preview {
    FAQView()
}
