//
//  ContentView.swift
//  otv
//
//  Created by Nick Rosen on 1/13/24.
//
import MusicKit
import SwiftUI
import Foundation
import MediaPlayer

public typealias LibraryPlaylists = MusicItemCollection<LibraryPlaylist>

public struct LibraryPlaylist: Codable, MusicItem {
  public let id: MusicItemID
  public let attributes: Attributes

  public struct Attributes: Codable, Sendable {
    public let canEdit: Bool
    public let name: String
    public let isPublic: Bool
    public let hasCatalog: Bool
    public let playParams: PlayParameters
    public let description: Description?
    public let artwork: Artwork?
  }

  public struct Description: Codable, Sendable {
    public let standard: String
  }

  public struct PlayParameters: Codable, Sendable {
    public let id: MusicItemID
    public let isLibrary: Bool
    public let globalID: MusicItemID?

    enum CodingKeys: String, CodingKey {
      case id, isLibrary
      case globalID = "globalId"
    }
  }

  public var globalID: String? {
    attributes.playParams.globalID?.rawValue
  }
}

// Define an enumeration to wrap either a Track or a Song
enum TrackOrSong {
    case track(Track)
    case song(Song)
}

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
    @State var songs = [Item]()
    @State var playlists = MusicItemCollection<Playlist>()
    @State var playlistsWithTracks = MusicItemCollection<Playlist>()
    //    @State var playlistsToDuplicate = MusicItemCollection<Playlist>
    @State private var isProcessingPlaylists = false
    @State private var processingComplete = false
    @State var playlistsToDuplicateCount = 0
    @State var songsToDuplicateCount = 0
    @State var duplicateSongsCount = 0
    @State var completedPlaylistCount = 0
    @State var tvSongCount = 0
    @State var isLoading = false
    
    @State var processing = false
    @State var processingCompleteCount = 0
    @State var processingTotalCount = 0
    @State var statusMsg = ""
//    Fetching Playlists
//    Scanning Playlists
//    Fetching Taylor's Versions
//    Creating New Playlists
    @State var scanningPlaylists = false
    @State var fetchingTaylorsVersions = false
    @State var creatingNewPlaylists = false
    
    var body: some View {
        NavigationView {
            if isLoading {
                LoadingView()
            } else if processing {
                StatusView(statusMessage: $statusMsg, completeCount: processingCompleteCount, totalCount: processingTotalCount)
            } else if processingComplete {
                CompleteView(processedPlaylistCount: playlistsToDuplicateCount, processedSongCount: tvSongCount)
            } else {
                VStack{
                    Image("banner-heart").resizable().scaledToFit()
                        .padding(.bottom, 40)
                    //                Button("Do It!", systemImage: "arrow.up", action: fetchPlaylistsWithTracks)
                    Button(action: {
                        // Your action here
                        isLoading = true
                        fetchPlaylistsWithTracks()
                    }) {
                        Text("TAP HERE")
                            .font(.custom("ColdBrew", size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#3E4969")) // Replace with the color in your design
                            .cornerRadius(20)
                    }
                    .padding()
                    Text("To convert all your playlists to").multilineTextAlignment(.center).font(.custom("Elementary", size: 24)).foregroundColor(Color(hex: "#3E4969"))
                    Text("only Taylor's Version").multilineTextAlignment(.center).font(.custom("Elementary", size: 24)).foregroundColor(Color(hex: "#3E4969"))
                }
            }
        }
    }
    
    let taylorsVersions = ["1989", "Speak Now", "Red", "Fearless" ]
    let TV = "Taylor's Version"
    
    func addTracksToAppleMusicPlaylist(targetPlaylistId: String, tracksToAdd: [Song]) async throws -> Void {
        let tracks = AppleMusicPlaylistPostRequestBody(data: tracksToAdd.compactMap {
            AppleMusicPlaylistPostRequestItem(id: $0.id, type: "songs")
        })
        
        do {
            if let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists/\(targetPlaylistId)/tracks") {
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                let encoder = JSONEncoder()
                let data = try encoder.encode(tracks)
                urlRequest.httpBody = data
                let musicRequest = MusicDataRequest(urlRequest: urlRequest)
                let musicRequestResponse = try await musicRequest.response()
                print("Music Request Response", musicRequestResponse)
            } else {
                print("Bad URL!")
                //                throw AddTracksToPlaylistError.badUrl(message: "Bad URL!")
            }
        } catch {
            print("Error Saving Tracks to Playlist", error)
            throw error
        }
    }
    
    
    
    
    private func shouldReplaceWithTV(track: Track) -> Bool{
        for albumTitle in taylorsVersions {
            let trackAlbum = track.albumTitle ?? ""
            if(trackAlbum.contains(albumTitle) && !trackAlbum.contains(TV)){
                //                print("True", track.albumTitle ?? "")
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
    
    enum SongOrTrack {
        case song(Song)
        case track(Track)
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
//            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: "\(playlist.name) (Taylor's Version)", items: items)
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
//                    _ = try await MusicLibrary.shared.add(item, to: newPlaylist)
                    print(item.id)
                    trackList.append(item)
//                    duplicateSongsCount += 1
                }
//                processingCompleteCount += 1
                
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
        playlistsToDuplicateCount = playlists.count
        isLoading = false
        for playlist in playlists {
               Task {
                   await processPlaylist(playlist, tvPlaylist: tvPlaylist)
                   print("Done: ", playlist.name)
                   processingCompleteCount += 1
                   completedPlaylistCount += 1
                   if processingTotalCount == processingCompleteCount {
                       processing = false
                       processingComplete = true
                   }
                   if completedPlaylistCount == playlistsToDuplicateCount {
                       isProcessingPlaylists = false
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
//                                if(processingTotalCount == tracks.count){
//                                    processingCompleteCount += 1
//                                }
                                if(track.artistName.contains("Taylor Swift")){
                                    if(shouldReplaceWithTV(track: track)){
                                        tvSongCount += 1
                                        // Push to duplicate list
                                        playListsToDuplicate.append(playlistWithTracks)
//                                        futureTVSongs.append(track)
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
//                    playlistsToDuplicateCount = uniquePlaylists.count
//                    songsToDuplicateCount = uniquePlaylists.reduce(0) { $0 + ($1.tracks?.count ?? 999) }
//                    isProcessingPlaylists = true
//                    print("zzz \(songsToDuplicateCount) \(tvSongCount) \(songsToDuplicateCount)")
//                    futureTVSongs = Array(Set(futureTVSongs))
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
//                            print("sheesh", tvSong)
                            tvSongs.append(tvSong)
    //                        _ = try await MusicLibrary.shared.add(tvSong, to: newPlaylist)
//                            duplicateSongsCount += 1
                        }
                    }
                    let tvsPlaylist = try await createPlaylistWithTracks(named: "OTV: Replacement Tracks", tracks: tvSongs)
//                    print("mmm \(futureTVSongs[0]) \(tvSongCount) \(futureTVSongs.count)")
                    
                    isLoading = true
                    
                    makeTVPlaylists(playlists: uniquePlaylists, tvPlaylist: tvsPlaylist)
                } catch {
                    print(String(describing: error))
                }
                
                // Assign songs
            default:
                break
            }
            
            
        }
    }
}

#Preview {
    ContentView()
}
