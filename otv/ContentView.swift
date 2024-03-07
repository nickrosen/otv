//
//  ContentView.swift
//  otv
//
//  Created by Nick Rosen on 1/13/24.
//
import MusicKit
import SwiftUI

struct Item: Identifiable, Hashable {
    var id = UUID()
    let name: String
    let artist: String
    let imageUrl: URL?
}

struct AppleMusicPlaylistPostRequestBody: Codable {
    let data: [AppleMusicPlaylistPostRequestItem]
}

struct AppleMusicPlaylistPostRequestItem: Codable {
    let id: MusicItemID
    let type: String
}

struct ContentView: View {
    let taylorsVersions = ["1989", "Speak Now", "Red", "Fearless" ]
    let TV = "Taylor's Version"

    @State private var processingComplete = false
    @State var completedPlaylistCount = 0
    @State var tvSongCount = 0
    @State var isLoading = false
    
    @State var processing = false
    @State var processingCompleteCount = 0
    @State var processingTotalCount = 0
    @State var statusMsg = ""
    @State var scanningPlaylists = false
    @State var fetchingTaylorsVersions = false
    @State var creatingNewPlaylists = false
    
    @State var isFaqScreenVisible = false
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack{
                if isLoading {
                    LoadingView()
                } else if processing {
                    StatusView(statusMessage: $statusMsg, completeCount: processingCompleteCount, totalCount: processingTotalCount)
                } else if processingComplete {
                    VStack{
                        CompleteView(processedPlaylistCount: completedPlaylistCount, processedSongCount: tvSongCount)
                        HStack{
                            Spacer()
                            Button(action: {
                                // Action for your help button
                                isFaqScreenVisible = true
                            }) {
                                Image(systemName: "questionmark.circle.fill") // SF Symbol for question mark
                                    .foregroundColor(colorScheme == .dark ? .white : .black) // Icon color
                                    .font(.largeTitle) // Icon size
                            }.padding(.top, 0).padding(.horizontal,20)
                                .sheet(isPresented: $isFaqScreenVisible) {
                                    FAQView() // Present FAQView modally
                                }
                        }
                    }
                } else {
                    VStack{
                        Image("banner-heart").resizable().scaledToFit()
                            .padding(.bottom, 40)
                        Button(action: {
                            // Your action here
                            isLoading = true
                            fetchPlaylistsWithTracks()
                        }) {
                            Text("TAP HERE")
                                .font(.custom("Elementary", size: 32))
                                .shadow(
                                    color: Color(hex: "#FF00FF"), /// shadow color
                                    radius: 0, /// shadow radius
                                    x: 1, /// x offset
                                    y: 1 /// y offset
                                )
                                .shadow(
                                    color: Color(hex: "#00FFFF"), /// shadow color
                                    radius: 0, /// shadow radius
                                    x: -1, /// x offset
                                    y: 1 /// y offset
                                )
                                .foregroundColor(Color(hex: "#3782C7"))
                                .padding()
                                .padding(.bottom, -4)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#B5E5F8")) // Replace with the color in your design
                                .cornerRadius(20)
                        }
                        .padding()
                        Text("To convert all your playlists to")
                            .multilineTextAlignment(.center)
                            .font(.custom("Elementary", size: 24))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3E4969"))
                        Text("only Taylor's Version")
                            .multilineTextAlignment(.center)
                            .font(.custom("Elementary", size: 24))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3E4969"))
                    }
                }
            }
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    
    private func shouldReplaceWithTV(track: Track) -> Bool{
        for albumTitle in taylorsVersions {
            let trackAlbum = track.albumTitle ?? ""
            let trackTitle = track.title
            if(trackAlbum.contains(albumTitle) && !trackAlbum.contains(TV) && !trackTitle.contains(TV)){
                return true
            }
        }
        return false
    }
    
    private func requestTaylorsVersion(searchTerm: String) -> MusicCatalogSearchRequest {
        // other types include Album, Playlist, etc
        var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
        request.limit = 1
        return request
    }
    
    private func fetchTaylorsVersion(_ searchTerm: String) async -> Song? {
        do {
            let status = await MusicAuthorization.request()
            switch status {
            case .authorized:
                let result = try await requestTaylorsVersion(searchTerm: searchTerm).response()
                return result.songs.first
            default:
                return nil
            }
        } catch {
            print(String(describing: error))
            return nil
        }
    }
    
    enum PlaylistCreationError: Error {
        case playlistCreationFailed(String)
        case trackFetchFailed
        case musicAuthorizationFailed
    }
    
    func createPlaylistWithTracks(named playlistName: String, tracks: [Song]) async throws -> [Track] {
        // First, ensure that we have authorization to access the music library.
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            throw PlaylistCreationError.musicAuthorizationFailed
        }
        
