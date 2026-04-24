import UIKit
import SwiftUI

/// Displays detailed information about a repository and provides actions.
final class RepoDetailViewController: UIViewController {

    private let repository: GitHubRepository
    private var collectionView: UICollectionView!

    enum Section: Int, CaseIterable {
        case header
        case stats
        case actions

        var title: String? {
            switch self {
            case .header: return nil
            case .stats: return "Statistics"
            case .actions: return "Actions"
            }
        }
    }

    init(repository: GitHubRepository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = repository.name
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        setupCollectionView()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            config.headerMode = .supplementary
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(UICollectionViewListCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")

        view.addSubview(collectionView)
    }
}

extension RepoDetailViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .header: return 1
        case .stats: return 3
        case .actions: return 4
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICollectionViewListCell
        var content = cell.defaultContentConfiguration()

        guard let section = Section(rawValue: indexPath.section) else { return cell }

        switch section {
        case .header:
            content.text = repository.fullName
            content.secondaryText = repository.description
            content.secondaryTextProperties.numberOfLines = 0
        case .stats:
            if indexPath.item == 0 {
                content.text = "Stars"
                content.secondaryText = "\(repository.stargazersCount)"
                content.image = UIImage(systemName: "star.fill")
                content.imageProperties.tintColor = .systemYellow
            } else if indexPath.item == 1 {
                content.text = "Forks"
                content.secondaryText = "\(repository.forksCount)"
                content.image = UIImage(systemName: "arrow.triangle.branch")
                content.imageProperties.tintColor = .systemGreen
            } else {
                content.text = "Watchers"
                content.secondaryText = "\(repository.watchersCount)"
                content.image = UIImage(systemName: "eye.fill")
                content.imageProperties.tintColor = .systemPurple
            }
        case .actions:
            let actions = ["Branches", "Commits", "Pull Requests", "File Explorer"]
            let icons = ["arrow.branch", "clock.fill", "tray.full.fill", "folder.fill"]
            content.text = actions[indexPath.item]
            content.image = UIImage(systemName: icons[indexPath.item])
            cell.accessories = [.disclosureIndicator()]
        }

        cell.contentConfiguration = content
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! UICollectionViewListCell
        var content = header.defaultContentConfiguration()
        content.text = Section(rawValue: indexPath.section)?.title
        header.contentConfiguration = content
        return header
    }
}

extension RepoDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.section == Section.actions.rawValue else { return }

        switch indexPath.item {
        case 0: // Branches
            let vc = UIHostingController(rootView: BranchListView(owner: repository.owner.login, repo: repository.name))
            navigationController?.pushViewController(vc, animated: true)
        case 1: // Commits
            let vc = UIHostingController(rootView: CommitHistoryView(owner: repository.owner.login, repo: repository.name))
            navigationController?.pushViewController(vc, animated: true)
        case 2: // PRs
            let vc = UIHostingController(rootView: PullRequestsView(owner: repository.owner.login, repo: repository.name))
            navigationController?.pushViewController(vc, animated: true)
        case 3: // File Explorer
            let vc = UIHostingController(rootView: RepoFileExplorerView(owner: repository.owner.login, repo: repository.name, path: ""))
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
