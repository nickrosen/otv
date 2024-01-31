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
    
    var body: some View {
        NavigationView {
            Button("Do It!", systemImage: "arrow.up", action: getPlaylists)
//                .labelStyle(.iconOnly)
            List(playlists) {playlist in
                HStack {
//                    AsyncImage(url: song.imageUrl)
//                        .frame(width: 75, height: 75, alignment: .center)
                    VStack(alignment: .leading) {
                        Text(playlist.name)
                            .font(.title3)
//                        Text(song.artist)
//                            .font(.footnote)
                    }
                    .padding()
                    
                }
            }
        }
//        .onAppear{
//            fetchMusic()
//        }
    }
    
    let taylorsVersions = ["1989", "Speak Now", "Red", "Fearless" ]
    let TV = "Taylor's Version"
    
//    func searchAppleMusic(_ searchTerm: String!) -> [Song] {
//        let lock = DispatchSemaphore(value: 0)
//        var songs = [Song]()
//        var musicRequest = URLRequest(url: musicURL)
//        musicRequest.httpMethod = "GET"
//        musicRequest.addValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
//        musicRequest.addValue(getUserToken(), forHTTPHeaderField: "Music-User-Token")
//        
//        URLSession.shared.dataTask(with: musicRequest) { data, response, error in
//            guard error == nil else { return }
//            
//            if let json = try? JSON(data: data!) {
//                let result = json["results"]["songs"]["data"].array!
//                
//                for song in result {
//                    let attributes = song["attributes"]
//                    let currentSong = Song(id: attributes["playParams"]["id"].string!, name: attributes["name"].string!, artistName: attributes["artistName"].string!, artworkURL: attributes["artwork"]["url"].string!)
//                    songs.append(currentSong)
//                }
//                
//                lock.signal()
//            } else {
//                lock.signal()
//            }
//        }.resume()
//        
//        lock.wait()
//        
//        return songs
//    }
    
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
    

    
    
    private func shouldReplaceWithTV(track: MPMediaItem) -> Bool{
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
    
    func addSongsToPlaylist(songs: MusicItemCollection<Song>, to playlist: Playlist) async {
      for song in songs {
        do {
          let _ = try await MusicLibrary.shared.add(song, to: playlist)
        } catch {
          print("Error adding song \(song.title) to the playlist \(playlist.name): \(error)")
        }
      }
    }
    
//    private func fetchTaylorsVersion(searchTerm: String, completion: @escaping (Item?) -> Void) {
    
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

    
    private func makeTVPlaylists(playlists:[MPMediaItemCollection]) {
        Task {
            print("makeTVPlaylists")
            for playlist in playlists {
                print( "\(playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? "") (Taylor's Version")
//                try await MusicLibrary.shared.createPlaylist(name: "\(playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? "") (Taylor's Version")
                
                let items = playlist.items
                var newPlaylist = [Song]()
                
                for item in items {
                    if(shouldReplaceWithTV(track: item)){
                        let term = "\(item.title ?? "") (Taylor's Version) Taylor Swift"
                        if let tv = await fetchTaylorsVersion(term) {
                            newPlaylist.append(tv)
                        }
                    } else {
//                        newPlaylist.append(item ?? nil)
                    }
                }
                print("np", newPlaylist)
                
                do {
                    let newPlaylistName = "\(playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? "") (Taylor's Version)"
                    let createdPlaylist = try await MusicLibrary.shared.createPlaylist(name: newPlaylistName, items: newPlaylist)
                    print("Created playlist: \(createdPlaylist.name)")
                } catch {
                    print("Failed to create playlist: \(error)")
                }
            }
        }
    }
    
    private func getPlaylists(){
        let query: MPMediaQuery = MPMediaQuery.playlists()
        let playlists = query.collections
        guard playlists != nil else {
            return
        }
        
        var playListsToDuplicate:[MPMediaItemCollection] = []
        
        for playlist in playlists ?? [] {
//            print("Playlist Title: \(playlist.value(forProperty: MPMediaPlaylistPropertyName) ?? ""), songs: \(playlist.count)")
            let items = playlist.items

            for item in items {
//                print("Track Title: \(item.title ?? "") \(item.playbackStoreID) \(item.artist ?? "")")
                if(item.artist?.contains("Taylor Swift") == true ){
                    if(shouldReplaceWithTV(track: item)){
                        playListsToDuplicate.append(playlist)
                    }
                }
            }
        }

        makeTVPlaylists(playlists: Array(Set(playListsToDuplicate)))
    }
    
//    private let request: MusicCatalogSearchRequest = {
//        // other types include Album, Playlist, etc
//        var request = MusicCatalogSearchRequest(term: "Happy", types: [Song.self])
//        request.limit = 25
//        return request
//    }()
//    
//    private func fetchMusic() {
//        // use task for async
//        Task {
//            // request permission
//            let status = await MusicAuthorization.request()
//            switch status {
//            case .authorized:
//                // Request -> Response
//                do{
//                    let result = try await request.response()
//                    self.songs = result.songs.compactMap({
//                        return .init(name: $0.title, artist: $0.artistName, imageUrl: $0.artwork?.url(width: 75, height: 75))
//                    })
////                    print(String(describing: songs[0]))
//                    fetchPlaylistsWithTracks()
//                } catch {
//                    print(String(describing: error))
//                }
//                
//                // Assign songs
//            default:
//                break
//            }
//            
//            
//        }
//    }
//    
//    
//    private func fetchPlaylistsWithTracks() {
//        // use task for async
//        Task {
//            // request permission
//            let status = await MusicAuthorization.request()
//            switch status {
//            case .authorized:
//                // Request -> Response
//                do{
//                    // Request for playlists
//                    let playlistsRequest = MusicLibraryRequest<Playlist>()
//                    let playlistsResponse = try await playlistsRequest.response()
//                    
//                    var playListsToDuplicate:[Playlist] = []
//
//                    for playlist in playlistsResponse.items {
//                        // Request for tracks in the playlist
//                        let playlistWithTracks:Playlist = try await playlist.with([.tracks])
////                        self.playlistsWithTracks = playlistWithTracks
//                        if let tracks = playlistWithTracks.tracks {
//                            print("Playlist: \(playlistWithTracks)")
//                            for track in tracks {
//                                if(track.artistName.contains("Taylor Swift")){
//                                    if(shouldReplaceWithTV(track: track)){
////                                        Push to duplicate list
//                                        playListsToDuplicate.append(playlistWithTracks)
//                                    }
//                                    print("Track: \(track.id) \(track.title) \(track.artistName)  \(track.albumTitle ?? "")")
//                                }
//                                
//                            }
//                        }
//                    }
//                    print("To duplicate: \(playListsToDuplicate[0])")
//                    self.playlists = playlistsResponse.items
////                    this is wrong
////                    makeTVPlaylists(playlists: playListsToDuplicate)
//                } catch {
//                    print(String(describing: error))
//                }
//                
//                // Assign songs
//            default:
//                break
//            }
//            
//            
//        }
//        getPlaylists()
//    }


}

#Preview {
    ContentView()
}