        // Create a new playlist with the provided name and tracks.
        do {
            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: playlistName, items: tracks)
            var trackList:[Track] = []
            let playlistWithTracks:Playlist = try await newPlaylist.with([.tracks])
            if let tracks = playlistWithTracks.tracks {
                for track in tracks {
                    
                    trackList.append(track)
                }
            }
            
            return trackList
        } catch {
            throw PlaylistCreationError.playlistCreationFailed("Could not create playlist: \(error)")
        }
    }
    
    private func processPlaylist(_ playlist: Playlist, tvPlaylist: [Track]) async {
        guard let items = playlist.tracks else {
            return
        }
        
        print("Processing playlist: \(playlist.name)")
        
        do {
            var trackList:[Track] = []

            for item in items {
                if shouldReplaceWithTV(track: item) {
                    
                    if let matchingTrack = tvPlaylist.first(where: { $0.title.lowercased().contains(item.title.lowercased()) }) {
                        print("Found matching track: \(matchingTrack.title)")
                        trackList.append(matchingTrack)
                    } else {
                        print("No track found with the substring '\(item.title)' in its title.")
                    }
                } else {
                    trackList.append(item)
                }
                
            }
            try await MusicLibrary.shared.createPlaylist(name: "\(playlist.name) (Taylor's Version)", items: trackList)
            return
        } catch {
            print("Failed to create or populate playlist: \(error)")
        }
    }
    
    private func makeTVPlaylists(playlists: [Playlist], tvPlaylist:[Track]) {
        processing = true
        statusMsg = "Creating New Playlists"
        processingCompleteCount = 0
        processingTotalCount = playlists.count
        completedPlaylistCount = playlists.count
        isLoading = false
        
        for playlist in playlists {
               Task {
                   await processPlaylist(playlist, tvPlaylist: tvPlaylist)

                   processingCompleteCount += 1

                   if processingTotalCount == processingCompleteCount {
                       processing = false
                       processingComplete = true
                   }
                   
                   
               }
           }
    }
    
    private func fetchPlaylistsWithTracks() {
        // use task for async
        Task {
            
            // request permission
            let status = await MusicAuthorization.request()
            switch status {
            case .authorized:
                // Request -> Response
                do{
                    // Request for playlists
                    let playlistsRequest = MusicLibraryRequest<Playlist>()
                    let playlistsResponse = try await playlistsRequest.response()
                    
                    var playListsToDuplicate:[Playlist] = []
                    var futureTVSongs:[Track] = []
                    
                    isLoading = false
                    processing = true
                    statusMsg = "Scanning Playlists"
                    processingTotalCount = playlistsResponse.items.count
                    
                    for playlist in playlistsResponse.items {
                        let playlistWithTracks:Playlist = try await playlist.with([.tracks])
                        
                        if let tracks = playlistWithTracks.tracks {
                            
                            for track in tracks {
                                if(track.artistName.contains("Taylor Swift")){
                                    if(shouldReplaceWithTV(track: track)){
                                        tvSongCount += 1
                                        playListsToDuplicate.append(playlistWithTracks)
                                        if !futureTVSongs.contains(where: { $0.id == track.id }) {
                                            futureTVSongs.append(track)
                                        }
                                    }
                                    print("Track: \(track.id) \(track.title) \(track.artistName)  \(track.albumTitle ?? "")")
                                }
                                
                            }
                        }
                        processingCompleteCount += 1
                    }
                    let uniquePlaylists = Array(Set(playListsToDuplicate))
                    
                    isLoading = true
                    statusMsg = "Getting Taylor's Versions"
                    processingTotalCount = futureTVSongs.count
                    processingCompleteCount = 0
                    isLoading = false
                    
                    var tvSongs:[Song] = []
                    for song in futureTVSongs {
                        processingCompleteCount += 1
                        let term = "\(song.title) (Taylor's Version) Taylor Swift"
                        if let tvSong = await fetchTaylorsVersion(term) {
                            tvSongs.append(tvSong)
                        }
                    }
                    let tvsPlaylist = try await createPlaylistWithTracks(named: "OTV: Replacement Tracks", tracks: tvSongs)
                    
                    isLoading = true
                    
                    makeTVPlaylists(playlists: uniquePlaylists, tvPlaylist: tvsPlaylist)
                } catch {
                    print(String(describing: error))
                }
                
                // Assign songs
            default:
                statusMsg = "Apple Music Access Required"
                processing = true
                isLoading = false
                // Delay execution for 2 seconds
                let delayInSeconds = 2.0
                DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds) {
                    processing = false
                    statusMsg = ""
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                }
                break
            }
            
            
        }
    }
}

#Preview {
    ContentView()
}
