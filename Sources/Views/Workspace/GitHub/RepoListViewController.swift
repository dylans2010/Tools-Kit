import UIKit
import Combine

/// Displays a list of repositories for the authenticated user.
final class RepoListViewController: UIViewController {

    private enum Section {
        case main
    }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, GitHubRepository>!
    private var cancellables = Set<AnyCancellable>()

    private let searchController = UISearchController(searchResultsController: nil)
    private var repositories: [GitHubRepository] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDataSource()
        fetchRepositories()
    }

    private func setupUI() {
        title = "Repositories"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true

        setupCollectionView()
        setupSearchController()
    }

    private func setupCollectionView() {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            self?.makeSwipeActions(for: indexPath)
        }

        let layout = UICollectionViewCompositionalLayout.list(using: config)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.delegate = self
        view.addSubview(collectionView)
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search repositories..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, GitHubRepository> { cell, indexPath, repo in
            var content = cell.defaultContentConfiguration()
            content.text = repo.name
            content.secondaryText = repo.description
            content.image = UIImage(systemName: repo.private ? "lock.fill" : "book.closed.fill")
            content.imageProperties.tintColor = repo.private ? .systemOrange : .systemBlue

            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, GitHubRepository>(collectionView: collectionView) { collectionView, indexPath, repo in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: repo)
        }
    }

    private func fetchRepositories() {
        Task {
            do {
                let repos: [GitHubRepository] = try await GitHubAPIClient.shared.request(.userRepos)
                self.repositories = repos
                updateSnapshot(with: repos)
            } catch {
                presentError(error)
            }
        }
    }

    private func updateSnapshot(with repos: [GitHubRepository]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, GitHubRepository>()
        snapshot.appendSections([.main])
        snapshot.appendItems(repos)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func makeSwipeActions(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let repo = dataSource.itemIdentifier(for: indexPath) else { return nil }

        let starAction = UIContextualAction(style: .normal, title: "Star") { _, _, completion in
            Task {
                try? await GitHubAPIClient.shared.requestEmpty(.starred(owner: repo.owner.login, repo: repo.name))
                completion(true)
            }
        }
        starAction.backgroundColor = .systemYellow
        starAction.image = UIImage(systemName: "star.fill")

        return UISwipeActionsConfiguration(actions: [starAction])
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension RepoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let repo = dataSource.itemIdentifier(for: indexPath) else { return }

        let detailVC = RepoDetailViewController(repository: repo)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension RepoListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        if query.isEmpty {
            updateSnapshot(with: repositories)
            return
        }

        Task {
            do {
                // Simplified search: filter local if not hitting API
                // For production, we'd call .searchRepos(query: query)
                let filtered = repositories.filter { $0.name.localizedCaseInsensitiveContains(query) }
                updateSnapshot(with: filtered)
            }
        }
    }
}
