import SwiftUI

struct ThreadedDiscussionView: View {
    let targetID: UUID
    @StateObject private var service = ThreadedDiscussionService.shared
    @State private var newComment = ""

    var body: some View {
        VStack {
            let thread = service.threads.first { $0.targetID == targetID }

            List {
                if let comments = thread?.comments {
                    ForEach(comments) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.author).font(.caption.bold())
                            Text(comment.text)
                        }
                    }
                }
            }

            HStack {
                TextField("Add a comment...", text: $newComment)
                Button("Post") {
                    if let threadID = thread?.id {
                        service.postComment(threadID: threadID, text: newComment)
                        newComment = ""
                    }
                }
            }
            .padding()
        }
    }
}
