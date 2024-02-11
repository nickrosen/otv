//
//  PlaylistProcessor.swift
//  otv
//
//  Created by Nick Rosen on 2/10/24.
//

import Foundation
import BackgroundTasks
import MusicKit

class PlaylistProcessor: ObservableObject {
    static let shared = PlaylistProcessor()
    
    @Published var loading = false
    @Published var processing = false
    @Published var done = false
    @Published var completedSongCount = 0
    @Published var totalSongCount = 0
    @Published var tvSongCount = 0
    
    @Published var completedPlaylistCount = 0
    @Published var totalPlaylistCount = 0
    
    let taylorsVersions = ["1989", "Speak Now", "Red", "Fearless"]
    let TV = "Taylor's Version"
    
    func startProcessing(complete: @escaping (Bool) -> Void) {
        Task {
            // Processing playlists
            await fetchPlaylistsWithTracks()
            DispatchQueue.main.async {
                complete(true)
            }
        }
    }
    
    private func shouldReplaceWithTV(track: Track) -> Bool {
        for albumTitle in taylorsVersions {
            if let trackAlbum = track.albumTitle, trackAlbum.contains(albumTitle) && !trackAlbum.contains(TV) {
                return true
            }
        }
        return false
    }
    
    private func fetchTaylorsVersion(_ searchTerm: String) async -> Song? {
        do {
            let status = await MusicAuthorization.request()
            if status == .authorized {
                let result = try await MusicCatalogSearchRequest(term: searchTerm, types: [Song.self]).response()
                return result.songs.first
            }
        } catch {
            print("Error fetching Taylor's Version: \(error)")
        }
        return nil
    }
    
    private func processPlaylist(_ playlist: Playlist) async {
        guard let items = playlist.tracks else { return }
        
        let newPlaylistResult = try? await MusicLibrary.shared.createPlaylist(name: "\(playlist.name) (Taylor's Version)")

        guard let newPlaylist = newPlaylistResult else { return }
        
        for item in items {
            var updateCount = false
            
            if shouldReplaceWithTV(track: item), let tvSong = await fetchTaylorsVersion("\(item.title) (Taylor's Version) Taylor Swift") {
                _ = try? await MusicLibrary.shared.add(tvSong, to: newPlaylist)
                updateCount = true
            } else {
                _ = try? await MusicLibrary.shared.add(item, to: newPlaylist)
                updateCount = true
            }
            
            if updateCount {
                DispatchQueue.main.async {
                    self.completedSongCount += 1
                }
            }
        }
    }
    
    private func makeTVPlaylists(playlists: [Playlist]) async {
        for playlist in playlists {
            await processPlaylist(playlist)
            DispatchQueue.main.async {
                self.completedPlaylistCount += 1
                if self.completedPlaylistCount == self.totalPlaylistCount {
                    self.processing = false
                    self.done = true
                }
            }
        }
    }
    
    private func fetchPlaylistsWithTracks() async {
        DispatchQueue.main.async {
            self.loading = true
        }
        
        let status = await MusicAuthorization.request()
        if status == .authorized {
            do {
                let playlistsRequest = MusicLibraryRequest<Playlist>()
                let playlistsResponse = try await playlistsRequest.response()
                
                var playListsToDuplicate: [Playlist] = []
                var localTVSongCount = 0
                
                for playlist in playlistsResponse.items {
                    let playlistWithTracks = try await playlist.with([.tracks])
                    if let tracks = playlistWithTracks.tracks {
                        for track in tracks {
                            if track.artistName.contains("Taylor Swift") && shouldReplaceWithTV(track: track) {
                                localTVSongCount += 1
                                playListsToDuplicate.append(playlistWithTracks)
                            }
                        }
                    }
                }
                
                let uniquePlaylists = Array(Set(playListsToDuplicate))
                
                DispatchQueue.main.async {
                    self.tvSongCount = localTVSongCount
                    self.totalPlaylistCount = uniquePlaylists.count
                    self.totalSongCount = uniquePlaylists.reduce(0) { $0 + ($1.tracks?.count ?? 0) }
                    self.processing = true
                    self.loading = false
                }
                
                await makeTVPlaylists(playlists: uniquePlaylists)
                
            } catch {
                DispatchQueue.main.async {
                    print("Error processing playlists: \(error)")
                    self.loading = false
                }
            }
        } else {
            DispatchQueue.main.async {
                self.loading = false
            }
        }
    }
}

