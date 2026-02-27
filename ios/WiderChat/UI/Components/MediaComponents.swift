import AVFoundation
import AVKit
import PDFKit
import SwiftUI
import UIKit
import WebKit

struct MediaMessageView: View {
    let mediaKind: String
    let mediaUrl: String?
    let caption: String
    let darkMode: Bool
    @State private var showImageViewer = false
    @State private var showDocumentViewer = false
    @State private var showVideoPlayer = false

    var kindTitle: String {
        switch mediaKind.lowercased() {
        case "image": return "Image"
        case "audio": return "Audio"
        case "video": return "Video"
        case "document": return "Document"
        case "location": return "Location"
        default: return "Media"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if mediaKind.lowercased() == "image", let mediaUrl, let url = URL(string: mediaUrl) {
                Button {
                    showImageViewer = true
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(darkMode ? Color(red: 0.15, green: 0.20, blue: 0.26) : Color(red: 0.89, green: 0.95, blue: 1.0))
                            .frame(width: 220, height: 140)

                        AsyncImage(url: url) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 220, height: 140)
                                    .clipped()
                            case .failure(_):
                                Text("Tap to open image")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))
                            default:
                                ProgressView()
                                    .tint(darkMode ? .white : AppPalette.primary)
                            }
                        }
                        VStack {
                            Spacer()
                            HStack {
                                Label("Photo", systemImage: "photo.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.35))
                        }
                        .frame(width: 220, height: 140)
                    }
                }
                .buttonStyle(.plain)
                .fullScreenCover(isPresented: $showImageViewer) {
                    ZoomableImageViewer(imageURL: url)
                }
            } else if mediaKind.lowercased() == "video", let mediaUrl, let url = URL(string: mediaUrl) {
                Button {
                    showVideoPlayer = true
                } label: {
                    VideoMessageThumbnail(url: url, darkMode: darkMode)
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showVideoPlayer) {
                    VideoPlayerSheet(videoURL: url)
                }
            } else if mediaKind.lowercased() == "audio", let mediaUrl, let url = URL(string: mediaUrl) {
                InlineAudioMessageView(audioURL: url, darkMode: darkMode)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: iconName(for: mediaKind))
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(kindTitle) message")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))

                if let mediaUrl, let url = URL(string: mediaUrl) {
                    if mediaKind.lowercased() == "document" {
                        Button {
                            showDocumentViewer = true
                        } label: {
                            Text("Open \(kindTitle.lowercased())\(fileName(from: mediaUrl).map { " · \($0)" } ?? "")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showDocumentViewer) {
                            DocumentPreviewSheet(documentURL: url)
                        }
                    } else {
                        Link(destination: url) {
                            Text("Open \(kindTitle.lowercased())\(fileName(from: mediaUrl).map { " · \($0)" } ?? "")")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))
                        }
                    }
                    if mediaKind.lowercased() == "document" {
                        RemoteFileMetaView(url: url)
                    }
                }
            }

            if !caption.isEmpty, !caption.hasPrefix("[") {
                Text(caption)
                    .font(.system(size: 14))
                    .foregroundStyle(AppPalette.textPrimary)
            }
        }
    }

    private func iconName(for kind: String) -> String {
        switch kind.lowercased() {
        case "audio": return "waveform"
        case "video": return "video.fill"
        case "document": return "doc.fill"
        case "location": return "mappin.and.ellipse"
        default: return "photo.fill"
        }
    }

    private func fileName(from urlText: String) -> String? {
        guard let url = URL(string: urlText) else { return nil }
        let value = url.lastPathComponent
        return value.isEmpty ? nil : value
    }
}

