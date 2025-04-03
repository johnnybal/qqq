import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Models
struct Poll: Codable {
    let id: String
    let question: String
    let options: [PollOption]
    let creatorId: String
    let createdAt: Date
    let expiresAt: Date
    let isAnonymous: Bool
    let category: PollCategory
    var totalVotes: Int
    var boostCount: Int
    var matchType: String?
    var matchedUsers: [String]?
    
    enum PollCategory: String, Codable, CaseIterable {
        case general
        case school
        case sports
        case entertainment
        case dating
        case other
    }
}

struct PollOption: Codable {
    let id: String
    let text: String
    var voteCount: Int
}

struct PollVote: Codable {
    let pollId: String
    let userId: String
    let optionId: String
    let timestamp: Date
}

// MARK: - PollCell
class PollCell: UITableViewCell {
    static let identifier = "PollCell"
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let timeRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(questionLabel)
        contentView.addSubview(optionsStackView)
        contentView.addSubview(timeRemainingLabel)
        contentView.addSubview(categoryLabel)
        
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 12),
            optionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            timeRemainingLabel.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 8),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeRemainingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            categoryLabel.centerYAnchor.constraint(equalTo: timeRemainingLabel.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with poll: Poll) {
        questionLabel.text = poll.question
        categoryLabel.text = poll.category.rawValue.capitalized
        
        // Clear existing options
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add option buttons
        for option in poll.options {
            let button = UIButton(type: .system)
            button.setTitle(option.text, for: .normal)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 8
            button.tag = Int(option.id) ?? 0
            
            let votePercentage = poll.totalVotes > 0 ? Double(option.voteCount) / Double(poll.totalVotes) : 0
            button.setTitle("\(option.text) (\(Int(votePercentage * 100))%)", for: .normal)
            
            optionsStackView.addArrangedSubview(button)
        }
        
        // Update time remaining
        let timeRemaining = poll.expiresAt.timeIntervalSince(Date())
        if timeRemaining > 0 {
            let hours = Int(timeRemaining) / 3600
            let minutes = (Int(timeRemaining) % 3600) / 60
            timeRemainingLabel.text = "\(hours)h \(minutes)m remaining"
        } else {
            timeRemainingLabel.text = "Poll ended"
        }
    }
}

// MARK: - PollsViewController
class PollsViewController: UIViewController {
    // MARK: - Properties
    private let tableView = UITableView()
    private let createPollButton = UIButton(type: .system)
    private var polls: [Poll] = []
    private let db = Firestore.firestore()
    private let refreshControl = UIRefreshControl()
    private let emptyStateView = EmptyStateView()
    private let filterButton = UIButton(type: .system)
    private var selectedCategory: Poll.PollCategory?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupRefreshControl()
        setupEmptyState()
        fetchPolls()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Polls"
        view.backgroundColor = .systemBackground
        
        // TableView setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PollCell.self, forCellReuseIdentifier: PollCell.identifier)
        tableView.separatorStyle = .none
        
