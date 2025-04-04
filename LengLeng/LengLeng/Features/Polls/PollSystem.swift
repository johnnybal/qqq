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
    
    private var selectedOptionId: String?
    private var poll: Poll?
    private var onVote: ((String) -> Void)?
    
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
            timeRemainingLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            categoryLabel.centerYAnchor.constraint(equalTo: timeRemainingLabel.centerYAnchor),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with poll: Poll, onVote: @escaping (String) -> Void) {
        self.poll = poll
        self.onVote = onVote
        self.selectedOptionId = nil
        
        questionLabel.text = poll.question
        categoryLabel.text = poll.category.rawValue.capitalized
        timeRemainingLabel.text = poll.expiresAt.timeAgoDisplay()
        
        // Clear existing options
        optionsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new options
        for option in poll.options {
            let optionButton = createOptionButton(option: option)
            optionsStackView.addArrangedSubview(optionButton)
        }
    }
    
    private func createOptionButton(option: PollOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(option.text, for: .normal)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        
        // Add percentage label
        let percentageLabel = UILabel()
        percentageLabel.font = .systemFont(ofSize: 14)
        percentageLabel.textColor = .systemGray
        if poll?.totalVotes ?? 0 > 0 {
            let percentage = Int((Double(option.voteCount) / Double(poll?.totalVotes ?? 1)) * 100)
            percentageLabel.text = "\(percentage)%"
        }
        
        button.addSubview(percentageLabel)
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            percentageLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -12),
            percentageLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        // Style based on selection
        if selectedOptionId == option.id {
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            percentageLabel.textColor = .white
        } else {
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
        }
        
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(optionTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func optionTapped(_ sender: UIButton) {
        guard let poll = poll,
              let optionIndex = optionsStackView.arrangedSubviews.firstIndex(of: sender),
              selectedOptionId == nil else { return }
        
        let option = poll.options[optionIndex]
        selectedOptionId = option.id
        onVote?(option.id)
        
        // Update UI
        for (index, view) in optionsStackView.arrangedSubviews.enumerated() {
            if let button = view as? UIButton {
                if index == optionIndex {
                    button.backgroundColor = .systemBlue
                    button.setTitleColor(.white, for: .normal)
                    if let percentageLabel = button.subviews.first as? UILabel {
                        percentageLabel.textColor = .white
                    }
                } else {
                    button.isEnabled = false
                }
            }
        }
    }
}

// MARK: - PollsViewController
class PollsViewController: UIViewController {
    private let tableView = UITableView()
    private var polls: [Poll] = []
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchPolls()
    }
    
    private func setupUI() {
        title = "Polls"
        view.backgroundColor = .systemBackground
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PollCell.self, forCellReuseIdentifier: PollCell.identifier)
        tableView.separatorStyle = .none
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshPolls), for: .valueChanged)
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func fetchPolls() {
        FirebaseService.shared.fetchPolls { [weak self] result in
            switch result {
            case .success(let polls):
                self?.polls = polls
                self?.tableView.reloadData()
            case .failure(let error):
                print("Error fetching polls: \(error)")
            }
            self?.refreshControl.endRefreshing()
        }
    }
    
    @objc private func refreshPolls() {
        fetchPolls()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension PollsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return polls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PollCell.identifier, for: indexPath) as! PollCell
        let poll = polls[indexPath.row]
        cell.configure(with: poll) { [weak self] optionId in
            self?.voteOnPoll(pollId: poll.id, optionId: optionId)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    private func voteOnPoll(pollId: String, optionId: String) {
        FirebaseService.shared.voteOnPoll(pollId: pollId, optionId: optionId) { [weak self] result in
            switch result {
            case .success:
                self?.fetchPolls()
            case .failure(let error):
                print("Error voting on poll: \(error)")
            }
        }
    }
} 