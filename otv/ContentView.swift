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
    @StateObject var processor = PlaylistProcessor.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            if processor.loading {
                LoadingView()
            } else if processor.processing {
                ProcessingView(
                    processingPlaylistCount: processor.totalPlaylistCount,
                    processingSongCount: processor.totalSongCount,
                    processedSongCount: $processor.completedSongCount,
                    tvSongCount: processor.tvSongCount
                )
            } else if processor.done {
                CompleteView(
                    processedPlaylistCount: processor.completedPlaylistCount,
                    processedSongCount: processor.completedSongCount
                )
            } else {
                VStack{
                    Image("banner-heart").resizable().scaledToFit()
                        .padding(.bottom, 40)
                    Button(action: {
                        PlaylistProcessor.shared.startProcessing { success in
                            print("Processing completed: \(success)")
                        }
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
                            .foregroundColor(Color(hex: "#18B7F6"))
                            .padding()
                            .padding(.bottom, -4)
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#B5E5F8")) // Replace with the color in your design
                            .cornerRadius(20)
                    }
                    .padding()
                    Text("To convert all your playlists to").multilineTextAlignment(.center).font(.custom("Elementary", size: 24)).foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3E4969"))
//                    Text("only Taylor's Version").multilineTextAlignment(.center).font(.custom("Elementary", size: 24)).foregroundColor(Color(hex: "#3E4969"))
                    Text("only Taylor's Version").multilineTextAlignment(.center).font(.custom("Elementary", size: 24)).foregroundColor(colorScheme == .dark ? .white : Color(hex: "#3E4969"))
                }
            }
        }
    }
    
//    let taylorsVersions = ["1989", "Speak Now", "Red", "Fearless" ]
//    let TV = "Taylor's Version"
    
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
    
    
    
    
//    private func shouldReplaceWithTV(track: Track) -> Bool{
//        for albumTitle in taylorsVersions {
//            let trackAlbum = track.albumTitle ?? ""
//            if(trackAlbum.contains(albumTitle) && !trackAlbum.contains(TV)){
//                //                print("True", track.albumTitle ?? "")
//                return true
//            }
//        }
//        return false
//    }
    
//    private func requestTaylorsVersion(searchTerm: String) -> MusicCatalogSearchRequest {
//        // other types include Album, Playlist, etc
//        var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
//        request.limit = 1
//        return request
//    }
    
//    private func fetchTaylorsVersion(_ searchTerm: String) async -> Song? {
//        do {
//            let status = await MusicAuthorization.request()
//            switch status {
//            case .authorized:
//                let result = try await requestTaylorsVersion(searchTerm: searchTerm).response()
//                return result.songs.first
//            default:
//                return nil
//            }
//        } catch {
//            print(String(describing: error))
//            return nil
//        }
//    }
    enum SongOrTrack {
        case song(Song)
        case track(Track)
    }
    
//    private func processPlaylist(_ playlist: Playlist) async {
//        guard let items = playlist.tracks else {
//            return
//        }
//        
//        print("Processing playlist: \(playlist.name)")
//        
//        do {
//            let newPlaylist = try await MusicLibrary.shared.createPlaylist(name: "\(playlist.name) (Taylor's Version)")
//
//            for item in items {
//                if shouldReplaceWithTV(track: item) {
//                    let term = "\(item.title) (Taylor's Version) Taylor Swift"
//                    if let tvSong = await fetchTaylorsVersion(term) {
//                        _ = try await MusicLibrary.shared.add(tvSong, to: newPlaylist)
//                        duplicateSongsCount += 1
//                    }
//                } else {
//                    _ = try await MusicLibrary.shared.add(item, to: newPlaylist)
//                    duplicateSongsCount += 1
//                }
//            }
//        } catch {
//            print("Failed to create or populate playlist: \(error)")
//        }
//    }
    
//    private func makeTVPlaylists(playlists: [Playlist]) {
//        for playlist in playlists {
//               Task {
//                   await processPlaylist(playlist)
//                   print("Done: ", playlist.name)
//                   completedPlaylistCount += 1
//                   if completedPlaylistCount == playlistsToDuplicateCount {
//                       isProcessingPlaylists = false
//                       processingComplete = true
//                   }
//                   
//                   
//               }
//           }
//    }
    
//    private func addItems(_ items: [SongOrTrack], to playlist: Playlist) async throws {
//        for item in items {
//            switch item {
//            case .song(let song):
//                let _ = try await MusicLibrary.shared.add(song, to: playlist)
//                duplicateSongsCount += 1
//                print("duck", duplicateSongsCount)
//                
//            case .track(let track):
//                let _ = try await MusicLibrary.shared.add(track, to: playlist)
//                duplicateSongsCount += 1
//                print("duck", duplicateSongsCount)
//            }
//        }
//    }
    
    
}

#Preview {
    ContentView()
}