        // Create Poll Button
        createPollButton.setTitle("Create Poll", for: .normal)
        createPollButton.backgroundColor = .systemBlue
        createPollButton.setTitleColor(.white, for: .normal)
        createPollButton.layer.cornerRadius = 25
        createPollButton.addTarget(self, action: #selector(createPollTapped), for: .touchUpInside)
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(createPollButton)
        
        // Setup constraints
        tableView.translatesAutoresizingMaskIntoConstraints = false
        createPollButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            createPollButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createPollButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createPollButton.widthAnchor.constraint(equalToConstant: 120),
            createPollButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshPolls), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupEmptyState() {
        emptyStateView.configure(
            title: "No Polls Yet",
            message: "Be the first to create a poll!",
            buttonTitle: "Create Poll"
        )
        emptyStateView.button.addTarget(self, action: #selector(createPollTapped), for: .touchUpInside)
        view.addSubview(emptyStateView)
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    @objc private func createPollTapped() {
        let createPollVC = CreatePollViewController()
        createPollVC.delegate = self
        let nav = UINavigationController(rootViewController: createPollVC)
        present(nav, animated: true)
    }
    
    @objc private func refreshPolls() {
        fetchPolls()
    }
    
    // MARK: - Data
    private func fetchPolls() {
        var query = db.collection("polls")
            .order(by: "createdAt", descending: true)
        
        if let category = selectedCategory {
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        
        query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            self.refreshControl.endRefreshing()
            
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.polls = []
                self.tableView.reloadData()
                self.updateEmptyState()
                return
            }
            
            self.polls = documents.compactMap { document -> Poll? in
                try? document.data(as: Poll.self)
            }
            
            self.tableView.reloadData()
            self.updateEmptyState()
        }
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !polls.isEmpty
        tableView.isHidden = polls.isEmpty
    }
    
    @objc private func filterButtonTapped() {
        let alert = UIAlertController(title: "Filter Polls", message: nil, preferredStyle: .actionSheet)
        
        // Add "All" option
        alert.addAction(UIAlertAction(title: "All Categories", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.fetchPolls()
        })
        
        // Add category options
        for category in Poll.PollCategory.allCases {
            alert.addAction(UIAlertAction(title: category.rawValue.capitalized, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.fetchPolls()
            })
        }
        
        // Add cancel option
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension PollsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return polls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PollCell.identifier, for: indexPath) as? PollCell else {
            return UITableViewCell()
        }
        
        let poll = polls[indexPath.row]
        cell.configure(with: poll)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let poll = polls[indexPath.row]
        let detailVC = PollDetailViewController(poll: poll)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - CreatePollViewController
class CreatePollViewController: UIViewController {
    // MARK: - Properties
    weak var delegate: PollsViewController?
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let questionTextField = UITextField()
    private let optionsStackView = UIStackView()
    private let categorySegmentedControl = UISegmentedControl()
    private let anonymousSwitch = UISwitch()
    private let durationPicker = UIDatePicker()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Create Poll"
        view.backgroundColor = .systemBackground
        
        // Navigation bar setup
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Create",
            style: .done,
            target: self,
            action: #selector(createTapped)
        )
        
        // Question TextField
        questionTextField.placeholder = "Enter your question"
        questionTextField.borderStyle = .roundedRect
        
        // Options StackView
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 8
        
        // Category Segmented Control
        let categories = Poll.PollCategory.allCases.map { $0.rawValue.capitalized }
        categorySegmentedControl = UISegmentedControl(items: categories)
        categorySegmentedControl.selectedSegmentIndex = 0
        
        // Anonymous Switch
        let anonymousLabel = UILabel()
        anonymousLabel.text = "Anonymous Poll"
        
        // Duration Picker
        durationPicker.datePickerMode = .countDownTimer
        durationPicker.minuteInterval = 15
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(questionTextField)
        contentView.addSubview(optionsStackView)
        contentView.addSubview(categorySegmentedControl)
        contentView.addSubview(anonymousLabel)
        contentView.addSubview(anonymousSwitch)
        contentView.addSubview(durationPicker)
        
        // Setup constraints
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        questionTextField.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        categorySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        anonymousLabel.translatesAutoresizingMaskIntoConstraints = false
        anonymousSwitch.translatesAutoresizingMaskIntoConstraints = false
        durationPicker.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            questionTextField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            questionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            questionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            optionsStackView.topAnchor.constraint(equalTo: questionTextField.bottomAnchor, constant: 20),
            optionsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            categorySegmentedControl.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 20),
            categorySegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categorySegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            anonymousLabel.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor, constant: 20),
            anonymousLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            anonymousSwitch.centerYAnchor.constraint(equalTo: anonymousLabel.centerYAnchor),
            anonymousSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            durationPicker.topAnchor.constraint(equalTo: anonymousLabel.bottomAnchor, constant: 20),
            durationPicker.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            durationPicker.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Add initial option fields
        addOptionField()
        addOptionField()
    }
    
    private func addOptionField() {
        let textField = UITextField()
        textField.placeholder = "Enter option \(optionsStackView.arrangedSubviews.count + 1)"
        textField.borderStyle = .roundedRect
        optionsStackView.addArrangedSubview(textField)
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func createTapped() {
        guard let question = questionTextField.text, !question.isEmpty else {
            showAlert(title: "Error", message: "Please enter a question")
            return
        }
        
        let options = optionsStackView.arrangedSubviews.compactMap { view -> String? in
            guard let textField = view as? UITextField else { return nil }
            return textField.text
        }.filter { !$0.isEmpty }
        
        guard options.count >= 2 else {
            showAlert(title: "Error", message: "Please enter at least 2 options")
            return
        }
        
        let poll = Poll(
            id: UUID().uuidString,
            question: question,
            options: options.enumerated().map { index, text in
                PollOption(id: String(index), text: text, voteCount: 0)
            },
            creatorId: Auth.auth().currentUser?.uid ?? "",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(durationPicker.countDownDuration),
            isAnonymous: anonymousSwitch.isOn,
            category: Poll.PollCategory.allCases[categorySegmentedControl.selectedSegmentIndex],
            totalVotes: 0,
            boostCount: 0,
            matchType: nil,
            matchedUsers: nil
        )
        
        savePoll(poll)
    }
    
    private func savePoll(_ poll: Poll) {
        do {
            try db.collection("polls").document(poll.id).setData(from: poll)
            dismiss(animated: true)
        } catch {
            showAlert(title: "Error", message: "Failed to create poll: \(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - PollDetailViewController
class PollDetailViewController: UIViewController {
    // MARK: - Properties
    private let poll: Poll
    private let db = Firestore.firestore()
    
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let optionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()
    
    private let timeRemainingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    // MARK: - Initialization
    init(poll: Poll) {
        self.poll = poll
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(questionLabel)
        view.addSubview(optionsStackView)
        view.addSubview(timeRemainingLabel)
        
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            questionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            questionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            optionsStackView.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 20),
            optionsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timeRemainingLabel.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor, constant: 20),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])
    }
    
    private func configureUI() {
        questionLabel.text = poll.question
        
        // Clear existing options
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add option buttons
        for option in poll.options {
            let button = UIButton(type: .system)
            button.setTitle(option.text, for: .normal)
            button.backgroundColor = .systemGray6
            button.layer.cornerRadius = 8
            button.tag = Int(option.id) ?? 0
            button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
            
            let votePercentage = poll.totalVotes > 0 ? Double(option.voteCount) / Double(poll.totalVotes) : 0
            button.setTitle("\(option.text) (\(Int(votePercentage * 100))%)", for: .normal)
            
            optionsStackView.addArrangedSubview(button)
        }
        
        // Update time remaining
        let timeRemaining = poll.expiresAt.timeIntervalSince(Date())
        if timeRemaining > 0 {
            let hours = Int(timeRemaining) / 3600
            let minutes = (Int(timeRemaining) % 3600) / 60
            timeRemainingLabel.text = "\(hours)h \(minutes)m remaining"
        } else {
            timeRemainingLabel.text = "Poll ended"
        }
    }
    
    // MARK: - Actions
    @objc private func optionTapped(_ sender: UIButton) {
        guard let option = poll.options.first(where: { $0.id == String(sender.tag) }) else {
            showAlert(title: "Error", message: "Invalid option selected")
            return
        }
        
        handleVote(for: option)
    }
    
    private func handleVote(for option: PollOption) {
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Error", message: "Please sign in to vote")
            return
        }
        
        // Create vote
        let vote = PollVote(
            pollId: poll.id,
            userId: userId,
            optionId: option.id,
            timestamp: Date()
        )
        
        // Save vote
        do {
            try db.collection("votes").document("\(poll.id)_\(userId)").setData(from: vote)
            
            // Update poll option vote count
            db.collection("polls").document(poll.id).updateData([
                "options.\(option.id).voteCount": FieldValue.increment(Int64(1)),
                "totalVotes": FieldValue.increment(Int64(1))
            ])
            
            // Send notification to the selected user
            if let selectedUserId = option.userId {
                NotificationsManager.shared.sendPollSelectionNotification(
                    selectedBy: userId,
                    pollType: poll.question,
                    isPremiumUser: false, // You'll need to check this from user data
                    pollId: poll.id
                )
            }
            
            // Check for matches
            checkForMatches(selectedUserId: option.userId)
            
            // Disable all buttons after voting
            optionsStackView.arrangedSubviews.forEach { view in
                if let button = view as? UIButton {
                    button.isEnabled = false
                }
            }
            
            showAlert(title: "Success", message: "Your vote has been recorded!")
        } catch {
            showAlert(title: "Error", message: "Failed to record vote: \(error.localizedDescription)")
        }
    }
    
    private func checkForMatches(selectedUserId: String) {
        // Check if the selected user has also voted for the current user
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("votes")
            .whereField("pollId", isEqualTo: poll.id)
            .whereField("selectedUserId", isEqualTo: currentUserId)
            .whereField("userId", isEqualTo: selectedUserId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking for matches: \(error.localizedDescription)")
                    return
                }
                
                if let document = snapshot?.documents.first {
                    // It's a match!
                    self.handleMatch(between: currentUserId, and: selectedUserId)
                }
            }
    }
    
    private func handleMatch(between user1: String, and user2: String) {
        // Create a match record
        let matchId = UUID().uuidString
        let match = [
            "id": matchId,
            "users": [user1, user2],
            "timestamp": FieldValue.serverTimestamp(),
            "type": poll.category.rawValue
        ]
        
        db.collection("matches").document(matchId).setData(match) { [weak self] error in
            if let error = error {
                print("Error creating match: \(error.localizedDescription)")
                return
            }
            
            // Send match notifications to both users
            self?.sendMatchNotifications(user1: user1, user2: user2)
        }
    }
    
    private func sendMatchNotifications(user1: String, user2: String) {
        // Fetch user names
        let group = DispatchGroup()
        var user1Name = ""
        var user2Name = ""
        
        group.enter()
        db.collection("users").document(user1).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["name"] as? String {
                user1Name = name
            }
            group.leave()
        }
        
        group.enter()
        db.collection("users").document(user2).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let name = data["name"] as? String {
                user2Name = name
            }
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            // Send notifications to both users
            NotificationsManager.shared.sendMatchNotification(
                matchedUser: user1Name,
                matchType: self?.poll.category.rawValue ?? "general"
            )
            
            NotificationsManager.shared.sendMatchNotification(
                matchedUser: user2Name,
                matchType: self?.poll.category.rawValue ?? "general"
            )
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// Add EmptyStateView
class EmptyStateView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    let button = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Configure imageView
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        
        // Configure labels
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textColor = .systemGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        // Configure button
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        
        // Add subviews
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(button)
        
        // Setup constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 120),
            imageView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            button.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(title: String, message: String, buttonTitle: String) {
        titleLabel.text = title
        messageLabel.text = message
        button.setTitle(buttonTitle, for: .normal)
    }
} 