private struct VideoMessageThumbnail: View {
    let url: URL
    let darkMode: Bool
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(darkMode ? Color(red: 0.15, green: 0.20, blue: 0.26) : Color(red: 0.89, green: 0.95, blue: 1.0))
                .frame(width: 220, height: 140)

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 220, height: 140)
                    .clipped()
            } else {
                ProgressView().tint(darkMode ? .white : AppPalette.primary)
            }

            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 1)
                )

            VStack {
                Spacer()
                HStack {
                    Text("Video")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(url.lastPathComponent)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
            }
            .frame(width: 220, height: 140)
        }
        .task(id: url) {
            thumbnail = await makeVideoThumbnail(url: url)
        }
    }

    private func makeVideoThumbnail(url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVURLAsset(url: url)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                let time = CMTime(seconds: 0.2, preferredTimescale: 600)
                do {
                    let cg = try generator.copyCGImage(at: time, actualTime: nil)
                    continuation.resume(returning: UIImage(cgImage: cg))
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

private struct VideoPlayerSheet: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentSeconds: Double = 0
    @State private var durationSeconds: Double = 0
    @State private var isScrubbing = false
    @State private var scrubbingSeconds: Double = 0
    @State private var timeObserverToken: Any?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                PlainVideoPlayerView(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(16)
                Spacer()

                VStack(spacing: 8) {
                    HStack(spacing: 18) {
                        Button("<<") {
                            guard let player else { return }
                            let next = max(0, player.currentTime().seconds - 10)
                            player.seek(to: CMTime(seconds: next, preferredTimescale: 600))
                        }
                        .foregroundStyle(.white)

                        Button {
                            guard let player else { return }
                            if isPlaying {
                                player.pause()
                                isPlaying = false
                            } else {
                                player.play()
                                isPlaying = true
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                        }

                        Button(">>") {
                            guard let player else { return }
                            let maxDuration = max(durationSeconds, player.currentItem?.duration.seconds ?? 0)
                            let next = min(maxDuration, player.currentTime().seconds + 10)
                            player.seek(to: CMTime(seconds: next, preferredTimescale: 600))
                        }
                        .foregroundStyle(.white)
                    }

                    Slider(
                        value: Binding(
                            get: { isScrubbing ? scrubbingSeconds : currentSeconds },
                            set: { value in
                                isScrubbing = true
                                scrubbingSeconds = value
                            }
                        ),
                        in: 0...(max(durationSeconds, 1)),
                        onEditingChanged: { editing in
                            isScrubbing = editing
                            guard !editing, let player else { return }
                            player.seek(to: CMTime(seconds: scrubbingSeconds, preferredTimescale: 600))
                        }
                    )
                    .tint(AppPalette.primary)

                    HStack {
                        Text(formatVideoTime(currentSeconds))
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.system(size: 12))
                        Spacer()
                        Text(formatVideoTime(durationSeconds))
                            .foregroundStyle(.white.opacity(0.9))
                            .font(.system(size: 12))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(Color.black.opacity(0.55))
            }
        }
        .onAppear {
            guard player == nil else { return }
            let p = AVPlayer(url: videoURL)
            player = p
            durationSeconds = p.currentItem?.asset.duration.seconds.isFinite == true ? (p.currentItem?.asset.duration.seconds ?? 0) : 0
            p.play()
            isPlaying = true

            timeObserverToken = p.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
                queue: .main
            ) { time in
                if !isScrubbing {
                    currentSeconds = max(0, time.seconds)
                }
                let d = p.currentItem?.duration.seconds ?? durationSeconds
                if d.isFinite, d > 0 { durationSeconds = d }
                if durationSeconds > 0, currentSeconds >= durationSeconds {
                    isPlaying = false
                }
            }
        }
        .onDisappear {
            player?.pause()
            isPlaying = false
            if let token = timeObserverToken, let player {
                player.removeTimeObserver(token)
            }
            timeObserverToken = nil
        }
    }
}

private struct PlainVideoPlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.playerLayer.videoGravity = .resizeAspect
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

private func formatVideoTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds > 0 else { return "0:00" }
    let total = Int(seconds)
    let mins = total / 60
    let secs = total % 60
    return "\(mins):\(String(format: "%02d", secs))"
}

private struct InlineAudioMessageView: View {
    let audioURL: URL
    let darkMode: Bool

    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentSeconds: Double = 0
    @State private var durationSeconds: Double = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button {
                    togglePlayback()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))
                }
                Text("Audio message")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78))
                Spacer()
            }

            AudioWaveformView(
                progress: progressValue,
                darkMode: darkMode,
                activeColor: darkMode ? Color(red: 0.74, green: 0.86, blue: 1.0) : Color(red: 0.11, green: 0.34, blue: 0.78)
            )

            Text("\(formatTime(currentSeconds)) / \(formatTime(durationSeconds))")
                .font(.system(size: 11))
                .foregroundStyle(AppPalette.textMuted)
        }
        .padding(.vertical, 2)
        .onAppear {
            if player == nil {
                let item = AVPlayerItem(url: audioURL)
                player = AVPlayer(playerItem: item)
                durationSeconds = item.asset.duration.seconds.isFinite ? item.asset.duration.seconds : 0
                if durationSeconds <= 0 {
                    Task {
                        let asset = AVURLAsset(url: audioURL)
                        do {
                            let loaded = try await asset.load(.duration)
                            let secs = loaded.seconds
                            if secs.isFinite, secs > 0 {
                                durationSeconds = secs
                                return
                            }
                        } catch {
                        }
                        do {
                            let (data, _) = try await URLSession.shared.data(from: audioURL)
                            let audioPlayer = try AVAudioPlayer(data: data)
                            let secs = audioPlayer.duration
                            if secs.isFinite, secs > 0 {
                                durationSeconds = secs
                            }
                        } catch {
                        }
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            player?.pause()
            isPlaying = false
        }
    }

    private var progressValue: Double {
        guard durationSeconds > 0 else { return 0 }
        return max(0, min(1, currentSeconds / durationSeconds))
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            timer?.invalidate()
            timer = nil
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                currentSeconds = player.currentTime().seconds.isFinite ? player.currentTime().seconds : 0
                let dur = player.currentItem?.duration.seconds ?? durationSeconds
                if dur.isFinite, dur > 0 {
                    durationSeconds = dur
                }
                if durationSeconds > 0, currentSeconds >= durationSeconds {
                    isPlaying = false
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

private struct ZoomableImageViewer: View {
    let imageURL: URL
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = max(1, min(4, lastScale * value))
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                            if scale <= 1.01 {
                                                scale = 1
                                                lastScale = 1
                                                offset = .zero
                                                lastOffset = .zero
                                            } else {
                                                offset = clampOffset(offset, in: geo.size, scale: scale)
                                                lastOffset = offset
                                            }
                                        },
                                    DragGesture()
                                        .onChanged { value in
                                            guard scale > 1 else { return }
                                            let candidate = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            offset = clampOffset(candidate, in: geo.size, scale: scale)
                                        }
                                        .onEnded { _ in
                                            offset = clampOffset(offset, in: geo.size, scale: scale)
                                            lastOffset = offset
                                        }
                                )
                            )
                            .onTapGesture(count: 2) {
                                if scale > 1.01 {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2.5
                                    lastScale = 2.5
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    case .failure(_):
                        Text("Failed to load image")
                            .foregroundStyle(AppPalette.textPrimary)
                    default:
                        ProgressView()
                            .tint(AppPalette.primary)
                    }
                }
            }
        }
        .onTapGesture(count: 1) {
            dismiss()
        }
    }

    private func clampOffset(_ candidate: CGSize, in size: CGSize, scale: CGFloat) -> CGSize {
        guard scale > 1 else { return .zero }
        let maxX = (size.width * (scale - 1)) / 2
        let maxY = (size.height * (scale - 1)) / 2
        return CGSize(
            width: min(max(candidate.width, -maxX), maxX),
            height: min(max(candidate.height, -maxY), maxY)
        )
    }
}

private struct DocumentPreviewSheet: View {
    let documentURL: URL

    var body: some View {
        VStack(spacing: 0) {
            if documentURL.pathExtension.lowercased() == "pdf" {
                NativePDFPreview(url: documentURL)
            } else {
                PDFWebPreview(url: documentURL)
            }
        }
    }
}

private struct NativePDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        guard uiView.document == nil else { return }
        Task.detached {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let document = PDFDocument(data: data) else { return }
                await MainActor.run {
                    uiView.document = document
                }
            } catch {
            }
        }
    }
}

private struct PDFWebPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let wrapped = "https://docs.google.com/gview?embedded=1&url=\(url.absoluteString)"
        if uiView.url?.absoluteString != wrapped, let requestURL = URL(string: wrapped) {
            uiView.load(URLRequest(url: requestURL))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {}
}

private struct AudioWaveformView: View {
    let progress: Double
    let darkMode: Bool
    let activeColor: Color

    private let bars: [CGFloat] = [4, 10, 7, 12, 5, 9, 11, 6, 13, 8, 10, 5, 12, 7, 9, 4, 11, 8, 10, 6, 12, 5]

    var body: some View {
        let activeBars = Int(Double(bars.count) * min(max(progress, 0), 1))
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(bars.enumerated()), id: \.offset) { idx, barHeight in
                RoundedRectangle(cornerRadius: 999)
                    .fill(idx <= activeBars ? activeColor : (darkMode ? Color(red: 0.20, green: 0.25, blue: 0.33) : Color(red: 0.82, green: 0.90, blue: 1.0)))
                    .frame(width: 4, height: barHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RemoteFileMetaView: View {
    let url: URL
    @State private var sizeText: String = ""

    var body: some View {
        Text(sizeText)
            .font(.system(size: 11))
            .foregroundStyle(AppPalette.textMuted)
            .task {
                if !sizeText.isEmpty { return }
                do {
                    var request = URLRequest(url: url)
                    request.httpMethod = "HEAD"
                    let (_, response) = try await URLSession.shared.data(for: request)
                    let bytes = response.expectedContentLength
                    guard bytes > 0 else { return }
                    let kb = Double(bytes) / 1024.0
                    if kb < 1024 {
                        sizeText = String(format: "%.0f KB", kb)
                    } else {
                        sizeText = String(format: "%.2f MB", kb / 1024.0)
                    }
                } catch {
                    sizeText = ""
                }
            }
    }
}
